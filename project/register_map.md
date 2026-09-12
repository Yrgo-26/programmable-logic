# Registerkartan

Det gemensamma kontraktet mellan **hårdvarugruppen** (den här kursen, som bygger CAN-noden i VHDL)
och **mjukvarugruppen** (parallellklassen, som skriver C++-drivrutinen). Båda sidor skriver mot det
här dokumentet, aldrig mot varandras kod.

> **Ändras kartan berör det två klasser.** Originalet är `project/register_map.md` i
> hårdvarukursens repo. Drivrutinskursen har en ordagrann kopia av det under
> `projects/P03/contract/` i sitt eget repo, plus en kortare sammanfattning i sitt kursmaterial.
> Ordningen vid en ändring är därför: originalet först, kopian i samma veva, koden sist. Aldrig
> tvärtom, och aldrig bara den ena.

Registren nås över SPI. Transaktionsformatet, alltså hur en läsning eller skrivning faktiskt ser
ut på ledningarna, står i [SPI- och registerprotokollet](./spi_register_protocol.md), som är den
auktoritativa specifikationen. Det här dokumentet beskriver *vad* registren betyder; det gör
*hur* de nås.

> **Observera.** En äldre version av det här projektet lät drivrutinen nå registren via
> minnesmappad I/O på basadressen `0xFF200000`. Det förutsätter en processor med en adressbuss ut
> mot FPGA-väven, vilket mikrokontrollern i det här systemet inte har. Registren nås över SPI, och kolumnen **Index**
> nedan, inte offseten, är det som står i kommandobyten.

---

## Registren

| Index | Register | Offset | Åtkomst | Beskrivning |
|---|---|---|---|---|
| 0 | `STATUS` | 0x00 | R | Bit 0: TX klar. Bit 1: RX giltig. Bit 2: Fel. |
| 1 | `TX_ID` | 0x04 | R/W | 11-bitars sändar-ID (bitarna 10-0). |
| 2 | `TX_DLC` | 0x08 | R/W | Data Length Code (bitarna 3-0, värde 0-8). |
| 3 | `TX_DATA_LO` | 0x0C | R/W | Sändardata byte 0-3 (byte 0 = MSB). |
| 4 | `TX_DATA_HI` | 0x10 | R/W | Sändardata byte 4-7 (byte 4 = MSB). |
| 5 | `TX_SEND` | 0x14 | W | Skriv `0x1` för att utlösa sändning. |
| 6 | `RX_ID` | 0x18 | R | Mottagen identifierare (bitarna 10-0). |
| 7 | `RX_DLC` | 0x1C | R | Mottagen DLC (bitarna 3-0). |
| 8 | `RX_DATA_LO` | 0x20 | R | Mottagen data byte 0-3. |
| 9 | `RX_DATA_HI` | 0x24 | R | Mottagen data byte 4-7. |
| 10 | `RX_ACK` | 0x28 | W | Skriv `0x1` för att kvittera och tömma RX-bufferten. |
| 11 | `ERROR_FLAGS` | 0x2C | R/W | Felregistret; skriv `0x0` för att nollställa. |
| 12 | `TX_ABORT` | 0x30 | W | Skriv `0x1` för att tvinga tillbaka TX klar efter en avbruten sändning. |

Index 13-15 är reserverade: en läsning ger `0x00000000`, en skrivning ignoreras.

`Index` är `Offset / 4`. Offseten finns kvar i tabellen därför att drivrutinens konstanter är
skrivna i den formen, men det är indexet som går ut på ledningen.

---

## STATUS

| Bit | Betydelse | Sätts av | Nollställs av |
|---|---|---|---|
| 0 | TX klar | reset; kontrollerns puls `tx_done`; en stigande flank på `error` medan biten är låg; en accepterad skrivning till `TX_ABORT` | en accepterad skrivning till `TX_SEND` |
| 1 | RX giltig | kontrollerns puls `rx_valid`, som också låser `RX_*` | en skrivning av `0x1` till `RX_ACK` |
| 2 | Fel | en **stigande flank** på kontrollerns nivå `error` | en skrivning av `0x0` till `ERROR_FLAGS` |

Poängen med hela lagret ligger i den tabellen. Kontrollern signalerar med encykelspulser, 20 ns
vid 50 MHz. En drivrutin som pollar över SPI ser systemet några mikrosekunder i taget i bästa
fall, så en puls är borta tusentals cykler innan nästa pollning kommer. Registerbanken gör om
pulserna till **klibbiga, pollbara nivåer med uttrycklig nollställning**.

---

## Semantik, register för register

* **`TX_SEND`** utlöser en enda `tx_req`-puls när ett värde med **bit 0 satt** skrivs och STATUS
  bit 0 är satt. Övriga bitar i det skrivna ordet ignoreras. Är STATUS bit 0 låg ignoreras
  skrivningen: en sändning pågår. En skrivning med bit 0 låg gör ingenting. Läsning ger
  `0x00000000`, eftersom registret inte lagrar något utan *gör* något.
* **`RX_ACK`** nollställer STATUS bit 1. Läsning ger `0x00000000`.
* **`TX_ABORT`** sätter STATUS bit 0 tillbaka till `1`, och gör ingenting annat. Bara en
  skrivning med **bit 0 satt** gör något; läsning ger `0x00000000`. Registret når inte
  kontrollern - en kontroller som avbrutit en sändning är redan tillbaka i vila och kan sända
  igen, det är bara
  bankens klibbiga bit som fastnat. Det här är nödutgången: i en riktig konstruktion ska den
  aldrig behövas, eftersom bit 0 redan har två automatiska vägar tillbaka.
* **`ERROR_FLAGS`** är en lås-och-nollställ-på-noll-konstruktion, inte ett allmänt register: bara
  en skrivning av `0x0` nollställer, alla andra värden ignoreras.
* **Maskning vid skrivning.** `TX_ID` lagrar bitarna 10-0 och `TX_DLC` bitarna 3-0; överflödiga
  bitar läses tillbaka som noll. En skrivning av `0xFFFFFFFF` läses alltså tillbaka som
  `0x000007FF` respektive `0x0000000F`. `TX_DATA_LO`/`HI` lagrar alla 32 bitarna.
* **Ingen validering.** En `TX_DLC` på `0xF` lagras och lämnas vidare till kontrollern som den är.
  Att avvisa `dlc > 8` är drivrutinens ansvar. Att göra det på båda sidor är precis så de två
  kopiorna av regeln glider isär.
* **Ingen buffring på mottagarsidan.** Kommer en ny ram innan den förra kvitterats skrivs den över,
  och den nyaste vinner. Det är ett medvetet, dokumenterat val och inte en bugg; en riktig
  kontroller har en mottagningskö.

---

## Databyteordning

`tx_data` och `rx_data` är 64 bitar breda, med databyte 0 i de mest signifikanta bitarna:

```text
bit 63                                                              bit 0
+--------+--------+--------+--------+--------+--------+--------+--------+
| byte 0 | byte 1 | byte 2 | byte 3 | byte 4 | byte 5 | byte 6 | byte 7 |
+--------+--------+--------+--------+--------+--------+--------+--------+
 \___________ TX_DATA_LO ___________/ \___________ TX_DATA_HI __________/
```

Namnen `LO` och `HI` syftar på registerparets ordning, inte på bitsignifikans. `TX_DATA_LO` bär de
*första* fyra databytesen.

---

## Detaljer en drivrutin behöver, register för register

Punkterna nedan är de som annars bara går att läsa ur `bridge/register_bank_tb.vhd`. De hör till
kontraktet lika mycket som tabellen ovan.

* **Varje register är 32 bitar brett.** Alla fem bytes i en transaktion överförs alltid, även för
  ett register som bara har fyra meningsfulla bitar.
* **`STATUS` bitarna 31-3 läses som `0`.** Testa gärna mot `status = 0x1` om ni vill; bankens
  läsmux nollar allt ovanför bit 2.
* **`ERROR_FLAGS` är **en** bit.** Bit 0 är låsningen och speglar `STATUS` bit 2; bitarna 31-1
  läses som `0`. Namnet är i plural av historiska skäl, och `R/W` i tabellen betyder inte att det
  är ett vanligt register: bara en skrivning där **hela ordet är noll** gör något. `0x000000FF`
  nollställer alltså inte, trots att bit 0 är satt.
* **`ERROR_FLAGS` skiljer inte på felorsaker.** De fyra orsakerna - förlorad arbitrering,
  stoppfel, misslyckad CRC och mottagen fjärrram - ger alla samma enda bit.
* **`RX_ACK` kräver bit 0 satt.** En skrivning med bit 0 låg gör ingenting; övriga bitar
  ignoreras. Samma regel som `TX_SEND`, och motsatsen till `ERROR_FLAGS`, som nollställs just av
  ett helt nollställt ord.
* **`RX_DATA_LO`/`HI` bortom `RX_DLC` läses som `0x00`.** Kontrollern nollställer sin
  dataackumulator vid varje ramstart, så bytes ovanför den mottagna längden bär aldrig rester från
  en tidigare ram: en ram med `DLC = 2` som följer på en med `DLC = 8` läses som två bytes data och
  sex nollor. **Maskera ändå mot `RX_DLC`** - nollorna är kontrollerns garanti, inte ramens
  innehåll, och en drivrutin som kopierar åtta bytes rapporterar sex bytes som aldrig sändes.
* **`TX_DATA_LO`/`HI` bortom `TX_DLC` skickas aldrig**, så de behöver inte nollställas.
* **Skrivningar till `STATUS`, `RX_ID`, `RX_DLC` och `RX_DATA_LO`/`HI` ignoreras tyst.**
  Transaktionen fullbordas normalt; inget fel rapporteras.
* **Läsningar av `TX_SEND` och `RX_ACK` ger `0x00000000`.** De lagrar ingenting.
* **Det finns ingen tidsgräns att härleda.** Kartan säger inte hur lång en sändning är, så en
  drivrutin som vill ge upp får välja sin timeout själv. Ett riktvärde: en maximal ram är omkring
  130 bitar, och vid 1 Mbit/s alltså omkring 130 µs, plus väntan på en ledig buss.
* **En förlorad arbitrering återställer STATUS bit 0**, precis som en lyckad sändning gör.
  Kontrollern pulsar `tx_done` också när den avbryter, och banken sätter dessutom biten på en
  stigande flank av `error` medan biten är låg. En drivrutin behöver alltså inte skilja på
  utfallen för att kunna sända igen: polla bit 0, och läs `ERROR_FLAGS` för att veta hur det
  gick. `TX_ABORT` finns som nödutgång men ska aldrig behövas.

---

## Motsvarigheter i hårdvaran

| Register | Port på `can_controller` |
|---|---|
| `TX_ID`, `TX_DLC`, `TX_DATA_LO`/`HI` | `tx_id`, `tx_dlc`, `tx_data` |
| `TX_SEND` | `tx_req` (en puls) |
| STATUS bit 0 | `tx_done` (en puls), låst till en nivå |
| `RX_ID`, `RX_DLC`, `RX_DATA_LO`/`HI` | `rx_id`, `rx_dlc`, `rx_data` |
| STATUS bit 1 | `rx_valid` (en puls), låst till en nivå |
| STATUS bit 2, `ERROR_FLAGS` | `error` (en nivå), låst på stigande flank |

Översättningen mellan de två kolumnerna är exakt vad `register_bank.vhd` i
[`bridge/`](../bridge/README.md) gör, och ingenting mer.

---

## Att ändra i det här dokumentet

Registerkartan är ett kontrakt mellan två klasser som inte kan kompilera mot varandra. Ändras den
måste båda sidor veta om det innan ändringen mergas. I praktiken: ändringar diskuteras med båda
handledarna först, och det här dokumentet uppdateras före koden, aldrig efter.

---
