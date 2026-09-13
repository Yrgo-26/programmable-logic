# Programmerbar logik
Kursrepo för **Programmerbar logik** med klassen Eh26, vt27.

Kursen tar dig från ett grindnät på papper till en CAN-nod i en FPGA som en AVR32DB28 kan prata
med över SPI. Första halvan bygger upp VHDL och synkron konstruktion; andra halvan är ett
grupprojekt där den kunskapen används till något en parallellklass sedan skriver drivrutiner mot.

**Ämnet är VHDL och digital konstruktion i FPGA.** Grindar, sanningstabeller, boolesk algebra och
Karnaughdiagram repeteras snarare än lärs ut. Se [förkunskaper](./info/README.md#förkunskaper).

Kursens text är på **svenska**, appendixen inräknade. All kod, alla kommentarer i koden och all
utskrift från testbänkarna är på **engelska**. Undantaget är verktygsreferenserna i
[`info/`](./info/README.md), som är på engelska eftersom de citerar verktygens egen utskrift och
menyvägar rad för rad.

---

## Om kursen

### Del 1: Digital konstruktion i VHDL (L01-L08)
Syntetiserbar VHDL för kombinatorisk och sekventiell hårdvara: metastabilitet och synkronisering,
räknare, timers och tillståndsmaskiner, var och en först resonerad om som en krets och sedan
uttryckt i språket, körd på en riktig FPGA.

Där en krets går att rita ritas den först: den resoneras om som grindar, byggs och simuleras för
hand i [CircuitVerse](https://circuitverse.org/simulator) innan den skrivs i VHDL. Undantaget är
L05, som är en språkföreläsning utan ny krets; och när en sorts krets väl har ritats går senare
designer av samma sort direkt in i VHDL.

Verifieringen sker i tre lager:
* **För hand, i CircuitVerse**, innan någon VHDL finns. Du härleder vad kretsen ska göra, bygger
  den, och simulerar den mot din egen förutsägelse. Ingenting automatiskt kontrollerar det steget,
  medvetet: att förutsäga ett beteende och sedan bekräfta det är den färdighet resten av kursen
  vilar på.
* **I övningarna**, där du skriver VHDL:en och kontrollerar den med en utdelad självkontrollerande
  testbänk under GHDL.
* **I föreläsningen**, där designer syntetiseras i Quartus Prime Lite och körs på ett Terasic
  DE0-CV, demonstrerat från katedern.

### Del 2: Grupprojektet (L10-L19)
En förenklad CAN-kontroller, konstruerad modul för modul i grupper om 4-5, med Git, feature-branchar
och kodgranskning: ett delat konstantpaket, en bittimer, en CRC-15-motor, bitstoppande
skiftregister och en ramsekvenserande tillståndsmaskin, komponerade till en `can_controller`.

Därefter det lager som gör kontrollern nåbar utifrån: en registerbank som gör encykelspulser till
pollbara register, och en SPI-brygga som gör dem läs- och skrivbara från en AVR32DB28. Det är den
punkt där hårdvaran och mjukvaran möts, och den andra sidan av det gränssnittet skrivs av en
parallellklass.

Projektet har **inga milstolpar**: efter det delade paketet är de fyra lövmodulerna oberoende av
varandra och har var sin utdelad testbänk, så gruppen väljer själv ordning och takt. Två
hållpunkter är obligatoriska, kodgranskningsseminariet i L15 och slutredovisningen i L19. Se
[projektspecifikationen](./project/README.md).

### Examination
Grupprojektet står för halva kursen, och två individuella praktiska tentamina för resten: L09 över
sekvensnät, och L20 över projektets moduler. Se [examination.md](./info/examination.md).

---

## Efter kursen
Du ska kunna:
* Realisera en boolesk funktion som ett grindnät, och simulera den för hand.
* Läsa och skriva kombinatorisk och sekventiell VHDL: entiteter, arkitekturer, signaler, variabler
  och processer.
* Förklara metastabilitet och tillämpa dubbelvippsynkroniseraren på varje asynkron ingång.
* Konstruera räknare, skiftregister, timers och tillståndsmaskiner, och komponera en design av
  moduler du redan byggt i stället för att skriva om deras logik.
* Konstruera ett kommunikationsprotokolls hårdvara: bittajming, checksummor, bitstoppning,
  ramsekvensering och arbitrering.
* Konstruera gränssnittet mellan hårdvara och mjukvara: en registerbank och en SPI-transport, mot
  ett kontrakt en annan grupp skriver mot.
* Verifiera en design genom att köra en självkontrollerande testbänk under GHDL, och spåra ett fel
  tillbaka till koden som orsakade det.
* Arbeta i en grupp med feature-branchar, Pull Requests och kodgranskning.

---

## Boken
Hela kursen finns också som en bok, i två upplagor med samma innehåll:
* Svenska: [Programmerbar logik](./book/sv/programmerbar-logik.pdf).
* Engelska: [Programmable Logic](./book/en/programmable-logic.pdf).

Varje föreläsning är ett kapitel, med samma avsnitt som passets appendix, och bilagorna håller
verktygsreferenserna för GHDL och Quartus, projektspecifikationen och det delade kontraktet mot
drivrutinskursen. Övningarna följer med; lösningarna gör det inte, utan ligger kvar i det här
repot. De byggs från källorna i [`book/`](./book/README.md), där det också står hur du bygger dem
själv (`make -C book` bygger båda) och hur de hålls i takt med kursmaterialet.

### Referenslitteratur
CAN som protokoll ligger i en egen bok, också den i två språkupplagor:
* Svenska: [CAN - bussen, framen och
  kontrollern](https://github.com/Yrgo-26/can-book/blob/main/sv/can-sv.pdf).
* Engelska: [CAN - the bus, the frame and the
  controller](https://github.com/Yrgo-26/can-book/blob/main/en/can-en.pdf).

CAN som protokoll beskrivs inte där, utan i
[CAN - bussen, framen och kontrollern](https://github.com/Yrgo-26/can-book), som är gemensam med
drivrutinskursen. Den är protokollreferensen genom hela del 2: dess kapitel 1-6 är
kravspecifikationen för det som byggs här, bit för bit, och dess kapitel 7 beskriver den färdiga,
förenklade kontrollern.

---

## Struktur

```text
Makefile     Ingång till kontrollerna nedan; kör `make help` för mållistan.
book/        Kursen satt som en bok med LuaLaTeX, på svenska i sv/ och engelska i en/;
             `make -C book` bygger båda PDF:erna.
ci/          Kontrollskript: GHDL-bygge, dubblettkontroll, Markdown-länkar.
info/        Kursplan, examination, och de permanenta referenserna för GHDL och Quartus.
lectures/    Per föreläsning: README, appendix/, exercises/, och genomarbetade exempel.
project/     Grupprojektets specifikation, registerkartan och SPI-protokollet.
controller/  CAN-kontrollerns utdelade testbänkar.
bridge/      SPI-lagrets utdelade testbänkar, plus spi_slave.vhd och spi_def.vhd.
diagrams/    Python-källor till de genererade figurerna, och övningarnas entitetsdefinitioner.
libs/        Submoduler. Bara testramverket L10:s C++-övning bygger mot.
```

Sju av katalogerna har en egen README: [`book/`](./book/README.md) beskriver bokbygget,
[`lectures/`](./lectures/README.md) listar de tjugo passen, [`info/`](./info/README.md) håller
kursplanen, [`project/`](./project/README.md) är projektspecifikationen,
[`controller/`](./controller/README.md) och [`bridge/`](./bridge/README.md) säger vilken fil som
skrivs när, och [`diagrams/`](./diagrams/README.md) beskriver hur figurerna ritas om.

---

## Att bygga
Repot har två halvor som byggs var för sig, eftersom de är upplagda helt olika.

```bash
make help              # Lista alla mål.
make build             # Båda halvorna.
make build-lectures    # L01-L08: bygg och simulera varje exempel, kontrollera varje övning.
make build-project     # controller/ och bridge/: varje testbänk vars moduler finns.
make lint              # Markdown-länkar, dubblettkontroll, inga radslut med blanksteg.
make clean             # Ta bort GHDL-bibliotek och andra genererade filer.
```

`make build-lectures MODULE=timer` bygger bara de exempel vars sökväg innehåller "timer".

**`make build-project` rapporterar varje testbänk som överhoppad i ett färskt utcheckat repo.** Det
är det förväntade tillståndet: `controller/` och `bridge/` innehåller bara de utdelade filerna, och
modulerna är gruppens att skriva i sitt eget repo. En testbänk vars moduler saknas hoppas över,
aldrig underkänns.

Verktygskedjan installeras med apt på WSL/Ubuntu:

```bash
sudo apt -y update
sudo apt -y install git make ghdl g++
ghdl --version           # 3.x eller senare
```

Repot har en submodul, testramverket i `libs/test`, som L10:s C++-övning bygger mot. Klona med den:

```bash
git clone --recurse-submodules <repo-url>
```

Är repot redan klonat utan den, hämta den efteråt:

```bash
git submodule update --init
```

`g++` och submodulen behövs bara för L10:s ramningsövning, kursens enda C++-moment. Allt annat
klarar sig med GHDL.

`python3` är valfritt. Med det kontrolleras övningarnas testbänkar mot sina entiteter och körs mot
publicerade lösningar; utan det faller de tillbaka på en syntaxkontroll.

---

## Licens
Kursmaterialet är licensierat under [CC BY 4.0](./LICENSE) – Erik Pihl. Det gäller
föreläsningarna, appendixen och projektbeskrivningen.

VHDL-koden och skripten är licensierade separat under [MIT](./LICENSE-CODE), eftersom CC BY 4.0
inte är avsedd för mjukvara: modulerna och testbänkarna i `controller/` och `bridge/`, och
skripten i `ci/`. Testramverket i `libs/test` har en egen licens.

---
