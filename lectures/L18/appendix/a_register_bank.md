# Appendix A

## Registerbanken

### Varför det här lagret finns
`can_controller`s statusutgångar är gjorda för en anropare i samma klockdomän som ser varje
cykel: `tx_done` och `rx_valid` är **encykelspulser**, 20 ns vid 50 MHz (L11). En drivrutin som
pollar över SPI samplar systemet några *mikrosekunder* i taget i bästa fall - en puls är borta
tusentals cykler innan nästa pollning kommer. Registerkartan (se `project/register_map.md`) lovar
därför något annat: **klibbiga, pollbara nivåer** med uttryckliga nollställningar (`RX_ACK`,
`ERROR_FLAGS`), och skrivutlösta händelser (`TX_SEND`).

Att konvertera mellan de två världarna är hela den här modulens uppgift. Den innehåller ingen
protokollkunskap i någon riktning: ingenting om CAN-ramar (det stannar i `can_controller`) och
ingenting om SPI (det kommer senare under den här föreläsningen, och i L19). Det är register,
låsningar och en pulsgenerator - vilket är precis därför den kan verifieras fullständigt under det
här passet, innan det finns någon SPI alls.

Ni har sett båda dess kärntrick förut, i L03 och L04. En klibbig statusbit är L03:s vippa med de
två frågorna uttryckligen besvarade: vad som sätter den, och vad som nollställer den. Och att göra
om en hållen nivå till en encykelspuls är precis vad `button_sync`s flankdetektering gjorde i L04 -
här går den åt samma håll för `TX_SEND` (en skrivning blir en puls) och åt motsatt håll för
`tx_done` (en puls blir en nivå som ligger kvar). Det här passet befordrar båda från en övning till
ett riktigt arkitekturlager med ett dokumenterat kontrakt:
[avsnittet om registersemantik i protokollspecifikationen](../../../project/spi_register_protocol.md),
som det här appendixet gör om till signaler.

---

### Gränssnittet
Sexton portar, **alla ingångar först, sedan alla utgångar**, samma konvention som varje modul i
projektet - och, som överallt annars i det, är bindningen *positionell*, så ordningen nedan är det
kontrakt `register_bank_tb` håller er till:

```text
 1 clock        5 reg_wdata    9 rx_data     13 tx_id
 2 reset_s2_n   6 tx_done     10 rx_valid    14 tx_dlc
 3 reg_index    7 rx_id       11 error       15 tx_data
 4 reg_write    8 rx_dlc      12 reg_rdata   16 tx_req
```

Typerna kommer från `can_def` (`use work.can_def.all;`), så portarna mot kontrollern har exakt
samma typer som `can_controller`s egna. Vid sidan av `clock` och `reset_s2_n` (portarna 1 och 2)
faller de fjorton övriga i två grupper:

**Sidan mot bryggan (portarna 3-5, 12)** är en medvetet minimal registeråtkomstport - det som
L19:s brygga kommer att driva, och det som testbänken driver direkt i dag:
* `reg_index : std_logic_vector(3 downto 0)` - vilket register, protokollets index (offset/4).
* `reg_write : std_logic` - en **encykelsstrob**; på dess stigande klockflank verkställs
  `reg_wdata` i det adresserade registret.
* `reg_wdata : std_logic_vector(31 downto 0)` - värdet som ska skrivas.
* `reg_rdata : std_logic_vector(31 downto 0)` - det adresserade registrets aktuella värde,
  **kombinatoriskt**: det följer `reg_index` utan att någon klockflank är inblandad. Regeln om att
  låsa en gång vid läsning ur protokollspecifikationen är *bryggans* uppgift (L19), inte den här
  modulens - banken berättar alltid den nuvarande sanningen, och bryggan avgör när den tar sitt
  enda atomära sampel.

**Sidan mot kontrollern (portarna 6-11, 13-16)** speglar `can_controller`s portar på registersidan
en mot en: `tx_id`/`tx_dlc`/`tx_data`/`tx_req` ut till kontrollern, och
`tx_done`/`rx_id`/`rx_dlc`/`rx_data`/`rx_valid`/`error` tillbaka från den. I L19:s toppnivå kopplas
de rakt över, port till port, ingenting emellan.

`reset_s2_n` är den *synkroniserade* reseten, som för varje delblock i projektet. L19:s toppnivå
äger en `meta_prev` för den, precis som `can_controller` äger sin egen internt.

---

### De tre STATUS-bitarna: en låsning var
Varje `STATUS`-bit är en vippa med ett namngivet sättvillkor och ett namngivet
nollställningsvillkor, och ingenting mer:

| Bit | Betydelse | Sätts av | Nollställs av |
|---|---|---|---|
| 0 | TX klar | reset; kontrollerns puls `tx_done`; **en stigande flank på `error` medan den här biten är låg**; **en accepterad skrivning till `TX_ABORT`** | en accepterad skrivning till `TX_SEND` |
| 1 | RX giltig | kontrollerns puls `rx_valid` | en skrivning av `0x1` till `RX_ACK` |
| 2 | Fel | en **stigande flank** på kontrollerns nivå `error` | en skrivning av `0x0` till `ERROR_FLAGS` |

Tre av dem förtjänar en andra blick:

* **Bit 0 börjar på `'1'`.** Ur reset är kontrollern i vila, så banken är redo att ta emot en ram -
  en drivrutin som pollar innan den någonsin sänt måste se "klar", annars skulle `send()`
  misslyckas för alltid på ett nyss spänningssatt system.
* **Bit 2 låser en flank, inte en nivå.** Kontrollern håller `error` hög tills nästa ram börjar
  (L11), på sitt eget schema. Att låsa den stigande flanken ger *drivrutinen* en egen livscykel för
  flaggan: `clearError()` nollställer den även medan kontrollerns nivå fortfarande är hög, och
  låsningen sätts inte igen förrän ett genuint *nytt* fel producerar en ny stigande flank. Att i
  stället låsa på nivån skulle få `clearError()` att verka trasig - nollställd och omedelbart satt
  igen - så länge kontrollern håller ledningen.
* **Bit 0 har tre vägar tillbaka upp, och det är avsiktligt.** Läs de två extra som livrem och
  hängslen kring det enda fel som kan slå ut hela noden:

  En sändning som förlorar arbitreringen slutar utan att någonsin nå EOF. L17 låter kontrollern
  pulsa `tx_done` också på den vägen, just för att den här biten ska komma tillbaka - men
  kontrollern är *er*, och en version som glömmer det lämnar biten låg för alltid, så varje senare
  `TX_SEND` kastas och noden kan inte sända igen förrän den resettas. Banken förlitar sig därför
  inte på att kontrollern gör rätt. **En stigande flank på `error` medan bit 0 redan är låg kan
  bara betyda att en sändning slutade illa**, eftersom en nod antingen sänder eller tar emot, och
  ett mottagningsfel inte kan inträffa medan en sändning pågår. Så den flanken sätter biten också,
  och det behövs ingen `role`-port för att veta det.

  `TX_ABORT` är den tredje vägen: en uttrycklig nödutgång som drivrutinen kan dra i om den bedömer
  att den väntat länge nog. Ingenting i konstruktionen ska någonsin behöva den. Bygg in den ändå -
  kostnaden är ett enda register som bara går att skriva till, och alternativet är en nod som en
  drivrutin inte har någon möjlighet att få loss.

En enda ordningsregel binder ihop låsningarna: i den klockade processen **tillämpas kontrollerns
händelser efter bryggans skrivningar**, så om en `TX_SEND`-skrivning och en `tx_done`-puls någonsin
landade på samma flank vinner hårdvaran och banken förblir klar. En så sällsynt konflikt bör lösas
åt det håll som inte kan köra fast systemet, och det är samma princip som stycket ovan tillämpar
tre gånger om.

---

### `TX_SEND`: en skrivning blir en puls
En `TX_SEND`-skrivning med `reg_wdata(0) = '1'`, som anländer medan TX klar är satt, gör exakt två
saker på den klockflanken: höjer `tx_req` **under en cykel**, och nollställer TX klar. Mer precist:
`tx_req` är hög under den enda cykeln *efter* skrivningens klockflank, och låg igen på nästa -
testbänken kontrollerar båda ändarna av det påståendet.

Allt annat med det här registret är vad det *ignorerar*:
* En skrivning medan TX klar är låg (en sändning pågår) kastas helt - ingen puls, ingen
  tillståndsändring. Att skriva över `tx_id`/`tx_dlc`/`tx_data` mitt i en sändning är den korruption
  som drivrutinens egen klar-kontroll skyddar mot från mjukvarusidan; det här är samma skydd på
  hårdvarusidan, och ingendera sidan får anta att den andra finns där.
* En skrivning med `reg_wdata(0) = '0'` gör ingenting: registerkartan säger "skriv `0x1` för att
  utlösa", och banken håller den till det.
* Läsningar ger noll - `TX_SEND` lagrar ingenting, det *gör* något.

Varför pulsdisciplinen spelar roll syns tydligast i felet den förhindrar. `can_controller` agerar
på `tx_req` så fort den är hög och bussen är ledig (L16), så en `tx_req` som lämnas *hållen* begär
på nytt i samma ögonblick som en ram tar slut, för alltid, och suddar `error` vid varje passage
tillbaka genom starttillståndet. Begäran måste vara en händelse, och något måste göra den till en.
På det här lagret är det enklare - en skrivstrob är redan en händelse, inte en nivå - men det måste
ändå *upprätthållas*: en skrivning, en puls, oavsett vad mastern gör härnäst.

---

### `TX_ABORT`: nödutgången
Index 12, bara skrivbart, och spegelbilden av `TX_SEND`: en skrivning av `0x1` sätter TX klar
tillbaka till `'1'`. En skrivning av något annat gör ingenting, och en läsning ger `0x00000000`.

Det rör ingenting annat. Det når inte `can_controller` - kontrollern har ingen ingång för att
avbryta, dess femton portar spikades i L11 och `can_controller_tb` binder dem positionellt - och
den behöver ingen. En kontroller som avbrutit en sändning är redan tillbaka i `STATE_IDLE` och
fullt kapabel att sända igen; det enda som sitter fast är den här bankens klibbiga bit. `TX_ABORT`
lossar den, och det är hela modulen.

Det är värt att stanna vid ett ögonblick, eftersom det är buggens allmänna form. Ingenting i
*hårdvaran* hade kört fast. Det som kört fast var en **statusbit vars enda sättvillkor hängde på en
händelse som inte längre inträffade**. Varje klibbig flagga med en väg upp och en väg ner är en
missad händelse från samma fel, och lösningen är alltid densamma: se till att varje väg ut ur
upptagettillståndet också höjer flaggan, och ge anroparen ett sätt att tvinga fram den ifall ni har
fel om "varje".

---

### RX-sidan: infångning vid pulsen
När `rx_valid` pulsar gör banken två saker på samma flank: sätter STATUS bit 1, och **fångar in**
`rx_id`, `rx_dlc` och `rx_data` i de fyra `RX_*`-registren - `rx_data`s övre ord (bitarna 63-32,
databyte 0-3, byte 0 i den mest signifikanta positionen) i `RX_DATA_LO`, dess undre ord i
`RX_DATA_HI`.

Att fånga in, i stället för att koppla kontrollerns portar rakt till läsmuxen, är det som ger
drivrutinen en stabil ram att läsa: `RX_*`-registren håller sina värden medan drivrutinen arbetar
sig igenom fyra separata SPI-lästransaktioner, oavsett vad kontrollerns portar gör under tiden. En
skrivning till `RX_ACK` nollställer *bara flaggan* - dataregistren behåller sitt innehåll till
nästa infångning, vilket är ofarligt: registerkartans kontrakt är att `RX_*` är meningsfullt
*medan RX giltig är satt*.

Vad infångningen **inte** ger drivrutinen är buffring. En ny ram som fullbordas innan den förra
kvitterats fångas helt enkelt in ovanpå den - en ram hålls, den nyaste vinner. Det är inte den här
modulen som är lat; det är en dokumenterad lucka som ärvts från kontrollern själv, som håller exakt
en mottagen ram i `rx_id`/`rx_dlc`/`rx_data` och skriver över den vid nästa (L11). Banken gör den
luckan synlig på registernivå i stället för att dölja den, och
[L19 appendix A](../../L19/appendix/a_system_verification.md) återkommer till vad den kostar en
drivrutin.

---

### Maskning vid skrivning
Skrivbara register lagrar bara de bitar som finns i hårdvaran, och läses tillbaka som nollor
ovanför dem:

| Register | Lagrade bitar | En skrivning av `0xFFFFFFFF` läses tillbaka som |
|---|---|---|
| `TX_ID` | 10-0 (`id_t`) | `0x000007FF` |
| `TX_DLC` | 3-0 (`dlc_t`) | `0x0000000F` |
| `TX_DATA_LO`/`HI` | alla 32 | `0xFFFFFFFF` |

Lägg märke till vad banken *inte* gör: validerar. En `TX_DLC` på `0xF` lagras och lämnas vidare
till kontrollern som den är - att avvisa `dlc > 8` är drivrutinens ansvar, i den parallella
mjukvaruklassen, och att göra det två gånger på två språk är precis så de två kopiorna glider isär.
Banken maskar till de bitar som fysiskt finns; drivrutinen upprätthåller betydelsen. `STATUS` och
`RX_*`-registren ignorerar skrivningar helt, och de reserverade indexen 13-15 läses som noll och
ignorerar skrivningar, precis som protokollspecifikationen kräver.

Utgångarna mot kontrollern kommer direkt från TX-registren:
`tx_data <= TX_DATA_LO & TX_DATA_HI` - 64 bitar med databyte 0 i den mest signifikanta positionen,
den layout `can_controller` väntar sig (L16) och samma packning som drivrutinen utför på andra
sidan kartan (se diagrammet över databyteordningen i
[`register_map.md`](../../../project/register_map.md)).

---

### Att skriva `register_bank.vhd`
Filen hamnar i [`bridge/`](../../../bridge/README.md), bredvid era kopierade kontrollermoduler.
Formen är två processer och en handfull konkurrenta tilldelningar:

* **En klockad process** som äger varje register och låsning: resetvärdena (TX klar `'1'`, allt
  annat noll), skriv-`case`:et över `reg_index`, och sedan de tre uppdateringarna från kontrollerns
  händelser, i den ordningen.
* **En kombinatorisk process** för läsmuxen: ge `reg_rdata` förvalet idel nollor, och skriv sedan
  över de bitar varje register faktiskt har - samma stil med "tilldela ett förval, skriv över i
  specifika grenar" som varje räknare och tillståndsmaskin från L06 och framåt.
* Konkurrenta tilldelningar som kopplar ut `tx_id`/`tx_dlc`/`tx_data`/`tx_req` från TX-registren
  och pulsvippan.

Analysera den (`ghdl -a --std=93`, från `bridge/`; `can_def.vhd` ligger en katalog bort, i
`controller/`), och kör sedan den utdelade testbänken:

```bash
ghdl -a --std=93 ../controller/can_def.vhd register_bank.vhd register_bank_tb.vhd
ghdl -e --std=93 register_bank_tb
ghdl -r --std=93 register_bank_tb --assert-level=error
```

---

### Vad testbänken kontrollerar
[`register_bank_tb.vhd`](../../../bridge/register_bank_tb.vhd) går igenom kontraktet i elva fall, i
tur och ordning: reset-tillståndet (bit 0 satt, allt annat noll); skrivning och återläsning med
maskning på varje skrivbart register, och utgångarna mot kontrollern som följer dem; `TX_SEND`s
encykelspuls och nollställningen av klar; skrivningen som kastas medan sändning pågår; `tx_done`
som återställer klar; en `TX_SEND`-skrivning av `0x0` som inte gör något; infångning av mottagen
ram, att den håller trots att ingångarna ändras, att den är skrivskyddad, och `RX_ACK`;
fellåsningens flanksemantik, inklusive `clearError()`s regel om skrivning av noll och en
nollställning medan nivån fortfarande är hög; de reserverade indexen; och sist de två
återhämtningsvägar som ger tillbaka TX klar efter en förlorad arbitrering, en automatisk och en
driven av `TX_ABORT`. Varje fallkommentar i filen säger vad ett underkänt fall betyder, så läs
testbänken innan ni skriver modulen - den är den körbara formen av det här appendixet.

---

### Vad som kommer härnäst
Det andra bryggan behöver är `spi_slave.vhd`, utdelad snarare än skriven: en byte-motor som får
`SCK`/`MOSI`/`SS` säkert in i 50 MHz-domänen och lämnar över en ren byte i taget till bryggan.
Banken som byggs i dag kommer inte att ändras igen - L19 kopplar bara saker till den.

---
