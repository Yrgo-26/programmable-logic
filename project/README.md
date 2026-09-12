# Projekt: en CAN-nod i VHDL

Kursens grupprojekt, som löper över [L10](../lectures/L10/README.md) till
[L19](../lectures/L19/README.md) och står för halva kursens poäng.

Ni ska konstruera, simulera och köra en förenklad CAN-kontroller i VHDL, och göra den nåbar från
en AVR32DB28 över SPI. Parallellklassen skriver C++-drivrutinen mot samma register, så det ni
bygger är ena halvan av ett riktigt hårdvaru-/mjukvarusystem och inte en övning som slutar i
simulatorn.

När projektet är klart har ni implementerat:
* En **bittimer** som producerar sampel- och bitslutspulser.
* En **CRC-15-motor** som både beräknar och verifierar CAN:s checksumma.
* Ett **sändningsskiftregister** som serialiserar data och sätter in stoppbitar.
* Ett **mottagningsskiftregister** som deserialiserar och tar bort stoppbitar.
* En **CAN-kontroller** vars tillståndsmaskin sekvenserar ramens fält och hanterar arbitrering.
* En **registerbank** som översätter kontrollerns pulser till pollbara register.
* En **SPI-brygga** som gör registren nåbara utifrån.
* En **toppnivå** som binder ihop alltihop till en nod en mikrokontroller kan prata med.

---

## 1. Arbetsform

Projektet genomförs i grupper om **4-5 studenter**. Gruppen ansvarar gemensamt för hela
projektet, och arbetssättet följer industriell praxis.

### 1.1 Git och GitHub
* Skapa ett privat repository och bjud in alla gruppmedlemmar samt handledaren som collaborator.
* Arbeta i feature-branchar. En branch per modul är en rimlig utgångspunkt.
* Committa ofta, med meddelanden som säger vad ändringen gör och inte bara att den finns.
* **Pusha aldrig direkt till `main`.** All kod når `main` genom en Pull Request. Skydda branchen i
  GitHubs inställningar så att regeln inte beror på att alla kommer ihåg den.

### 1.2 Kodgranskning
* Varje PR granskas av **minst en annan gruppmedlem** innan den mergas.
* Granskaren kontrollerar: att portordningen stämmer mot gränssnittstabellen, att modulens
  testbänk passerar, att inga värden är hårdkodade förbi `can_def`, och att varje entitets
  gränssnitt och varje viktig intern signal är kommenterad.
* Lägg granskningskommentarer i GitHub, inte i chatt eller muntligt. En granskning som inte finns
  skriftligt har inte hänt.
* En granskning som bara säger "ser bra ut" är ingen granskning. Ställ minst en riktig fråga, även
  när koden är bra: *varför* den gör som den gör är oftare intressant än *att* den gör det.

### 1.3 Arbetsfördelning
* Alla ska skriva VHDL och alla ska granska VHDL. Fördelningen får vara ojämn i mängd, inte i art.
* Dokumentera fördelningen löpande i `CONTRIBUTORS.md` i repots rot.

---

## 2. Så här drivs projektet

Projektet har **inga milstolpar**. Varje föreläsning från L10 och framåt anger ett *riktvärde*,
formulerat som "ni bör vara ungefär här". Riktvärdena är inte krav och betygsätts inte.

Det är ett medvetet val och inte generositet. Efter `can_def.vhd` har de fyra lövmodulerna,
`bit_timer`, `crc15`, `tx_shift_reg` och `rx_shift_reg`, **inga beroenden till varandra**, och var
och en har sin egen utdelade testbänk. En grupp om 4-5 kan därför bygga dem parallellt, i vilken
ordning som helst. Att låsa fast en ordning skulle bara hindra det.

**Men beroendegrafen är inte platt, och det är värt att planera efter.** Den ser ut så här:

```text
             meta_prev                                    (läser inget paket alls)
can_def  ──> bit_timer, crc15, tx_shift_reg, rx_shift_reg (de fyra lövmodulerna, parallella)
                                    └──> can_controller   (L16 sändning, sedan L17 mottagning)
can_def  ──> register_bank                                (oberoende, byggbar från L10)
spi_def  ──> spi_reg_bridge                               (oberoende, byggbar från L10)
spi_slave                                                 (utdelad, skrivs inte av gruppen)
        can_controller + register_bank + spi_reg_bridge + spi_slave ──> can_spi_node   (L19)
```

Två saker följer av den:

* **`can_controller` är den kritiska vägen.** Den har ingen intern parallellitet, den sträcker sig
  över två pass, och dess testbänk är en systemtestbänk som antingen går igenom eller inte -
  ingen delvis grön. Den som ska äga den bör börja läsa L16:s appendix tidigt, och gruppen bör
  räkna med att den tar mest tid av allt.
* **`register_bank` och `spi_reg_bridge` är två fullvärdiga arbetsspår som kan starta direkt.**
  Den ena behöver bara `can_def`, den andra bara `spi_def`, och båda har utdelade testbänkar.
  Ingen behöver vänta på kontrollern för att ha något att göra, och en grupp som skjuter dem till
  L18 och L19 har lagt sitt tightaste arbete sist. Se
  [L19:s riktvärde](../lectures/L19/README.md).

Två hållpunkter är obligatoriska:

| När | Vad |
|---|---|
| [L15](../lectures/L15/README.md) | **Kodgranskningsseminarium.** Varje grupp visar en mergad PR och en granskning gruppen skrivit, och berättar om en sak i arbetssättet som inte fungerat. |
| [L19](../lectures/L19/README.md) | **Slutredovisning och inlämning.** Gröna testbänkar, genomgång av `can_spi_node`, bring-up på hårdvara så långt ni kommit, och repots historik. |

Det som bedöms är slutresultatet och arbetssättet: designen, Git-historiken, PR:erna och
granskningarna. **Inte takten.** En grupp som ligger efter halvvägs igenom projektet och lämnar in
en komplett, välgranskad nod har gjort projektet rätt.

---

## 3. Projektstruktur

Lägg upp gruppens repo så här. Två platta kataloger, med modulerna bredvid de testbänkar som
kontrollerar dem:

```text
controller/   can_def.vhd, meta_prev.vhd, bit_timer.vhd, crc15.vhd,
              tx_shift_reg.vhd, rx_shift_reg.vhd, can_controller.vhd
              + de sex utdelade *_tb.vhd
bridge/       register_bank.vhd, spi_reg_bridge.vhd, can_spi_node.vhd
              + utdelade spi_slave.vhd, spi_def.vhd, register_bank_tb.vhd, spi_reg_bridge_tb.vhd
ci/           build_project.sh, kopierad från kursrepot
Makefile      med målet build-project
CONTRIBUTORS.md
.gitignore
```

Gränsen mellan de två katalogerna går vid protokollet: allt i `controller/` känner till CAN och
ingenting om SPI, och **ingen modul i någondera katalogen känner till båda**. `register_bank` är
mitten: den känner varken CAN-ramformatet eller SPI utan bara registersemantik, och läser `can_def`
enbart för porttyperna. Se
[`controller/README.md`](../controller/README.md) och [`bridge/README.md`](../bridge/README.md).

De utdelade filerna hämtas från kursrepot och läggs in oförändrade. `spi_slave.vhd` skriver ni
inte: den är transport, inte kursens ämne, och ni läser den i
[L18](../lectures/L18/README.md) i stället.

---

## 4. Namnkonventioner och kodstil

All kod och alla kommentarer i koden skrivs på **engelska**. Instruktionerna är på svenska.

* Modul- och signalnamn i snake_case, till exempel `timer_enable`.
* Konstanter i SNAKE_CASE med versaler, till exempel `TICKS_PER_BIT`.
* `std_logic` och `std_logic_vector` för allt som är ledningar; `natural` för räknare.
* Inga hårdkodade värden. Allt som är protokoll ligger i `can_def`.
* Kommentera varje entitets gränssnitt och varje viktig intern signal.
* Håll gränssnitten stabila. Testbänkarna är utdelade och binder positionellt.

### 4.1 Positionell portbindning
Varje utdelad testbänk binder till sin modul **positionellt**, och det gör varje instansiering
inuti `can_controller` också. Kontraktet är alltså **ordningen och typerna** på portarna, exakt
som tabellerna i avsnitt 6 och 7 listar dem. Portarnas *namn* är era.

Byt plats på två portar av samma typ och ingenting klagar vid analys; designen beter sig bara fel
i simuleringen. Det är priset för att gränssnittstabellen får vara enda sanningskälla.

---

## 5. Det delade paketet `can_def`

Skrivs i [L10](../lectures/L10/README.md), i `controller/can_def.vhd`, och läses av allt annat.

**Konstanter:** `CLOCK_FREQ_HZ`, `BIT_RATE_HZ`, `TICKS_PER_BIT`, `SAMPLE_TICK`, `ID_WIDTH`,
`DLC_WIDTH`, `DLC_MAX`, `CRC_WIDTH`, `DATA_WIDTH`, `MAX_RUN`, `CRC_POLY`.

**Subtyper:** `byte_t`, `id_t`, `crc_t`, `dlc_t`, `data_t`.

Riktvärden för ett DE0-CV med 50 MHz systemklocka och CAN på 1 Mbit/s:

| Konstant | Värde | Kommentar |
|---|---|---|
| `CLOCK_FREQ_HZ` | `50_000_000` | Systemklockan. |
| `BIT_RATE_HZ` | `1_000_000` | 1 Mbit/s. |
| `TICKS_PER_BIT` | `CLOCK_FREQ_HZ / BIT_RATE_HZ` | 50 klockcykler per CAN-bit. Räkna ut den, skriv den inte. |
| `SAMPLE_TICK` | `TICKS_PER_BIT * 7 / 10` | Sampelpunkten, ungefär 70 % in i bitperioden. |
| `ID_WIDTH` | `11` | Standardidentifierare. |
| `DLC_WIDTH` | `4` | DLC är fyra bitar. |
| `DLC_MAX` | `8` | Högst åtta databytes. |
| `DATA_WIDTH` | `DLC_MAX * 8` | 64 bitar nyttolast. |
| `CRC_WIDTH` | `15` | CAN:s CRC-15. |
| `MAX_RUN` | `5` | Femregeln för bitstoppning. |
| `CRC_POLY` | `"100010110011001"` | Motsvarar x¹⁵ + x¹⁴ + x¹⁰ + x⁸ + x⁷ + x⁴ + x³ + 1. |

Att `TICKS_PER_BIT` och `SAMPLE_TICK` är *uträknade* och inte inskrivna spelar roll: byter någon
bithastighet ska allt följa med.

---

## 6. Modulerna i `controller/`

Beskrivningarna nedan säger vad varje modul ska göra och exakt vilket gränssnitt den ska ha.
Detaljerna, med tidsdiagram och en genomgång av vad testbänken låser fast, står i respektive
föreläsnings appendix.

### 6.1 `meta_prev.vhd` - synkroniseraren ([L12](../lectures/L12/README.md))

| # | Port / generic | Riktning | Typ |
|---|---|---|---|
| - | `WIDTH` | generic | `natural := 1` |
| 1 | `clock` | in | `std_logic` |
| 2 | `async_in` | in | `std_logic_vector(WIDTH-1 downto 0)` |
| 3 | `sync_out` | out | `std_logic_vector(WIDTH-1 downto 0)` |

Dubbelvippsynkroniseraren från [L04](../lectures/L04/README.md), skriven en gång med en
breddgeneric. Den behöver ingen reset: efter två klockcykler är innehållet ändå ersatt.
Instansieras två gånger inuti `can_controller`, för `reset_n` och för `rx_bus`.

### 6.2 `bit_timer.vhd` - bittimern ([L12](../lectures/L12/README.md))

| # | Port | Riktning | Typ | Betydelse |
|---|---|---|---|---|
| 1 | `clock` | in | `std_logic` | Systemklocka. |
| 2 | `reset_s2_n` | in | `std_logic` | Synkroniserad, aktiv låg reset. |
| 3 | `enable` | in | `std_logic` | Räknar medan `'1'`, håller medan `'0'`. |
| 4 | `resync` | in | `std_logic` | Tvingar tillbaka räknaren till tick 0. |
| 5 | `sample` | out | `std_logic` | Puls vid sampelpunkten. |
| 6 | `bit_done` | out | `std_logic` | Puls vid bitperiodens slut. |

En räknare från `0` till `TICKS_PER_BIT-1` som pulsar `sample` vid `SAMPLE_TICK` och `bit_done`
vid periodens slut. `resync` används en gång per ram, vid SOF; däremellan löper timern fritt.

### 6.3 `crc15.vhd` - CRC-motorn ([L13](../lectures/L13/README.md))

| # | Port | Riktning | Typ | Betydelse |
|---|---|---|---|---|
| 1 | `clock` | in | `std_logic` | Systemklocka. |
| 2 | `reset_s2_n` | in | `std_logic` | Synkroniserad, aktiv låg reset. |
| 3 | `clear` | in | `std_logic` | Nollställer registret utan reset. |
| 4 | `enable` | in | `std_logic` | Integrerar `data` denna flank. |
| 5 | `data` | in | `std_logic` | Aktuell bit. |
| 6 | `crc` | out | `crc_t` | Registrets nuvarande värde. |
| 7 | `valid` | out | `std_logic` | `'1'` när registret är idel nollor. |

Ett 15-bitars register med återkoppling: XOR:a insignalen med registrets högsta bit, skifta, och
XOR:a med `CRC_POLY` när resultatet av den första operationen är `'1'`.

Samma motor både genererar och kontrollerar. Sändaren matar in sina bitar och läser ut `crc`;
mottagaren matar in samma bitar *plus* den mottagna CRC:n, och `valid` går hög om allt stämmer.
Ingen lägesomkoppling behövs. `clear` behövs ändå: en avbruten ram lämnar skräp i registret.

### 6.4 `tx_shift_reg.vhd` - sändningsskiftregistret ([L14](../lectures/L14/README.md))

| # | Port | Riktning | Typ | Betydelse |
|---|---|---|---|---|
| 1 | `clock` | in | `std_logic` | Systemklocka. |
| 2 | `reset_s2_n` | in | `std_logic` | Synkroniserad, aktiv låg reset. |
| 3 | `load` | in | `std_logic` | Laddar `data`/`bit_count` **och** lägger ut första biten samma cykel. |
| 4 | `data` | in | `byte_t` | Gruppen, med sina giltiga bitar i de mest signifikanta bitarna. |
| 5 | `bit_count` | in | `std_logic_vector(3 downto 0)` | Antal giltiga bitar, 1-8. |
| 6 | `shift` | in | `std_logic` | En puls per CAN-bit, från `bit_timer.bit_done`. |
| 7 | `tx_bit` | out | `std_logic` | Biten som ska drivas nästa bitperiod. |
| 8 | `stuff` | out | `std_logic` | `'1'` på just den skiftning som lägger ut en stoppbit. |
| 9 | `done` | out | `std_logic` | Pulsar när gruppen är helt utsänd. |
| 10 | `bit_valid` | out | `std_logic` | `'1'` den cykel en ny bit lades ut på `tx_bit`. |

Skiftar ut MSB först, räknar lika bitar i rad, och sätter in en stoppbit med motsatt värde efter
`MAX_RUN` lika. **Stoppningstillståndet lever kvar över omladdningar**: regeln gäller bitströmmen,
inte den enskilda gruppen.

`stuff` och `bit_valid` finns för `can_controller`s skull: CRC:n ska matas på
`bit_valid and not stuff`, eftersom en stoppbit inte ingår i checksumman.

### 6.5 `rx_shift_reg.vhd` - mottagningsskiftregistret ([L15](../lectures/L15/README.md))

| # | Port | Riktning | Typ | Betydelse |
|---|---|---|---|---|
| 1 | `clock` | in | `std_logic` | Systemklocka. |
| 2 | `reset_s2_n` | in | `std_logic` | Synkroniserad, aktiv låg reset. |
| 3 | `sample` | in | `std_logic` | En puls per CAN-bit, från `bit_timer.sample`. |
| 4 | `rx_bus` | in | `std_logic` | Bussnivån, giltig vid sampelpunkten. |
| 5 | `bit_count` | in | `std_logic_vector(3 downto 0)` | Antal *riktiga* bitar att samla in, 1-8. |
| 6 | `enable` | in | `std_logic` | Avgör om `sample`-pulser behandlas. |
| 7 | `data` | out | `byte_t` | Den insamlade gruppen, högerjusterad. |
| 8 | `valid` | out | `std_logic` | Pulsar när `bit_count` riktiga bitar samlats in. |
| 9 | `stuff_error` | out | `std_logic` | Pulsar om en väntad stoppbit inte inverterar. |
| 10 | `real_bit` | out | `std_logic` | Den avstoppade bit som accepterades. |
| 11 | `real_bit_valid` | out | `std_logic` | `'1'` när en riktig bit accepterades, `'0'` för en kastad stoppbit. |

Sändarens spegelbild. Efter `MAX_RUN` lika bitar i rad *måste* nästa bit vara den motsatta; är den
det kastas den och räkningen börjar om, är den det inte är det ett `stuff_error`.

`real_bit`/`real_bit_valid` matar CRC-motorn på mottagarsidan, av samma skäl som `stuff` finns på
sändarsidan.

### 6.6 `can_controller.vhd` - kontrollern ([L11](../lectures/L11/README.md), [L16](../lectures/L16/README.md), [L17](../lectures/L17/README.md))

Toppnivån för CAN-halvan, och det enda block som känner till ramformatet. Den instansierar alla
delblock, och dess tillståndsmaskin sekvenserar ramens fält.

Femton portar, i exakt den här ordningen, alla ingångar först:

```text
 1 clock     4 tx_id    7 rx_bus    10 bus_en   13 rx_data
 2 reset_n   5 tx_dlc   8 tx_done   11 rx_id    14 rx_valid
 3 tx_req    6 tx_data  9 tx_bus    12 rx_dlc   15 error
```

**Ramsekvensen** en sändning går igenom: SOF (1 bit), arbitreringsfältet (11 bitars identifierare
+ RTR), kontrollfältet (IDE, r0, DLC = 6 bitar), datafältet (0-64 bitar enligt DLC), CRC (15 bitar
+ avgränsare), ACK (lucka + avgränsare) och EOF (7 bitar). Varje fält får ett eget
`LOAD`-tillstånd före sitt skifttillstånd.

**Bussen** modelleras som öppen dränering: `bus_en` avgör om noden driver alls, `tx_bus` vad den
driver. Bussvärdet är `'1'` bara om ingen nod drar ned det. Under ACK-luckan släpper den sändande
noden bussen, och en mottagare med godkänd CRC drar ned den. **Sändaren läser aldrig tillbaka
ACK-luckan.** En ram som ingen kvitterar fullbordas alltså precis som en kvitterad, och `tx_done`
pulsar ändå. Det är en medveten förenkling mot riktig CAN, och en av punkterna i
[L19 Appendix B](../lectures/L19/appendix/b_fpga_bringup_and_review.md).

**Arbitrering:** under arbitreringsfältet jämförs varje sänd bit med det som faktiskt ligger på
bussen. Skickar noden en recessiv bit och läser tillbaka en dominant har den förlorat: den sätter
`error`, pulsar `tx_done`, lämnar sändarrollen och går till `STATE_IDLE`. Den **tar inte** emot
ramen som vann; den väntar ut bussen och börjar om från nästa ram. Också det en förenkling: en
riktig nod fortsätter ta emot oavsett vem som vann.

Att `tx_done` pulsar även här är avsiktligt: pulsen betyder "sändningsförsöket är över och porten
är din igen", inte "ramen kom fram". `error` säger vilketdera. Utan den pulsen har en anropare
ingen flank att vänta på, och registerbanken i avsnitt 7.1 får aldrig tillbaka sin TX-klar-bit.

**`error`** går hög av fyra orsaker: förlorad arbitrering, `stuff_error`, misslyckad CRC-kontroll,
och en mottagen fjärrram (recessiv RTR-bit, L10). Den ligger kvar tills nästa sändning eller
mottagning startar. Portens enda bit skiljer dem inte åt - se avsnitt 6.7.

**`tx_done`** och **`rx_valid`** är pulser på exakt en klockcykel. Det är korrekt här och är
precis det som gör registerbanken i avsnitt 7.1 nödvändig.

### 6.7 Kända begränsningar, och en som drivrutinen märker av

Förenklingarna mot riktig CAN listas i sin helhet i
[L19 Appendix B](../lectures/L19/appendix/b_fpga_bringup_and_review.md). Tre av dem syns ända ut i
registerkartan och måste därför stå här också, eftersom parallellklassen skriver kod mot dem:

* **En förlorad arbitrering går inte att skilja från en lyckad sändning på STATUS bit 0.** Båda
  ger tillbaka biten, eftersom kontrollern pulsar `tx_done` också när den avbryter. Det är
  avsiktligt: biten betyder "porten är fri", inte "ramen kom fram". En drivrutin som vill veta
  utfallet läser `ERROR_FLAGS` efter att bit 0 kommit tillbaka.

  Det här var en gång en riktig bugg, och det är värt att veta varför den inte är det längre.
  Sattes bit 0 enbart av `tx_done`, och pulsade `tx_done` bara vid EOF, blev biten liggande låg
  efter varje förlorad arbitrering och noden kunde inte sända igen förrän den nollställdes på
  resetknappen - på en tvånodsbuss alltså i normal drift. Tre saker gör att den inte kan uppstå
  igen, och de är medvetet överlappande: kontrollern pulsar `tx_done` även vid avbrott (L17),
  banken sätter bit 0 också på en stigande flank av `error` medan biten är låg (L18), och
  `TX_ABORT` finns som nödutgång. `can_controller_tb` fall 2 och `register_bank_tb` fall 10-11
  kontrollerar de tre.

* **`error` är en bit för fyra orsaker.** Drivrutinen kan se *att* något gick fel, aldrig *vad*.
  Retry-logik som skiljer på förlorad arbitrering och trasig CRC går inte att skriva mot det här
  gränssnittet.

* **Ingen buffring på mottagarsidan.** Kontrollern håller en ram. Kommer nästa innan den förra
  lästs ut skrivs den över. Registerbanken vidarebefordrar begränsningen i stället för att dölja
  den; se [registerkartan](./register_map.md).

---

## 7. Modulerna i `bridge/`

### 7.1 `register_bank.vhd` - registerbanken ([L18](../lectures/L18/README.md))

Sexton portar, i den här ordningen:

```text
 1 clock        5 reg_wdata    9 rx_data     13 tx_id
 2 reset_s2_n   6 tx_done     10 rx_valid    14 tx_dlc
 3 reg_index    7 rx_id       11 error       15 tx_data
 4 reg_write    8 rx_dlc      12 reg_rdata   16 tx_req
```

Översätter kontrollerns encykelspulser till klibbiga, pollbara nivåer, och registerskrivningar
till händelser. Semantiken i sin helhet står i [registerkartan](./register_map.md); den är
kontraktet mot parallellklassen och får inte ändras ensidigt.

`reg_rdata` är **kombinatorisk**. Att låsa ett läst värde är bryggans ansvar, inte bankens.

### 7.2 `spi_reg_bridge.vhd` - transaktionsbryggan ([L19](../lectures/L19/README.md))

Tio portar, i den här ordningen: `clock`, `reset_s2_n`, `ss_active`, `rx_data`, `rx_valid`,
`reg_rdata`, `tx_data`, `reg_addr`, `reg_wdata`, `reg_write`.

Implementerar transaktionen ur [protokollspecifikationen](./spi_register_protocol.md): en
kommandobyte plus fyra databytes, alltid exakt fem. Kommandobyten avkodas till skriv/läs-bit och
registerindex. Vid läsning **låses registervärdet en gång** i slutet av kommandobyten; vid
skrivning verkställs ingenting förrän femte byten är hel. Går `ss_active` låg dessförinnan
avbryts transaktionen helt, utan sidoeffekter.

`reg_addr` **håller** det avkodade indexet tills nästa kommandobyte avkodar ett nytt: det är ett
låst värde, inte en puls som följer den pågående byten. Testbänken kontrollerar indexet när alla
fem bytes är förbrukade, så en brygga som nollställer `reg_addr` när den återgår till vila
passerar de första fallen och faller på det.

### 7.3 `can_spi_node.vhd` - noden ([L19](../lectures/L19/README.md))

Nio portar, i den här ordningen:

```text
 1 clock      4 mosi     7 rx_bus
 2 reset_n    5 ss       8 tx_bus
 3 sclk       6 miso     9 bus_en
```

Rent strukturell toppnivå. Instansierar `spi_slave`, `spi_reg_bridge`, `register_bank` och
`can_controller`, plus en `meta_prev` för reset. Ingen funktionell logik här.

Ordningen är SPI:s fyra ledningar som en grupp, `sclk`/`mosi`/`ss`/`miso`, och därefter
CAN-bussens tre. `miso` ligger alltså bland SPI-portarna och inte hos de andra utgångarna, så att
de fyra pinnarna står i samma ordning som i kopplingstabellen i [L19](../lectures/L19/README.md).
Det spelar roll: `can_spi_node_tb` binder positionellt som allt annat, och `miso` och `rx_bus` har
samma typ, så en förväxling av dem passerar analysen utan ett ord och ger en nod som aldrig
svarar.

---

## 8. Testplan

Ni skriver inga testbänkar i det här projektet. Nio är utdelade, och de är kontraktet: sju
modultestbänkar och två systemtestbänkar.

### 8.1 Modultestbänkar
| Testbänk | Kontrollerar |
|---|---|
| `meta_prev_tb` | Två vippors fördröjning, för både en bit och en vektor. |
| `bit_timer_tb` | `sample` och `bit_done` vid rätt tick; `resync`; `enable`. |
| `crc15_tb` | CRC-värden för kända sekvenser; `valid`; `clear`. |
| `tx_shift_reg_tb` | MSB-först skiftning, stoppning efter fem lika, `done`-tajmingen. |
| `rx_shift_reg_tb` | Deserialisering, avstoppning, `stuff_error`, `real_bit`. |
| `register_bank_tb` | Elva fall, från reset-tillståndet till `TX_ABORT` och de två vägarna tillbaka till TX klar. |
| `spi_reg_bridge_tb` | Fyra fall: en skrivning, en läsning byte för byte, ett avbrott på `ss_active`, och en kommandobyte med reserverad bit satt. |

### 8.2 Systemtestbänkar
`can_controller_tb` sätter två noder på en gemensam wired-AND-buss och kontrollerar att den ena
tar emot den andras ram, och att arbitrering löses upp rätt när båda sänder samtidigt. Den hoppas
över av bygget tills kontrollern har en mottagarväg.

`can_spi_node_tb` gör samma sak ett lager ut: två kompletta noder på samma buss, men varje nod
driven av en modellerad SPI-master på sina fyra pinnar. Den spelar upp
protokollspecifikationens genomarbetade exempel genom hela kedjan - `spi_slave`,
`spi_reg_bridge`, `register_bank`, er `can_controller` - och följer en ram från en
SPI-skrivning på den ena noden till en SPI-läsning på den andra. Sju fall: resettillståndet,
det genomarbetade exemplet, ogiltiga kommandobytes och reserverade index, `TX_ABORT`,
avbrottsregeln, extra bytes under samma `SS`, och till sist sändningen och mottagningen.

**Det är den enda testbänk i kursen som driver `sclk`, `mosi` och `ss` som riktiga vågformer.**
`spi_reg_bridge_tb` matar bryggan färdiga bytes och rör aldrig en pinne, så allt mellan ledningen
och byten - synkroniserarna, SCK-flankdetekteringen, `ss_active`-ramningen - provas här eller
ingenstans. Den hoppas över på samma villkor som `can_controller_tb`.

### 8.3 Egen verifiering
`can_spi_node_tb` är snäll mot tidskraven med flit: den håller 200 ns tyst kring varje
`SS`-flank, där protokollet kräver minst 60 ns. Det är rätt för en testbänk som ska skilja
logikfel från tidsfel, men det betyder också att **ingen** utdelad testbänk pressar
specifikationens tidsminima.

Det är den verifiering projektet ber er göra själva: kopiera `can_spi_node_tb`, krymp
`SETTLE_NS` ner mot 60 ns, och ta reda på vid vilket värde er nod slutar svara och varför.
Svaret ligger i `spi_slave`s synkroniserare, och det är det enda stället där kursen låter er
mäta en marginal i stället för att läsa den. Övning 4(b) i
[L19 Appendix C](../lectures/L19/appendix/c_exercises.md) ställer frågan i sin helhet.

### 8.4 Checklista före inlämning
* [ ] Alla nio utdelade testbänkar passerar, `can_controller_tb` och `can_spi_node_tb` inräknade. **Kontrollera att
  den verkligen *kördes* och inte hoppades över** - se rutan nedan.
* [ ] `make build-project` går grönt från ett rent utcheckat repo.
* [ ] Portordningen stämmer mot tabellerna i avsnitt 6 och 7.
* [ ] Inga värden hårdkodade förbi `can_def`.
* [ ] Varje entitets gränssnitt är kommenterat.
* [ ] `CONTRIBUTORS.md` är aktuell.
* [ ] `main` innehåller inga commits som inte gått via en granskad PR.

> **Överhoppad är inte godkänd.** `can_controller_tb` gatas på om `can_controller.vhd` innehåller
> L17:s CRC-grindning, letad upp med en textsökning på de interna signalnamnen appendixet
> använder. Skriver ni en korrekt mottagarväg med andra namn rapporteras testbänken som *skipped*,
> och eftersom överhoppad aldrig är underkänd ser checklistan uppfylld ut medan kursens
> pass/fail-testbänk aldrig kördes. Kör därför
>
> ```bash
> CI_BUILD_ALL=1 make build-project
> ```
>
> minst en gång före inlämning, och lämna in det utfallet. Se
> [`controller/README.md`](../controller/README.md) för uttrycken det söks efter.

---

## 9. Bedömning

Projektet står för **50 av kursens 100 poäng**; de två praktiska tentorna för 25 vardera. Se
[info/examination.md](../info/examination.md) för helheten.

Projektet bedöms i tre delar:

| Del | Poäng | Vad som bedöms |
|---|---:|---|
| Designen | 30 | Modulerna fungerar enligt specifikation och testbänkarna passerar. |
| Arbetssättet | 12 | Git-historik, PR:er, granskningarnas kvalitet, seminariet, `CONTRIBUTORS.md`. |
| Redovisningen | 8 | Slutredovisningen: att gruppen kan förklara vad den byggt och varför. |

Betyget sätts på gruppen. Är insatsen påtagligt ojämn kan enskilda betyg justeras; det är den enda
anledningen till att `CONTRIBUTORS.md` ska hållas aktuell löpande och inte skrivas kvällen före.

**Godkänt** kräver en **komplett nod**: alla nio utdelade testbänkar ska passera, alltså
`CI_BUILD_ALL=1 make build-project` grönt rakt igenom. Kontrollern ensam räcker inte, och skälet
ligger efter den här kursen: noden följer med er till CAN-labben i *Inbyggda system 2*, där en
drivrutin ska nå den över SPI. En kontroller utan registerbank och brygga går inte att nå, och en
nod vars delar fungerar var för sig men inte ihop går inte heller att nå.

**Väl godkänt** kräver dessutom den egna verifieringen i avsnitt 8.3, att koden är genomgående
dokumenterad och stilistiskt konsekvent, och att granskningskulturen syns i repots historik.

Bring-up på riktig hårdvara bedöms **inte**. Ett trasigt kit eller en trasig koppling får
inte kosta poäng. Allt som bedöms går att köra i GHDL på en vanlig laptop.

---

## 10. Praktiska tips

* Rita tidsdiagrammet innan ni skriver skiftregistren. De flesta fel där är tajmingfel på en
  cykel, inte logikfel, och de syns på papper innan de syns i simulatorn.
* Börja med `bit_timer` och `crc15` om ni är osäkra på var ni ska börja. De är de enklaste, de
  beror inte på något, och de går att bli helt klar med.
* Läs de utdelade testbänkarna. De säger mer exakt vad varje modul lovar än någon prosa gör, och
  de är skrivna för att läsas.
* Testa stoppningen noggrant, åt båda hållen. Det är projektets vanligaste felkälla.
* Håll `can_spi_node` strukturell. Så fort det smyger sig in logik i toppnivån blir den omöjlig
  att testa isolerat.
* Prata med parallellklassen tidigt, och gör det om [registerkartan](./register_map.md) snarare än
  om er kod.

---

## 11. Gemensam dokumentation

Två dokument delas med mjukvarugruppen och är kontraktet mellan klasserna:

* [`register_map.md`](./register_map.md) - vad registren betyder.
* [`spi_register_protocol.md`](./spi_register_protocol.md) - hur de nås.

Ändras något i dem måste båda klasserna veta om det innan ändringen mergas. Dokumenten uppdateras
före koden, aldrig efter.

---
