# Appendix B - Övningar

> **Så kontrollerar du ditt arbete.** Övning 1 är en kort uppvärmning med papper och penna på den
> notation kursen använder rakt igenom; den kräver varken VHDL, GHDL eller kort, och anger vad ett
> bra svar täcker.
>
> Från övning 2 och framåt har varje övning som ber dig skriva en VHDL-modul en utdelad
> självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess katalog
> `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och kör den
> sedan med GHDL - se [Appendix C](../../L02/appendix/c_testbenches.md) för de tre kommandona.
>
> Inget FPGA-kort behövs till någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL-koden rätt, och testbänken är
> hur du bekräftar det.

## Sanningstabeller och grindar
**1.** En funktion av två ingångar `A`, `B` och en utgång `X` har sanningstabellen nedan:

| A | B | X |
|---|---|---|
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

**a)** Härled summa-av-produkter-ekvationen för `X` direkt ur sanningstabellen (Appendix A, A.2).
Två rader har `X = 1`, så du får två AND-termer.

**b)** Förenkla den algebraiskt. Bryt ut det som de två termerna delar, och tillämpa
`A + A' = 1` och `1 · B' = B'` från A.2. Du ska hamna i en enda literal.

**c)** Ditt svar på **b)** säger något om `A`. Vad? Vilken enda grind ur tabellen i A.1 beräknar
funktionen, och vad händer med ingången `A` när du ritar den?

**d)** Bygg den enkelgrindsversionen i CircuitVerse och bekräfta att den återger varje rad i
sanningstabellen ovan. Lämna ingången `A` okopplad, eller utelämna den helt enkelt ur ritningen;
**b)** är motiveringen till att göra så.

---

## Entiteter och arkitekturer
**2.** Skriv två små grindar som kompletta VHDL-moduler, `and_gate` och `nand_gate`.

Ingen av grindarna är poängen, och du ska inte förvänta dig att någon av dem är svår. Poängen är att
det är här en entitet och en arkitektur slutar vara något du läser om i A.4 och blir något du
skriver, och att de två halvorna är värda att skriva i den ordningen.

Båda entiteterna har samma portar:

| Port | Riktning | Typ |
|---|---|---|
| `a` | in | `std_logic` |
| `b` | in | `std_logic` |
| `x` | out | `std_logic` |

**a)** Skriv `entity`-deklarationen för `and_gate`, och ingenting annat. I VHDL är en moduls
gränssnitt något du kan skriva ner och resonera om innan någon implementation alls finns, vilket är
den vana den här deluppgiften finns till för att bygga. Identifiera vilka portar som krävs,
riktningen på var och en, och typen på var och en.

**b)** Lägg till en `architecture` som implementerar AND-grinden med en enda konkurrent
signaltilldelning.

**c)** Skriv nu `nand_gate`: samma gränssnitt med inverterad utgång, med VHDL:s `nand`-operator
direkt. Skriv **inte** `not (a and b)`.

De två är likvärdiga som boolesk algebra, och på en FPGA gör de ingen skillnad alls, eftersom båda
hamnar i samma lookup-tabell. Det spelar roll på den sortens hårdvara som övning 6 nedan handlar om,
där NAND är den grind du fysiskt har och allt annat måste byggas av den. Att skriva vad du menar,
och låta verktygen avgöra vad det kostar, är vanan; att sträcka sig förbi en operator språket redan
ger dig är det som ska undvikas.

![Modulen `and_gate`](./images/and_gate.png)

![Modulen `nand_gate`](./images/nand_gate.png)

**Självkontroll:** döp dina entiteter till `and_gate` och `nand_gate`, var och en med portarna `a`,
`b` (in) och `x` (out), deklarerade i den ordningen; deras testbänkar ligger i
[`exercises/and_gate/`](../exercises/and_gate) och
[`exercises/nand_gate/`](../exercises/nand_gate), och var och en kontrollerar alla fyra raderna i
motsvarande sanningstabell.

---

**3.** En XOR-grind har tre ingångar, `a`, `b`, `c`, och en utgång, `x`. Utgången är `1` när ett
udda antal av ingångarna är `1` (XOR med tre ingångar, eller paritetsfunktionen).

**a)** Skriv sanningstabellen för `x` över alla åtta kombinationer av `a`, `b`, `c`, och bekräfta
att den stämmer med beskrivningen "ett udda antal `1`:or".
**b)** Implementera grinden i VHDL, som en egen modul med en entitet vars portar är tre
`std_logic`-ingångar och en `std_logic`-utgång, och en arkitektur som driver `x` med en enda
konkurrent tilldelning (Appendix A, A.4 visar mönstret entitet/arkitektur och noterar att VHDL:s
`xor`-operator arbetar direkt på `std_logic`; A.5 visar en komplett modul från början till slut).
**c)** Bygg samma grind i CircuitVerse och bekräfta att den återger varje rad i din sanningstabell.

**Tips:** `xor` kedjar från vänster till höger, så hela arkitekturkroppen är en enda rad,
`x <= a xor b xor c;`, utan behov av vare sig intern `signal` eller mellanliggande grindar.

![Modulen `xor3`](./images/xor3.png)

**Självkontroll:** döp din VHDL-entitet till `xor3`, med portarna `a`, `b`, `c` (in) och `x` (out),
deklarerade i den ordningen; dess testbänk ligger i [`exercises/xor3/`](../exercises/xor3), och A.5
listar de tre kommandon som kör den.

---

**4.** En **majoritetsgrind** har tre ingångar, `a`, `b`, `c`, och en utgång, `x`. Utgången är `1`
när *minst två* av de tre ingångarna är `1`.

Det här är kretsen bakom en trippelredundant omröstning: tre sensorer rapporterar samma mätvärde,
och systemet agerar på det svar två av dem är överens om, så att en enskild trasig sensor inte kan
bestämma något på egen hand.

**a)** Skriv sanningstabellen för `x` över alla åtta kombinationer av `a`, `b`, `c`.

**b)** Härled summa-av-produkter-ekvationen för `x` direkt ur sanningstabellen (Appendix A, A.2):
* Fyra rader har `x = 1`, så du får fyra AND-termer.
* Varje term innehåller alla tre ingångarna, primmade där ingången är `0` på sin rad.

**c)** Implementera grinden i VHDL, som en egen modul:
* En entitet med tre `std_logic`-ingångar och en `std_logic`-utgång.
* En arkitektur som driver `x` med en enda konkurrent tilldelning, och som översätter dina fyra
  AND-termer rakt av (Appendix A, A.4).

**d)** Bygg samma nät i CircuitVerse och bekräfta att det återger varje rad i din sanningstabell.

**Tips:** Skriv ut ekvationen på papper innan du öppnar vare sig editorn eller CircuitVerse. Fyra
AND-termer med tre ingångar plus en OR-grind med fyra ingångar är mycket ledningsdragning att rätta
i efterhand.

**Blick framåt:** räkna grindarna din ekvation kräver, och övertyga dig sedan genom inspektion om
att `x = ab + ac + bc` beräknar samma funktion med tre AND-grindar med två ingångar i stället för
fyra med tre. Summa-av-produkter gav dig ett *korrekt* nät, inte det *minsta*; att hitta det mindre
systematiskt, snarare än genom att stirra på det, är vad
[L02](../../L02/README.md) är till för.

![Modulen `majority3`](./images/majority3.png)

**Självkontroll:** döp din VHDL-entitet till `majority3`, med portarna `a`, `b`, `c` (in) och `x`
(out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/majority3/`](../exercises/majority3) och kontrollerar alla åtta raderna. Vilken som
helst av ekvationerna går igenom - testbänken kontrollerar funktionen, inte vilket nät du valde.

---

**5.** Skriv en **halvadderare**: `sum` och `carry` ur två enskilda bitar. Du kan kretsen; skälet
till att den står här är att den är kursens första modul med **två utgångar**, och det är en
VHDL-fråga snarare än en logikfråga.

**a)** Implementera den, med två konkurrenta tilldelningar och utan intern `signal`.

Två utgångar betyder inte två entiteter, två arkitekturer eller en process. Varje utgångsport drivs
av sin egen konkurrenta tilldelning, och de två är inte steg som sker i en ordning: de beskriver två
separata ledningsstycken, båda aktiva hela tiden. Om du kommer på dig själv med att sträcka dig
efter en process för att "returnera" två värden är den instinkten mjukvaruinstinkten, och A.4:s "en
konkurrent tilldelning beskriver en ledning" är rättelsen.

**b)** Bygg den i CircuitVerse och bekräfta båda utgångarna, så att du har sett formen med två
utgångar som en ritning innan du möter den som en entitet med flera `out`-portar i L02.

**Blick framåt:** det här är cellen som räknaren i [L06](../../L06/README.md) är byggd av. Adderaren
med fyra bitar där är fyra sådana kedjade carry-till-carry, och räknaren är den adderaren med sin
utgång återkopplad till sin ingång, vilket är därför överslaget inte behöver någon logik alls.

![Modulen `half_adder`](./images/half_adder.png)

**Självkontroll:** döp din entitet till `half_adder`, med portarna `a`, `b` (in) och `sum`, `carry`
(out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/half_adder/`](../exercises/half_adder) och kontrollerar `sum` och `carry` var för sig,
så att en konstruktion som har den ena rätt och den andra fel får veta vilken som är vilken.

---

## Universella grindar
**6.** Appendix A.1 slår fast att varje boolesk funktion kan byggas med enbart `NAND`-grindar. Den
här övningen får dig att bevisa det för dig själv för de tre operatorer du har använt.

**a)** Härled `OR`-fallet på papper innan du bygger något, eftersom De Morgan
([A.2](./a_combinational_logic.md#lagarna-som-en-påminnelse)) ger dig det direkt. Utgå från
`(A'B')'` och tillämpa lagen; du ska komma fram till `A + B`. Läs nu tillbaka det uttrycket som en
krets: vad är `A'B'` med en inversion på sin utgång, och hur många `NAND`-grindar är alltihop?

**b)** Bygg i CircuitVerse var och en av följande av enbart `NAND`-grindar, och stäm av var och en
mot dess sanningstabell i A.1 efter hand:
* `NOT a`: en NAND-grind räcker, om du matar samma signal till båda dess ingångar.
* `a AND b`: en NAND-grind, följd av den `NOT` du just byggde.
* `a OR b`: nätet du härledde i **a)**. Stäm av ditt grindantal mot vad du förutsade.

**c)** Skriv `OR`-versionen i VHDL, som en egen modul:
* En entitet med två `std_logic`-ingångar och en `std_logic`-utgång.
* En arkitektur som driver `x` med en enda konkurrent tilldelning.
* Använd enbart VHDL:s `nand`-operator:
  * ingen `or`, ingen `and`, ingen `not` någonstans i uttrycket.

**d)** Förklara varför det här spelar roll i praktiken. Tänk på att en chiptillverkningsprocess
fysiskt måste implementera varje grindtyp den erbjuder, och att `NAND` är den billigaste grinden att
bygga i CMOS.

**Tips:** VHDL:s `nand`-operator kedjar inte så som `and` och `or` gör: `a nand b nand c` är inte
giltigt. Parentessätt varje NAND explicit, vilket ändå är vad du vill här, eftersom varje
parentespar är en fysisk grind i din CircuitVerse-ritning.

![Modulen `or_from_nand`](./images/or_from_nand.png)

**Självkontroll:** döp din VHDL-entitet till `or_from_nand`, med portarna `a`, `b` (in) och `x`
(out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/or_from_nand/`](../exercises/or_from_nand) och kontrollerar den mot alla fyra raderna i
`OR`-sanningstabellen.

---

## Att sätta ihop det hela
**7.** Skriv bromsassistenten från
[Appendix A.6](./a_combinational_logic.md#a6-föreläsningens-krets-en-bromsassistent) i VHDL.

A.6 lät dig härleda dess ekvationer, räkna dess grindar och skissa dess nät *före* passet, och
passet byggde den sedan live. Det är här du skriver den själv, och där en testbänk avgör om din
läsning av kravet stämmer med den i A.6:s sanningstabell.

Entiteten måste ha:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `driver_brake` | in | `std_logic` | Föraren står på bromspedalen. |
| `sensor` | in | `std_logic` | Avståndssensorn ser ett hinder. |
| `radar` | in | `std_logic` | Radarn ser ett hinder. |
| `error` | in | `std_logic` | Assistanssystemet rapporterar ett fel. |
| `engine_brake` | out | `std_logic` | Lägg an bromsarna. |

**a)** Implementera den utifrån **dina egna** ekvationer snarare än utifrån det som stod på skärmen.
Om de två är oense är den oenigheten det mest användbara den här övningen kan ge dig, och testbänken
talar om vilken av dem sanningstabellen håller med.

Använd två konkurrenta tilldelningar och en intern `signal`:
* Signalen håller assistanssystemets eget beslut, innan förarens pedal vägs in.
* Det här är kursens första övning med en intern signal, och det är anledningen till att nyckelordet
  finns: ett namn på ett mellanresultat, så att varje rad fortfarande läser sig som den sats i
  kravet den kom ifrån.

**b)** Gör nu sönder den avsiktligt, på det specifika sätt A.6 varnar för. Mata `driver_brake`
*genom* fellogiken i stället för att låta den gå förbi:

```vhdl
engine_brake <= (driver_brake or sensor or radar) and (not error);
```

Det är en grind enklare, och det ser rimligt ut. Kör testbänken mot den och svara:
* Vilken ingångskombination faller den på först, och vad händer fysiskt i bilen i det ögonblicket?
* Hur många av de sexton raderna får den fel, och vad har de alla gemensamt?
* De rader som fallerar är precis de som säkerhetskravet skrevs för. Vad säger det dig om värdet av
  en sanningstabell du härlett ur ett krav, till skillnad från en du läst av ur en krets du redan
  byggt?

![Modulen `adas`](./images/adas.png)

**Självkontroll:** döp din entitet till `adas`, med ingångarna `driver_brake`, `sensor`, `radar`,
`error` och utgången `engine_brake`, deklarerade i den ordningen; dess testbänk ligger i
[`exercises/adas/`](../exercises/adas) och kontrollerar alla sexton raderna i A.6:s sanningstabell.

---
