# L19 - SPI-bryggan, `can_spi_node` och bring-up mot AVR32DB28

Projektets sista pass, och dess capstone: transaktionslagret, toppnivån som binder ihop allt, och
hela kedjan verifierad först i simulering och sedan på riktig hårdvara: två kort på en buss, och
er egen hatt som SPI-master mot dem.

---

## Agenda
* Transaktions-FSM:en: kommandobyte, fyra databytes, låsning en gång vid läsning, verkställande på
  femte byten, och avbrott när SS går hög för tidigt.
* `spi_reg_bridge` på tavlan: blocket med sina tio portar, och transaktions-FSM:ens tillstånd.
* Att komponera `spi_slave`, `spi_reg_bridge`, `register_bank` och `can_controller` till
  `can_spi_node.vhd`.
* Systemverifiering: två noder på en buss, arbitrering, och hela vägen från ett SPI-kommando till
  en ram på bussen.
* Bring-up i två halvor: två kort på en delad busslinje, sedan hatten som master mot dem, från
  en ensam nods loopback till två noder som pratar på SPI-kommando.
* Vad riktiga CAN-kontrollrar gör som den här designen inte gör.
* Slutredovisning och överlämning till drivrutinsklassen.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera transaktions-FSM:en enligt protokollspecifikationen, inklusive avbrottsregeln.
* Förklara varför en läsning låser registervärdet en gång, och vad som går fel utan den regeln.
* Komponera hela noden till en toppnivå och verifiera den i simulering.
* Koppla ihop två DE0-CV till en delad buss, och en AVR32DB28 som master över dess MVIO-domän,
  och felsöka kedjan systematiskt nerifrån och upp.
* Säga vilka krav SPI-kopplingen ställer på hattens konstruktion, och varför de inte går att
  rätta i efterhand.
* Säga vad som återstår att bevisa när en drivrutin skriven av någon annan först möter noden.
* Säga vad simulering har bevisat och vad bara hårdvara kan bevisa.

---

## Förkunskaper
* [L18](../L18/README.md): registerbanken, och den utdelade `spi_slave.vhd`.
* [SPI- och registerprotokollet](../../project/spi_register_protocol.md), i sin helhet. Det är
  specifikationen bryggan implementerar.
* [L17](../L17/README.md): en `can_controller` som både sänder och tar emot.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 19 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 19.1, bryggans
> specifikation är avsnitt 19.2, Appendix B är avsnitt 19.3-19.8, och övningarna i Appendix C är
> avsnitt 19.10. Protokollspecifikationen är bokens bilaga D. Läs antingen appendixen eller
> kapitlet; innehållet är detsamma.

* Läs [protokollspecifikationen](../../project/spi_register_protocol.md) noga, särskilt
  kommandobytens format och regeln om avbrott.
* Läs [Appendix A](./appendix/a_system_verification.md) om systemverifieringen med två noder.
* Läs [Appendix B](./appendix/b_fpga_bringup_and_review.md) om `can_spi_node` och vägen ut på
  kortet, och om vad riktiga CAN-kontrollrar gör som den här designen inte gör.
* Läs [`bridge/spi_reg_bridge_tb.vhd`](../../bridge/spi_reg_bridge_tb.vhd), som är kontraktet.

### Under föreläsningen
* Transaktionsformatet på tavlan, byte för byte, med de fem raderna ur protokollspecifikationens
  exempel.
* `spi_reg_bridge` på tavlan: vad bryggan gör efter varje byte, och vad som händer när `SS` går
  hög för tidigt.
* `can_spi_node` på tavlan: blocken den instansierar, och vilka signaler som går mellan dem.

### Bring-up
Bring-upen har två halvor, och båda är era: CAN-sidan mellan två kort, och SPI-sidan mellan er
hatt och kortet. Ta dem i den ordningen. CAN-halvan behöver ingen mikrokontroller alls, så den går
att köra medan hatten fortfarande ligger på lödbordet, och den utesluter en hel felklass innan
någon SPI-ledning finns att misstänka.

#### CAN-halvan: två DE0-CV på en buss
Två kort, deras busslinjer på `GPIO_0(2)` knutna ihop till **en** ledning med gemensam jord, och
drivningen med öppen dränering ur [Appendix B](./appendix/b_fpga_bringup_and_review.md) gör den
delade ledningen till ett wired-AND.

1. **Ett ensamt kort.** Busslinjen bär ingenting annat än pull-upen, så noden läser tillbaka
   exakt den nivå den driver: en loopback. `tx_bus` och `bus_en` ska växla fält för fält på en
   logikanalysator via `GPIO_0(0)`/`GPIO_0(1)`, `tx_done` pulsa vid slutet av EOF, och `error`
   aldrig gå hög.
2. **Två kort, en ledning.** Tryck på `KEY(1)` på det ena kortet och `LEDR(1)` ska tändas på det
   andra. Det är första gången konstruktionen möter två *oberoende* oscillatorer; i
   `can_controller_tb` delade noderna en `clock`.
3. **Arbitrering på riktigt.** Låt båda korten sända samtidigt och se att den med lägst
   identifierare vinner, och att förloraren backar utan att sätta `error`.

#### SPI-halvan: hatten mot kortet
Kopplingen, per nod. Den är inte er att välja: den står i
[protokollspecifikationen](../../project/spi_register_protocol.md), eftersom parallellklassen
skriver sin drivrutin mot samma tabell.

| Signal | AVR32DB28 | DE0-CV |
|---|---|---|
| `SCK` | `PC2` | `sclk` |
| `MOSI` | `PC0` | `mosi` |
| `MISO` | `PC1` | `miso` |
| `SS` | `PC3` | `ss` |
| I/O-matning | `VDDIO2` | 3.3 V |
| Kärnmatning | `VDD` | - (hattens egen 5 V) |
| GND | `GND` | GND |

Ingen nivåomvandlare behövs, och det är ett val och inte en förenkling: AVR32DB28:ans `PORTC` är
en egen spänningsdomän, matad från `VDDIO2` i stället för `VDD`, så den läggs på DE0-CV:ns 3,3 V
medan kärnan går kvar på 5 V. Varje nivå FPGA:n ser är då en nivå den är specificerad för. SPI0
flyttas dit med `PORTMUX.SPIROUTEA = ALT1`.

**Tre krav på hatten, och de måste vara på plats innan den etsas.** Hatten ni bygger för den här
kursen är SPI-mastern, och tabellen ovan bestämmer tre saker om den:

* **`PC0`-`PC3` är reserverade.** De är SPI0:s ALT1-mux och får inte bära någon annan kringutrustning.
  Ingen lysdiod, ingen knapp, och framför allt ingen avkopplingskondensator på `SS` - en knapp med
  100 nF på pinnen gör `SS`-flanken obrukbar vid 1 MHz.
* **Ingenting annat på `PORTC`.** Hela porten ligger i `VDDIO2`-domänen på 3,3 V, så en
  5 V-kringutrustning där skulle både sluta fungera och mata 5 V in i en 3,3 V-domän.
* **`VDDIO2` är en egen bana.** Den får inte knytas till `VDD` på kortet, utan ska ut till en pinne
  där DE0-CV:ns 3,3 V kopplas in, med 100 nF nära chippet. Att domänen över huvud taget är
  separat styrs dessutom av `MVSYSCFG` i `FUSE.SYSCFG1`: i enkelmatningsläge knyts `VDDIO2`
  internt till `VDD`, `PORTC` blir en 5 V-port, och kopplingen ovan lägger då 5 V rakt in i
  ingångar som inte är 5 V-toleranta - på en hatt som ser precis likadan ut som en rätt byggd.
  Kontrollera fusen före första inkopplingen. Det är det enda felet i det här passet som kan kosta
  ett kort.

Jämför med P1-hatten från *Programmeringsmetodik* för att se varför kraven står här: den lägger
lysdioder på `PC0`-`PC2`, SW1 med 100 nF på `PC3` och hela `PA0`-`PA7` på display och relä, och
båda mux-alternativen för SPI0 är därmed upptagna. Den hatten kan inte vara master i det här
systemet; er nya kan, om de tre punkterna ovan hålls.

Stegen tas i den här ordningen, och inte i någon annan. Varje steg utesluter en felkälla, så att
det som fortfarande inte fungerar efter steg *n* med säkerhet ligger i steg *n+1*:

4. **SPI-loopback på enbart hatten**, med `PC1` kopplad till `PC0` och FPGA:n urkopplad. Bevisar
   att mastern fungerar, och på köpet att `PORTMUX` och `VDDIO2` är rätt satta.
5. **Registereko**: skriv `TX_ID`, läs tillbaka det. Bevisar att hela transaktionskedjan bär.
6. **`STATUS`-pollning**: läs `STATUS` och se att bit 0 är satt efter reset.
7. **En nod sänder på kommando**: skriv en ram och utlös `TX_SEND`, och se `STATUS` bit 0 gå låg
   och tillbaka - nu utlöst över SPI i stället för av en knapp.
8. **Två noder, hela kedjan**: den ena sänder på SPI-kommando, den andra tar emot och kvitterar
   med `RX_ACK`. Det är systemet.

Mastersidan, alltså C++-koden på hatten, skrivs av parallellklassen, men blir klar först efter
att den här kursen är slut. För bring-upen räcker ett litet testprogram som gör stegen ovan; det
delas ut.

#### Vad som återstår
När passet är slut har båda halvorna gått på riktig hårdvara. Det som återstår är inte
kopplingen utan **motparten**: er nod har svarat på ett testprogram som är skrivet för att
lyckas, inte på en drivrutin skriven av någon annan mot enbart specifikationen. Det mötet sker i
CAN-labben i *Inbyggda system 2*. Det är därför protokollspecifikationens tidskrav - de 60 ns
kring `SS`, regeln om vad `MISO` bär under kommandobyten, och avbrottsregeln - är skrivna som krav
och inte som råd: ett testprogram som aldrig gör något oväntat bekräftar dem aldrig, och en
drivrutin som gör det fäller er på dem.

### Handledd grupptid
Kortare än i tidigare pass, eftersom redovisningen tar sin del av tiden. Prioritera i den här
ordningen:
* Implementera `spi_reg_bridge.vhd` utifrån
  [protokollspecifikationen](../../project/spi_register_protocol.md) och få `spi_reg_bridge_tb`
  grön. Den är det enda som står mellan er och en fullständig `make build-project`.
* Koppla ihop `can_spi_node` och simulera kedjan. Bring-upen är roligare, men det är simuleringen
  som bedöms.
* Bring-up så långt ni hinner, i stegens ordning.

### Slutredovisning
Varje grupp visar, på ungefär femton minuter:
* En körning av `make build-project` med alla testbänkar gröna.
* En kort genomgång av `can_spi_node`: vad varje block gör och var gränserna går.
* Bring-upen, så långt ni kommit, på riktig hårdvara.
* `CONTRIBUTORS.md` och en snabb genomgång av repots historik: branchar, PR:er, granskningar.

Slutredovisningen är projektets andra och sista fasta hållpunkt. Projektet lämnas in samma dag.

### Efter föreläsningen
* [Appendix C](./appendix/c_exercises.md) innehåller övningarna.
* Förbered [L20](../L20/README.md), den avslutande praktiska tentamen.

---

## Riktvärde
Det här passet är kursens tightaste, och det är värt att säga rakt ut: två moduler ska skrivas,
hela kedjan ska simuleras, hårdvaran ska upp, och varje grupp redovisar. Med fyra till sex grupper
går en tredjedel till halva passet åt till redovisningarna.

**Ligg därför före.** `register_bank` och `spi_reg_bridge` beror inte på `can_controller` alls -
den förra behöver bara `can_def`, den senare bara `spi_def` - så båda går att skriva parallellt
med kontrollern, från [L10](../L10/README.md) och framåt. En grupp som kommer till det här passet
med registerbanken klar och transaktionsformatet läst har passet till att koppla ihop och
felsöka. En grupp som börjar här hinner inte allt.

Bring-upen bedöms inte. Kommer ni till steg 3 av fem är det ett bra resultat; det som bedöms är
simuleringen bakom den.

---

## Kontrollfrågor
* Varför låses registervärdet en gång vid slutet av kommandobyten i stället för att läsas medan
  databytesen skiftas ut? Vilket register lider mest av att den regeln bryts?
* SS går hög efter tre bytes. Vad har hänt med transaktionen, och vad har ändrats i noden?
* En skrivning till ett reserverat index. Vad gör bryggan, och varför konsumerar den ändå alla
  fem bytesen?
* Varför finns ingen felkanal i transaktionslagret?
* Vilket bring-up-steg skulle avslöja en förväxlad MISO och MOSI, och vilket skulle avslöja ett
  `VDDIO2` som aldrig kopplades in?
* Hatten lägger en lysdiod på `PC2`. Vilket steg fallerar först, och varför är det ett fel som
  inte går att programmera sig ur?
* Vad bevisade stegen 1 till 3 som stegen 4 till 8 inte behövde bevisa om igen?
* Vad har simuleringen bevisat om designen, och vad har den inte kunnat bevisa?

---

## Nästa föreläsning
[L20](../L20/README.md): kursens andra **praktiska tentamen**, med uppgifter på projektets
moduler. Efter den är kursen slut.

Kontrollern ni byggt lämnas över till parallellklassen, som skriver C++-drivrutinen mot samma
register över samma SPI-transport. Det gemensamma kontraktet är
[registerkartan](../../project/register_map.md) och
[protokollspecifikationen](../../project/spi_register_protocol.md), och ingenting annat.

---
