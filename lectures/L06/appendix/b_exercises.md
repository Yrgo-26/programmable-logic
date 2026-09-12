# Appendix B - Övningar

> **Så kontrollerar du ditt arbete.** Varje övning nedan som ber dig skriva en VHDL-modul har en
> självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess katalog
> `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och kör den
> sedan med GHDL - se [Appendix C](../../L02/appendix/c_testbenches.md) för de tre kommandona.
>
> Inget FPGA-kort behövs för någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL:en rätt, och testbänken är hur
> du bekräftar det.

## Räknare

**1.** En signal deklareras som:

```vhdl
signal counter: natural range 0 to 1023;
```

**a)** Hur många bitar bred blir det register som det här syntetiseras till?

**b)** Vilket är det största värde `counter` kan hålla innan den slår över tillbaka till `0` vid
nästa ökning?

**c)** Skriv om deklarationen för en räknare som i stället behöver räkna från `0` upp till `63`.

Följ räknarmönstret i
[Appendix A.1](./a_counters_and_shift_registers.md#a1-från-register-till-räknare).

---

**2.** Spåra en räknare av typen `natural range 0 to 3` för hand (ingen VHDL behövs).

Anta att:
* Räknaren startar på `2`.
* Den ökas en gång per klockflank, under fem flanker i följd.
* Det finns ingen reset däremellan.

Notera, klockflank för klockflank:
* Värdet som hålls före flanken.
* Värdet som fångas på flanken.

Förklara varför räknaren återgår till `0` utan någon uttrycklig "om räkningen når sitt maxvärde,
nollställ den"-logik.

**Notera:** det här är det *syntetiserade* beteendet, det som spelar roll för hårdvara. A.1 flaggar
för det simuleringsförbehåll som hör till: GHDL intervallkontrollerar en signal av typen
`natural range 0 to 3`, så en simulering av den här räknaren avbryter vid överslaget i stället för
att rulla över. Spåra den på papper som hårdvara, och grip efter en `unsigned` i full bredd om du
någonsin behöver en räknare som slår över också i simulering.

---

**3.** Bygg 4-bitarsräknaren från
[Appendix A.1](./a_counters_and_shift_registers.md#a1-från-register-till-räknare) för hand i
CircuitVerse, och använd den för att se spillet i stället för att ta det på förtroende.

**a)** Bygg den:
* Ett 4-bitars register: fyra D-vippor som delar en klocka.
* En adderare, med registrets utgångar på den ena ingången och en konstant `1` på den andra.
* Adderarens summa kopplad tillbaka till registrets `D`-ingångar.
* Fyra utgångselement eller lysdioder, en per bit, så att du kan läsa av räkningen.

**b)** Kör den med en klockperiod på `1000 ms` och notera vad du ser:
* Skriv ner sekvensen av räkningar över sexton klockflanker i följd, med start från `0000`.
* Håll ögonen på `carry_out` på den översta adderaren medan räkningen rullar från `1111` till
  `0000`:
  * Under hur många av de sexton flankerna är den hög?
  * Vad är kopplat till den?
* Förklara, med en mening, vart den femte biten tar vägen, och varför registret lagrar `0000`
  snarare än `10000`.

**c)** Resonera nu om det du *inte* byggde:
* Peka på den del av din ritning som avgör att räknaren ska återgå till `0000`.
* Det finns ingen. Säg vad som gör jobbet i stället.
* Vad skulle du behöva lägga till för att få den att räkna `0` till `9` och sedan slå över? (Övning
  4 ber dig skriva precis det i VHDL, så spara ditt svar.)

**d)** Ändra bredden till tre bitar genom att ta bort den översta vippan och smalna av adderaren:
* Förutsäg den nya överslagspunkten innan du kör den.
* Bekräfta den.
* Formulera regeln som kopplar en räknares bredd till det värde den slår över vid.

**Spara den här kretsen.** [L07](../../L07/README.md) bygger sin timer genom att lägga till två
saker till den - en jämförare och en nollställning - och att utgå från en räknare du redan har sett
fungera är hela poängen med övningen där.

---

**4.** Skriv en entitet med namnet `counter` som räknar från `0` upp till ett steg under sin radix,
och sedan slår över tillbaka till `0`. Med standardvärdet på radix är det en decimalräknare, `0`
till `9`.

Entiteten har en generic:

| Generic | Typ | Standardvärde | Betydelse |
|---|---|---|---|
| `RADIX` | `natural range 1 to 2**16` | `10` | Hur många värden räknaren går igenom innan den upprepar sig. Den räknar `0` till `RADIX-1` inklusive, så `RADIX` är cykelns längd, inte den största räkningen. |

och de här portarna:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad**: den kommer från din `reset_sync` (L04 övning 8), aldrig rakt från en pinne. Asynkron, så den nollställer utan att någon klockflank är inblandad. |
| `count` | out | `natural range 0 to RADIX-1` | Den löpande räkningen. `0` är ett värde den antar, så intervallet börjar där: reset driver den till `0`, och den återvänder dit vid varje överslag. |
| `tick` | out | `std_logic` | En puls på en cykel vid den flank där `count` slår över från `RADIX-1` tillbaka till `0`. |

Implementera den med en enda synkron process:
* Ta med `clock` och `reset_s2_n` i känslighetslistan.
* Vid reset, sätt `count` till `0` och `tick` till `'0'`.
* Vid varje stigande klockflank:
  * Driv `tick` låg som utgångsläge.
  * När `count` har nått `RADIX-1`, slå över `count` till `0` och pulsa `tick` hög.
  * Öka annars `count`.

Skriv jämförelsen mot `RADIX-1`, aldrig mot `9`. Genericen är hela skillnaden mellan en modul och en
modul du kan använda två gånger: `RADIX` är fastlagd innan syntesen körs, så jämföraren den bygger
blir inte större än en hårdkodad, och räknarens register dimensioneras efter den radix du ber om.
Det är samma argument som
[L04 A.8](../../L04/appendix/a_metastability_and_synchronization.md#a8-generics-en-modul-flera-storlekar)
för fram för `button_sync`:s `COUNT`, och skälet till att L07:s `timer` tar sitt målvärde som en
generic snarare än som en konstant.

Till skillnad från det gratis överslaget hos en räknare av typen `natural range 0 to 15` (A.1)
behöver en räknare med godtycklig radix en uttrycklig jämförelse, eftersom `RADIX-1` i allmänhet
inte är en tvåpotensgräns. Lägg märke till vad som händer när den är det: med `RADIX = 16` skrivs
jämförelsen fortfarande ut, men hårdvaran under behöver den inte längre.

**Tips:** Processen behöver läsa den löpande räkningen (för att jämföra den och för att öka den), så
håll räkningen i en intern `signal count_s: natural range 0 to RADIX-1;`, kör logiken på `count_s`,
och driv utgången med `count <= count_s;` utanför processen, precis som `d_flip_flop.vhd` använder
`q_s` i L03. Det är inget stilval: varje `ghdl`-kommando i den här kursen skickar `--std=93`, och
under VHDL-93 kompilerar det inte alls att läsa en `out`-port. Senare standarder mjukar upp det,
vilket är varför du kan ha sett det göras på annat håll.

Följ räknarmönstret i
[Appendix A.1](./a_counters_and_shift_registers.md#a1-från-register-till-räknare), och den
driv-låg-och-pulsa-sedan-form som `data_ready` har i
[Appendix A.5](./a_counters_and_shift_registers.md#a5-genomgånget-exempel-en-8-bitars-seriemottagare).

![Modulen `counter`](./images/counter.png)

**Självkontroll:** döp din entitet till `counter`, med genericen `RADIX`
(`natural range 1 to 2**16`, standardvärde `10`), ingångarna `clock`, `reset_s2_n` och utgångarna
`count` (`natural range 0 to RADIX-1`) och `tick` (`std_logic`), deklarerade i den ordningen; dess
testbänk finns i [`exercises/counter/`](../exercises/counter). Den elaborerar **två** instanser, en
med `RADIX = 10` och en med `RADIX = 4`, och kör vardera genom två fulla cykler, och kontrollerar
att `tick` är en puls på en cykel snarare än en nivå och att den aldrig utlöser halvvägs igenom. En
arkitektur som tyst hårdkodar `10` klarar den första instansen och fallerar på den andra, vilket är
poängen med att kontrollera två.

---

## Skiftregister

**5.** Ett 8-bitars SIPO-skiftregister startar på `00000000` och använder idiomet från
[Appendix A.3](./a_counters_and_shift_registers.md#a3-serie-inparallell-ut-sipo):

```vhdl
shift_reg <= shift_reg(6 downto 0) & serial_in;
```

Det tar emot den seriella bitströmmen `1, 0, 1, 1` (en bit per klockflank, i den ordningen) över
fyra stigande klockflanker i följd.

**a)** Skriv ut hela det 8-bitars innehållet i `shift_reg` efter var och en av de fyra
klockflankerna.

**b)** Efter de fyra flankerna:
* Vilka fyra bitar i `shift_reg` håller de mottagna data?
* I vilken ordning ligger de, i förhållande till den ordning bitarna anlände i?

---

**6.** Ett 4-bitars PISO-register, som följer idiomet från
[Appendix A.4](./a_counters_and_shift_registers.md#a4-parallell-inserie-ut-piso), är:
* Parallellt laddat med `parallel_in = "1010"` (`load = '1'` under en klockflank).
* Sedan skiftat med `shift = '1'` under de följande fyra klockflankerna.
* Med `serial_in` hållen på `'0'` hela tiden.

Kom ihåg hållet från
[Appendix A.2](./a_counters_and_shift_registers.md#a2-skiftregister):
* bitarna flyttar mot MSB.
* `serial_out` är bit 3, värdet som är på väg att lämna.
* `serial_in` kommer in vid bit 0.

**a)** Skriv ut registrets innehåll och `serial_out` vid varje steg, en rad per klockflank:
* Raden för laddningsflanken, före all skiftning.
* Sedan en rad för var och en av de fyra skiftflankerna.

**b)** I vilken ordning dyker de fyra laddade bitarna upp på `serial_out`, i förhållande till sina
positioner i `parallel_in`?

**c)** Vad är registrets slutliga innehåll efter alla fyra skiftningarna, och varför?

**Tips:** Du behöver ingen riktig hårdvara för att kontrollera övning 5 och 6 för hand. Gå igenom
dem precis som du skulle spåra en sanningstabell: en klockflank, en rad, i taget.

---

**7.** Implementera föreläsningens två användbara skiftregisterutföranden i VHDL.

**a)** Skriv en entitet med namnet `sipo8`, ett register med serie in/parallell ut.

Entiteten ska ha:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad**: den kommer från din `reset_sync` (L04 övning 8), aldrig rakt från en pinne. Asynkron, så den nollställer utan att någon klockflank är inblandad. Nollställer hela registret, så `parallel_out` läser `"00000000"` medan den hålls låg. |
| `serial_in` | in | `std_logic` | Den inkommande biten. |
| `parallel_out` | out | `std_logic_vector(7 downto 0)` | Registrets innehåll. |

Följ SIPO-idiomet från
[Appendix A.3](./a_counters_and_shift_registers.md#a3-serie-inparallell-ut-sipo).

![Modulen `sipo8`](./images/sipo8.png)

**Självkontroll:** portarna `clock`, `reset_s2_n`, `serial_in` (in) och `parallel_out`
(`std_logic_vector(7 downto 0)`, out), deklarerade i den ordningen; dess testbänk finns i
[`exercises/sipo8/`](../exercises/sipo8).

**b)** Skriv en entitet med namnet `piso8`, ett register med parallell in/serie ut.

Entiteten ska ha:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad**: den kommer från din `reset_sync` (L04 övning 8), aldrig rakt från en pinne. Asynkron, så den nollställer utan att någon klockflank är inblandad. Nollställer hela registret, så `serial_out` läser `'0'` medan den hålls låg. |
| `load` | in | `std_logic` | Fånga `parallel_in` vid nästa stigande flank. |
| `shift` | in | `std_logic` | Skifta en position vid nästa stigande flank. |
| `serial_in` | in | `std_logic` | Biten som matas in vid bit 0 vid en skiftning. |
| `parallel_in` | in | `std_logic_vector(7 downto 0)` | Värdet som fångas vid en laddning. |
| `serial_out` | out | `std_logic` | Registrets översta bit. |

Följ PISO-idiomet från
[Appendix A.4](./a_counters_and_shift_registers.md#a4-parallell-inserie-ut-piso):
* Vid en laddningsflank (`load = '1'`), fånga `parallel_in`.
* Vid en skiftflank (`shift = '1'`), flytta varje bit en position mot MSB, och mata in `serial_in`
  vid bit 0.
* Driv `serial_out` från bit 7, så att en laddad byte lämnar med den mest signifikanta biten först.
* `load` har företräde framför `shift` när båda är höga.

![Modulen `piso8`](./images/piso8.png)

**Självkontroll:** portarna `clock`, `reset_s2_n`, `load`, `shift`, `serial_in`, `parallel_in`
(`std_logic_vector(7 downto 0)`) och `serial_out` (out), deklarerade i den ordningen; dess testbänk
finns i [`exercises/piso8/`](../exercises/piso8). Spara den här modulen:
[L08](../../L08/README.md):s capstone med sändaren (övning 7) instansierar den inte, men den är värd
att läsa om där för idiomets skull, eftersom den maskinen skiftar ut byten inline.

Härled varje idiom på nytt ur appendixet snarare än att kopiera `serial_rx8`:s skiftrad.

**c)** Namnge, för vart och ett av de fyra skiftregisterutförandena, en uppgift som det är det
naturliga valet för:
* SISO (serie in/serie ut).
* SIPO (serie in/parallell ut).
* PISO (parallell in/serie ut).
* PIPO (parallell in/parallell ut).

Följ sammanfattningstabellen i
[Appendix A.2](./a_counters_and_shift_registers.md#a2-skiftregister).

---

## Att läsa seriemottagaren
Till det genomgångna exemplet, [`serial_rx8`](../serial_rx8/serial_rx8.vhd), hör en
referenstestbänk. Kör den från exemplets egen katalog innan du börjar:

```bash
cd lectures/L06/serial_rx8
ghdl -a --std=93 serial_rx8.vhd serial_rx8_tb.vhd
ghdl -e --std=93 serial_rx8_tb
ghdl -r --std=93 serial_rx8_tb --assert-level=error --stop-time=10ms
```

**8.** Redogör för mottagarens beteende, med hänvisning till
[Appendix A.5](./a_counters_and_shift_registers.md#a5-genomgånget-exempel-en-8-bitars-seriemottagare).

**a)** Bitströmmen `1, 0, 1, 1, 0, 0, 1, 0` anländer, en bit per aktiverad klockflank:
* Vad ligger på `data_out` under den cykel där `data_ready` pulsar?
* Vilken anländande bit hamnar i `data_out(7)`, och vilken i `data_out(0)`?

**b)** `shift_enable` går låg under tre klockcykler efter den fjärde biten, och sedan hög igen under
de återstående fyra:
* Producerar mottagaren fortfarande samma byte? Förklara vad biträknaren gör under uppehållet.
* Vad skulle i stället gå fel om `shift_enable` grindade bara skiftregistret och inte räknaren?

**c)** Gör var och en av följande ändringar i din egen kopia av `serial_rx8.vhd`, en i taget, och
**förutsäg** vad referenstestbänken kommer att rapportera innan du kör den. Kör den sedan och
redogör för resultatet:
* Ändra skiftraden till det spegelvända hållet,
  `shift_reg <= serial_in & shift_reg(7 downto 1);`.
* Ta bort det villkorslösa `data_ready <= '0';` högst upp i den klockade grenen.
* Ändra biträknarens jämförelse från `7` till `6`.

Var och en av dem är en verklig bugg som någon har skickat ut skarpt. Säg för var och en vilken av
testbänkens kontroller som fångar den, och hur felet hade sett ut på en verklig seriell länk om
ingenting hade fångat det.

---
