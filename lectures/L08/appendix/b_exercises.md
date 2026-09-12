# Appendix B - Övningar

> **Så kontrollerar du ditt arbete.** Övning 1 och 2 är penna och papper: de handlar om att få en
> tillståndsmaskin rätt *innan* den blir kod, och inget i dem kräver VHDL, GHDL eller kort.
>
> Från övning 4 och framåt har varje övning som ber dig skriva en VHDL-modul en utdelad
> självkontrollerande testbänk under [`exercises/`](../exercises), och ingenting annat; övning 3
> ändrar en modul du redan har och kontrolleras för hand, som det står där. Att sätta ihop resten av
> katalogen är en del av arbetet: modulerna du skrev i tidigare föreläsningar (`reset_sync`,
> `button_sync`, `sync`, `timer`) kopieras in från där du än skrev dem. Varje övning skriver ut de
> exakta kommandon den behöver. Skriv din modul i dess katalog `exercises/<module>/`, med det
> entitetsnamn och den **portordning** övningen anger, och kör den sedan med GHDL - se
> [Appendix C](../../L02/appendix/c_testbenches.md) för de tre kommandona.
>
> Övning 6 och 7 är kursens capstones: de två ändarna av en och samma seriella länk, en mottagare
> och en sändare. Var och en komponerar moduler från fyra olika föreläsningar, så var och en behöver
> mer än ett argument till `ghdl -a`, och det gör övning 4 och 5 också. Där så är fallet skriver
> övningen ut det kommando den behöver.
>
> Inget FPGA-kort behövs för någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL-koden rätt, och testbänken är
> hur du bekräftar det.

## Tillståndsdiagram och tillståndstabeller

**1.** Konstruera en ny Mooremaskin med fyra tillstånd, `{Q1, Q2}`, som styr en lysdiod via en enda
synkroniserad, flankdetekterad puls `X` från en knapp (producerad precis som `X` i det genomarbetade
exemplet i
[Appendix A.2](./a_state_machines.md#a2-att-konstruera-en-mooremaskin-för-hand-tillståndsdiagram-tillståndstabell-och-karnaughhärledd-logik)).

Den skiljer sig från det genomarbetade exemplet på två sätt:
* Tillståndsordningen är den vanliga binärräkningen `00 -> 01 -> 10 -> 11 -> 00`, **inte** den
  Graykod som används i A.2.
* Lysdioden (`Y`) lyser i **två** tillstånd i stället för ett:
  * Närhelst `Q1 = 1` (alltså i både `10` och `11`).

**a)** Rita tillståndsdiagrammet:
* Fyra tillstånd.
* En övergångspil per tillstånd för `X = 1`.
* En självloop per tillstånd för `X = 0`.

**b)** Fyll i hela tillståndstabellen (alla åtta rader av `{Q1, Q2, X}`).

**c)** Härled `Q1+`, `Q2+` och `Y` med Karnaughdiagram, på samma sätt som A.2 härleder dem för
Graykodsversionen.

**d)** Realisera grindnätet för hand:
* Två D-vippor för `{Q1, Q2}`.
* Grindar som beräknar `Q1+`, `Q2+` och `Y`.
* Bygg och simulera det i CircuitVerse, med dubbelvippsynkronisering och flankdetektering av
  knappingången precis som i
  [Appendix A.3](./a_state_machines.md#a3-från-grindnät-till-circuitverse).

**e)** Verifiera den i CircuitVerse, mot din egen tillståndstabell. Det finns ingen testbänk för den
här maskinen, och det är inte meningen att det ska finnas: tillståndstabellen du härledde i **b)**
*är* specifikationen, och att kontrollera en krets mot en specifikation du själv arbetat fram är
hela poängen med övningen.

Stega klockan för hand och kontrollera, i den här ordningen:
* **Stegningsvägen.** Pulsa `X` en gång per steg och gå ett helt varv, `00 -> 01 -> 10 -> 11 -> 00`.
  Läs av det förväntade nästa tillståndet ur din tabell före varje flank. Läs av `{Q1, Q2}` på
  vippornas utgångar efter flanken. Alla fyra övergångarna måste stämma.
* **Hållvägen.** Stega klockan med `X = 0` i vart och ett av de fyra tillstånden och bekräfta att
  maskinen står kvar. Det är fyra kontroller till, och det är den halva folk hoppar över; en maskin
  som stegar rätt men inte håller är en maskin vars `X'`-termer är fel.
* **Utgången.** Kontrollera `Y` mot din tabell i varje tillstånd: hög i `10` och `11`, låg i `00`
  och `01`. Gör det som en egen genomgång, inte medan du tittar på tillståndsbitarna.

Var de skiljer sig åt säger dig vilken grind du ska titta på. Ett felaktigt `Q1+` syns bara på de
övergångar där `Q1` skulle ha ändrats. Ett felaktigt `Y` syns med tillståndsföljden fortfarande helt
korrekt, vilket är varför det är värt en egen genomgång.

**Tips:** Eftersom tillståndsordningen ändrades från Graykod till binär, räkna med en övergång
(`01 -> 10`) där *två* tillståndsbitar vänder på en gång. Enligt A.2 är det harmlöst för maskinen
själv, eftersom ingenting samplar tillståndsregistret mellan flankerna, och CircuitVerses ideala
simulering visar dig ingenting åt något håll. Vad det däremot påverkar är `Y`, som här avkodas
kombinatoriskt ur tillståndsbitarna: på riktig hårdvara kan `Y` glitcha kort medan de två bitarna är
skeva. Lägg märke till vilken övergång det är, och vad du skulle göra åt det om `Y` drev något som
brydde sig.

---

## Sekvensdetektering

**2.** Konstruera en **Moore**maskin som detekterar sekvensen `1, 0, 1` när den kommer en bit per
klockcykel på en ingång `din`, och som höjer sin utgång `y` så snart träffens tredje bit setts.
* Icke-överlappande duger här: efter en fullständig träff, börja leta efter ett nytt `1, 0, 1` från
  början i stället för att återanvända de avslutande bitarna.

**a)** Rita tillståndsdiagrammet:
* Ett tillstånd per hur stor del av mönstret som matchats hittills.
* En pil ut ur varje tillstånd för `din = 0` *och* för `din = 1`; en sekvensdetektor är aldrig
  sysslolös, den antingen stegar framåt eller faller tillbaka.
* Markera vilket tillstånd som driver `y = 1`.

**b)** Fyll i tillståndstabellen, en rad per kombination av (tillstånd, `din`).

**c)** Följ den. Välj en sexbitarssekvens för `din` som innehåller minst en träff, och anteckna,
cykel för cykel:
* Tillståndet före flanken.
* Värdet på `din`.
* Utgången `y`.

**d)** Fällan i den här maskinen är pilarna tillbaka, inte de framåt. Säg för varje tillstånd vad
som händer på den ingång som *inte* för träffen vidare:
* Vilka av dem går tillbaka till starten?
* Finns det någon ingång som borde skicka dig tillbaka till ett *delvis* matchat tillstånd i stället
  för hela vägen till början? Motivera ditt svar för det här mönstret.

**Tips:** räkna dina tillstånd innan du ritar dem. "Inget matchat än", "sett `1`", "sett `10`",
"sett `101`" är den naturliga uppdelningen, och det sista av dem är det som driver `y`.

**Spara ditt svar.** Övning 4 nedan implementerar samma detektor i VHDL, som en Mealymaskin - som,
enligt [Appendix A.5](./a_state_machines.md#a5-mealymaskiner-skillnaden-på-en-klockcykel), behöver ett
tillstånd färre än det du just ritade. Att lista ut vilket av dina tillstånd som försvinner, och
varför, är en del av den övningen.

---

## Ändliga tillståndsmaskiner i VHDL

**3.** Utöka `fsm_led` med ett fjärde tillstånd, `STATE_FAST_BLINK`, som blinkar med 20 ms i stället
för `STATE_BLINK`:s 100 ms. Följ det genomarbetade exemplet i
[Appendix A.4](./a_state_machines.md#a4-samma-maskin-i-vhdl).

Arbeta på en **kopia** av modulen, inte på `lectures/L08/fsm_led/fsm_led.vhd` självt. Kopiera först
hela katalogen till ett eget ställe, tillsammans med de tre egna moduler den instansierar:

```bash
cp -r lectures/L08/fsm_led /tmp/fsm_led_fast
cp lectures/L04/exercises/reset_sync/reset_sync.vhd /tmp/fsm_led_fast     # the three you wrote
cp lectures/L04/exercises/button_sync/button_sync.vhd /tmp/fsm_led_fast   # yourself
cp lectures/L07/exercises/timer/timer.vhd /tmp/fsm_led_fast
cd /tmp/fsm_led_fast
```

Det finns ingen testbänk att köra här, men maskinen med fyra tillstånd ska ändå gå att analysera,
och det är värt att göra efter varje ändring: det fångar en saknad `case`-gren, eller ett
`state_t`-värde du lagt till i den ena processen men inte den andra.

```bash
ghdl -a --std=93 reset_sync.vhd button_sync.vhd timer.vhd fsm_led.vhd
```

Skälet är värt att känna till, eftersom det är en verklig fallgrop och inte sysselsättning för dess
egen skull. `fsm_led` har en utdelad referenstestbänk, `fsm_led_tb.vhd`, och övning 5 ber dig köra
den. Den testbänken kontrollerar cykeln med **tre** tillstånd: den trycker på knappen en gång från
`STATE_BLINK` och kontrollerar att lysdioden lyser fast, eftersom nästa tillstånd i maskinen som den
är skriven är `STATE_ON`. I din version med fyra tillstånd landar det trycket i `STATE_FAST_BLINK`,
lysdioden blinkar fortfarande, och assertionen fallerar. Ingenting i felet talar om vilken av de två
övningarna det hör till. Håll referensmaskinen intakt så uppstår aldrig den frågan.

Det finns ingen testbänk för maskinen med fyra tillstånd. Kontrollera den så som A.2 lät dig
kontrollera ett tillståndsdiagram: förutsäg tillståndsföljden för en serie knapptryck, läs sedan
tillbaka dina `case`-grenar och bekräfta att de stämmer.

Du behöver:
* Lägga till det nya värdet i `state_t`.
* Lägga till en gren i varje `case`-sats, i både `STATE_PROCESS` och `LED_PROCESS`.
* Hantera de två blinktakterna, antingen genom att:
  * Lägga till en andra timerinstans, eller
  * Låta den befintliga timerns tickantal växla utifrån det aktuella tillståndet.

---

**4.** Implementera detektorn för `1, 0, 1` från övning 2 i VHDL, i en ny katalog
`seq_detect_101_mealy` - den här gången som en **Mealy**maskin.

Utgå från ditt tillståndsdiagram för Mooremaskinen och konvertera det:
* Ditt sista tillstånd, "sett `101`", finns bara för att hålla utgången hög i en cykel.
* En Mealymaskin behöver det inte: utgångsvillkoret kan läsa `din` direkt i det tillstånd som redan
  matchat `1, 0`.
* Ta bort det tillståndet, och flytta in dess utgång i villkoret för `y`.

Följ sedan mönstret `type state_t is (...)` / `case` från
[Appendix A.4](./a_state_machines.md#a4-samma-maskin-i-vhdl) och
[Appendix A.5](./a_state_machines.md#a5-mealymaskiner-skillnaden-på-en-klockcykel):
* Återanvänd `reset_sync` för `reset_n`, precis som
  [`seq_detect_mealy.vhd`](../seq_detect_mealy/seq_detect_mealy.vhd) gör. Det finns ingen knapp i
  den här designen, så `button_sync` instansieras helt enkelt inte.
* Se till att tilldelningen av utgången `y` är en enda konkurrent sats, utanför varje klockad
  process, som beror på både `state` och `din`, inte bara `state`.
  * Annars har du i tysthet byggt en Mooremaskin i stället, och dess utgång kommer en cykel för
    sent - vilket är precis vad testbänken kontrollerar.

![Modulen `seq_detect_101_mealy`](./images/seq_detect_101_mealy.png)

**Självkontroll:** döp din entitet till `seq_detect_101_mealy`, med portarna `clock`, `reset_n`,
`din` (in) och `y` (out), deklarerade i den ordningen för att matcha `seq_detect_mealy`. En testbänk
finns i [`exercises/seq_detect_101_mealy/`](../exercises/seq_detect_101_mealy); den kontrollerar en
icke-överlappande "101"-detektor. Din modul instansierar `reset_sync`, som inte är utdelad där
eftersom du skrev den i [L04 övning 8](../../L04/appendix/b_exercises.md): kopiera in din egen. Det
här är den första övningen som behöver mer än en fil på `ghdl -a`-raden, med delblocket först så att
GHDL ser det före modulen som instansierar det:

```bash
cd lectures/L08/exercises/seq_detect_101_mealy
cp ../../../L04/exercises/reset_sync/reset_sync.vhd .     # the one you wrote in L04
ghdl -a --std=93 reset_sync.vhd seq_detect_101_mealy.vhd seq_detect_101_mealy_tb.vhd
ghdl -e --std=93 seq_detect_101_mealy_tb
ghdl -r --std=93 seq_detect_101_mealy_tb --assert-level=error --stop-time=10ms
```

---

## Att läsa den genomarbetade maskinen

**5.** `fsm_led` demonstreras på DE0-CV under föreläsningen (se
[Appendix A.6](./a_state_machines.md#a6-fpga-demonstration)). Den här övningen kontrollerar att du
kan redogöra för det du såg, och den har en utdelad referenstestbänk du kan köra själv. Den
återanvänder dina två L04-synkroniserare och din L07-`timer`, och ingen av dem är utdelad, så
kopiera in dem först:

```bash
cd lectures/L08/fsm_led
cp ../../L04/exercises/reset_sync/reset_sync.vhd .     # the three you wrote yourself
cp ../../L04/exercises/button_sync/button_sync.vhd .
cp ../../L07/exercises/timer/timer.vhd .
ghdl -a --std=93 reset_sync.vhd button_sync.vhd timer.vhd \
                 fsm_led.vhd fsm_led_tb.vhd
ghdl -e --std=93 fsm_led_tb
ghdl -r --std=93 fsm_led_tb --assert-level=error --stop-time=10ms
```

**a)** Räkna ut blinktakten ur källkoden, inte ur demonstrationen:
* `fsm_led` instansierar `timer` med `TIMER_TICK_COUNT` som har förvalet `5_000_000`, på en klocka
  på `50 MHz`.
* Hur lång är en timeoutperiod?
* `STATE_BLINK` växlar lysdioden vid varje timeout. Vilken **blink**frekvens ger det, och varför är
  den hälften av vad du kanske först skriver ned?

**b)** Testbänken skriver över `TIMER_TICK_COUNT` med ett mycket mindre värde än förvalet:
* Hitta den överskrivningen i [`fsm_led_tb.vhd`](../fsm_led/fsm_led_tb.vhd).
* Förklara varför en testbänk inte rimligen kan använda det riktiga värdet, och ungefär hur länge en
  simulering av en verklig blinkperiod skulle behöva köra.

**c)** Redogör för tillståndsmaskinens beteende:
* Alla tre tillstånden går att nå åt båda hållen. Följ de tryck på `button_n(0)` och `button_n(1)`
  som besöker varje tillstånd och återvänder till `STATE_OFF`.
* Tryck på båda knapparna under samma klockcykel. Vad gör `fsm_led`, och vilka två rader i
  arkitekturen avgör det?
* `timer_enable` drivs ur `state`, så timern går bara i `STATE_BLINK`. Lägg märke till att `timer`
  **fryses** snarare än nollställs när den är avstängd (L07 A.3). Vad betyder det för ögonblicket
  då du återvänder till `STATE_BLINK` efter att ha lämnat det, och skulle det vara bättre eller
  sämre att hålla `timer_enable` hög permanent?

---

## Capstone: en seriell mottagare
**6.** Det här är första halvan av kursens capstone, och den komponerar fyra föreläsningar till en
enda design. Övning 7 bygger den andra änden av samma seriella länk, så stanna inte här. Ingenting i
den är en ny idé; allt handlar om att koppla ihop moduler du redan har, runt en tillståndsmaskin du
konstruerar själv:
* [L04](../../L04/README.md):s `reset_sync`, som synkroniserar reset.
* [L05](../../L05/README.md):s `sync`, som synkroniserar ledningen `rx`, vilken kommer från någon
  annans kristall och är asynkron i precis den mening L04 avser.
* [L07](../../L07/README.md):s `timer`, som genererar översamplingsticket.
* Den här föreläsningens tillståndsmaskin, som ramar in alltihop och sköter sin egen skiftning och
  biträkning. Det byggde du som en modul i [L06](../../L06/README.md); här är det fyra rader inuti
  maskinen som redan har de räknare den behöver, vilket är det vanligare sättet en mottagare skrivs
  på.

Skriv en entitet med namnet `uart_rx8`: en mottagare för en byte asynkron seriell data, i det format
en UART sänder.

### Ledningens format
Ledningen `rx` bär ramar, och mellan ramarna ligger den i viloläge:
* **Vila**: ledningen hålls hög.
* **Startbit**: ledningen går låg i exakt en bitperiod. Det är det som markerar början på en ram;
  det finns ingen separat klockledning, vilket är vad "asynkron seriell" betyder.
* **Åtta databitar**, mest signifikant först, en bitperiod var.
* **Stoppbit**: ledningen går tillbaka hög i en bitperiod.

![UART-ram: en ledning som vilar hög, en startbit, åtta databitar med den mest signifikanta först, och en stoppbit, med mottagaren som samplar mitt i varje bit](./images/uart_frame.png)

Ramen ovan bär `10110010`, som är den första byten testbänken skickar. Pilarna är de åtta ögonblick
då mottagaren tar upp en **databit**: en och en halv bitperiod efter den fallande flanken, och
sedan en gång per bitperiod därefter. Den tittar på ledningen även däremellan - efter den fallande
flanken, mitt i startbiten för att kontrollera att den fortfarande är låg, och mitt i stoppbiten -
men bara de åtta pilarna bidrar med bitar till den mottagna byten.

Mottagaren måste återskapa bittajmingen enbart ur startbitens fallande flank. Det är hela problemet
den här övningen löser, och det är därför timern finns här.

**En medveten avvikelse från en riktig UART:** en riktig UART sänder sina databitar med den
**minst** signifikanta först, som
[L06 A.3](../../L06/appendix/a_counters_and_shift_registers.md#a3-serie-inparallell-ut-sipo)
påpekar. Den här övningen sänder dem med den mest signifikanta först:
* ramningen och tajmingen, som är vad de här två övningarna faktiskt handlar om, är identiska åt
  båda hållen.
* det är den riktning L06 A.3:s SIPO-idiom skiftar åt, så mottagarens skift blir en rad, och
  sändaren i övning 7 blir dess spegelbild.
* de utdelade testbänkarna sänder och förväntar sig MSB först för att matcha, så paret är konsekvent
  med sig självt.
* för att prata med en riktig UART skulle du vända skiftriktningen till L06 A.2:s spegelvända form
  och inte ändra något annat. Värt att veta innan du kopplar det här till en dators serieport och
  undrar varför varje byte kommer bitvänd.

### Översampling: sexton tick per bit
Mottagaren måste hitta mitten av en bit vars början den bara kan sluta sig till. Tekniken heter
**översampling**: kör `timer` med **sexton gånger** baudhastigheten, så att det finns sexton tick
per bitperiod, och räkna dem.

* Startbitens fallande flank nollställer tickräkningen till `0`. Timern går kontinuerligt, före,
  under och efter en ram; det är *räkningen* som nollställs, aldrig timern.
* **Tick 8** ligger en halv bit senare, mitt i startbiten. Kontrollera att ledningen *fortfarande är
  låg* där. Har den gått hög var det en glitch och ingen startbit, och mottagaren återgår till
  viloläge. Den omkontrollen är det som hindrar brus på en vilande ledning från att läsas som data.
* Därifrån är vart **sextonde** tick mitten på nästa bit: sampla ledningen och skifta in den. Åtta
  av dem är databitarna, och det nionde är stoppbiten.

Att sampla mitt i biten i stället för vid flankerna är det som ger mottagaren dess tajmingmarginal.
Sändarens klocka är en annan fysisk kristall än din, så de två driver isär under en ram; en
mottagare som samplade nära gränserna skulle läsa fel bit så snart de gjorde det. Sexton tick är det
konventionella valet, och sändaren i övning 7 går på samma tick.

### Entiteten `uart_rx8`

| Generic | Typ | Förval | Beskrivning |
|---|---|---|---|
| `OVERSAMPLE_TICK_COUNT` | `natural` | `325` | Tickantalet för `timer` för **en sextondel** av en bitperiod. 9600 baud vid `50 MHz`; del **b)** ber dig härleda det. |

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_n` | in | `std_logic` | Asynkron, aktiv låg; går genom `reset_sync`, som alltid. |
| `rx` | in | `std_logic` | Den seriella ledningen, direkt från en pinne och därför **asynkron**. Synkronisera den till `rx_s2` innan något annat läser den. |
| `data_out` | out | `std_logic_vector(7 downto 0)` | Den mottagna byten, giltig under den cykel då `byte_valid` är hög. |
| `byte_valid` | out | `std_logic` | En puls på en cykel: en komplett, korrekt ramad byte ligger på `data_out`. |
| `frame_err` | out | `std_logic` | En puls på en cykel: stoppbiten var inte hög, så ramen är trasig och ingen byte lämnas över. |

### Vad du ska bygga: mottagaren
**a)** Konstruera tillståndsmaskinen **på papper först**, precis som A.2 lät dig göra. Fyra
tillstånd:
  * `STATE_IDLE`, som väntar på att ledningen ska gå låg.
  * `STATE_START`, som vid tick 8 kontrollerar att ledningen fortfarande är låg.
  * `STATE_DATA`, som samplar en bit vart sextonde tick, åtta gånger.
  * `STATE_STOP`, som samplar stoppbiten sexton tick efter den sista databiten och väljer mellan
    `byte_valid` och `frame_err`.

Rita den innan du skriver någon VHDL, och på diagrammet:
* Ge varje tillstånd sin **självloop**: pilen för "ticket jag väntar på har inte kommit än, stå
  kvar". Det är den pil som brukar saknas, och ett tillstånd utan den faller igenom dit `else` råkar
  peka.
* Skriv bredvid varje tillstånd **hur många tick det väntar på**, så att tickbokföringen ligger på
  papperet i stället för i huvudet.
* Markera var `ticks` **nollställs**. Timern själv stannar aldrig, så de nollställningarna är de
  enda ställen där mottagaren avgör vad "början på en bit" betyder.
* Märk pilen ut ur `STATE_IDLE` med en **flank**, inte en nivå: `rx_s2` låg *och* hög vid
  föregående tick. Det kräver en bit historik, så anteckna var du tänker hålla den.

**b)** Räkna ut tajmingen innan du implementerar den:
* DE0-CV:s klocka är `50 MHz` och 9600 baud betyder 9600 bitar per sekund. Hur många klockcykler är
  en bitperiod? Hur många är en sextondel av en?
* `timer` pulsar var `TICK_COUNT + 1` klockcykel (L07 A.1). Vilket `OVERSAMPLE_TICK_COUNT` ger det
  dig? Det exakta svaret är inget heltal, så det finns två kandidater på var sin sida om det: räkna
  ut felet var och en av dem lämnar, och säg vilken av dem förvalet ovan är och varför.
* Det felet är en bråkdel av en procent, och det ackumuleras över en ram. Hur långt har din
  samplingspunkt tio bitperioder efter startflanken drivit från mitten av stoppbiten, mätt i
  översamplingstick? Hur många tick marginal hade den från början?
* Och nu skälet till att svaret är bekvämt: du omsynkroniserar vid varje startbit. Vad skulle behöva
  gälla för ramlängden för att det skulle sluta räcka?

**c)** Implementera `uart_rx8`. Den instansierar tre moduler och gör resten själv:
* `reset_sync` för reset. Allt annat i designen tar dess `reset_s2_n`.
* **`sync`**, modulen du skrev i [L05 övning 4](../../L05/appendix/b_exercises.md), på pinnen `rx`,
  som ger det `rx_s2` tillståndsmaskinen läser. Instansiera den med `SIZE = 1` och `PRESET = '1'`:
  en vilande ledning är hög, och en synkroniserare som kommer ur reset och läser `'0'` skulle för
  den här maskinen se ut som en startbit. `rx` kommer från en pinne som drivs av en sändare med sin
  egen kristall, så den är asynkron i precis den mening L04 avser, och varje regel från den
  föreläsningen gäller oförändrad. Lägg märke till att den tar en `std_logic_vector` med ett element
  på var sida, så du deklarerar ett par sådana och plockar ut `rx_s2` ur utgången.
* `timer`, med `OVERSAMPLE_TICK_COUNT` skickat rakt igenom, `enable` bundet till `'1'`, och dess
  `timeout` som din enda uppfattning om förfluten tid. Kalla den `baud_tick`. Timern frilöper: den
  stoppas aldrig, nollställs aldrig, och inget tillstånd rör den någonsin. Det maskinen fasar om i
  stället är sin egen räknare `ticks`.
* Ingen skiftregistermodul. Maskinen behöver ändå en biträknare, så den skiftar in ledningen direkt
  i en signal `frame` själv, en rad VHDL per samplad bit.

**Tillståndsmaskinen, tillstånd för tillstånd.** Två räknare: `ticks` som räknar `0` till `15` inom
en bit, och `bit_count` som räknar de åtta databitarna. Allt nedan händer **bara när
`baud_tick = '1'`**; vid varje annan klockflank står maskinen still. Eftersom timern frilöper är ett
tick alltid på väg, i varje tillstånd inklusive vila.

| Tillstånd | Väntar på | Sedan | Till |
|---|---|---|---|
| `STATE_IDLE` | fallande flank på `rx_s2` | nollställ `ticks` | `STATE_START` |
| `STATE_START` | `ticks` = 8 | `rx_s2` fortfarande låg? nollställ `ticks` | `STATE_DATA` |
| | | `rx_s2` hög? det var en glitch | `STATE_IDLE` |
| `STATE_DATA` | `ticks` = 15 | skifta in `rx_s2` i `frame`, nollställ `ticks` | `STATE_DATA` tills 8 bitar, sedan `STATE_STOP` |
| `STATE_STOP` | `ticks` = 15 | `rx_s2` hög? `data_out <= frame`, pulsa `byte_valid` | `STATE_IDLE` |
| | | `rx_s2` låg? pulsa `frame_err`, kasta byten | `STATE_IDLE` |

Det finns inget "klart"-tillstånd. Samplingen av stoppbiten är där ramen bedöms, så det är där byten
lämnas över, och maskinen går rakt tillbaka till viloläge.

**Varför vilotillståndet väntar på en flank i stället för en nivå.** Håll ett tick historik för
`rx_s2`, och lämna vilotillståndet bara vid övergången från hög till låg. Att i stället testa nivån,
"om `rx_s2` är låg, starta en ram", ser likvärdigt ut och klarar allt utom det enda fall som spelar
roll.

Betrakta ett **break**: ledningen hålls låg långt längre än en ram, vilket är hur en sändare som
tappar strömmen ser ut. Ett nivåtest återaktiveras i samma ögonblick som den föregående ramens
stoppbit bedöms, så mottagaren tillbringar hela breaket med att marschera genom ram efter ram av
idel nollor. Var och en slutar på en låg stoppbit och förkastas korrekt, och den delen är i sin
ordning. Problemet är den ram som är i luften när breaket *slutar*: dess stoppbit samplas efter att
ledningen gått tillbaka hög, så det är en fullkomligt välformad ram så vitt mottagaren kan avgöra,
och en byte gjord av ingenting lämnas över som riktiga data. Flanktestet återaktiveras inte alls
under breaket, eftersom det efter den första fallande flanken inte kommer någon till förrän
ledningen har hämtat sig.

Det är hela skillnaden, den kostar en vippa, och det är därför en mottagare som "fungerar" på rena
data ändå kan lämna över skräp första gången en kabel dras ur.

**Skiftet.** Åtta databitar kommer med den mest signifikanta först, så SIPO-idiomet från
[L06 A.3](../../L06/appendix/a_counters_and_shift_registers.md#a3-serie-inparallell-ut-sipo) klarar
det helt utan indexaritmetik:

```vhdl
frame <= frame(6 downto 0) & rx_s2;
```

`bit_count` räknar då bara *hur många* bitar som kommit, aldrig *var* de hamnar. Att i stället lagra
med `frame(bit_count) <= rx_s2` lägger den först ankomna biten i bit 0, vilket vänder byten: det är
den ordning med minst signifikant först som en riktig UART använder, och det skulle vara rätt val om
den här mottagaren måste prata med en sådan. Här ligger MSB först på ledningen, så skiftet är det
som matchar.

Fyra saker avgör om det här fungerar:

* **Allt är villkorat på `baud_tick`.** Ett tillstånd som agerar på en vanlig klockflank körs sexton
  gånger per tick och ungefär femtusen gånger per bit.
* **Varje tillstånd behöver sin "inte än"-väg.** Om ticket du väntar på inte har kommit, eller
  räkningen inte har nått sitt mål, måste maskinen **stå kvar där den är**. Att skicka den någon
  annanstans i `else` är det överlägset vanligaste sättet den här designen fallerar på, och den
  fallerar fullständigt snarare än subtilt: maskinen hamnar i att studsa fram och tillbaka mellan
  två tillstånd och når aldrig det tredje.
* **Se upp med ettfelet i räknaren.** Med `ticks` som börjar på `0` och ökar vid varje tick är det
  *n*:te ticket `ticks = n - 1` i det ögonblick du testar det. Om du jämför före eller efter
  ökningen avgör vilket tick du faktiskt samplar på, och att vara ett eller två tick sen går att
  överleva medan åtta inte gör det.
* **Timern frilöper, så din fas kommer ur `ticks`, aldrig ur timern.** Startflanken kommer när
  sändaren skickar den, vilket är någonstans inuti en tickperiod mottagaren inte valt, så det första
  ticket efter den flanken kan komma allt från ett helt tick till nästan ingen tid senare. Att
  nollställa `ticks` på vägen ut ur vilotillståndet är det som fasar om samplingen mot startbiten.
  Den överblivna bråkdelen av ett tick är priset för att aldrig stoppa timern, och det är billigt:
  en sextondel av en bit, mot den halva bit marginal del **b)** ber dig räkna ut.

**d)** Kör testbänken. Den behöver fyra designfiler, delblocken först, och inget av de tre
delblocken är utdelat i övningskatalogen: alla tre är moduler du skrivit, `reset_sync` i L04, `sync`
i L05 och `timer` i L07.

```bash
cd lectures/L08/exercises/uart_rx8
cp ../../../L04/exercises/reset_sync/reset_sync.vhd .     # the three you wrote yourself
cp ../../../L05/exercises/sync/sync.vhd .
cp ../../../L07/exercises/timer/timer.vhd .
ghdl -a --std=93 sync.vhd reset_sync.vhd timer.vhd uart_rx8.vhd uart_rx8_tb.vhd
ghdl -e --std=93 uart_rx8_tb
ghdl -r --std=93 uart_rx8_tb --assert-level=error --stop-time=10ms
```

Den agerar sändare, och kontrollerar:
* två rena ramar, som kommer fram som rätt byte, utan något `frame_err`.
* en vilande ledning, före, mellan och efter dem, som inte producerar något.
* en ram vars stoppbit är **låg**: `frame_err` måste pulsa och ingen byte får lämnas över.
* ledningen hållen låg långt längre än en ram, vilket är ett **break**: varje ram mottagaren tror
  sig se där slutar med en låg stoppbit, så ingen av dem är en byte.
* en ram där varje databit bär sitt värde bara i **mitten** av bitperioden och motsatt nivå på var
  sida. En mottagare som samplar nära tick 8 läser den perfekt; en som samplar nära en gräns läser
  grannbiten.
* att `byte_valid` och `frame_err` var för sig aldrig är höga två cykler i rad.

**Tips:** bygg den i etapper och kör testbänken efter varje, i stället för att skriva alla fyra
tillstånden och felsöka dem på en gång:
* Få först maskinen att lämna vilotillståndet på en startbit och nå `STATE_DATA`. Kommer den aldrig
  dit är det "inte än"-vägen du ska titta på.
* Sampla sedan en databit och kontrollera att det är rätt bit innan du bryr dig om de andra sju.
* Sedan stoppbiten och de två pulserna.

**e)** Ha nu sönder den med flit, och fundera på vad resultatet bevisar och inte bevisar:
* Ta bort stoppbitstillståndet, och lämna över byten så snart den åttonde databiten är inne.
* Förutsäg vad som borde gå fel, och kör den sedan. Två kontroller fångar det här, och det är värt
  att veta vilken som utlöser först: ramen med låg stoppbit höjer inte längre `frame_err`, och den
  lämnar över en byte som skulle ha kastats.
* Nu andra halvan av lärdomen. Att passera är den svagare signalen, så hitta en sabotering
  testbänken **inte** fångar. Här är en: **ta bort omkontrollen mitt i startbiten**, så att
  `STATE_START` går vidare till `STATE_DATA` vid tick 8 utan att bekräfta att ledningen fortfarande
  är låg. Testbänken lägger aldrig någon glitch på en vilande ledning, så ingenting märker det, och
  på riktig hårdvara startar en enda brusspik en spökram. Läs `uart_rx8_tb.vhd` och säg vad du
  skulle lägga till för att fånga det.
* Här är en andra: **sampla vid tick 3 i stället för tick 8.** Räkna ut varför testbänken
  fortfarande passerar, och vad du har gett bort. Svaret ligger i marginalberäkningen i del **b)**.
* Och en tredje, som är den viktigaste av de tre: **ta bort synkroniseraren för `rx`** och läs
  pinnen direkt. Varje kontroll passerar fortfarande, och det kommer den alltid att göra, oavsett
  vad som läggs till i testbänken. Säg varför, i termer av vad en simulator modellerar och vad den
  inte modellerar, och läs sedan om
  [L04 A.4](../../L04/appendix/a_metastability_and_synchronization.md#a4-intuition-för-tidsförhållandena-varför-nästan-säkert-duger).
  Det här är den enda sortens bugg i kursen som testning inte kan nå, vilket är precis varför L04
  ger dig en regel att följa snarare än ett symptom att leta efter.
* Med några meningar: vad lovar egentligen "passerar sin testbänk", och vad lovar det inte?

![Modulen `uart_rx8`](./images/uart_rx8.png)

**Självkontroll:** döp din entitet till `uart_rx8`, med generic `OVERSAMPLE_TICK_COUNT`
(`natural`), ingångarna `clock`, `reset_n`, `rx`, och utgångarna `data_out`
(`std_logic_vector(7 downto 0)`), `byte_valid` och `frame_err`, deklarerade i den ordningen. Dess
testbänk finns i [`exercises/uart_rx8/`](../exercises/uart_rx8), och inget annat: **kopiera in dina
egna `reset_sync`, `sync` och `timer`**, som del **d)** visar. En projektkatalog innehåller allt den
byggs av, och att sätta ihop den är en del av övningen. L07:s `walking_led` sätts ihop på samma
sätt.

---

**7.** Den andra halvan av länken: skriv `uart_tx8`, en sändare som skickar en byte i samma format
som övning 6 tar emot.

En sändare är den enklare av de två, och skälet är värt att förstå innan du börjar:
* Mottagaren måste *återskapa* bittajmingen ur en startflank den inte styrde över, vilket är varför
  den samplade mitt i biten och varför dess timer gick på en sextondels bitperiod.
* Sändaren **definierar** tajmingen. Ingenting behöver återskapas, så timern går på en hel bitperiod
  och maskinen håller helt enkelt varje bit på ledningen under en timeout.

Den sänder den mest signifikanta biten först, vilket matchar mottagaren i övning 6 snarare än en
riktig UART, av skälet som anges där.

### Entiteten `uart_tx8`

| Generic | Typ | Förval | Beskrivning |
|---|---|---|---|
| `BIT_TICK_COUNT` | `natural` | `5207` | Tickantalet för `timer` för en **hel** bitperiod, 9600 baud vid `50 MHz`. Sexton av övning 6:s översamplingstick, så när som på den avrundning **övning 6:s** del b) ber dig räkna ut, så att en `uart_tx8` och en `uart_rx8` byggda med de matchande förvalen pratar i samma takt. |

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_n` | in | `std_logic` | Asynkron, aktiv låg; genom `reset_sync`, som alltid. |
| `data_in` | in | `std_logic_vector(7 downto 0)` | Byten som ska skickas. |
| `send` | in | `std_logic` | En begäran om att sända `data_in`. Ignoreras medan sändaren är upptagen. |
| `tx` | out | `std_logic` | Den seriella ledningen. **Vilar hög**, även under reset. |
| `busy` | out | `std_logic` | Hög från ögonblicket en ram startar tills stoppbiten är över. |

### Vad du ska bygga: sändaren
**a)** Rita tillståndsmaskinen först. Fyra tillstånd är den naturliga uppdelningen: vila, startbit,
databitar, stoppbit, och vart och ett håller ledningen på en definierad nivå under en bitperiod:
* Markera vad som driver `tx` i varje tillstånd. Lägg märke till att `tx` aldrig beror på `send`
  eller någon annan primär ingång: det är tillståndet, plus skiftregistrets aktuella utgång. Det gör
  det här till en Mooremaskin, som allt annat i den här kursen.
* Markera var `busy` kommer ifrån. Det är en enda jämförelse mot tillståndet.
* Bestäm var byten fångas. Den måste låsas när ramen startar, inte läsas kontinuerligt ur `data_in`:
  producenten står fritt att ändra `data_in` i samma ögonblick som `busy` går hög, och en verklig
  sådan kommer att göra det.

**b)** Skifta ut byten med den mest signifikanta biten först, i maskinen själv, spegelbilden av vad
mottagaren gör:
* Lås in `data_in` i en signal `frame` när ramen startar.
* Driv `tx` från den översta biten i `frame` medan du är i datatillståndet.
* Skifta `frame` ett steg uppåt per bitperiod, och håll räkningen på de åtta bitar som går ut.

Det här skrev du som en modul i [L06 övning 7b](../../L06/appendix/b_exercises.md), och `piso8` är
värd att läsa om för idiomets skull. Att instansiera den här skulle fungera, men maskinen äger redan
den biträknare ett PISO-register behöver, så skiftet blir en enda rad inuti det tillstånd där det
hör hemma. Så är båda halvorna av den här länken byggda, och samma avvägning återkommer i L14, där
`tx_shift_reg` är en egen modul just för att `can_controller` *inte* redan äger den räknare den
behöver.

**c)** Implementera den, med `reset_sync` instansierad för reset och `timer` med `BIT_TICK_COUNT`
skickat rakt igenom.

Här **är** timerns `enable` driven av tillståndet, hög bara medan en ram är i luften, och det är det
enda stället där den här designen medvetet skiljer sig från övning 6. Mottagaren måste låta sin
timer frilöpa eftersom den inte styr när en ram börjar: den kan bara fasa om sin egen tickräkning
när startflanken redan har kommit. Sändaren har det motsatta problemet. Den *bestämmer* när ramen
börjar, så den kan starta timern i det ögonblicket och få en första bitperiod som är exakt lika lång
som alla andra. Låt den frilöpa här i stället, så blir startbiten kort med precis så mycket av en
tickperiod som råkade återstå när `send` kom, vilket är en defekt i det enda en sändare är ansvarig
för.

Två krav testbänken är sträng med:
* **`send` ignoreras medan sändaren är upptagen.** Att ladda om mitt i en ram skulle starta om byten
  och korrumpera det som redan ligger på ledningen. En begäran som kommer under en ram kastas, den
  köas inte.
* **`busy` ligger kvar hög genom hela stoppbiten**, inte bara databitarna. Ramen är inte över förrän
  ledningen hållits hög under den sista bitperioden.

**d)** Kör testbänken. Den agerar mottagare: den väntar på din startbit, samplar mitten av varje
bitperiod, och kontrollerar ramningen, byten, handskakningen med `busy`, och att ett `send` som
matas in två bitperioder in i en ram ignoreras.

```bash
cd lectures/L08/exercises/uart_tx8
cp ../../../L04/exercises/reset_sync/reset_sync.vhd .     # the two you wrote yourself
cp ../../../L07/exercises/timer/timer.vhd .
ghdl -a --std=93 reset_sync.vhd timer.vhd uart_tx8.vhd uart_tx8_tb.vhd
ghdl -e --std=93 uart_tx8_tb
ghdl -r --std=93 uart_tx8_tb --assert-level=error --stop-time=10ms
```

**e)** Svara, i löpande text:
* En sändare som hoppar över stoppbiten helt lämnar ändå ledningen hög efteråt, eftersom vila och
  stopp är samma nivå. Vad går egentligen fel, och när visar det sig först?
  * Testbänken fångar den här. Vilken av dess kontroller gör det, och varför hade det aldrig gått
    att fånga genom att bara titta på `tx`?
* Din mottagare i övning 6 samplar mitt i varje bit; din sändare ändrar ledningen vid flankerna. Om
  båda gick på kristaller som skilde sig med 1 %, ungefär hur många bitar in i en ram skulle
  mottagarens samplingspunkt driva in i fel bit? Vad säger det dig om varför seriella format har en
  startbit per byte, snarare än en enda i början av ett långt meddelande?

![Modulen `uart_tx8`](./images/uart_tx8.png)

**Självkontroll:** döp din entitet till `uart_tx8`, med generic `BIT_TICK_COUNT` (`natural`),
ingångarna `clock`, `reset_n`, `data_in` (`std_logic_vector(7 downto 0)`), `send`, och utgångarna
`tx`, `busy`, deklarerade i den ordningen. Dess testbänk finns i
[`exercises/uart_tx8/`](../exercises/uart_tx8), och inget annat: kopiera in dina egna `reset_sync`
och `timer`, som del **d)** visar.

---
