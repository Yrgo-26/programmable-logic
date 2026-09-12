# Appendix B - Övningar
> **Så kontrollerar du ditt arbete.** Varje övning nedan som ber dig skriva en VHDL-modul har en
> utdelad självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess
> katalog `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och
> kör den sedan med GHDL - se [Appendix C](./c_testbenches.md) för de tre kommandona.
>
> Inget FPGA-kort behövs till någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL-koden rätt, och testbänken är
> hur du bekräftar det.

## Karnaughdiagram
**1.** Härled en minimerad ekvation för `X` ur Karnaughdiagrammet nedan, realisera sedan motsvarande
grindnät och simulera det i CircuitVerse:

| ABC | X |
|-----|---|
| 000 | 1 |
| 001 | 1 |
| 010 | 0 |
| 011 | 0 |
| 100 | 1 |
| 101 | 1 |
| 110 | 0 |
| 111 | 0 |

**Tips:** Lägg `AB` nedåt i raderna i Graykodsordning (`00, 01, 11, 10`) och `C` i sidled i
kolumnerna, precis som i det genomarbetade exemplet i Appendix A.1, innan du börjar gruppera `1`:or.

---

**2.** Härled en minimerad ekvation för `X` ur Karnaughdiagrammet nedan, realisera sedan motsvarande
grindnät och simulera det i CircuitVerse:

| ABCD | X |
|------|---|
| 0000 | 0 |
| 0001 | 1 |
| 0010 | 0 |
| 0011 | 1 |
| 0100 | 0 |
| 0101 | 0 |
| 0110 | 0 |
| 0111 | 0 |
| 1000 | 0 |
| 1001 | 1 |
| 1010 | 0 |
| 1011 | 1 |
| 1100 | 1 |
| 1101 | 0 |
| 1110 | 1 |
| 1111 | 0 |

**Tips:** Med fyra variabler lägger du två av dem (i Graykod) på varje axel, så att du får ett
4x4-rutnät. Grupper kan fortfarande gå runt varje kant av rutnätet, inte bara vänster-höger; kom
ihåg att kontrollera överkant/underkant också.

---

## Kretsar i VHDL
**3.** Ett grindnät har:
* Fyra ingångar, `ABCD`.
* Tre utgångar, `XYZ`.

Det ges av sanningstabellen nedan:

| ABCD | XYZ |
|------|-----|
| 0000 | 001 |
| 0001 | 010 |
| 0010 | 001 |
| 0011 | 011 |
| 0100 | 100 |
| 0101 | 110 |
| 0110 | 100 |
| 0111 | 111 |
| 1000 | 101 |
| 1001 | 110 |
| 1010 | 101 |
| 1011 | 111 |
| 1100 | 000 |
| 1101 | 010 |
| 1110 | 000 |
| 1111 | 011 |

**a)** Behandla `X`, `Y` och `Z` som tre separata funktioner av `ABCD` med en utgång var, och härled
en minimerad ekvation för var och en via ett Karnaughdiagram.
**b)** Realisera det resulterande grindnätet och simulera det i CircuitVerse; stäm av alla tre
utgångarna mot sanningstabellen ovan.
**c)** Implementera konstruktionen i VHDL, i en egen modul med fyra `std_logic`-ingångar och tre
`std_logic`-utgångar ([L01 Appendix A.4](../../L01/appendix/a_combinational_logic.md#a4-precis-så-mycket-vhdl-att-du-kan-läsa-och-skriva-ett-grindnät)
och Appendix A.2 visar mönstret för att göra konkurrenta VHDL-tilldelningar av en härledd ekvation).
**d)** Kör testbänken (se noteringen högst upp i det här appendixet) och bekräfta att alla 16
raderna går igenom.

Om en rad fallerar namnger assertion-meddelandet ingångskombinationen:
* Gå tillbaka till Karnaughdiagrammet för den av `X`, `Y`, `Z` som är fel.
* En enda fel utgång på en enda rad är nästan alltid en felgrupperad `1` i ett diagram.

**Tips:** Två av de tre utgångarna här visar sig bero på bara en eller två av de fyra ingångarna när
de väl minimerats. Anta inte att varje utgång behöver alla fyra.

![Modulen `xyz_logic`](./images/xyz_logic.png)

**Självkontroll:** döp din VHDL-entitet till `xyz_logic`, med portarna `a`, `b`, `c`, `d` (in) och
`x`, `y`, `z` (out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/xyz_logic/`](../exercises/xyz_logic) och kontrollerar alla 16 raderna i sanningstabellen
ovan.

---

## Multiplexrar
**4.** En 4-till-1-multiplexer har:
* Fyra dataingångar, `A`-`D`.
* Två väljarbitar, `S[1:0]`.
* En utgång, `X`.

Låt väljaren namnge sin dataingång direkt: `S[1:0] = "00"` väljer `A`, `"01"` väljer `B`, `"10"`
väljer `C` och `"11"` väljer `D`. Det är den avbildning övning 6 implementerar.

**a)** Skriv ut multiplexerns sanningstabell (fyra rader, en per väljarkombination).
**b)** Härled summa-av-produkter-ekvationen för `X` uttryckt i `A`-`D` och `S[1:0]` (Appendix A.4
gör likadant för 8-till-1-fallet; halvera det här).
**c)** Bygg och simulera nätet i CircuitVerse, och bekräfta att `X` följer varje dataingång i tur
och ordning när du ändrar `S[1:0]`.

Spara ditt svar: övning 6 nedan implementerar precis den här kretsen i VHDL, när A.5 väl har gett
dig de `process`- och `case`-satser den behöver.

---


**5.** [Appendix A.5](./a_larger_networks.md#a5-multiplexrar-i-vhdl-process-och-case) skriver
2:1-multiplexern med en `case`-sats. Skriv samma krets en gång till med en `if`/`else` i stället,
och övertyga dig själv om att de två beskriver identisk hårdvara.

Skriv en entitet med namnet `mux2` med:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `d0` | in | `std_logic` | Dataingång. |
| `d1` | in | `std_logic` | Dataingång. |
| `sel` | in | `std_logic` | Väljare. |
| `x` | out | `std_logic` | Den valda dataingången. |

Väljaren kopplar fram den dataingång vars nummer den namnger:
* `sel = '0'` väljer `d0`.
* `sel = '1'` väljer `d1`.
* Observera att det är omvänt mot `case`-exemplet i
  [Appendix A.5](./a_larger_networks.md#a5-multiplexrar-i-vhdl-process-och-case),
  som väljer sin *andra* ingång `b` vid `'0'`. Vilken ingång ett väljarvärde namnger är en
  konvention, inte en regel, så läs av det ur specifikationen varje gång i stället för att anta.

Implementera multiplexern med en processbaserad arkitektur:
* Ta med `d0`, `d1` och `sel` i känslighetslistan.
* Använd en `if`/`else`-sats på `sel`.
* Tilldela `x` i varje gren.
* Använd inte:
  * En villkorlig konkurrent tilldelning (`x <= d1 when sel = '1' else d0;`).
  * En `with...select`-sats:
    * en konkurrent form av `case` som kursen inte går igenom.
    * nämnd bara för att du inte ska sträcka dig efter den om du mött den någon annanstans.

![Modulen `mux2`](./images/mux2.png)

**Självkontroll:** döp din entitet till `mux2`, med portarna `d0`, `d1`, `sel` (in) och `x` (out),
deklarerade i den ordningen; dess testbänk ligger i [`exercises/mux2/`](../exercises/mux2) och
kontrollerar alla åtta kombinationer av de tre ingångarna.

---

**6.** Utöka övning 5 till en 4:1-multiplexer med namnet `mux4`.

Det här är kretsen du härledde, ritade och simulerade för hand i övning 4 ovan. Härled
`case`-grenarna på nytt själv för fyra ingångar och två väljarbitar i stället för att kopiera
8-till-1-exemplet från A.5.

Entiteten måste ha:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `d0` | in | `std_logic` | Dataingång. |
| `d1` | in | `std_logic` | Dataingång. |
| `d2` | in | `std_logic` | Dataingång. |
| `d3` | in | `std_logic` | Dataingång. |
| `sel` | in | `std_logic_vector(1 downto 0)` | Väljare. |
| `x` | out | `std_logic` | Den valda dataingången. |

Som i övning 5 namnger väljaren sin dataingång direkt:
* `"00"` väljer `d0`.
* `"01"` väljer `d1`.
* `"10"` väljer `d2`.
* `"11"` väljer `d3`.
* Återigen är det den omvända avbildningen mot A.5:s genomarbetade 8-till-1-exempel, där `"000"`
  kopplar fram `inputs(7)`. Härled dina `case`-grenar ur de fyra raderna ovan, inte ur den
  listningen.

Implementera multiplexern med en process:
* Ta med alla dataingångar och `sel` i känslighetslistan.
* Använd en `case`-sats på `sel`, en gren per väljarvärde ovan.
* Ta med en `when others`-gren.
  * Välj ett säkert utgångsvärde för väljaringångar som innehåller värden som `'X'`, `'U'` eller
    `'Z'`.
* Ersätt inte `case`-satsen med en `if`/`elsif`-kedja.

![Modulen `mux4`](./images/mux4.png)

**Självkontroll:** döp din entitet till `mux4`, med portarna `d0`, `d1`, `d2`, `d3`, `sel`
(`std_logic_vector(1 downto 0)`) och `x` (out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/mux4/`](../exercises/mux4) och sveper alla fyra väljarvärdena mot alla sexton
dataingångskombinationerna.

---

## Submoduler och 7-segmentsdisplayer

Övning 7 och 8 bygger en konstruktion i två halvor: en modul som driver en enda 7-segmentsdisplay,
och en toppnivå som använder två kopior av den för att visa en hexadecimal siffra på var och en. Gör
dem i ordning: övning 8 instansierar det du skriver i övning 7.

En 7-segmentsdisplay är sju lysdioder, namngivna `a` till `g`, arrangerade runt en åtta. Tänd rätt
delmängd så får du en siffra. Det här är utseendet, och det är det du behöver för att kunna räkna ut
koderna nedan:

```text
      aaaa
     f    b
     f    b
      gggg
     e    c
     e    c
      dddd
```

Så `1` tänder `b` och `c` (de två till höger), och `7` tänder `a`, `b` och `c`. Att jämföra koderna
som ges för de två siffrorna är ett snabbt sätt att bekräfta att du har utseendet rättvänt innan du
börjar härleda `A` till `F`.

På DE0-CV är displayerna kopplade **aktivt låga**: att driva
ett segment till `'0'` tänder det, och `'1'` släcker det. Det är därför koden för `8`, som tänder
varje segment, är `"0000000"`, och varför en släckt display är `"1111111"`.

Genomgående avbildas `hex(6 downto 0)` på segmenten `g`, `f`, `e`, `d`, `c`, `b`, `a`: bit 6 är `g`
och bit 0 är `a`.

**7.** Skriv en modul med namnet `display` som driver en 7-segmentsdisplay med en hexadecimal
siffra.

Entiteten måste ha:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `number` | in | `std_logic_vector(3 downto 0)` | Värdet som ska visas, `0000` till och med `1111`. |
| `hex` | out | `std_logic_vector(6 downto 0)` | Segmentkoden för det värdet. |

Så att mata `number` värdet `0111` måste lägga koden för `7` på `hex`, och att mata den `1110` måste
lägga koden för `E` på `hex`.

Implementera den med en process:
* Lägg `number` i känslighetslistan.
* Använd en `case`-sats på `number`, en gren per värde.
* Ta med en `when others`-gren, och släck displayen i den.

Du får koderna för `0` till `9`. Räkna ut `A` till `F` själv, utifrån segmentlayouten ovan:

```vhdl
constant DISPLAY_0  : std_logic_vector(6 downto 0) := "1000000";
constant DISPLAY_1  : std_logic_vector(6 downto 0) := "1111001";
constant DISPLAY_2  : std_logic_vector(6 downto 0) := "0100100";
constant DISPLAY_3  : std_logic_vector(6 downto 0) := "0110000";
constant DISPLAY_4  : std_logic_vector(6 downto 0) := "0011001";
constant DISPLAY_5  : std_logic_vector(6 downto 0) := "0010010";
constant DISPLAY_6  : std_logic_vector(6 downto 0) := "0000010";
constant DISPLAY_7  : std_logic_vector(6 downto 0) := "1111000";
constant DISPLAY_8  : std_logic_vector(6 downto 0) := "0000000";
constant DISPLAY_9  : std_logic_vector(6 downto 0) := "0010000";
-- Todo: add DISPLAY_A through DISPLAY_F here.
constant DISPLAY_OFF: std_logic_vector(6 downto 0) := "1111111";
```

Två av de sex är gemener på en 7-segmentsdisplay, eftersom deras versalformer skulle vara omöjliga
att skilja från en siffra: `b` skulle läsas som `8` och `d` skulle läsas som `0`. `A`, `C`, `E` och
`F` är versaler.

Alla sexton koderna sitter också i `display_tb.vhd`, eftersom en självkontrollerande testbänk inte
kan kontrollera en utgång utan att veta vad den borde vara. Så det här är inget pussel du kan bli
utelåst från. Härled de sex ändå: det tar ett par minuter med segmentdiagrammet, och att läsa av dem
ur testbänken lär dig ingenting som `case`-satsen inte gör. Jobbet i den här övningen är
`case`-satsen med sexton grenar, inte uppslagstabellen.

![Modulen `display`](./images/display.png)

**Självkontroll:** döp din entitet till `display`, med portarna `number`
(`std_logic_vector(3 downto 0)`) och `hex` (out, `std_logic_vector(6 downto 0)`), deklarerade i den
ordningen; dess testbänk ligger i [`exercises/display/`](../exercises/display) och kontrollerar alla
sexton värdena mot hela kodtabellen, och namnger siffran och båda koderna när en är fel.

---

**8.** Skriv en modul med namnet `hex_display` som visar ett tvåsiffrigt hexadecimalt tal på två
displayer, med två instanser av din `display` från övning 7.

Entiteten måste ha:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `input` | in | `std_logic_vector(7 downto 0)` | Åtta strömbrytare: de fyra översta är den vänstra siffran, de fyra nedersta den högra. |
| `hex1` | out | `std_logic_vector(6 downto 0)` | Segmentkod för den vänstra siffran. |
| `hex0` | out | `std_logic_vector(6 downto 0)` | Segmentkod för den högra siffran. |

När den fungerar:
* dyker talet på `input(7 downto 4)` upp på `hex1`.
* dyker talet på `input(3 downto 0)` upp på `hex0`.

Bygg den med submoduler, enligt
[Appendix A.6](./a_larger_networks.md#a6-att-bygga-en-design-av-submoduler):
* Skapa två instanser av `display`, med etiketterna `display1` och `display0`.
* Koppla `input(7 downto 4)` och `hex1` till `display1`.
* Koppla `input(3 downto 0)` och `hex0` till `display0`.
* Använd positionell `port map`, som överallt annars i den här kursen.
* Skriv ingen egen logik i `hex_display`. Om du kommer på dig själv med att skriva en `case`-sats
  här duplicerar du övning 7 i stället för att återanvända den.

Kopiera in din `display.vhd` från övning 7 i övningskatalogen, eftersom `hex_display` inte kan
analyseras utan den. Det här är kursens första konstruktion byggd av mer än en fil, så namnge
`display.vhd` först, före den fil som instansierar den:

```bash
ghdl -a --std=93 display.vhd hex_display.vhd hex_display_tb.vhd
ghdl -e --std=93 hex_display_tb
ghdl -r --std=93 hex_display_tb --assert-level=error --stop-time=10ms
```

[Appendix C.4b](./c_testbenches.md#c4b-när-konstruktionen-behöver-mer-än-en-fil) förklarar varför
ordningen spelar roll.

![Modulen `hex_display`](./images/hex_display.png)

**Självkontroll:** döp din entitet till `hex_display`, med portarna `input`
(`std_logic_vector(7 downto 0)`), `hex1` (out) och `hex0` (out, båda
`std_logic_vector(6 downto 0)`), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/hex_display/`](../exercises/hex_display) och sveper alla 256 ingångsvärdena, och
kontrollerar varje halva oberoende så att en konstruktion som kastar om de två siffrorna fångas i
stället för att gå igenom på de värden där båda halvorna råkar stämma överens.

---

**9. Om du har tid.** Realisera en siffra som ett grindnät, så som L01 och A.1 lät dig göra:
* Ta de fyra ingångarna och ett segment, säg `a`, och härled den booleska ekvationen för det ur
  sanningstabellen med 16 rader. Ett Karnaughdiagram är värt att använda här: de flesta segment
  minimeras rejält.
* Upprepa för så många av de sex återstående segmenten som du har tålamod med, och bygg resultatet
  i CircuitVerse.
* Kopiera sedan hela grindnätet för att driva en andra display.

Den kopian är poängen med övningen. Att duplicera ett block grindar är precis vad det gjorde att
instansiera `display` en andra gång i övning 8, och det är värt att ha gjort en gång för hand för
att se vad den enda raden VHDL står för.

---

## Att namnge ett mellanresultat
**10.** Skriv en entitet med namnet `combo_logic` som implementerar den booleska funktionen:

```math
x = ab + c'd
```

[Appendix A.2](./a_larger_networks.md#a2-att-översätta-karnaughdiagrammets-nät-till-vhdl) hävdade att
det inte kostar något och ger läsbarhet att namnge ett deluttryck med en intern signal. Den här
övningen är där du bekräftar det snarare än tar det på tro: du skriver funktionen två gånger, en
gång som ett enda uttryck och en gång med termen `c'd` utbruten i en intern signal med namnet `y`.

En signal deklarerad inuti en arkitektur är en ledning. Den är ingen variabel, den lagrar ingenting,
och att namnge ett deluttryck med en sådan lägger varken till en grind, en fördröjning eller en
vippa i kretsen. Den ger bara en del av nätet ett namn, så att du, när du läser det senare, kan se
vad den delen är till för. Båda arkitekturerna nedan syntetiseras till samma grindar, och den
utdelade testbänken går igenom mot vilken som helst av dem.

Entiteten måste ha:

| Port | Riktning | Typ |
|---|---|---|
| `a` | in | `std_logic` |
| `b` | in | `std_logic` |
| `c` | in | `std_logic` |
| `d` | in | `std_logic` |
| `x` | out | `std_logic` |

**a)** Implementera hela funktionen med en enda konkurrent signaltilldelning:
* Deklarera inga interna signaler.
* Översätt varje boolesk operation till motsvarande VHDL-operator.

**b)** Skriv om arkitekturen med en intern signal med namnet `y`:
* Använd `y` för att representera termen:

```math
c'd
```

* Tilldela `x` det slutliga uttrycket.
* Det här är samma form som `gate_network` i A.2, som namnger sin `AND`-term `ab`.

Bekräfta att de två arkitekturerna beskriver samma krets.

**Tips:** Två beskrivningar representerar samma kombinatoriska krets när de producerar samma utgång
för varje möjlig ingångskombination.

Med fyra ingångar:
* Det finns 16 möjliga ingångskombinationer.
* Skriv den fullständiga sanningstabellen.
* Verifiera att båda arkitekturerna producerar samma värde på `x` på varje rad.

![Modulen `combo_logic`](./images/combo_logic.png)

**Självkontroll:** döp din entitet till `combo_logic`, med portarna `a`, `b`, `c`, `d` (in) och `x`
(out), deklarerade i den ordningen; dess testbänk ligger i
[`exercises/combo_logic/`](../exercises/combo_logic) och kontrollerar alla 16 raderna. Den går
igenom mot vilken som helst av arkitekturerna, vilket är poängen med jämförelsen ovan.

---
