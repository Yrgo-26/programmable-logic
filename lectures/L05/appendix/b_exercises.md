# Appendix B - Övningar

> **Så kontrollerar du ditt arbete.** Varje övning nedan som ber dig skriva en VHDL-modul har en
> självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess katalog
> `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och kör den
> sedan med GHDL - se [Appendix C](../../L02/appendix/c_testbenches.md) för de tre kommandona.
>
> Inget FPGA-kort behövs för någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL:en rätt, och testbänken är hur
> du bekräftar det.

## `variable` kontra `signal`

**1.** Den trasiga `parity_gen`-arkitekturen från
[Appendix A.2](./a_variables_and_hardware.md#a2-variable-processlokal-lagring-som-uppdateras-direkt)
återges nedan:

```vhdl
architecture broken of parity_gen is
signal parity_s: std_logic;
begin
    parity <= parity_s;

    process(bits) is
    begin
        parity_s <= '0';
        for i in bits'range loop
            parity_s <= parity_s xor bits(i);
        end loop;
    end process;
end architecture;
```

Anta att:
* `bits` har intervallet `7 downto 0`.
* `bits = "10110110"`.
* `parity_s` håller `'0'` innan processen börjar.

**a)** Spåra processen för hand.

Notera, för den inledande tilldelningen och för varje loopiteration:
* Det aktuella indexet `i`.
* Värdet på `bits(i)`.
* Värdet som läses från `parity_s`.
* Värdet som schemaläggs för `parity_s`.
* Om den schemalagda tilldelningen överlever fram till att processen suspenderar.

Kom ihåg:
* En signaltilldelning uppdaterar inte signalen omedelbart.
* Tilldelningar till samma signal under ett och samma varv ersätter tidigare schemalagda
  tilldelningar för samma simuleringstidpunkt.

**b)** Bestäm det slutliga värde som tilldelas `parity_s` efter att processen suspenderat.

Sedan:
* Beräkna den korrekta XOR-pariteten hos `"10110110"` för hand.
* Jämför den med resultatet från den trasiga arkitekturen.
* Förklara varför upprepade tilldelningar till signalen inte skapar en ackumulator.

**c)** Spåra den variabelbaserade arkitekturen `behaviour` från föreläsningens fil `parity_gen.vhd`
med samma ingång.

Notera, för varje loopiteration:
* Värdet på `bits(i)`.
* Värdet på `acc` före XOR-operationen.
* Värdet på `acc` omedelbart efter XOR-operationen.

Bekräfta att:
* `acc` behåller varje iterations resultat så att nästa iteration kan använda det.
* Det slutliga värde som tilldelas `parity` är den korrekta XOR-pariteten.

---

**2.** Skriv en entitet med namnet `min_of_two`.

Entiteten ska ha:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `a` | in | `std_logic_vector(3 downto 0)` | Första värdet. |
| `b` | in | `std_logic_vector(3 downto 0)` | Andra värdet. |
| `m` | out | `std_logic_vector(3 downto 0)` | Det minsta av de två. |

Behandla `a` och `b` som teckenlösa fyrabitarsvärden.

Implementera kretsen med en process:
* Ta med `a` och `b` i känslighetslistan.
* Deklarera en processlokal variabel som håller det minsta värdet.
* Jämför `a` och `b` som teckenlösa tal.
* Tilldela variabeln exakt en gång per varv.
* Tilldela variabeln till `m` efter jämförelsen.

Använd faciliteterna i `ieee.numeric_std` när du gör den teckenlösa jämförelsen, enligt
[L02 A.3](../../L02/appendix/a_larger_networks.md#a3-std_logic_vector-mer-än-en-ledning).

Den här övningen kräver ingen loop. Poängen med den är att använda en variabel som tillfällig
processlokal lagring för något *annat* än en ackumulator: A.2:s genomarbetade exempel bygger upp ett
värde över iterationerna i en loop, vilket är det fall en variabel oftast introduceras för, och det
är lätt att gå därifrån och tro att det är det enda de duger till. Här håller variabeln helt enkelt
ett mellanresultat under de få rader som skiljer beräkningen från användningen, vilket är den
vanligare av de två användningarna i verklig kod.

![Modulen `min_of_two`](./images/min_of_two.png)

**Självkontroll:** döp din entitet till `min_of_two`, med portarna `a`, `b` (in) och `m` (out), alla
`std_logic_vector(3 downto 0)`, deklarerade i den ordningen; dess testbänk finns i
[`exercises/min_of_two/`](../exercises/min_of_two).

---

**3.** Skriv en entitet med namnet `ones_count8` som räknar hur många bitar i en 8-bitars ingång som
är ettställda.

Övning 1 lät dig spåra ackumulatorbuggen på papper, och övning 2 använde en variabel som inte var
någon ackumulator alls. Den här är det fall A.2 faktiskt handlar om: ett värde som byggs upp över
iterationerna i en loop. Det är den enda övningen i kursen där du skriver en sådan.

Entiteten ska ha:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `bits` | in | `std_logic_vector(7 downto 0)` | Värdet att räkna över. |
| `ones` | out | `natural range 0 to 8` | Antalet bitar i `bits` som är `'1'`. |

Implementera den med en enda kombinatorisk process:
* Sätt `bits` i känslighetslistan.
* Deklarera en processlokal `variable` för den löpande räkningen, och sätt den till `0` överst i
  varje varv. En variabel behåller sitt värde mellan varv, så en räkning som aldrig nollställs
  fortsätter växa.
* Loopa över `bits'range` och lägg till `1` för varje ettställd bit.
* Tilldela variabeln till `ones` en gång, efter loopen.

Svara sedan, med en mening var:
* Skriv samma sak med en `signal` som ackumulator i stället, kör testbänken, och notera vad den
  rapporterar för ingången `00000010`. Förklara talet du får med schemaläggningsregeln, inte genom
  att gissa.
* Loopen körs åtta gånger. Hur många adderare lägger den här designen på FPGA:n, och hur många
  klockcykler tar det för den att producera ett svar? Om de två svaren överraskar dig, läs om
  [A.2](./a_variables_and_hardware.md#vad-den-loopen-inte-är).
* `ones` är en `natural range 0 to 8` snarare än ett `std_logic_vector(3 downto 0)`. Båda rymmer
  svaret. Vad köper intervallet dig, och vad skulle GHDL göra om din räkning någonsin lämnade det?

![Modulen `ones_count8`](./images/ones_count8.png)

**Självkontroll:** döp din entitet till `ones_count8`, med ingången `bits`
(`std_logic_vector(7 downto 0)`) och utgången `ones` (`natural range 0 to 8`), deklarerade i den
ordningen; dess testbänk finns i [`exercises/ones_count8/`](../exercises/ones_count8) och sveper
igenom alla 256 ingångsvärden.

---

## En modul värd att ha för sig själv

**4.** Skriv dubbelvippsynkroniseraren som en egen modul, med namnet `sync`.

Du har redan byggt den här kretsen. Det är de två första vipporna i
[L04:s `button_sync`](../../L04/appendix/b_exercises.md), skrivna inline där eftersom det vid den
punkten var *idén* som spelade roll: en asynkron ingång behöver två vippor innan något annat får
titta på den. Här bryter du ut de två till en modul, och övningen är inte logiken, som du redan kan,
utan allt runt omkring.

Två saker gör det värt att ta en gång till. Den första är att en naken synkroniserare är vad de
flesta asynkrona ingångar faktiskt behöver: `button_sync` lägger till en flankdetektor eftersom en
knapptryckning är en händelse, men en seriell ledning, en statusflagga från en annan klockdomän,
eller en strömbrytare vars nivå är allt du någonsin läser, behöver de två vipporna och inget mer.
L08:s seriemottagare instansierar precis det här på sin `rx`-pinne. Den andra är att den tar **två
generics**, och en av dem är inte ett tal.

| Generic | Typ | Standardvärde | Betydelse |
|---|---|---|---|
| `SIZE` | `natural range 1 to 15` | `1` | Hur många oberoende signaler som ska synkroniseras, och därmed bredden på båda vektorportarna. |
| `PRESET` | `std_logic` | `'0'` | Värdet som båda stegen antar vid reset. |

och de här portarna:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | 50 MHz systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad** reset. En synkroniserare synkroniserar inte sin egen reset; det gör L04:s `reset_sync`. |
| `async_in` | in | `std_logic_vector(SIZE - 1 downto 0)` | Den asynkrona ingången eller ingångarna, rakt utifrån klockdomänen. |
| `sync_out` | out | `std_logic_vector(SIZE - 1 downto 0)` | Samma signaler, säkra att använda, två stigande flanker senare. Varje bit synkroniseras oberoende. |

**a)** Implementera den:
* Två interna signaler av typen `std_logic_vector(SIZE - 1 downto 0)`, en per steg.
* En process, känslig för `clock` och `reset_s2_n`.
* Vid reset, driv båda stegen till `PRESET`, utanför den klockade grenen.
* Vid en stigande klockflank, skifta `async_in` genom de två stegen.
* Driv `sync_out` från det andra steget med en konkurrent tilldelning.

**b)** `PRESET` är en generic av typen `std_logic`, den första i den här kursen som inte är ett tal,
och den finns eftersom det säkra reset-värdet beror på vad signalen *betyder*. Bara den
instansierande designen vet det. Svara:
* `button_sync` synkroniserar aktivt låga knappar, så den skulle skicka in `'1'`. Vad skulle `'0'`
  påstå om knapparna under de två cyklerna efter varje reset?
* En seriell ledning vilar hög, så L08:s mottagare skickar också in `'1'`. Hur skulle `'0'` se ut
  för en mottagare som håller utkik efter en startbit?
* Varför är *standardvärdet* ändå `'0'` snarare än `'1'`, givet båda dessa, och vad säger det om vem
  som ansvarar för att få det rätt?

**c)** Det här är också en fråga om vad en generic kostar. `SIZE` är `natural range 1 to 15` och
`PRESET` är `std_logic`, och båda är fastlagda innan syntesen körs. Använd A.3:s bild av vad FPGA:n
faktiskt består av och säg hur många vippor en instans med `SIZE = 4` använder, hur många en instans
med `SIZE = 1` använder, och var i den byggda kretsen `PRESET` hamnar. Ingen av de två dyker upp som
logik någonstans; säg vad som hände med dem i stället.

**d)** Verifiera den med dess testbänk. Den instansierar din modul två gånger, en gång en bit bred
med `PRESET = '1'` och en gång tre bitar bred med `PRESET = '0'`, så en design som hårdkodar någon
av de två generics fallerar. Den kontrollerar att `sync_out` följer `async_in` efter **exakt** två
stigande flanker snarare än efter en eller så småningom, att varje bit i en vektor synkroniseras för
sig, och att reset laddar `PRESET` utan att någon klockflank är inblandad.

**Tips:** skriv arkitekturen för `SIZE = 1` i huvudet först, och kontrollera sedan att varje rad
redan är korrekt för en vektor. Aggregatet `(others => PRESET)` och en vanlig vektortilldelning
arbetar båda elementvis, så generaliseringen bör inte kosta någon extra kod.

![Modulen `sync`](./images/sync.png)

**Självkontroll:** döp din entitet till `sync`, med generics `SIZE` (`natural range 1 to 15`,
standardvärde `1`) och `PRESET` (`std_logic`, standardvärde `'0'`), ingångarna `clock`,
`reset_s2_n`, `async_in` (`std_logic_vector(SIZE - 1 downto 0)`) och utgången `sync_out`
(`std_logic_vector(SIZE - 1 downto 0)`), deklarerade i den ordningen; dess testbänk finns i
[`exercises/sync/`](../exercises/sync).

**Spara den här filen.** [L08](../../L08/README.md):s capstone med seriemottagaren instansierar den
på `rx`-pinnen, och ber dig kopiera in den.

---

## Från VHDL till hårdvara
Quartus-flödet demonstreras på ett riktigt DE0-CV-kort under föreläsningarna - först med
bromsassistenten redan i L01 - och finns nedskrivet i
[info/quartus_workflow.md](../../../info/quartus_workflow.md) som referens. Du behöver varken
Quartus eller ett kort själv; övningarna nedan handlar om att förstå vad det flödet gör med den VHDL
du skriver.

**5.** Besvara vart och ett av följande, med hänvisning till
[info/quartus_workflow.md](../../../info/quartus_workflow.md) och till det du såg demonstreras. En
eller två meningar var.

**a)** Ett Quartus-projekt behöver en vald **toppnivåentitet** innan det kompilerar:
* Vad gör verktyget annorlunda med toppnivåentiteten än med någon annan entitet i projektet?
* `min_of_two` från övning 2 och dess testbänk är båda giltig VHDL. Varför kan bara den ena någonsin
  vara toppnivåentitet i ett FPGA-projekt?

**b)** Pinntilldelning kopplar ett portnamn till en fysisk pinne:
* Varför måste pinnarna tilldelas *före* kompileringen snarare än efteråt?
* Vad skulle `m` fysiskt vara kopplad till om du kompilerade `min_of_two` utan att ha tilldelat
  några pinnar alls?

**c)** Syntesen gör om din arkitektur till grindar på chippet:
* L02:s övning `combo_logic` lät dig skriva `x = ab + c'd` två gånger: en gång som ett enda uttryck,
  och en gång med `c'd` namngivet av en intern signal. Vad bör syntesen producera för vardera, och
  varför är ditt svar detsamma för båda?
* Vilken av de två skulle du hellre läsa om sex månader?

**d)** Kompileringen ger varningar såväl som fel:
* Varför är "det kompilerade utan fel" ett mycket svagare påstående om en FPGA-design än "det
  kompilerade utan fel" är om ett C-program?
* Nämn en sorts varning du aldrig skulle ignorera.

---

**6.** `parity_gen` från [Appendix A.2](./a_variables_and_hardware.md#a2-variable-processlokal-lagring-som-uppdateras-direkt)
är föreläsningens genomarbetade exempel, och till det hör en referenstestbänk i
[`../parity_gen/parity_gen_tb.vhd`](../parity_gen/parity_gen_tb.vhd).

**a)** Förutsäg, innan du kör något, `parity` för hand för var och en av de här ingångarna:
* `"00000000"`
* `"10110110"`
* `"11111111"`
* `"10000000"`

**b)** Kör referenstestbänken mot det genomarbetade exemplet och bekräfta dina fyra förutsägelser:

```bash
cd lectures/L05/parity_gen
ghdl -a --std=93 parity_gen.vhd parity_gen_tb.vhd
ghdl -e --std=93 parity_gen_tb
ghdl -r --std=93 parity_gen_tb --assert-level=error --stop-time=10ms
```

**c)** Ta vilken som helst av de ingångarna och vänd exakt en bit, och lämna de andra sju
oförändrade:
* Vad händer med `parity`?
* Förklara varför en ändring av exakt en ingångsbit *alltid* måste invertera XOR-paritetsresultatet,
  vilken bit du än väljer och vilket startvärdet än är.
* Det är den egenskapen som gör en paritetsbit förmögen att upptäcka ett enbitsfel vid överföring.
  Vilken sorts fel missar den, och varför?

---

**7.** En kollega skickar dig den här kombinatoriska avkodaren för granskning. Den kompilerar, och
Quartus rapporterar inga fel.

```vhdl
architecture behaviour of level_decode is
begin
    process(sel) is
    begin
        case sel is
            when "00"   => leds <= "0001";
            when "01"   => leds <= "0010";
            when "10"   => leds <= "0100";
            when others => null;
        end case;
    end process;
end architecture;
```

**a)** Quartus ger `Warning: Inferred latch(es) for signal "leds"`. Förklara med hjälp av
[Appendix A.3](./a_variables_and_hardware.md#a3-vad-fpgan-faktiskt-bygger) vad verktyget byggde
och varför. Vad bad VHDL-koden om som ett kombinatoriskt nät inte kan göra?

**b)** Författarens försvar är att `sel` är två bitar, så `"11"` är det enda värde `when others` kan
matcha, och designen genererar det aldrig. Ge två skilda skäl till att det argumentet inte håller:
* ett om vad `sel` faktiskt kan hålla, från
  [L01 A.4](../../L01/appendix/a_combinational_logic.md#a4-precis-så-mycket-vhdl-att-du-kan-läsa-och-skriva-ett-grindnät).
* ett som skulle gälla även om `sel` verkligen bara kunde vara `"00"`, `"01"` eller `"10"`.

**c)** Åtgärda den, på två olika sätt:
* genom att ändra enbart grenen `when others`.
* genom att lägga till en enda rad *före* `case`-satsen, och lämna varje gren orörd.

Vilken av de två skulle du hellre underhålla, och varför? Den andra skalar till ett `case` med tjugo
grenar; den första gör det inte.

**d)** Det här är en varning, inte ett fel, och designen kommer ofta att verka fungera på kortet.
Varför gör det saken farligare än ett fel snarare än mindre farlig?

---
