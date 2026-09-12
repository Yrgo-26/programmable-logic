# L08 - Tillståndsmaskiner

## Agenda
* Ändliga tillståndsmaskiner: tillstånd, övergångar, ingångar och utgångar.
* Att konstruera en Mooremaskin för hand: tillståndsdiagram, tillståndstabell, Karnaughhärledd
  logik.
* Tillståndskodning som ett designbeslut, och varför den genomarbetade maskinen använder Graykod.
* Samma maskin i VHDL: en uppräkningstyp och `case`-mönstret för övergångar.
* Varför Moore är standardvalet här och i CAN-projektet.
* `fsm_led` demonstrerad på DE0-CV: knappar som växlar lysdioden mellan släckt, blinkande och tänd.
* Självstudier: Mealymaskiner (A.5), och `seq_detect_mealy` att läsa och köra.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **En Mooremaskin konstruerad för hand.** Specifikation, tillståndsdiagram, tillståndstabell,
   och sedan Karnaughhärledd nästa-tillstånds- och utgångslogik. Inget steg överhoppat.
2. **Det resulterande grindnätet, i CircuitVerse.** Stegat genom sin tillståndscykel för hand. Vid
   varje steg: förutsäg nästa tillstånd ur diagrammet innan klockan stegas fram.
3. **Samma sorts maskin i VHDL.** `fsm_led`, A.4:s lysdiodsstyrning med tre tillstånd: en
   uppräknad typ `state_t` och en process med `case`, som ersätter tillståndstabellen och
   Karnaughdiagrammen helt. En annan och större maskin än steg 1:s, med flit, så att
   överensstämmelsen du ser är strukturell snarare än en avskrift.
4. **`fsm_led` ut på kortet.**

Steg 3 är utdelningen från steg 1: varje rad du härledde för hand i tillståndstabellen blir en
gren i ett `case`, och att se den överensstämmelsen är värt mer än något av stegen för sig.

[`fsm_led`](./fsm_led/fsm_led.vhd) är maskinen steg 3 och 4 skriver och demonstrerar: en
lysdiodsstyrning med tre tillstånd, komponerad av L04:s synkroniserare och L07:s timer, beskriven i
[A.4](./appendix/a_state_machines.md#a4-samma-maskin-i-vhdl).

Mealymaskiner läses i stället för att presenteras, i
[A.5](./appendix/a_state_machines.md#a5-mealymaskiner-skillnaden-på-en-klockcykel) med
[`seq_detect_mealy`](./seq_detect_mealy/seq_detect_mealy.vhd) att läsa och köra. De examineras
nedan, och övning 4 låter dig skriva en.

Att läsa A.5 spelar större roll än det kan se ut. Allt som presenteras är Moore, och Moore är
standardvalet både här och i CAN-projektet. A.5 är där du får veta vad alternativet kostar och
köper, vilket är enda sättet för det standardvalet att bli ett val i stället för en vana.

---

## Före föreläsningen
* Läs [Appendix A](./appendix/a_state_machines.md).
* Föreläsningen förutsätter L02:s Karnaughdiagram och L03:s vippor, och återanvänder L07:s `timer`
  oförändrad tillsammans med L04:s synkroniserare breddad till två knappar.

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md). De två första är penna och papper;
  resten är VHDL.
* Övning 6 och 7 är **kursens två capstones**: de två halvorna av en seriell länk. Mottagaren
  komponerar L04:s `reset_sync`, L05:s `sync` och L07:s `timer` runt en tillståndsmaskin som
  sköter sin egen skiftning; sändaren behöver bara den första och den sista av dem, speglade.
  Avsätt riktig tid för dem, och konstruera varje tillståndsdiagram på papper innan du skriver
  någon VHDL.
  * Gör mottagaren först. Den är den svårare av de två, eftersom den måste återskapa den
    bittajming den blir tilldelad snarare än att definiera den själv.
* De två capstones är också den bästa förberedelsen inför den praktiska tentamen i
  [L09](../L09/README.md).

---

## Det här ska du kunna efteråt
* Förklara vad en ändlig tillståndsmaskin är, och peka ut dess tillstånd, övergångar, ingångar och
  utgångar i en given krets.
* Konstruera en Mooremaskin för hand, från specifikation via tillståndsdiagram och
  tillståndstabell till Karnaughhärledda ekvationer, och bygga resultatet i CircuitVerse.
* Modellera samma maskin i VHDL med en uppräknad typ `state_t` och en `case`-process.
* Känna igen en Mealymaskin på sekunden och säga vad dess utgång kostar och köper, en klockcykels
  latens mot ett extra tillstånd, och varför Moore är standardvalet här och i CAN-projektet.
* Komponera en tillståndsmaskin med tidigare byggda subkomponenter i stället för att skriva om
  dem. I capstonen betyder det tre tidigare föreläsningars moduler runt en maskin som är den enda
  nya logiken, med skift- och räknaridiom från ytterligare en.

---

## Frågor att testa dig själv med
* Vad gör en krets till en tillståndsmaskin, snarare än bara ett register med lite logik omkring?
* Vad är `X` exakt i den handkonstruerade maskinen, och varför måste det vara en puls på en
  klockcykel snarare än knappens nivå?
* Varför är den maskinens tillståndskodning en Graykod? Vad kan gå fel med en vanlig binärräkning?
* En räknare och ett skiftregister är tekniskt sett också tillståndsmaskiner. Vad skiljer dem från
  maskinen som konstruerades här?
* Vilka signaler får en Mooreutgång bero på, och vilka får en Mealyutgång bero på? Hur avgör du,
  givet en enda rad VHDL som driver en utgång, vilken av dem du tittar på?
* Varför behöver Mooreversionen i A.5:s jämförelse ett extra tillstånd, och varför ligger dess
  utgång exakt en klockcykel efter Mealyversionens?
* Varför läser `LED_PROCESS` i `fsm_led.vhd` bara `state`, aldrig `button_edge_s2` eller
  `button_n` direkt? Vad skulle ändras om den gjorde det?
* Varför går inte `din` i `seq_detect_mealy` genom en synkroniserare, till skillnad från `reset_n`?
* Vad köper `when others` dig i ett `case` för tillståndsövergångar, när `state_t` bara har de
  värden du deklarerat?
* Varför går timern i capstone-mottagaren sexton gånger så fort som baudhastigheten snarare än en
  gång per bit, och varför gör det att designen tål en sändare vars klocka skiljer sig något från
  din, att sampla mitt i en bit?
* Capstone-sändaren använder en helbitstimer och behöver ingenting mitt i biten. Vad har den som
  mottagaren inte har, som gör skillnaden?

---

## Referens
* [Appendix A](./appendix/a_state_machines.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna, inklusive de två capstones.
* Att köra testbänkarna beskrivs i [L02 Appendix C](../L02/appendix/c_testbenches.md). De två
  capstones instansierar tre respektive två tidigare moduler, så deras `ghdl -a`-rader namnger
  flera filer på en gång; varje övning skriver ut det kommando den behöver.
* Modulerna som capstones återanvänder är värda att ha öppna bredvid: [L04](../L04/README.md):s
  `reset_sync`, [L05](../L05/README.md):s `sync` och [L07](../L07/README.md):s `timer`. L06:s
  `serial_rx8` och `piso8` är värda att läsa om för skiftidiomet, även om ingen av dem
  instansieras: de två capstones skiftar inuti sina egna tillståndsmaskiner.
* [info/quartus_workflow.md](../../info/quartus_workflow.md) är verktygsreferensen bakom
  kortdemonstrationen i A.6.

---

## Nästa föreläsning
Det här är den sista föreläsningen i kursens första del. Över åtta föreläsningar har vi gått från
grindar och Karnaughdiagram, via register, metastabilitet och själva VHDL-språket, till räknare,
skiftregister och timers, och nu ändliga tillståndsmaskiner, i varje steg med resonemang om
kretsen för hand innan den skrevs i syntetiserbar VHDL och kördes på en riktig FPGA. Varje mönster
som byggts längs vägen, dubbelvippsynkroniseraren, kodstilen med `process`/`case`, och nu
Mooremaskinen, har återanvänts i den här föreläsningens egna exempel, och följer med oförändrat in
i det som kommer härnäst.

Härnäst är [L09](../L09/README.md), den första **praktiska tentamen**: tre timmar, individuell,
vid datorn med GHDL, över allt L01-L08 har byggt. Efter den börjar
[grupprojektet](../../project/README.md), där en CAN-kontroller konstrueras i VHDL över tio
föreläsningar och avslutas mot en riktig AVR32DB28 över SPI.

---
