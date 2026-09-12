# Appendix A - Kombinatorik

## A.1 Digitala signaler och logiska grindar
En digital signal antar ett av två värden, `0` eller `1`, i stället för det kontinuerliga intervall
en analog signal använder. Allt som ligger tillräckligt nära `0` eller `1` läses som exakt `0` eller
`1`, så små mängder elektriskt brus ändrar ingenting. Den brusimmuniteten är anledningen till att
nästan all modern beräkning, från mikrokontroller till FPGA:er, är digital.

En **logisk grind** har en eller flera enbitarsingångar, en enbitarsutgång och en fast boolesk
funktion mellan dem.

**Kombinatorik**, den här föreläsningens ämne, producerar utgångar enbart utifrån de aktuella
ingångarna, utan minne. **Sekvensnät** (L03) beror på de aktuella ingångarna *och* på tillstånd
lagrat i vippor.

Varje grundläggande grind med två ingångar, plus den unära `NOT`:

| A | B | AND |  OR | NAND | NOR | XOR | XNOR |
| - | - | :-: | :-: | :--: | :-: | :-: | :--: |
| 0 | 0 |  0  |  0  |   1  |  1  |  0  |   1  |
| 0 | 1 |  0  |  1  |   1  |  0  |  1  |   0  |
| 1 | 0 |  0  |  1  |   1  |  0  |  1  |   0  |
| 1 | 1 |  1  |  1  |   0  |  0  |  0  |   1  |

| A | NOT A |
| - | :---: |
| 0 |   1   |
| 1 |   0   |

Värt att lägga på minnet direkt ur tabellerna:
* `NAND`, `NOR` och `XNOR` är inverserna av `AND`, `OR` och `XOR`.
* `XOR` är `1` när ingångarna skiljer sig åt. Bortom två ingångar generaliseras det till **udda
  paritet**: `1` när ett udda antal ingångar är `1` ([Appendix B](./b_exercises.md), övning 3).
* Varje boolesk funktion kan byggas av `AND`, `OR` och `NOT`, och även av enbart `NAND` eller enbart
  `NOR`.

---

## A.2 Boolesk algebra som notation
Tre operatorer, som avbildas rakt av på grindarna ovan:

| Grind | Notation i boolesk algebra |
|---|---|
| AND | multiplikation: `A` **AND** `B` skrivs `AB` |
| OR | addition: `A` **OR** `B` skrivs `A + B` |
| NOT | prim: **NOT** `A` skrivs `A'` |

En funktion skriven som en OR av AND-termer, till exempel `X = AB' + CD`, står på
**summa-av-produkter**-form.

Varje sanningstabell kan läsas av direkt som en summa av produkter:
1. Leta upp varje rad där utgången är `1`.
2. Skriv för var och en en AND-term som innehåller samtliga ingångar: direkt om ingången är `1` på
   den raden, primmad om den är `0`.
3. OR:a ihop de termerna.

Till exempel:

| A | B | X |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

Raden `AB = 01` bidrar med `A'B` och raden `AB = 10` med `AB'`, vilket ger `X = A'B + AB'`. Stäm av
mot tabellen: det är `XOR`, så samma nät är en enda `XOR`-grind i stället för två `AND`-grindar, två
`NOT`-grindar och en `OR`.

### Lagarna, som en påminnelse
Du har mött dem förut. De står här för att kursen ska ha en enda notation för dem och för att de
senare appendixen ska kunna hänvisa till dem, inte för att de behöver läras ut:

| Lag | Med OR | Med AND |
|---|---|---|
| Identitet | `A + 0 = A` | `A · 1 = A` |
| Dominans | `A + 1 = 1` | `A · 0 = 0` |
| Idempotens | `A + A = A` | `A · A = A` |
| Komplement | `A + A' = 1` | `A · A' = 0` |
| Absorption | `A + AB = A` | `A(A + B) = A` |
| De Morgan | `(A + B)' = A'B'` | `(AB)' = A' + B'` |

**De Morgan är den lag kursen lutar sig mot**, mindre för minimering än som en regel för hur en
inversion flyttas genom en grind: en `OR` med båda ingångarna inverterade *är* en `NAND`, och en
`AND` med båda ingångarna inverterade *är* en `NOR`. Det är därför en `NAND`-grind kan bygga vad som
helst, vilket [Appendix B](./b_exercises.md) övning 6 låter dig skriva i VHDL, och det kommer
tillbaka varje gång en aktivt låg signal möter logik skriven för aktivt hög. I en kurs där varje
reset och varje knapp är aktivt låg är det ofta.

Glappet mellan en rakt avläst summa av produkter och det minsta nätet är vad ett **Karnaughdiagram**
sluter, och [L02](../../L02/README.md) går igenom ett från början till slut. Inte för att tekniken
är ny för dig, utan för att det är den minimerade ekvationen som skrivs i VHDL, och L08 härleder sin
tillståndsmaskins nästa-tillstånd-logik på precis det sättet.

---

## A.3 Att bygga och simulera en krets i CircuitVerse
[CircuitVerse](https://circuitverse.org/simulator) är en gratis, webbläsarbaserad logiksimulator.
Varje grindnät i den här kursen byggs och testas där för hand innan det skrivs i VHDL:
1. Öppna simulatorn och starta ett nytt projekt.
2. Placera ett **input**-element per insignal och ett **output**-element per utsignal, omdöpta så
   att de matchar dina variabler.
3. Placera de grindar din ekvation kräver, från panelen *Gates*.
4. Koppla ihop nätet en grind i taget, enligt din härledda ekvation. Du ska redan veta exakt vilka
   grindar du behöver innan du öppnar simulatorn, vilket är därför A.2 kommer först.
5. Slå om varje ingång och kontrollera att utgången stämmer med din sanningstabell på **varje** rad.
6. Spara via `Project -> Save Online`, eller `Project -> Download as image/data` för en
   återimporterbar `.cv`-fil.

**Steg 5 är inte valfritt, och ingenting annat gör det åt dig.** Tre regler gör det till en kontroll
snarare än en formalitet:
* **Uttömmande, inte stickprov.** Två ingångar är fyra rader, tre är åtta. Vid de storlekarna finns
  ingen ursäkt för att sampla. För sekvensnäten längre fram blir det här "stega klockan och
  kontrollera vid varje flank", samma disciplin tillämpad på tid.
* **Härled först, simulera sedan.** Rita kretsen och bestäm *sedan* vad den ska göra, så kommer du
  att läsa av dina egna förväntningar ur simuleringen, vilket inte bevisar något.
* **En avvikelse är information.** Den säger att ritningen och ekvationen är oense, och att en av
  dem har fel.

Varje hårdvarubugg du kommer att jaga hittas genom att förutsäga ett beteende och sedan kontrollera
det. Att göra det för hand på en krets med fyra grindar är hur du lär dig göra det på en du inte kan
överblicka på en gång.

När konstruktionen väl är VHDL tar en självkontrollerande testbänk över det jobbet. Varje
genomarbetat exempel och varje övning har en utdelad; du kör dem snarare än skriver dem, vilket
[L02 Appendix C](../../L02/appendix/c_testbenches.md) går igenom.

---

## A.4 Precis så mycket VHDL att du kan läsa och skriva ett grindnät
VHDL beskriver hårdvara, inte en sekvens av instruktioner. Varje sats nedan körs konkurrent och
kontinuerligt, precis som grindarna den beskriver. Språket kommer allteftersom det behövs; det här
avsnittet räcker för ett enkelt kombinatoriskt nät.

Varje VHDL-modul har två delar:
* En **entitet**, vyn utifrån: portarna, och ingenting om vad som händer inuti.
* En **arkitektur**, implementationen bakom den.

Den uppdelningen är ett kontrakt, inte ceremoni. Entiteten är allt en annan konstruktion behöver för
att kunna använda modulen, vilket är det som låter en konstruktion instansiera en annan utan att
läsa den, och som låter dig skriva om en implementation utan att röra det som beror på den. Formen
är en header vid sidan av en källfil, eller ett gränssnitt vid sidan av sin klass; skillnaden är att
VHDL kräver den för varje modul, utan något sätt att hoppa över gränssnittet eller läcka
implementationen genom det.

Ta `or_gate`: ingångarna `a`, `b`, utgången `x`, och `x = a or b`.

```vhdl
entity or_gate is
    port(a, b: in std_logic;
         x   : out std_logic);
end entity;
```

![Entiteten `or_gate`](./images/or_gate_entity.png)

`std_logic` är signaltypen för en enstaka bit. Den är inte inbyggd i VHDL utan kommer från paketet
`std_logic_1164`, vilket är därför varje fil i den här kursen inleds med:

```vhdl
library ieee;
use ieee.std_logic_1164.all;
```

Den har nio värden i stället för två, eftersom verklig hårdvara behöver mer än sant och falskt:
* `'0'` och `'1'`: driven låg och driven hög. De enda två du kommer att skriva i den här kursen.
* `'Z'`: högimpedans, ingenting driver ledningen alls.
* `'U'`: oinitierad, det en signal håller innan något har tilldelat den ett värde.
* `'X'`: okänd, det en simulator visar när två saker driver samma signal och är oense.
* `'-'`, `'W'`, `'L'`, `'H'`: don't-care-värden och svagt drivande värden, sällan skrivna för hand.

Att känna igen de sju du inte kommer att skriva spelar ändå roll: de är hur en simulator talar om
för dig att något är fel. En signal som ligger kvar på `'U'` eller `'X'` är en bugg, inte ett värde.

Arkitekturen fyller i lådan:

```vhdl
architecture behaviour of or_gate is
begin
    x <= a or b;
end architecture;
```

![Arkitekturen `or_gate`](./images/or_gate_arch.png)

Tillsammans utgör de den kompletta modulen:

![Modulen `or_gate`](./images/or_gate_module.png)

`x <= a or b;` är A.2:s booleska algebra nästan ordagrant: VHDL:s `and`, `or`, `not` och `xor`
arbetar direkt på `std_logic`, så varje ekvation du härlett för hand blir VHDL med knappt någon
översättning alls.

Tilldelningen är **konkurrent**. Den körs inte en gång; den gäller kontinuerligt, som en ledning
mellan verkliga grindar.

Nyckelordet `signal` deklarerar en intern ledning inuti en arkitektur, till skillnad från en utifrån
synlig port. Du använder en i övning 7 för att namnge ett mellanresultat i stället för att nästla in
det på plats, och [L02](../../L02/README.md) lutar sig mot samma idé rakt igenom.

---

## A.5 Den kompletta modulen: `or_gate`
A.4:s delar tillsammans blir en komplett, syntetiserbar fil. Det här är hela
[`or_gate.vhd`](../or_gate/or_gate.vhd), och det är en riktig konstruktion som syntetiseras och körs
på DE0-CV.

```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity or_gate is
    port(a, b: in  std_logic;
         x   : out std_logic);
end entity;

architecture behaviour of or_gate is
begin
    x <= a or b;
end architecture;
```

* `library`/`use`-satserna drar in `std_logic`.
* `entity` deklarerar utsidan: två ingångar, en utgång.
* `architecture` implementerar insidan, som en enda konkurrent tilldelning.

Det är den minsta kompletta VHDL-konstruktion som finns, och formen ändras aldrig. Varje modul i den
här kursen, ända upp till tillståndsmaskinerna i [L08](../../L08/README.md), är samma
`library`/`entity`/`architecture`-skelett. Det som växer är arkitekturkroppen, aldrig ramen.

**Att kontrollera ditt arbete.** `or_gate` har en utdelad
[`or_gate_tb.vhd`](../or_gate/or_gate_tb.vhd), som driver alla fyra ingångskombinationerna och
kontrollerar utgången:

```bash
cd lectures/L01/or_gate
ghdl -a --std=93 or_gate.vhd or_gate_tb.vhd
ghdl -e --std=93 or_gate_tb
ghdl -r --std=93 or_gate_tb --assert-level=error --stop-time=10ms
```

Ingen utskrift utöver en avslutande notering betyder att varje kontroll gick igenom. Testbänkar
behandlas ordentligt i [L02 Appendix C](../../L02/appendix/c_testbenches.md); tills vidare, betrakta
de här tre kommandona som sättet du bekräftar att en modul fungerar på.

---

## A.6 Föreläsningens krets: en bromsassistent
Föreläsningen bygger en annan krets än `or_gate`, live, så att du får se samma väg gås två gånger:
en gång här i skrift, och en gång på något du inte redan läst svaret på.

Kravet: **bilen bromsar om föraren bromsar, eller om assistanssystemet bestämmer sig för det.**
Assistanssystemet bestämmer sig för det när endera detektorn ser något, om det inte samtidigt
rapporterar ett fel, i vilket fall det inte anförtros att bromsa alls.

| Port | Riktning | Betydelse |
|---|---|---|
| `driver_brake` | in | Föraren står på bromspedalen. |
| `sensor` | in | Avståndssensorn ser ett hinder. |
| `radar` | in | Radarn ser ett hinder. |
| `error` | in | Assistanssystemet rapporterar ett fel. |
| `engine_brake` | out | Lägg an bromsarna. |

Tre satser avgör tillsammans hela strukturen:
* endera detektorn räcker på egen hand, och ingen av dem väger tyngre än den andra.
* ett fel utlöser inget larm; det *hindrar* assistanssystemet från att kunna bromsa.
* föraren kan alltid bromsa, även när assistanssystemet är trasigt och inte gör någonting.

Den sista är ett säkerhetskrav, och det är den att hålla fast vid när du härleder nätet: pedalen är
inte en ingång till assistanslogiken, den går förbi den. Räkna ut vad som ändras om pedalen i
stället matas genom fellogiken, så har du hittat buggen som strukturen finns till för att förhindra.

### Sanningstabellen
Sexton rader, i den ordning en fyrabitars räknare skulle producera dem. `adas_brake` är ingen port;
den är assistanssystemets eget beslut, visad som en mellankolumn så att du kan se var strukturen
kommer ifrån.

| `driver_brake` | `sensor` | `radar` | `error` | `adas_brake` | `engine_brake` |
|---|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 0 | 1 | 0 | 0 |
| 0 | 0 | 1 | 0 | 1 | 1 |
| 0 | 0 | 1 | 1 | 0 | 0 |
| 0 | 1 | 0 | 0 | 1 | 1 |
| 0 | 1 | 0 | 1 | 0 | 0 |
| 0 | 1 | 1 | 0 | 1 | 1 |
| 0 | 1 | 1 | 1 | 0 | 0 |
| 1 | 0 | 0 | 0 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 | 1 |
| 1 | 0 | 1 | 0 | 1 | 1 |
| 1 | 0 | 1 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 | 1 |
| 1 | 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 1 | 0 | 1 | 1 |
| 1 | 1 | 1 | 1 | 0 | 1 |

Den nedre halvan är genomgående `1`: så snart `driver_brake` är satt ändrar ingenting annat svaret.
Det är hur "åsidosätter allt" ser ut i en tabell.

### Före föreläsningen
Allt ovan är specifikationen. Härledningen, grindnätet och VHDL-koden är det som föreläsningen
bygger live, och det är värt att komma dit med ett eget svar att jämföra mot snarare än ett du redan
läst. Så, utifrån tabellen ovan:
* Läs av en summa-av-produkter-ekvation för `engine_brake` direkt ur den, på samma sätt som A.2
  gjorde.
* Förenkla den för hand. Kravet är tre satser långt, så det minimala nätet är avsevärt mindre än vad
  den radvisa avläsningen ger dig. Räkna ut hur mycket mindre innan du får det berättat för dig.
* Räkna grindarna din förenklade ekvation behöver, och skriv ner antalet.
* Skissa nätet, och avgör vilken enda grind säkerhetsargumentet ovan vilar på.

Ta med de fyra svaren till passet. Att ha fel om något av dem är värt mer än att inte ha gissat,
eftersom du då vet exakt vilket steg du ska granska om när den live-gjorda härledningen når fram
till det. Det är A.3:s "härled först, simulera sedan" tillämpat på en krets du inte byggt ännu, och
det är den vana resten av kursen är byggd på. Efteråt skriver du VHDL-koden själv, i
[Appendix B](./b_exercises.md) övning 7, och en testbänk avgör om dina ekvationer och A.6:s
sanningstabell är överens.

### Varför det finns en testbänk för den
Sexton kombinationer är få nog att kontrollera för hand en gång. Det är inte få nog att kontrollera
varje gång någon redigerar filen, vilket är den situation varje modul i den här kursen befinner sig
i härifrån och framåt.

En **testbänk** är en andra VHDL-fil som gör kontrollen. Den är inte en del av konstruktionen och
når aldrig FPGA:n: den driver ingångarna genom varje fall, räknar ut vad utgången borde ha varit,
jämför och rapporterar. För `adas`, som skrivs vid sidan av den under föreläsningen, är det en loop
över de sexton kombinationerna som återger bromsregeln oberoende.

*Oberoende* är det viktiga ordet. En testbänk som läste sitt förväntade svar ur konstruktionen
skulle stämma med den per konstruktion, även när konstruktionen har fel. Att återge kravet separat
är det som gör det till en kontroll.

Det är därför nästan varje katalog i det här repot har en `_tb.vhd` vid sidan av modulen: det är så
du kan få en modul i handen, ändra den, och inom en sekund veta om du gjort sönder den.
[L02 Appendix C](../../L02/appendix/c_testbenches.md) går igenom hur de körs; du ombeds inte skriva
någon någonstans i den här kursen.

---
