# Appendix B - Övningar
> **Så kontrollerar du ditt arbete.** Varje övning nedan som ber dig skriva en VHDL-modul har en
> utdelad självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess
> katalog `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och
> kör den sedan med GHDL - se [Appendix C](../../L02/appendix/c_testbenches.md) för de tre
> kommandona.
>
> Inget FPGA-kort behövs till någon övning. Stegen med Quartus-syntes och kortprogrammering
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL-koden rätt, och testbänken är
> hur du bekräftar det.

## Metastabilitetsbegrepp
**1.** Förklara metastabilitet med egna ord.
Beskriv i din förklaring:
* Vad som händer inuti en D-vippa när dess ingång ändras för nära den aktiva klockflanken.
* Varför vippans utgång tillfälligt kan bli kvar mellan en giltig logisk `0` och logisk `1`.
* Varför utgången kan ta en oförutsägbar tid på sig att stabilisera sig.
* Varför två grindar nedströms kan tolka den ostabiliserade utgången olika:
  * Den ena grinden kan tolka den som `0`.
  * Den andra grinden kan tolka den som `1`.

Förklara varför den oenigheten kan få olika delar av en digital krets att hamna i inkonsistenta
tillstånd.

---

**2.** Setup-tid och hold-tid definierar ett fönster kring den aktiva klockflanken under vilket en
vippas ingång måste förbli stabil.

Förklara:
* Varför en synkront genererad signal normalt kan konstrueras så att den uppfyller de här
  tidskraven.
* Varför en asynkron ingång, till exempel en mekanisk tryckknapp, inte har någon fast relation till
  systemklockan.
* Varför en asynkron ingång därför kan ändras under setup- och hold-fönstret oavsett hur den
  omgivande synkrona logiken är konstruerad.

Dra slutsatsen varför metastabilitetsrisken från en asynkron ingång måste hanteras snarare än helt
enkelt undvikas.

---

## Att konstruera en synkroniserare
**3.** Rita en dubbelvippsynkroniserare för en asynkron ingång.

Kretsen ska innehålla:
* En asynkron ingång.
* Två D-vippor kopplade i serie.
* En gemensam systemklocka.
* En synkroniserad utgång tagen från den andra vippan.

Förklara med egna ord:
* Varför den första vippan är direkt exponerad för den asynkrona ingången.
* Varför den första vippan kan bli metastabil.
* Hur intervallet mellan den första och den andra klockflanken ger det första steget tid att
  stabilisera sig.
* Varför den andra vippans utgång har en mycket lägre sannolikhet att vara metastabil.
* Varför det är det andra steget, och inte det första, som resten av designen ska använda.

En synkroniserare gör inte sannolikheten för metastabilitet exakt noll.
Förklara varför den ändå sänker risken till en acceptabelt låg nivå i de flesta designer.

**Tips:** Fundera på hur mycket stabiliseringstid den första vippan får innan dess värde samplas av
den andra vippan.

---

**4.** En kollega föreslår att använda tre synkroniserarvippor på varje asynkron ingång i en långsam
design som klockas i några megahertz, bara för säkerhets skull.

Ett tredje steg köper ytterligare en klockperiod för ett metastabilt värde att stabilisera sig på,
och kostar ytterligare en klockcykels latens på varje synkroniserad ingång. Vid några megahertz är
den extra klockperioden en enorm tid räknat i metastabilitetstermer, vilket är precis därför
förslaget låter förnuftigt, och också därför det redan kan vara onödigt.

**a)** Resonera igenom avvägningen åt båda hållen. Under vilka omständigheter faller den ut till det
tredje stegets fördel, och under vilka omständigheter räcker det andra steget redan? Ditt svar måste
hänga på något annat än klockfrekvensen, eftersom frekvensen ensam inte avgör saken: säg vad det
hänger på i stället.

**b)** A.4 kom fram till MTBF utifrån den stabiliseringstid som finns per steg. Utan att göra om den
räkningen, säg åt vilket håll var och en av de här faktorerna drar beslutet, och varför:
* Hur ofta den asynkrona ingången faktiskt ändras.
* Metastabilitetsegenskaperna hos den FPGA-familj du riktar in dig på.
* Vad ett synkroniseringsfel skulle kosta om det inträffade.

**c)** Ge din rekommendation för en vanlig långsam design av det slag som förekommer i den här
kursen. Beskriv sedan en design, verklig eller påhittad, där du i stället skulle argumentera för det
tredje steget, och säg vilken av faktorerna i **b)** som gör jobbet i det fallet.

> **Kontrollera att ditt svar täcker** de två saker ett tredje steg ger, ytterligare en klockperiods
> stabiliseringstid och en lägre sannolikhet att ett ostabiliserat värde når den funktionella
> logiken, och de två det kostar, ytterligare en cykels latens och ytterligare vippor. Om ditt svar
> på **a)** vilar på klockfrekvensen snarare än på den erforderliga medeltiden mellan fel, läs A.4
> en gång till innan du går vidare.

---

**5.** Förklara resetmönstret **aktivera asynkront, släpp synkront** som används i
`reset_sync.vhd`.

Se [Appendix A.5](./a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront).

Beskriv de två delarna var för sig:
* Asynkron aktivering:
  * Resetten får verkan omedelbart.
  * Den väntar inte på en klockflank.
* Synkront släpp:
  * Resetten tas bort bara vid en aktiv klockflank.
  * All berörd logik lämnar reset i en kontrollerad relation till klockan.

Förklara:
* Varför omedelbar aktivering av reset kan vara viktig när:
  * Klockan är stoppad.
  * Klockan är instabil.
  * Systemet måste gå in i sitt resettillstånd utan fördröjning.
* Varför ett släpp av en asynkron reset nära en klockflank kan bryta mot en vippas tidskrav för
  recovery eller removal.
* Varför synkronisering av släppet hindrar olika vippor från att lämna reset under olika
  klockcykler.

---

## Att bygga kretsen
**6.** Bygg kretsen `led_toggle_sync` från
[Appendix A.9](./a_metastability_and_synchronization.md#a9-genomarbetat-exempel-led_toggle_sync)
för hand i CircuitVerse.

**a)** Lägg till de yttre portarna:
* Ingångar:
  * `clock`
  * `reset_n`
    * Asynkron.
    * Aktiv låg.
  * `button_n`
    * Aktiv låg.
* Utgång:
  * `led`

**b)** Bygg tvåvippsresetsynkroniseraren:
* Koppla de två vipporna i serie.
* Aktivera båda stegen asynkront med den råa `reset_n`-ingången.
* Låt resetten fortplanta sig ut ur kedjan synkront.
* Använd den synkroniserade resetutgången, `reset_s2_n`, i hela resten av kretsen.
* Använd inte den råa `reset_n`-ingången direkt utanför resetsynkroniseraren.

**c)** Bygg trevippsknappsynkroniseraren och flankdetektorn:
* Använd de två första vipporna som dubbelvippsynkroniserare.
* Använd den tredje vippan för att lagra det föregående synkroniserade knappvärdet.
* Jämför det nuvarande och det föregående synkroniserade värdet.
* Detektera ett knapptryck när:
  * Det nuvarande synkroniserade, aktivt låga knappvärdet är `0`.
  * Det föregående synkroniserade värdet är `1`.
* Använd en AND-grind med det nuvarande värdet inverterat för att generera `button_edge_s2`.

Sambandet för fallande flank hos den aktivt låga knappen är:

```math
button\_edge\_s2 = previous \cdot current'
```

**d)** Bygg växlingslogiken för lysdioden:
* Lägg till en vippa som lagrar `led_s`.
* Resetta `led_s` med `reset_s2_n`.
* Växla `led_s` bara när `button_edge_s2 = 1`.
* Koppla utgången `led` till `led_s`.

**e)** Simulera hela designen:
* Sätt klockperioden till `1000 ms`.
* Aktivera och släpp `reset_n`.
* Tryck ned och släpp `button_n`.
* Observera de synkroniserade knappstegen.
* Observera `button_edge_s2`.
* Observera `led_s`.

Avgör:
* Om lysdioden växlar vid den första klockflanken efter det fysiska knapptrycket.
* Hur många klockcykler som krävs för att knappvärdet ska fortplanta sig genom synkroniseraren och
  flankdetektorn.
* Om den observerade latensen stämmer med det beteende Appendix A förutsäger.

---

## Studsfiltrering och tajming
**7.** Du har nu byggt och betraktat kretsen, så det här är en fråga om vad du såg.

Trevippskedjan i övning 6 gör tre jobb på en gång:
* Minskar risken för metastabilitet.
* Lagrar det föregående synkroniserade knappvärdet.
* Detekterar ett knapptryck.

Förklara varför den **inte** i sig garanterar att knappen är studsfiltrerad.

**a)** Skilj på de tre saker som är lätta att blanda ihop:
* Synkronisering:
  * Gör om en asynkron ingång till en signal som går att använda i klockdomänen.
* Flankdetektering:
  * Genererar en puls när den samplade signalen ändras.
* Studsfiltrering:
  * Hindrar flera fysiska övergångar från att tolkas som flera separata tryck.

Vilka två av dessa gör din krets faktiskt?

**b)** I din simulering gav ett tryck en enda ren växling. Det är ett starkare påstående än det ser
ut: det håller bara under ett särskilt villkor om var studsen hamnade i förhållande till
klockflankerna. Formulera det villkoret exakt, i termer av vad din krets samplade och vad den därmed
såg.

Förklara sedan varför det villkoret är en tillfällighet som beror på din klockperiod snarare än en
egenskap hos din krets. Var konkret med vilken av de två, studsen eller samplingen, din design
faktiskt styr.

**c)** Din simulering kördes med klockperioden `1000 ms`; FPGA:n går i `50 MHz`. En tryckknapps
kontakter studsar typiskt i storleksordningen 1 ms. Räkna ut konsekvenserna själv:
* Hur många gånger samplar en klocka med perioden `1000 ms` knappen under den millisekunden av
  studs?
* Hur många gånger samplar en klocka på `50 MHz` den?
* Varje samplad övergång ser ut som en ny flank för din flankdetektor. Förutsäg utifrån de två talen
  vad lysdioden gör på kortet vid ett enda fysiskt tryck, och säg varför exakt samma krets uppförde
  sig oklanderligt i CircuitVerse.

**d)** Beskriv en åtgärd av vardera slaget:
* En hårdvaruåtgärd:
  * till exempel ett RC-lågpassfilter följt av en Schmitt-triggeringång.
* En rent digital åtgärd:
  * till exempel att kräva att den synkroniserade signalen håller en ny nivå under ett visst minsta
    antal klockcykler innan den accepteras.
  * eller en räknare som ignorerar ytterligare övergångar under ett fast intervall efter ett tryck -
    vilket är vad [L07](../../L07/README.md):s timer skulle ge dig.

**e)** Förklara varför dubbelvippsynkroniseraren måste behållas även när en studsfiltreringsmetod
lagts till. Vilket problem löser inte studsfiltreringen?

---

## Synkroniserarna som egna moduler
Det genomarbetade exemplet lägger varje synkroniserare i en egen modul, så att varje senare design
instansierar samma två filer i stället för att härleda dem på nytt. Det är därför både L07:s
`walking_led` och L08:s `fsm_led` ber dig kopiera in de här två, och därför L08:s
`seq_detect_mealy`, som inte har någon knapp, tar resetsynkroniseraren ensam och lämnar den andra
därhän ([Appendix A.9](./a_metastability_and_synchronization.md#a9-genomarbetat-exempel-led_toggle_sync)).

De två följande övningarna är du som skriver de modulerna. Appendix A.5 och A.6 ger dig logiken; vad
de inte ger dig är entiteten runt den, och, för den andra, steget från en enda knapp till en vektor
av dem. Skriv varje modul själv innan du öppnar det genomarbetade exemplets kopia, och jämför sedan.
Övning 10 sätter därefter ihop båda till en fungerande design.

---

**8.** Skriv resetsynkroniseraren som en modul med namnet `reset_sync`.

Entiteten har:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | 50 MHz systemklocka. |
| `reset_n` | in | `std_logic` | Aktiv låg asynkron reset, rakt från omvärlden. |
| `reset_s2_n` | out | `std_logic` | Aktiv låg synkroniserad reset, säker för resten av designen att använda. Går låg i samma ögonblick som `reset_n` gör det, utan att någon klockflank är inblandad, och återgår till hög två stigande flanker efter att `reset_n` gjort det. |

**a)** Implementera **aktivera asynkront, släpp synkront**
([Appendix A.5](./a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront)):
* En intern signal för det första steget, plus utgången för det andra.
* En process, känslig för både `clock` och `reset_n`.
* Vid `reset_n = '0'`, driv båda stegen låga, utanför den klockade grenen.
* Vid en stigande klockflank, skifta in en konstant `'1'` genom de två stegen.

**b)** Värdet som tvingas fram vid reset och värdet som skiftas in på klockan är varandras
motsatser, `'0'` och `'1'`. Förklara i en mening varför det inte är någon motsägelse, utifrån vad
respektive gren är till för.

**c)** Verifiera designen med dess testbänk (se noteringen högst upp i det här appendixet). Den
kontrollerar mönstrets båda halvor var för sig: att en låg `reset_n` drar `reset_s2_n` låg utan
någon klockflank däremellan, och att ett släpp av `reset_n` lämnar `reset_s2_n` låg tills två
stigande flanker har passerat.

**d)** Svara i löpande text:
* Utgången heter `reset_s2_n` snarare än `reset_n_sync`. Vad säger `s2`, och vad skulle behöva
  ändras i den här modulen för att det namnet skulle bli fel?
* Varje annan modul i den här kursen tar `reset_s2_n` som sin reset. Den här tar den råa `reset_n`.
  Varför måste exakt en modul i en design vara undantaget?

**Tips:** släppet är den intressanta halvan. Vid reset bryr sig processen inte om klockan alls, så
båda stegen går låga tillsammans; på klockan bryr den sig inte om `reset_n`, så `'1'`:an behöver en
flank per steg för att nå utgången. Två flankers latens vid släpp är priset för hela mönstret.

![Modul `reset_sync`](./images/reset_sync.png)

**Självkontroll:** döp din entitet till `reset_sync`, med portarna `clock`, `reset_n` (in) och
`reset_s2_n` (out), deklarerade i den ordningen; dess testbänk finns i
[`exercises/reset_sync/`](../exercises/reset_sync).

---

**9.** Skriv knappsynkroniseraren och flankdetektorn som en modul med namnet `button_sync`.

Övning 10 hanterar två knappar genom att skriva en tvåbitars synkroniserare. Den här är samma krets
med bredden lämnad öppen: en generic avgör hur många knappar den betjänar, så att `led_toggle_sync`
kan använda den för en knapp och `fsm_led` för två utan att någondera filen behöver ändras. Se
[Appendix A.8](./a_metastability_and_synchronization.md#a8-generics-en-modul-flera-storlekar) för
syntaxen och för varför den här modulen har en generic där `reset_sync` inte har någon.

Entiteten har en generic:

| Generic | Typ | Standardvärde | Beskrivning |
|---|---|---|---|
| `COUNT` | `natural range 1 to 3` | `1` | Antalet knappar, och därmed bredden på båda vektorportarna. |

och de här portarna:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | 50 MHz systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad** reset. Den här modulen synkroniserar inte sin egen reset; det gjorde modulen i övning 8. |
| `button_n` | in | `std_logic_vector(COUNT - 1 downto 0)` | Aktivt låga asynkrona tryckknappar. |
| `button_edge_s2` | out | `std_logic_vector(COUNT - 1 downto 0)` | En encykelspuls vid varje knapps fallande flank, två klockflanker efter trycket. Varje bit är oberoende av alla andra. |

**a)** Bygg trestegskedjan från
[Appendix A.6](./a_metastability_and_synchronization.md#a6-att-återanvända-kedjan-för-flankdetektering---och-i-förbigående-studsfiltrering),
nu över vektorer i stället för enskilda bitar:
* Tre interna `std_logic_vector(COUNT - 1 downto 0)`-signaler, en per steg.
* Steg 1 och 2 är dubbelvippsynkroniseraren; steg 3 lagrar det föregående värdet av steg 2.
* Vid reset, sätt alla tre stegen till `(others => '1')`, inte `(others => '0')`.
* Härled utgången med en enda konkurrent tilldelning, och lägg märke till att samma uttryck fungerar
  oförändrat på vektorer som på bitar.

**Håll den här i minnet.** De två första vipporna är en synkroniserare i sin helhet och ingenting
annat, och [L05 övning 4](../../L05/appendix/b_exercises.md) låter dig bryta ut dem igen som en egen
modul, generisk både i bredd och i det värde de resettar till. Att skriva dem inline här först är
vad som gör den övningen till en befästning i stället för en ny idé.

**b)** Förklara varför resetvärdet är enbart ettor. Enbart ettor betyder "släppt", eftersom
knapparna är aktivt låga, så en reset till enbart nollor startar kedjan med påståendet att varje
knapp redan hålls nedtryckt. Följ vad det kostar:
* Med knapparna släppta och en reset till enbart nollor, ger modulen ifrån sig en falsk puls när det
  släppta tillståndet fortplantar sig genom de tre stegen? Gå igenom utgångsuttrycket flank för
  flank innan du svarar, i stället för att gissa.
* Nu fallet som faktiskt går sönder. En användare håller en knapp nedtryckt i det ögonblick resetten
  släpps. Vad rapporterar modulen med en reset till enbart ettor, och vad rapporterar den med enbart
  nollor? Vilket av de två är det beteende du vill ha, och varför?

**c)** Verifiera designen med dess testbänk. Den instansierar din modul **två gånger**, en gång med
`COUNT = 1` och en gång med `COUNT = 2`, och kontrollerar att ett tryck ger exakt en encykelspuls,
att en nedhållen knapp inte ger några ytterligare pulser, att ett släpp inte ger någon alls, och att
ett tryck på den ena knappen i ett par aldrig pulsar den andra.

**d)** Svara i löpande text:
* `COUNT` är begränsad till `1 to 3` snarare än lämnad som en obegränsad `natural`. Vad köper den
  begränsningen, givet att ingenting i arkitekturen beror på den övre gränsen?
* Den här modulen är medvetet inte hopslagen med övning 8:s, trots att en design som har en knapp
  alltid behöver båda. Ange den design som motiverar uppdelningen, och säg vad den hade behövt göra
  i stället.

**Tips:** skriv arkitekturen för `COUNT = 1` i huvudet först, och kontrollera sedan att varje rad du
skrev redan är korrekt för en vektor. `and`, `not` och aggregatet `(others => '1')` fungerar alla
elementvis, så generaliseringen ska inte kosta dig någon extra kod alls. Gör den det är det värt en
extra titt.

![Modul `button_sync`](./images/button_sync.png)

**Självkontroll:** döp din entitet till `button_sync`, med genericen `COUNT` (`natural range 1 to
3`, standardvärde `1`), ingångarna `clock`, `reset_s2_n`, `button_n`
(`std_logic_vector(COUNT - 1 downto 0)`) och utgången `button_edge_s2`
(`std_logic_vector(COUNT - 1 downto 0)`), deklarerade i den ordningen; dess testbänk finns i
[`exercises/button_sync/`](../exercises/button_sync).

---

## Att sätta ihop dem till en design
**10.** Gör nu L03:s `led_toggle` metastabilitetssäker, i VHDL, som en ny modul med namnet
`led_toggle_sync2`.

L03:s `led_toggle` växlade två lysdioder från två tryckknappar, men matade in deras råa, asynkrona
signaler rakt i flankdetektorn - logiskt korrekt, men osäkert på riktig hårdvara (L03:s eget avsnitt
"Nästa föreläsning" flaggade för precis det här). Här bygger du om den med varje asynkron ingång
skyddad av den här föreläsningens dubbelvippsynkroniserare.

Entiteten har:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | 50 MHz systemklocka. |
| `reset_n` | in | `std_logic` | Aktiv låg asynkron reset. |
| `button_n` | in | `std_logic_vector(1 downto 0)` | Två aktivt låga asynkrona tryckknappar. |
| `led` | out | `std_logic_vector(1 downto 0)` | Två lysdioder; `led(i)` växlar en gång per tryck på `button_n(i)`. |

**a)** Synkronisera varje asynkron ingång:
* Tillämpa tvåvippsresetsynkroniseraren från Appendix A.5 (aktivera asynkront, släpp synkront).
* Ge knapparna en dubbelvippsynkroniserare plus ett tredje steg för flankdetektering, som i
  Appendix A.6 - nu över en `std_logic_vector(1 downto 0)`, så att båda knapparna synkroniseras
  parallellt.
* Låt aldrig den råa `reset_n` eller `button_n` nå växlingslogiken; använd bara den synkroniserade
  resetten och flankpulserna per knapp.

**Tips:** du kan lägga synkroniseraren inline, eller bryta ut den till en subkomponent som tar en
tvåbitars `button_n`, med instansieringssyntaxen från
[L02 A.6](../../L02/appendix/a_larger_networks.md#a6-att-bygga-en-design-av-submoduler). Att lägga
den inline är den kortare vägen, och då är bygget en enda fil:

```bash
ghdl -a --std=93 led_toggle_sync2.vhd led_toggle_sync2_tb.vhd
```

Om du i stället bryter ut den, kopiera in de `reset_sync.vhd` och `button_sync.vhd` du skrev till
övning 8 och 9 (och instansiera `button_sync` med `COUNT = 2`), och namnge dem först på raden
`ghdl -a`, före din egen modul, så att GHDL ser dem före den fil som instansierar dem:

```bash
ghdl -a --std=93 reset_sync.vhd button_sync.vhd \
                 led_toggle_sync2.vhd led_toggle_sync2_tb.vhd
```

Se [Appendix C.4b](../../L02/appendix/c_testbenches.md#c4b-när-konstruktionen-behöver-mer-än-en-fil).
Ingen av modulerna delas ut någonstans i repot, eftersom att skriva dem är övning 8 och 9. Om dina
inte fungerar än, gå tillbaka till
[A.5](./a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront),
som skriver ut `reset_sync`s process i sin helhet, och
[A.6](./a_metastability_and_synchronization.md#a6-att-återanvända-kedjan-för-flankdetektering---och-i-förbigående-studsfiltrering),
som ger `button_sync`s trevippskedja och dess flankekvation.

**b)** Bygg växlingslogiken:
* En vippa för lysdiodstillstånd per lysdiod.
* Vid den synkroniserade resetten, släck båda lysdioderna.
* Växla `led(i)` bara när knapp `i`:s synkroniserade puls för fallande flank utlöses.
* Bekräfta att `led(i)` svarar på enbart `button_n(i)`, aldrig på den andra knappen.

**c)** Verifiera designen med dess testbänk (se noteringen högst upp i det här appendixet).

Testbänken trycker på varje knapp i tur och ordning och kontrollerar att:
* Reset släcker båda lysdioderna.
* Inget tryck betyder ingen växling.
* Ett tryck på knapp 0 växlar **bara** `led(0)`, när synkroniserarlatensen har förflutit.
* Att hålla den knappen nedtryckt växlar den inte igen.
* Ett tryck på knapp 1 växlar sedan bara `led(1)`, och lämnar `led(0)` som den var.

Var uppmärksam på **latensen**: testbänken kontrollerar den *exakta* flanken, inte bara att
lysdioden till slut lägger sig rätt. Ett tryck måste nå växlingslogiken genom två
synkroniserarvippor, så `led` är fortfarande oförändrad efter den första och den andra stigande
flanken och växlar vid den tredje. Räkna vipporna ett tryck färdas genom och övertyga dig om att den
tredje flanken är den rätta, och att ett defensivt extra pipelinesteg nu skulle fångas snarare än
tolereras.

**d)** Svara i löpande text, genom att jämföra den här designen med din `led_toggle` från L03:
* Vad ändrar synkroniseraren när det gäller att trycka på en riktig, studsande knapp?
* Varför var den råa L03-versionen osäker att koppla till en fysisk knapp vid `50 MHz`?
* Din testbänk driver rena, perfekt tajmade övergångar. Vilket av den här föreläsningens två
  problem, metastabilitet eller kontaktstuds, kan en testbänk därför aldrig demonstrera för dig?

![Modul `led_toggle_sync2`](./images/led_toggle_sync2.png)

**Självkontroll:** döp din entitet till `led_toggle_sync2`, med ingångarna `clock`, `reset_n`,
`button_n` (`std_logic_vector(1 downto 0)`) och utgången `led` (`std_logic_vector(1 downto 0)`),
deklarerade i den ordningen; dess testbänk finns
i [`exercises/led_toggle_sync2/`](../exercises/led_toggle_sync2). Den trycker på varje knapp i tur
och ordning och kontrollerar att `led(i)` växlar på `button_n(i)`:s fallande flank, att den gör det
vid rätt klockflank snarare än bara lägger sig på rätt värde till slut, och att den aldrig utlöser
fel lysdiod - se [Appendix C](../../L02/appendix/c_testbenches.md).

---
