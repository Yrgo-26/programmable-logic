# Appendix A - Variabler och hårdvaran under

## A.1 Vad den här föreläsningen handlar om
Varje konstruktion du behöver för att beskriva hårdvara har du redan använt: `entity` och
`architecture` i L01, `std_logic_vector`, `process` och `case` i L02, den klockade processen och
schemaläggningsregeln i L03, subkomponenter och generics i L02 och L04.

Två saker återstår, och de är de två svåraste att lista ut på egen hand:
* Den första är `variable`, den enda konstruktion kursen inte har behövt förrän nu:
  * Den ser ut som en signal och beter sig inte alls som en, och skillnaden är precis den sort som
    ger en design som simulerar trovärdigt och är tyst felaktig.
  * A.2 går igenom fallet där det biter.
* Den andra är vad något av det här faktiskt blir:
  * Sedan L01 har du litat på att syntesverktyget bygger den krets du beskrev. Det gör det, men
    inte av något du skulle känna igen.
  * A.3 öppnar lådan. Det visar sig att en FPGA inte innehåller några grindar alls, vilket är
    skälet till att L02:s Karnaughdiagram köpte dig mindre än de såg ut att göra. Din klocka har en
    hastighetsgräns, och något specifikt sätter den. Och ett `case` med en gren som saknas ger dig
    tyst ett minneselement som ingen bad om.

Inget av avsnitten svarar på "är min logik rätt?" Den frågan har du besvarat sedan L01. De svarar på
de två frågorna efter den: är det här vad jag menade, och kommer det att få plats och gå.

---

## A.2 `variable`: processlokal lagring som uppdateras direkt
En `variable` deklareras inuti en `process`, mellan `process(...)` och `begin`. Den avgörande
skillnaden mot en `signal`: variabeltilldelning använder `:=` och får verkan **omedelbart**, så
redan nästa sats som läser den ser det uppdaterade värdet, precis som en tilldelning i C. Det finns
ingen schemaläggning, ingenting av den vänta-tills-processen-suspenderar-fördröjning som L03 A.6
stavade ut för signaler, och inget "sista tilldelningen vinner".

| | `signal` (`<=`) | `variable` (`:=`) |
|---|---|---|
| Deklareras | I arkitekturens deklarativa del | I processens deklarativa del |
| Synlig från | Var som helst i arkitekturen | Endast inuti sin egen process |
| Uppdateringstillfälle | Schemalagd: tillämpas när processen nästa gång suspenderar | Omedelbar: tillämpas före nästa sats |
| Upprepad tilldelning i ett varv | Bara den sista överlever; tidigare kastas | Var och en får verkan, i tur och ordning |

### Varför det här faktiskt spelar roll: en XOR-paritetsgenerator
En entitet som beräknar XOR-pariteten hos en 8-bitars ingång, `'1'` om `bits` har ett udda antal
ettställda bitar:

```vhdl
entity parity_gen is
    port(bits  : in  std_logic_vector(7 downto 0);
         parity: out std_logic);
end entity;
```

Med bakgrund i mjukvara är den första ingivelsen att ackumulera den löpande XOR-summan i en loop,
med en signal som ackumulator:

```vhdl
-- Don't do this: shown to demonstrate why it doesn't work.
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

Spåra ett varv, med schemaläggningsregeln från
[L03 A.6](../../L03/appendix/a_flip_flops_and_registers.md#a6-den-synkrona-processmallen-i-vhdl):
varje läsning av `parity_s` returnerar det den höll *innan det här varvet började* (kalla det
`old_parity`), och bara den sista tilldelningen överlever.
* `parity_s <= '0';` schemalägger `'0'`. Ännu inte tillämpad.
* `i = 7` (`bits'range` på `(7 downto 0)` går från hög till låg): läser `parity_s`, får
  `old_parity`, eftersom `'0'`:an inte har tillämpats. Schemalägger `old_parity xor bits(7)`, och
  kastar `'0'`:an.
* `i = 6`: läser `parity_s`, återigen `old_parity`. Schemalägger `old_parity xor bits(6)`, och
  kastar den föregående.
* ...och så vidare för varje iteration...
* `i = 0`, den sista satsen i varvet: läser fortfarande `old_parity`, schemalägger
  `old_parity xor bits(0)`, och kastar allt före den.
* Processen suspenderar och `parity_s` blir `old_parity xor bits(0)`, den enda av nio schemalagda
  tilldelningar som överlevde.

Resultatet beror bara på `bits(0)` och på vad `parity_s` råkade hålla sedan tidigare. Sju
iterationer och den inledande `'0'`:an beräknades och slängdes. Det här är inget randfall: det är
vad en signal-som-ackumulator *alltid* gör, eftersom varje iteration läser samma frusna värde och
bara den textuellt sista tilldelningen behålls.

Samma beräkning med en `variable`:

```vhdl
architecture behaviour of parity_gen is
signal parity_s: std_logic;
begin
    parity <= parity_s;

    PARITY_PROCESS: process(bits) is
        variable acc: std_logic;
    begin
        acc := '0';
        for i in bits'range loop
            acc := acc xor bits(i);
        end loop;
        parity_s <= acc;
    end process;
end architecture;
```

Nu tillämpas `acc := '0'` omedelbart; `i = 7` läser `'0'`, XOR:ar in `bits(7)` och uppdaterar `acc`
på en gång; `i = 6` läser det just uppdaterade värdet, och så vidare genom varje iteration. Loopen
slutar med att `acc` håller den sanna XOR:en av alla åtta bitarna, och `parity_s <= acc;`
schemalägger det enda korrekta värdet, den enda tilldelningen till `parity_s` i varvet.

Det här är det genomarbetade exemplet på disk:
[`parity_gen/parity_gen.vhd`](../parity_gen/parity_gen.vhd).

### Vad den loopen inte är
Det är inte åtta steg som hårdvaran utför ett efter ett. Det är här en bakgrund i C vilseleder som
mest, så det är värt att säga rakt ut:
En `for`-loop vars gränser är fastlagda vid elaboreringen **rullas ut** av syntesverktyget. De åtta
iterationerna blir åtta XOR-grindar i en kedja, som alla lägger sig inom en
fortplantningsfördröjning, i samma klockcykel. Det finns ingen räknare för `i`, ingen förgrening,
ingen iteration i tiden. Loopen skriver åtta grindar på tre rader; den gör inte åtta saker i följd.

Det är också därför `acc`, som läser sig som en löpande summa, inte kostar någon lagring alls. Den
behöver aldrig överleva en klockflank: vart och ett av dess värden är bara ledningen mellan två av
de där XOR-grindarna. En `variable` är rätt verktyg just för att den aldrig överlever ett varv.

Detsamma gäller `bits'range`. **Attributet** `'range` ger indexintervallet för `bits`, här
`7 downto 0`, så att loopen täcker varje bit utan att gränserna skrivs två gånger. Det löses upp vid
elaboreringen, som allt annat i loopens huvud, vilket är precis därför verktyget kan rulla ut den.
`for i in 0 to 1 loop` i L03:s `led_toggle.vhd` betyder samma sak: båda bitarna får sina egna
grindar och båda uppdateras i samma cykel.

### Tumregeln
* Använd en `variable` för en tillfällig beräkning som konsumeras helt inom ett varv:
  loopackumulatorer, temporära byten, mellanvärden som lämnas över till en signal på slutet, precis
  som `acc`.
* Använd en `signal` för allt som en annan process eller omvärlden läser, och allt som måste hålla
  sitt värde över skilda varv (en räknare, eller ett skiftregisters lagrade bitar, båda i L06).

En variabel *kan* behålla sitt värde mellan varv genom samma process, och beter sig då som statisk
lokal lagring snarare än en ny lokal variabel varje gång, så det går att bygga tillstånd med en. Men
eftersom dess uppdateringar är omedelbara snarare än schemalagda beter den sig annorlunda än en
signal som används på samma sätt, särskilt för allt som modellerar en kedja av register som stegar
ett steg per klockflank. Om tillstånd genuint behöver bestå och läsas av annan logik, grip efter en
`signal`: semantiken med schemalagd uppdatering är det som får L06:s räknare och skiftregister att
fungera.

---

## A.3 Vad FPGA:n faktiskt bygger

### De två saker FPGA-väven består av
En FPGA är inget oskrivet blad som grindar etsas in i. Den är ett fast rutnät av identiska små
block, tillverkade innan någon skrev din VHDL, och "syntes" är att lista ut hur de ska konfigureras
så att de beter sig som den krets du beskrev. Två av dem spelar roll här:
* En **uppslagstabell**, eller **LUT**: ett litet minne, typiskt fyra till sex ingångar och en
  utgång. Ladda den med sanningstabellen för vilken boolesk funktion som helst av de ingångarna, så
  beräknar den den funktionen. Det är det ärliga svaret på "vad blir en grind på en FPGA": ingenting
  blir en grind. En LUT med fyra ingångar beräknar `a and b`, `a xor b or (c and not d)`, eller
  vilken annan funktion som helst av upp till fyra ingångar till exakt samma kostnad, eftersom det i
  varje fall är samma block som håller en annan tabell.
* En **vippa**: en bit klockad lagring, som sitter bredvid varje LUT.

På DE0-CV:ns Cyclone V är de paketerade tillsammans som en **ALM**, som håller en delbar LUT med sex
ingångar, användbar som en funktion av sex variabler eller två mindre, plus fyra vippor. Det är den
enhet Quartus fitter-rapport räknar, vilket är skälet till att den talar om ALM:ar snarare än
grindar.

Det är nästan hela historien. `register4` blir fyra vippor, `mux_8to1` en handfull LUT:ar, och L08:s
tillståndsmaskin LUT:ar som matar de vippor som håller tillståndet.

Det förklarar också något från L02 som annars skulle se ut som ett brutet löfte:
Kursen lät dig minimera uttryck med Karnaughdiagram för att spara grindar, och nämnde sedan aldrig
besparingen igen. På en FPGA kostar en funktion av fyra variabler en LUT vare sig du minimerade den
eller inte. Minimering spelar fortfarande roll: det är så du förstår en krets, den är precis rätt
för de flöden med diskret logik och ASIC som Karnaughdiagram uppfanns för, och att reducera en
funktion under LUT:ens ingångsbredd är det som hindrar den från att behöva en andra nivå av LUT:ar.
Men på det här kortet köper den oftast ingenting, och det är bättre att veta det än att undra.

### Varför en klocka har en hastighetsgräns
Signaler tar tid på sig genom en LUT och längs ledningarna mellan block. Den
**fortplantningsfördröjningen** är skälet till att en klocka inte kan gå hur snabbt som helst.

Tänk dig den form varje design i den här kursen har, en vippa, lite kombinatorik, ännu en vippa:
* På en stigande flank presenterar den första ett nytt värde, som måste färdas genom varje LUT och
  ledning mellan de två och *lägga sig* innan nästa flank anländer.
* Om det inte har gjort det fångar den andra vippan ett värde som fortfarande ändras, och designen
  gör fel sak tillförlitligt och gåtfullt.

Så klockperioden måste täcka tre saker:
* Den första vippans **clock-to-Q**-fördröjning: tiden mellan flanken och att dess utgång faktiskt
  ändras.
* Den **kombinatoriska fördröjningen** genom LUT:arna och ledningarna mellan de två.
* Den andra vippans **setup-tid**.

Den långsammaste sådana vägen är **kritiska vägen**, och ett genom den summan är **Fmax**.

Quartus beräknar Fmax åt dig, i tidsanalyssteget i
[Quartus-flödet](../../../info/quartus_workflow.md), men bara om du talar om för den vad klockan är.
Det innebär en `.sdc`-villkorsfil med ett `create_clock` på `50 MHz`-ingången. Utan en sådan har
analysatorn ingen period att jämföra något mot, så den rapporterar varje väg som obegränsad och ger
dig ingen Fmax alls. Skilt från det är en design som "missar timingen" en där någon väg visade sig
långsammare än den period du faktiskt deklarerade.

**Inget av det ingår i den här kursen.** Du kommer inte att skriva någon `.sdc`, läsa någon
timingrapport, eller möta en design som missar timingen, eftersom varje design här ryms inom 20 ns
med marginal. Det är värt att veta att steget finns och vad det kräver, så att du känner igen det
första gången en design av dig närmar sig gränsen.

Två följder värda att bära med sig:
* **Djup kombinatorik kostar dig hastighet, inte antalet vippor.** Att kedja ett långt uttryck
  mellan två register förlänger kritiska vägen; att dela upp det så att en del av arbetet sker på en
  cykel och resten på nästa förkortar den. Den avvägningen, fler register mot en snabbare klocka, är
  det enskilt vanligaste greppet i snabb digital konstruktion.
* **`50 MHz` är en budget på 20 ns.** Det är den siffra varje väg i din design tävlar mot, och det
  är gott om tid vid de här hastigheterna.

### Låset du får av misstag
L03 byggde ett D-lås, visade att det var transparent medan det var aktiverat, och lade det sedan åt
sidan till förmån för vippan. Här kommer det tillbaka objudet.

[L02 A.5](../../L02/appendix/a_larger_networks.md#a5-multiplexrar-i-vhdl-process-och-case)
krävde ett `when others` på varje `case`, och gav språkets skäl: ett `case` måste täcka varje värde
av sin selektors typ. Den allmänna regeln bakom det är att en kombinatorisk `process` måste tilldela
sin utgång på *varje* väg genom sig, och det skälet går nu att formulera:
* VHDL kräver att en signal behåller sitt gamla värde om ingenting tilldelar ett nytt.
* Om någon väg genom din process lämnar `x` otilldelad har du sagt att `x` måste *minnas* sitt
  föregående värde på den vägen, och att minnas är inte något ett kombinatoriskt nät kan göra.
* Så verktyget bygger det enda som kan: ett lås, precis det från L03 A.2.

Det är ett **oavsiktligt lås**, och det är nästan aldrig vad någon menade. Det är en varning snarare
än ett fel, designen kommer ofta att verka fungera, och meddelandet är värt att känna igen:

```text
Warning: Inferred latch(es) for signal "x"
```

Åtgärden är aldrig att lägga till ett lås med flit. Den är att tilldela signalen på varje väg,
vilket är regeln du redan följde.

---

## A.4 Blicka framåt
Ingenting i L06 till L08 inför något nytt idiom. Räknare, skiftregister och timers håller alla
tillstånd över klockflanker med hjälp av
[L03:s klockade process](../../L03/appendix/a_flip_flops_and_registers.md#a6-den-synkrona-processmallen-i-vhdl)
och schemaläggningsregeln ovan, och L08:s tillståndsmaskiner lägger bara till en uppräknad typ och
ett `case` på den. Det som ändras är vad tillståndet används till.

Två saker att hålla utkik efter. L06:s `serial_rx8` är den första designen vars korrekthet du inte
kan kontrollera med ögat på en lysdiod, vilket är där de utdelade testbänkarna slutar vara en
formalitet. Och
[L04:s generic](../../L04/appendix/a_metastability_and_synchronization.md#a8-generics-en-modul-flera-storlekar)
sätts i arbete direkt: L07:s `timer` använder en för sitt tickantal, och `walking_led` instansierar
den timern vid sidan av `reset_sync` och `button_sync`, och skriver nästan ingen egen logik.

---
