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

## D-låset
**1.** Bygg den första kretsen i den här kursen som kan *minnas* något.

Allt du har byggt hittills har varit kombinatoriskt: utgångarna följer ingångarna, och i samma
ögonblick som ingångarna ändras ändras utgångarna med dem. Ett lås är det minsta möjliga avsteget
från det. Det har en dataingång `D` och en styringång `enable`, och det har två utgångar, `Q` och
dess komplement `Qn`. Så länge `enable` är hög är låset **genomsläppligt**: `Q` följer helt enkelt
`D`, och det ser ut som en ledning. Det intressanta är vad som händer när `enable` går låg. Låset
**låser**, och håller kvar det `D` var i det ögonblicket, och från och med då kan `D` göra vad det
vill utan att `Q` märker det. Det hållna värdet är en bit minne, och det är byggt av ingenting annat
än de grindar du redan känner till, kopplade så att utgången återkopplas till ingången.

`Qn` är ingen dekoration. Återkopplingsslingan är det som får kretsen att minnas, och de två
utgångarna är det som matar varandra: `Q` beräknas ur `Qn` och `Qn` ur `Q`. Bygg det så ser du
slingan; det är hela poängen med att rita det för hand innan du ens möter VHDL:en.

Använd ekvationerna från
[Appendix A.2](./a_flip_flops_and_registers.md#a2-d-låset):

```math
Q = (D' \cdot enable + Qn)'
```

```math
Qn = (D \cdot enable + Q)'
```

**a)** Realisera motsvarande grindnät:
* Rita nätet för hand.
* Återskapa och simulera det i
  [CircuitVerse](https://circuitverse.org/simulator).

**b)** Testa det genomsläppliga och det låsta tillståndet:
* Sätt `enable = 1`:
  * Ändra `D`.
  * Observera vad som händer med `Q` och `Qn`.
* Sätt `enable = 0`:
  * Ändra `D` igen.
  * Observera vad som händer med `Q` och `Qn`.
* Förklara skillnaden mellan de två fallen.

**c)** Kör `D` och `enable` genom följande kombinationer två gånger:
* `00`
* `01`
* `10`
* `11`

Bekräfta att du observerar båda fallen:
* Låset låser efter att ha varit genomsläppligt med `D = 1`.
* Låset låser efter att ha varit genomsläppligt med `D = 0`.

Förklara hur värdet på `Q` beror på värdet på `D` i det ögonblick `enable` ändras från `1` till
`0`.

---

## D-vippan
**2.** Bygg ut D-låset från övning 1 till en D-vippa, enligt
[Appendix A.3](./a_flip_flops_and_registers.md#a3-d-vippan).

Vippan ska ha:
* Ingångar:
  * `clock`
  * `reset_n`
  * `D`
  * `enable`
* Utgångar:
  * `Q`
  * `Qn`

Resetsignalen är:
* Asynkron:
  * Den får verkan utan att vänta på en klockflank.
* Aktiv låg:
  * Att sätta `reset_n = 0` ska tvinga `Q` till `0` omedelbart.

**Tips:**
* Resetten måste göra två saker i vart och ett av de två interna låsen, inte en:
  * Mata in ett aktivt högt `reset` (`reset_n` genom en NOT-grind) i den NOR-grind
    som producerar `Q`. Det tvingar `Q` låg utan att vänta på en klockflank.
  * `AND`:a in `reset_n` i den AND-grind som producerar det låsets produkt av `D`
    och `enable`. Det frigör `Qn` att gå hög.
  * Att grinda enbart återkopplingsvägen för `Q` räcker inte: med `enable = 1` och
    `D = 1` lämnar det `Qn` låg, och en låg `Qn` är precis det som håller `Q` hög,
    så resetten skulle inte göra någonting.
* Driv de två interna låsens enable-ingångar med:
  * `clock`
  * Inversen av `clock`
* Följ Appendix A.3 för hur den yttre `enable`-ingången styr om vippan tar emot ett
  nytt värde.

**a)** Realisera motsvarande grindnät:
* Rita nätet för hand.
* Återskapa och simulera det i CircuitVerse.
* Sätt klockperioden till `1000 ms`.
  * Det är långsamt nog för att observera beteendet med ögat.

**b)** Testa det klockade beteendet:
* Ändra `D` under klockans höga fas.
* Ändra `D` under klockans låga fas.
* Observera `Q` och `Qn`.
* Bekräfta att utgångarna ändras bara vid den aktiva klockflanken, aldrig mellan
  klockflankerna.

Förklara hur de två interna låsen samverkar för att ge flanktriggat beteende.

**c)** Testa den asynkrona resetten:
* Sätt först `Q = 1`.
* Aktivera resetten genom att sätta `reset_n = 0`.
* Observera om `Q` nollställs:
  * Omedelbart.
  * Vid nästa klockflank.

Förklara resultatet genom att hänvisa till skillnaden mellan en asynkron signal
och en synkron signal.

---

## Register
**3.** Skriv en fullständig VHDL-entitet med namnet `register4`: fyra vippor sida vid sida, som
delar en klocka, en reset och en enable.

Det här är övningen där vippan slutar vara en kuriositet och blir en byggsten. En ensam D-vippa
lagrar en bit, vilket inte är till mycket nytta i sig; vad en design egentligen vill ha är
någonstans att förvara ett *tal*. Sätt fyra vippor på rad, koppla samma klocka till dem alla, och du
har ett fyrabitars register. Ingenting hos den enskilda vippan ändras. Bara bredden gör det.

Det som är värt att lägga märke till är hur lite VHDL:en behöver ändras för att säga det. Du skriver
samma synkrona processmall från
[Appendix A.6](./a_flip_flops_and_registers.md#a6-den-synkrona-processmallen-i-vhdl) som du
redan använde för en bit, med `std_logic_vector(3 downto 0)` i stället för `std_logic`. Det finns
ingen loop, ingen upprepning, inga fyra kopior av någonting. Det är ingen genväg som språket
erbjuder dig; det är ett faktum om hårdvaran, och del **c)** nedan ber dig säga varför.

Entiteten ska ha:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_n` | in | `std_logic` | Asynkron, aktiv låg. Nollställer registret till `"0000"`. |
| `enable` | in | `std_logic` | `'0'` behåller nuvarande värde; `'1'` fångar `d` vid nästa stigande flank. |
| `d` | in | `std_logic_vector(3 downto 0)` | Värdet som ska fångas. |
| `q` | out | `std_logic_vector(3 downto 0)` | Det lagrade värdet. |

Skriv ut processen själv i stället för att kopiera det
[genomarbetade vippexemplet](../d_flip_flop/d_flip_flop.vhd). Att knappa in den är vad som får mallen
att sluta vara något du känner igen och börja vara något du kan producera ur minnet, och du kommer
att skriva den i varenda återstående föreläsning i den här kursen.

**a)** Skriv entiteten och den synkrona processen, och anpassa mallen från en enda bit till en
fyrabitars vektor.

**b)** Kontrollera den med testbänken, så som beskrivs högst upp i det här appendixet.

**c)** Förklara varför samma mall skalar från en vippa till fyra utan någon strukturell ändring,
medan en fyrabitars *räknare* inte helt enkelt kan vara fyra enbitsräknare sida vid sida. Vad
skiljer de två fallen åt?

![Modul `register4`](./images/register4.png)

**Självkontroll:** döp din entitet till `register4`, med portarna `clock`, `reset_n`, `enable`, `d`
(`std_logic_vector(3 downto 0)`) och `q` (`std_logic_vector(3 downto 0)`), deklarerade i den
ordningen; dess testbänk finns i [`exercises/register4/`](../exercises/register4).

---

## Flankdetektering
**4.** Konstruera en krets som växlar en lysdiod en gång för varje samplad
stigande flank hos en knappsignal.

Följ:
* [Appendix A.7](./a_flip_flops_and_registers.md#a7-flankdetektering)
* [Appendix A.9](./a_flip_flops_and_registers.md#a9-genomarbetat-exempel-flankdetekterad-lysdiodsväxling)

Kretsen ska ha:
* Ingångar:
  * `button`
  * `clock`
  * `reset`
* Utgång:
  * `led`

I den här övningen är `reset` aktiv hög, till skillnad från resetten i det
genomarbetade exemplet. Den är fortfarande **asynkron**, som varje reset i den här
kursen: aktivera den så nollställs `led` omedelbart, utan att vänta på en
klockflank. I mallen från A.6 betyder det att resetgrenen stannar utanför testet
`rising_edge(clock)`, och att bara polariteten på resettestet ändras.

**Tips:** Använd två vippor:
* Den ena vippan lagrar det föregående samplade värdet av `button`.
  * Använd det värdet för att detektera en stigande flank.
* Den andra vippan lagrar lysdiodens nuvarande tillstånd.
  * Växla den bara när en stigande flank detekteras.

**a)** Realisera motsvarande grindnät:
* Rita nätet för hand.
* Återskapa och simulera det i CircuitVerse.
* Sätt klockperioden till `1000 ms`.

**b)** Testa flankdetektorn:
* Håll `button` hög under flera klockcykler i följd.
* Bekräfta att `led` växlar exakt en gång.
* Bekräfta att den inte växlar en gång per klockcykel.

Förklara vilken lagrad signal som hindrar kretsen från att gång på gång detektera
samma höga nivå som en ny stigande flank.

---

**5.** Implementera kretsen från övning 4 i VHDL.

**a)** Skapa en entitet med namnet `led_toggle_single` med:

| Port | Riktning | Typ | Beskrivning |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset` | in | `std_logic` | Asynkron, och **aktiv hög**, till skillnad från varje annan modul i den här kursen. Aktivera den så nollställs `led` utan att vänta på en klockflank, så resetgrenen hör hemma utanför testet `rising_edge(clock)`. |
| `button` | in | `std_logic` | Växlar `led` en gång per tryck. |
| `led` | out | `std_logic` | Lysdiodens tillstånd. |

Lägg märke till enbitstyperna: det genomarbetade exemplet använder `std_logic_vector`-portar för två
knappar och två lysdioder, medan den här driver ett enda par.

Kopiera inte [`led_toggle.vhd`](../led_toggle/led_toggle.vhd) rakt av.

Gör så här i stället:
* Härled de två klockade processerna själv:
  * Den ena processen lagrar det föregående värdet av `button`.
  * Den andra processen lagrar och växlar det nuvarande värdet av `led`.
* Härled flankdetekteringsekvationen för:
  * En stigande flank.
  * En aktivt hög knapp.
* Använd ekvationen för stigande flank från Appendix A.7:

```math
edge = current \cdot previous'
```

Använd inte ekvationen för fallande flank från det genomarbetade exemplet, som utgår från en aktivt
låg knapp.

**b)** Verifiera designen med dess testbänk (se noteringen högst upp i det här appendixet).

Testbänken driver samma sekvens som du skulle gå igenom för hand på ett kort:
* Den aktiverar `reset` och kontrollerar att `led` är nollställd.
* Den drar `button` hög och kontrollerar att `led` växlar exakt en gång.
* Den **håller `button` hög** under ytterligare några klockcykler och kontrollerar, efter var och en
  av dem, att `led` *inte* växlar igen.
* Den släpper och trycker igen, och kontrollerar att det andra trycket växlar `led` en gång till.
* Den aktiverar `reset` med `led` tänd och **utan någon klockflank efteråt**, och kontrollerar att
  `led` nollställs ändå. Det är den kontroll som faller om du lägger resetten inuti grenen
  `rising_edge(clock)`.

Den tredje kontrollen är den som faller om din flankdetektor är fel:
* En `led` som växlar varje klockcykel medan knappen hålls nedtryckt betyder att du drev växlingen
  från `button`s **nivå** i stället för från dess flank.
* Läs om ekvationen ovan: `edge` är hög bara när `button` är hög *nu* och dess lagrade föregående
  värde är lågt.

![Modul `led_toggle_single`](./images/led_toggle_single.png)

**Självkontroll:** döp din entitet till `led_toggle_single`, med portarna `clock`, `reset`, `button`
(in) och `led` (out), deklarerade i den ordningen; dess testbänk finns i
[`exercises/led_toggle_single/`](../exercises/led_toggle_single). Lägg märke till att `reset` är
**aktiv hög** här, till skillnad från i det genomarbetade exemplet.

---
