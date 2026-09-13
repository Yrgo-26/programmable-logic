# Kursinformation

## Kursansvarig
Erik Pihl ([erik.axel.pihl@gmail.com](mailto:erik.axel.pihl@gmail.com))

---

## Förkunskaper
Kursens ämne är **VHDL och digital konstruktion i FPGA**, inte digitalteknikens grunder.
Deltagarna förutsätts komma med följande på plats:

* Logiska grindar och sanningstabeller, och att läsa en summa-av-produkter ur en tabell.
* Boolesk algebra: de grundläggande identiteterna och De Morgans lagar.
* Karnaughdiagram, för funktioner av tre eller fyra variabler.
* Register, D-vippor, och vad en klockflank gör.
* Tillståndsmaskiner som begrepp: tillstånd, övergångar, och skillnaden mellan Moore och Mealy.

Ingenting av det lärs ut från grunden. Det repeteras där språket kräver det, kort och i
appendixen snarare än i föreläsningarna: [L01](../lectures/L01/README.md) återger grind- och
boolesk notation så att kursen har en konvention, [L02](../lectures/L02/README.md) arbetar ett
Karnaughdiagram hela vägen eftersom minimering är det som motiverar den VHDL som följer, och
[L08](../lectures/L08/README.md) konstruerar en tillståndsmaskin för hand innan den skrivs.

Det kursen lär ut från noll är språket och verktygskedjan: `entity` och `architecture`, signaler
och variabler, processer, generics, subkomponenter, syntes i Quartus och simulering med GHDL.

Inget programmeringsspråk utöver allmän mjukvaruvana förutsätts. Vana vid C eller liknande
hjälper, eftersom flera förklaringar ställer VHDL:s semantik mot den.

Till grupprojektet tillkommer **Git och GitHub** på grundnivå: klona, branch, commit, push och
Pull Request.

---

# Kursplan - Programmerbar logik

Tjugo pass om tre timmar.

| Fl | Titel | Form |
|----|-------|------|
| L01 | Kombinatorik och första VHDL | Föreläsning |
| L02 | Större nät, multiplexrar och submoduler | Föreläsning |
| L03 | Sekvensnät | Föreläsning |
| L04 | Metastabilitet och synkronisering | Föreläsning |
| L05 | Variabler och hårdvaran under | Föreläsning |
| L06 | Räknare och skiftregister | Föreläsning |
| L07 | Timers | Föreläsning |
| L08 | Tillståndsmaskiner | Föreläsning |
| **L09** | **Praktisk tentamen 1 - sekvensnät** | **Examination** |
| L10 | Projektstart: CAN-bussen, ramen och `can_def` | Föreläsning + grupptid |
| L11 | Arkitektur, toppnivån, registerkartan och simulering | Föreläsning + grupptid |
| L12 | Synkronisering och bittimern | Föreläsning + grupptid |
| L13 | CRC-15-motorn | Föreläsning + grupptid |
| L14 | Sändningsskiftregister och bitstoppning | Föreläsning + grupptid |
| L15 | Mottagningsskiftregister och avstoppning | Föreläsning + seminarium |
| L16 | CAN-kontrollern I: tillståndsmaskinen och sändvägen | Föreläsning + grupptid |
| L17 | CAN-kontrollern II: mottagning och arbitrering | Föreläsning + grupptid |
| L18 | Registerbanken och SPI från vågformen | Föreläsning + grupptid |
| L19 | SPI-bryggan, `can_spi_node` och bring-up | Föreläsning + redovisning |
| **L20** | **Praktisk tentamen 2 - CAN-moduler** | **Examination** |

L10-L14 och L16-L18 följer samma upplägg: ungefär en timmes genomgång från katedern, oftast med
live-kodning, och därefter ungefär två timmars handledd grupptid. L15 och L19 är undantagen:
kodgranskningsseminariet tar ungefär en timme och slutredovisningarna en till en och en halv, så
de passen har kortare grupptid.

---

## Föreläsningsinnehåll

### L01 - Kombinatorik och första VHDL
Från sanningstabell till fungerande grindnät, i CircuitVerse och i VHDL.

Innehåll:
* Logiska grindar och sanningstabeller
* Boolesk algebra och summa-av-produkter
* Att bygga och simulera grindnät i CircuitVerse
* `entity`, `architecture`, `std_logic`, och den konkurrenta tilldelningen
* En komplett modul, bromsassistenten, tagen genom Quartus ut på DE0-CV

---

### L02 - Större nät, multiplexrar och submoduler
Att minimera ett nät, de första konstruktionerna som kräver en process, och den första designen
som består av mer än en entitet.

Innehåll:
* `process` och `case`, introducerade på en 4-till-1-multiplexer
* `std_logic_vector`: att bunta ihop ledningar, indexering och slicing
* Multiplexrar, från 2-till-1 till 8-till-1
* Karnaughdiagram, arbetade hela vägen
* Att översätta ett minimerat nät till VHDL, med interna signaler
* Submoduler: `entity work.<namn>`, positionell `port map`, och att dela upp en bred port
* En tvåsiffrig hexadecimal 7-segmentsdisplay, i CircuitVerse och i VHDL
* Att köra självkontrollerande testbänkar med GHDL

---

### L03 - Sekvensnät
Att lagra tillstånd: register, D-vippor och klockning.

Innehåll:
* D-låset och D-vippan
* Register byggda av vippor
* Klockning: stigande och fallande flank, klockperiod
* Flankdetektering

---

### L04 - Metastabilitet och synkronisering
Att göra en asynkron ingång säker att använda i ett synkront system.

Innehåll:
* Varför asynkrona ingångar orsakar metastabilitet
* Dubbelvippsynkroniseraren
* Studsfiltrering av en tryckknapp
* Tidsintuition: setup och hold, och varför två vippor räcker
* Generics: en modul som betjänar flera storlekar

---

### L05 - Variabler och hårdvaran under
Den sista konstruktionen som återstår, och vad verktygskedjan gör av alltihop.

Innehåll:
* `signal` kontra `variable`, och XOR-paritetsgeneratorn som skiljer dem åt
* Vad en FPGA fysiskt består av: uppslagstabeller och vippor
* Kritiska vägen, Fmax, och vad som sätter en hastighetsgräns på en klocka
* Låset man råkar beskriva av misstag, och varför det bara är en varning

---

### L06 - Räknare och skiftregister
Byggblock för allt som behöver räkna eller flytta bitar.

Innehåll:
* Räknare, och överslag som en konsekvens av bitbredden
* Skiftregister, SIPO och PISO
* En 8-bitars seriemottagare: ett skiftregister plus en biträknare

---

### L07 - Timers
En räknare med ett målvärde, ritad för hand innan den skrivs.

Innehåll:
* Timers, byggda av räknare
* En timer som grindnät i CircuitVerse, och att se den ticka
* Modulen `timer` i VHDL, och dess generic `TICK_COUNT`
* Att komponera en timer och L04:s två synkroniserare kring ett cirkulärt skiftregister: den
  vandrande lysdioden

---

### L08 - Tillståndsmaskiner
Först konstruerade för hand, sedan uttryckta i språket.

Innehåll:
* Tillstånd, övergångar, ingångar och utgångar
* Tillståndsdiagram, tillståndstabeller, och Karnaughhärledd logik
* Att realisera maskinen som ett grindnät i CircuitVerse
* Uppräknade tillståndstyper och `case`-mönstret för övergångar
* Moore genomgående; Mealy kort, i VHDL
* FPGA-demonstration
* Kursens två capstones, som självstudier: en 8-bitars seriemottagare och en seriesändare, var och
  en komponerad av moduler från tidigare föreläsningar kring en tillståndsmaskin man konstruerar
  själv. Räkna med 10 till 15 timmar för paret

---

### L09 - Praktisk tentamen 1: sekvensnät
Individuell tentamen, tre timmar, vid datorn med GHDL. Omfattar L01-L08 med tyngdpunkt på
sekvensnät. Se [examination.md](./examination.md).

---

### L10 - Projektstart: CAN-bussen, ramen och `can_def`
Grupprojektet startar. Arbetsformen först, sedan CAN från bussen och uppåt, och till sist
projektets första VHDL.

Innehåll:
* Projektupplägg: grupper, Git, Pull Requests och kodgranskning
* Varför protokoll behöver ramar: nyttolast, längdfält, checksumma, DST/SRC/SEQ
* CAN:s differentiella buss och multimasterdesign
* Dominanta och recessiva bitar, och varför arbitrering ersätter en bussmästare
* SOF, identifierare, RTR, kontrollfält, DLC, data, CRC-15, ACK, EOF
* Bitstoppning: femregeln och varför den finns
* Wired-AND-arbitrering, med två- och trenodersexempel för hand
* Bittajming och sampelpunkten, på begreppsnivå
* Live-kodning av `can_def.vhd`

---

### L11 - Arkitektur, toppnivån, registerkartan och simulering
Från protokoll till blockschema, och den toppnivå varje senare modul instansieras i.

Innehåll:
* Att avbilda CAN-begrepp på hårdvarublock, och vem som äger vad
* Registerkartan som parallellklassens drivrutin ska konsumera
* Att skriva `can_controller.vhd`: dess femton portar och en tom arkitektur
* Vilka portar som är asynkrona, och varför kontrollern synkroniserar dem själv
* Projektets simuleringsflöde i GHDL: analysera, elaborera, simulera
* Positionell portbindning: vad den köper och vad den ger upp

---

### L12 - Synkronisering och bittimern
De två första byggblocken, båda små: det som inte vet något alls, och det första som vet något om
CAN.

Innehåll:
* Live-kodning av `meta_prev.vhd`, med en breddgeneric, instansierad två gånger
* Live-kodning av `bit_timer.vhd`, som producerar `sample` och `bit_done`
* Att köra en utdelad testbänk och läsa dess rapport, för första gången i projektet
* Att instansiera båda inuti `can_controller`

---

### L13 - CRC-15-motorn
En motor, två jobb.

Innehåll:
* Live-kodning av `crc15.vhd`, en bitseriell CRC-15-motor
* Varför samma motor både genererar och kontrollerar, utan lägesomkoppling
* Varför den ändå behöver ett `clear`
* En kort CRC arbetad genom rekursionen för hand
* Verifiering mot utdelad testbänk

---

### L14 - Sändningsskiftregister och bitstoppning
Att serialisera ut på bussen, med samma stoppbitsregel som i L10, nu i VHDL.

Innehåll:
* Live-kodning av `tx_shift_reg.vhd`: MSB-först skiftning och insättning av stoppbitar
* Varför en laddad grupps första bit måste ut omedelbart, och varför `done` väntar en skiftning
* Varför stoppningstillståndet lever kvar över omladdningar
* `stuff` och `bit_valid`, och varför CRC:n grindas på dem

---

### L15 - Mottagningsskiftregister och avstoppning
Mottagarsidans spegelbild, plus projektets kodgranskningsseminarium.

Innehåll:
* Live-kodning av `rx_shift_reg.vhd`: deserialisering, avstoppning, stoppningsfel
* Att sampla mitt i bitperioden snarare än vid bitslut
* `real_bit`/`real_bit_valid`: att mata CRC-motorn en avstoppad bit i taget
* **Kodgranskningsseminarium**, obligatoriskt: varje grupp visar en PR och en granskning

---

### L16 - CAN-kontrollern I: tillståndsmaskinen och sändvägen
Ramen som tillståndsmaskin, först förklarad och sedan byggd på sändarsidan.

Innehåll:
* Tillståndsdiagrammet, fälttabellen och mönstret `STATE_LOAD_*`/skifta, före all VHDL
* Att lägga till tillståndstypen och maskinens signaler i `can_controller`
* Live-kodning av sändvägen
* Att driva den öppna dräneringsbussen från skiftregistrets aktuella bit
* Att mata `crc15` korrekt: grinda på `bit_valid`, inte på `bit_done`

---

### L17 - CAN-kontrollern II: mottagning och arbitrering
Att färdigställa kontrollern med mottagning och arbitrering.

Innehåll:
* Mottagarrollen: enable-tajmingen och den enda cykelns föregripande
* Att sätta ihop en mottagen ram, och att mata CRC:n på mottagarsidan
* Detektering av förlorad arbitrering, bit för bit över arbitreringsfältet
* Att köra `can_controller_tb` hela vägen, sändning och mottagning tillsammans

---

### L18 - Registerbanken och SPI från vågformen
Här börjar halvan som gör kontrollern nåbar från en mikrokontroller.

Innehåll:
* Varför encykelspulser är oanvändbara för en pollande drivrutin
* Live-kodning av `register_bank.vhd`: STATUS-låsning, `TX_SEND`, RX-infångning, maskning
* SPI från vågformen och uppåt: lägen, MSB först, SS som ramning
* Varför slaven översamplar SCK i stället för att klocka på den
* Genomgång av den utdelade `spi_slave.vhd`

---

### L19 - SPI-bryggan, `can_spi_node` och bring-up
Projektets capstone: transaktionslagret, toppnivån, och hela kedjan mot riktig hårdvara.

Innehåll:
* Transaktions-FSM:en: kommandobyte, fyra databytes, låsning vid läsning, avbrott vid SS
* Live-kodning av `spi_reg_bridge.vhd`
* `can_spi_node.vhd`: att komponera hela noden
* Systemverifiering: två noder på en buss
* Bring-up i två halvor: två DE0-CV på en delad buss, sedan hatten som SPI-master, i åtta steg
* Vad riktiga CAN-kontrollrar gör som den här designen inte gör
* **Slutredovisning** och överlämning till drivrutinsklassen

---

### L20 - Praktisk tentamen 2: CAN-moduler
Individuell tentamen, tre timmar, vid datorn med GHDL. Omfattar projektets moduler. Se
[examination.md](./examination.md).

---

## Kursmaterial

### Litteratur
Kursmaterialet består av:
* Föreläsningsanteckningar, ett appendix per föreläsning
* VHDL- och CircuitVerse-exempel
* Övningar som görs efter föreläsningarna
* En självkontrollerande testbänk till varje genomarbetat exempel och till nästan varje
  VHDL-övning, så att nästan allt går att verifiera på en laptop
* Åtta utdelade testbänkar till grupprojektets moduler. Ni skriver dem inte; ni får dem att passera
* [Simuleringsflödet](./simulation_workflow.md): den permanenta GHDL-referensen
* [Registerkartan](../project/register_map.md) och
  [SPI-protokollet](../project/spi_register_protocol.md), som är kontraktet mot
  parallellklassen

Kursens text är på **svenska**, appendixen inräknade. All kod, alla kommentarer i koden och all
utskrift från testbänkarna är på **engelska**. Undantaget är verktygsreferenserna i `info/`,
[simuleringsflödet](./simulation_workflow.md) och
[Quartusflödet](./quartus_workflow.md), som är på engelska eftersom de citerar verktygens egen
utskrift och menyvägar rad för rad.

---

### Mjukvara

**Det varje deltagare behöver**, på en vanlig laptop:
* **[CircuitVerse](https://circuitverse.org/simulator)** - gratis, webbläsarbaserad
  logiksimulator, används för att bygga varje krets för hand innan den skrivs i VHDL. Inget att
  installera
* **[GHDL](https://github.com/ghdl/ghdl)** - gratis VHDL-analysator och simulator. Det är
  verktyget kursen körs på: varje modul verifieras mot en testbänk i GHDL, och ingenting ni
  ombeds producera behöver något annat
  * på WSL/Ubuntu: `sudo apt -y install git make ghdl`
  * att köra testbänkar beskrivs i [L02 Appendix C](../lectures/L02/appendix/c_testbenches.md)
* **Git** och ett GitHub-konto, till grupprojektet
* **`g++`** (C++17), enbart till [L10](../lectures/L10/README.md):s ramningsövning, kursens enda
  C++-moment. Testramverket den bygger mot ligger som submodul i `libs/test`, så repot behöver
  klonas med `--recurse-submodules` eller kompletteras med `git submodule update --init`
  * på WSL/Ubuntu: `sudo apt -y install g++`

**Rekommenderat men inte nödvändigt:**
* **Quartus Prime Lite** med Cyclone V-stöd, för syntes och för att programmera kortet. Ingen
  övning och inget bedömt moment kräver det. Installation och DE0-CV-flödet beskrivs i
  [quartus_workflow.md](./quartus_workflow.md)

---

### Hårdvara

**Under L01-L09 behövs ingen hårdvara alls.** Kortdemonstrationerna görs från katedern.

**Under grupprojektet får varje grupp ett kit:**
* Ett **Terasic DE0-CV** (Cyclone V, `5CEBA4F23C7N`)
* **Hatten ni bygger för kursen**, med en AVR32DB28 som SPI-master
* Kopplingsdäck, kopplingstråd och en pull-upresistor till den delade busslinjen

**Hatten är SPI-mastern, och tre krav på den kommer från
[protokollspecifikationen](../project/spi_register_protocol.md):** `PC0`-`PC3` reserverade för
SPI0:s ALT1-mux, ingenting annat på `PORTC` eftersom hela porten ligger på 3,3 V, och `VDDIO2`
draget som en egen bana ut till en pinne i stället för knutet till `VDD`. De tre går inte att
rätta i efterhand, så de hör hemma i hattens konstruktion och inte i bring-upen.
[L19](../lectures/L19/README.md) motiverar var och en.

**C++-koden på hatten skrivs av parallellklassen, men blir klar först efter att den här kursen är
slut.** För bring-upen delas därför ett litet testprogram ut som gör de åtta stegen.
Noden möter en drivrutin skriven av någon annan först i CAN-labben i *Inbyggda system 2*.

Bring-upen i [L19](../lectures/L19/README.md) är praktiskt grupparbete, och varje grupp
demonstrerar sin egen tvånodslänk. Ingenting som **bedöms** kräver hårdvaran: allt går att köra i
GHDL, så ett trasigt kit kostar aldrig poäng.

En logikanalysator med åtta kanaler är till stor hjälp vid felsökning av SPI, men är inte
nödvändig.

---
