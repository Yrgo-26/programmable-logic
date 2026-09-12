# Appendix B - Övningar

> **Så kontrollerar du ditt arbete.** Varje övning nedan som ber dig skriva en VHDL-modul kommer med
> en självkontrollerande testbänk under [`exercises/`](../exercises). Skriv din modul i dess katalog
> `exercises/<module>/`, med det entitetsnamn och den **portordning** övningen anger, och kör den
> sedan med GHDL - se [Appendix C](../../L02/appendix/c_testbenches.md) för de tre kommandona.
>
> Från och med den här föreläsningen återanvänder designerna moduler du skrivit tidigare, och de
> delas inte ut en andra gång: varje övning säger vilka av dina egna filer som ska kopieras in, och
> skriver ut den `ghdl -a`-rad som behöver dem.
>
> Inget FPGA-kort behövs för någon övning. Stegen för syntes i Quartus och programmering av kortet
> demonstreras under föreläsningen; ditt jobb efteråt är att få VHDL:en rätt, och testbänken är hur
> du bekräftar det.

## Timers för hand

**1.** Bygg en andra timer för hand i CircuitVerse, enligt
[Appendix A.2](./a_timers.md#a2-att-bygga-en-timer-för-hand-i-circuitverse), men med målvärdet
`TICK_COUNT = 12` i stället för appendixets `10`.

**a)** Rikta om jämföraren:
* Skriv `12` binärt med 4 bitar.
* De fyra XNOR-grindarna sitter kvar precis där de sitter. Säg vilka av deras konstanta ingångar som
  ändras, och till vad.
* Säg, i en mening, varför en likhetsjämförare byggd av XNOR inte behöver någon grind tillagd,
  borttagen eller omkopplad för att jämföra mot ett annat värde.

**b)** Bygg den:
* Återanvänd din 4-bitars räknare och jämförare från föreläsningen, och ändra bara konstanterna.
* Sätt klockperioden till `1000 ms` och bekräfta att `timeout` slår till en gång var trettonde
  klockflank, under exakt en flank varje gång.

**c)** Ta nu bort nollställningen, så att `timeout` inte längre tvingar räknaren tillbaka till
`0000`:
* Förutsäg, innan du kör den, hur ofta `timeout` slår till nu.
* Kör den och bekräfta.
* Förklara resultatet utifrån räknarens eget överslag (L06 A.1).

**d)** Gör sönder jämföraren med flit: koppla loss en XNOR:s utgång från AND-grinden och håll den
AND-ingången hög i stället.
* Förutsäg vilka räknarvärden som nu höjer `timeout`, innan du simulerar.
* Bekräfta genom att stega räknaren genom en hel cykel.
* Det här är hur "tre av de fyra bitarna stämmer" ser ut, och det är det vanligaste sättet för en
  handritad jämförare att bli fel.

**Tips:** att räkna `0` till och med `12` är tretton flanker, inte tolv. Appendix A.1:s anmärkning
om `TICK_COUNT + 1` är samma ettfel, och det är värt att reda ut här, där du kan räkna flankerna med
ögat, snarare än senare vid 50 MHz.

---

**2.** Svara på var och en av frågorna nedan i en eller två meningar, med hänvisning till modulen
`timer` i [Appendix A.3](./a_timers.md#a3-modulen-timer-i-vhdl):

**a)** Varför är `timeout` en encykelspuls snarare än en signal som ligger kvar hög när målvärdet
väl är nått?

**b)** Medan en löpande timers `enable`-ingång hålls låg, vad händer med dess interna räknare från
en klockflank till nästa: nollställs den, pausar den, eller räknar den vidare?

**c)** Varför tar `timer` `reset_s2_n` (den synkroniserade reset-signalen) snarare än den råa
`reset_n` som sin reset-ingång?

**d)** CircuitVerse-timern i övning 1 behövde kopplas om för att målvärdet skulle ändras, medan
VHDL-modulen inte behöver ändras alls. Vad ersätter omkopplingen, och när låses dess värde fast?

---

## Timers i VHDL

**3.** DE0-CV-kortets systemklocka är `50 MHz`. Räkna för varje mål nedan ut den
`TICK_COUNT`-generic du skulle skicka in till modulen `timer` från
[Appendix A.3](./a_timers.md#a3-modulen-timer-i-vhdl):

**a)** En `timeout`-puls en gång per sekund.
**b)** En `timeout`-puls var `250` ms.
**c)** En `timeout`-puls tjugo gånger per sekund (`20 Hz`).

**Tips:** Sambandet mellan en period och dess tickantal är:

```math
TICK\_COUNT = seconds \times 50{,}000{,}000 - 1
```

`- 1` är samma ettfel som övning 1 kretsade kring: räknaren löper `0` till och med `TICK_COUNT`, så
en period är `TICK_COUNT + 1` klockcykler, inte `TICK_COUNT`.

---

**4.** Skriv själva modulen `timer`, som en entitet vid namn `timer`.

Den byggs live under föreläsningen och är tryckt i sin helhet i
[Appendix A.3](./a_timers.md#a3-modulen-timer-i-vhdl), så det här är ingen gåta. Skriv den ändå,
utan att kopiera: varje design härifrån till kursens slut instansierar den här modulen, båda
capstones inräknade, och det är värt att ha byggt det du strax ska återanvända sex gånger.

Entiteten har en generic:

| Generic | Typ | Standardvärde | Betydelse |
|---|---|---|---|
| `TICK_COUNT` | `natural` | `50_000_000` | Antal tick att räkna innan en timeout. En sekund vid DE0-CV:ns `50 MHz`-klocka, avrundat: enligt övning 3:s regel är det exakta värdet `49_999_999`, och 20 ns fel på en sekund är inte värt den mindre läsbara konstanten. |

och dessa portar:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, redan synkroniserad reset. Asynkron: den nollställer räknaren och `timeout` utan att någon klockflank är inblandad. |
| `enable` | in | `std_logic` | Timerns enable. Medan den är låg **håller** räknaren sitt värde, och fortsätter därifrån i stället för att börja om. |
| `timeout` | out | `std_logic` | Encykelspuls, som slår till var `TICK_COUNT + 1` cykler medan timern är aktiverad. |

Arkitekturen ska:
* Deklarera den interna räknaren som `natural range 0 to TICK_COUNT`, så att registret dimensioneras
  av genericen snarare än lämnas obegränsat.
* Använda en enda process, känslig för `clock` och `reset_s2_n`, enligt mallen för klockad process
  från [L03 A.6](../../L03/appendix/a_flip_flops_and_registers.md#a6-den-synkrona-processmallen-i-vhdl).
* Nollställa både räknaren och `timeout` vid reset, utanför den klockade grenen.
* Driva `timeout` låg villkorslöst högst upp i den klockade grenen, och hög bara vid den flank som
  nollställer räknaren. Det mönstret, ett förval följt av en överskrivning, är vad som gör pulsen
  exakt en cykel bred snarare än två.

Svara sedan, i en mening var:
* `enable = '0'` måste **pausa** räknaren, inte nollställa den. Anta att du nollställde den i
  stället. Förutsäg vad referenstestbänken rapporterar, och vilken av de två egenskaperna ovan den
  mäter när den gör det. Kör den sedan och se. (L08:s `fsm_led` hänger på pausen, vilket är varför
  testbänken bryr sig.)
* Räknaren räknar `0` till och med `TICK_COUNT`, så en period är `TICK_COUNT + 1` cykler. Var i din
  kod är det där "+ 1" faktiskt skrivet? Det står inte som en literal någonstans.
* A.2:s handritade `timeout` är en kombinatorisk avkodning av räkningen; din är registrerad. Båda
  har samma period. Vilken cykel slår var och en till på, och varför spelar skillnaden roll för
  något nedströms som samplar `timeout`?

![Modulen `timer`](./images/timer.png)

**Självkontroll:** namnge din entitet `timer`, med genericen `TICK_COUNT` (`natural`), ingångarna
`clock`, `reset_s2_n`, `enable` och utgången `timeout`, deklarerade i den ordningen; dess testbänk
ligger i [`exercises/timer/`](../exercises/timer). Den kör tre hela perioder, så en timer som bara
slår till en gång passerar inte, och den pausar mitt i räkningen för att bekräfta att räkningen
fortsatte i stället för att börja om.

**Spara den här filen.** Övning 5 nedan återanvänder den, det gör `walking_led` i övning 6 också,
och likaså båda L08:s capstones. Varje senare övning som behöver en timer ber dig kopiera in just
den här.

---

**5.** Skriv en entitet vid namn `blinker` som blinkar en lysdiod på och av en gång per sekund,
genom att återanvända modulen `timer` du just skrev snarare än att räkna klockcykler själv.

Entiteten har en generic:

| Generic | Typ | Standardvärde | Betydelse |
|---|---|---|---|
| `TICK_COUNT` | `natural` | `25_000_000` | En halv sekund vid DE0-CV:ns `50 MHz`-klocka. Exponera det som en generic i stället för att baka in antalet, så att en testbänk kan korta blinket; FPGA-bygget använder bara standardvärdet. |

och dessa portar:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_n` | in | `std_logic` | Aktiv låg reset, rå från omvärlden. Asynkron: aktivera den och `led` slocknar omedelbart, utan att vänta på någon klockflank. |
| `led` | out | `std_logic` | Nollställd till `'0'` medan reset-signalen är aktiv, och lämnad där till den första timeouten efter att reset-signalen släppts. |

Lägg märke till att den här entiteten tar den **råa** `reset_n` snarare än en redan synkroniserad
`reset_s2_n`. Att synkronisera den är en del av övningen, och det är vad
[L04 A.5](../../L04/appendix/a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront)
menar med "exakt en modul i en design är undantaget": här är den modulen `blinker` själv.

Arkitekturen ska:
* Instansiera din `reset_sync` från [L04 övning 8](../../L04/appendix/b_exercises.md), och använda
  dess utgång `reset_s2_n` som reset för allt inuti.
* Instansiera modulen `timer` från
  [Appendix A.3](./a_timers.md#a3-modulen-timer-i-vhdl):
  * Skicka din egen generic `TICK_COUNT` rakt igenom till timerns `TICK_COUNT`.
  * Hålla dess `enable`-ingång hög.
* Växla `led` i en synkron process varje gång timerns `timeout`-puls slår till.

Implementera inte räknelogiken, eller synkroniseraren, på nytt själv.

I stället:
* Återanvänd `timer` och `reset_sync` oförändrade, via en `generic map` och en `port map`, enligt
  kompositionsmönstret i [Appendix A.4](./a_timers.md#a4-att-komponera-en-komplett-timerkrets).
* Förklara varför en timerperiod på en **halv** sekund ger en blinkcykel på **en** sekund (en hel
  period av på och sedan av).

Svara sedan, i en mening var:
* Lysdioden måste vara släckt under reset, och testbänken kontrollerar att den slocknar utan någon
  klockflank däremellan. Vilken halva av mönstret aktivera-asynkront-släpp-synkront kontrollerar
  det, och vilken halva kontrollerar det inte?
* Din `timer` resettas av `reset_s2_n`, två flanker efter att `reset_n` släppts. Vad skulle gå fel
  om du matade den med den råa `reset_n` i stället? Namnge felet, inte bara regeln.

![Modulen `blinker`](./images/blinker.png)

**Självkontroll:** namnge din entitet `blinker`, med genericen `TICK_COUNT` (`natural`), ingångarna
`clock`, `reset_n` och utgången `led`, deklarerade i den ordningen; dess testbänk ligger i
[`exercises/blinker/`](../exercises/blinker).
**Kopiera in dina egna `reset_sync.vhd` och `timer.vhd` i den katalogen** innan du bygger; ingen av
dem delas ut där, eftersom du skrivit båda. Den skriver över `TICK_COUNT` med ett litet värde och
kontrollerar att lysdioden växlar om och om igen, ligger kvar exakt en timerperiod mellan
växlingarna, och att den första växlingen kommer sent med din synkroniserares två flanker
(se [Appendix C](../../L02/appendix/c_testbenches.md)):

```bash
cd lectures/L07/exercises/blinker
cp ../../../L04/exercises/reset_sync/reset_sync.vhd .   # the two you wrote yourself
cp ../timer/timer.vhd .
ghdl -a --std=93 reset_sync.vhd timer.vhd blinker.vhd blinker_tb.vhd
```

---

## Den vandrande lysdioden
En enda tänd lysdiod som vandrar längs en rad, en position per timertick, startad och stoppad med en
knapp. Den byggs live under föreläsningen och är beskriven i
[Appendix A.5](./a_timers.md#a5-fpga-implementation-ett-skiftregister-med-vandrande-lysdiod).

Det här är utdelningen från de fyra senaste föreläsningarna, och den skriver nästan ingen egen
logik: tre moduler, två av dem oförändrade från L04 och en skriven i dag, komponerade. Övning 6
bygger den, och övning 7 och 8 ändrar det du byggt.

**6.** Skriv en entitet vid namn `walking_led`.

Entiteten har två generics:

| Generic | Typ | Standardvärde | Betydelse |
|---|---|---|---|
| `LED_COUNT` | `natural` | `8` | Hur många lysdioder biten vandrar längs. Raden är så här bred, och vandringen slår över efter så här många steg. |
| `TICK_COUNT` | `natural` | `25_000_000` | Skickas rakt igenom till din `timer`, så att biten flyttar en position per timerperiod: ett steg per halv sekund vid DE0-CV:ns `50 MHz`-klocka. |

och dessa portar:

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_n` | in | `std_logic` | Aktiv låg reset, rå från omvärlden. Att synkronisera den är ditt jobb, precis som den var i `blinker`. |
| `button_n` | in | `std_logic` | Aktiv låg tryckknapp, rå. Varje tryck startar eller stoppar vandringen. |
| `led` | out | `std_logic_vector(LED_COUNT-1 downto 0)` | Lysdiodsraden. Exakt en bit är tänd åt gången; vid reset är det bit `0`. |

Arkitekturen komponerar tre moduler du redan skrivit, och lägger till två processer:
* Instansiera din **`reset_sync`**, och använd dess `reset_s2_n` som reset för allt annat i
  designen, de två instanserna nedan inräknade.
* Instansiera din **`button_sync`** med `generic map(1)`, för en encykelspuls per tryck. Dess
  knappportar är vektorer med `COUNT` bitar medan `button_n` här är en skalär, så överbrygga
  bredden med en `std_logic_vector(0 downto 0)` med ett element i vardera riktningen. A.5 visar det.
* Instansiera din **`timer`** med din egen `TICK_COUNT`, driv dess `enable` från skiftflaggan nedan
  och ta dess `timeout` som skiftticket.
* En process som växlar **`shift_enable`** vid varje puls från knappen, nollställd till `'0'` vid
  reset. Vandringen börjar därför stoppad.
* En process som håller det **skiftregister** som driver `led`: vid reset, ladda en enda tänd bit på
  position `0` och nollställ resten; vid varje `timeout` från timern, rotera ett steg mot MSB och
  låt den översta biten slå över tillbaka in i bit `0`. Det är ett PISO-register (L06 A.4) med sin
  egen seriella utgång kopplad tillbaka till sin seriella ingång, vilket är det som gör en
  engångsutskiftning till en oändlig vandring.

Svara sedan, i en mening var:
* `shift_enable` driver timerns `enable`, så att stoppa vandringen stoppar timern också. Övning 4
  fick dig att visa att `enable` **pausar** räkningen snarare än nollställer den. Vad ser en
  betraktare på kortet, vid det tryck som startar om vandringen, om din timer nollställer i stället?
* `button_sync` instansieras med `COUNT = 1` här och med `COUNT = 2` i L08:s `fsm_led`, ur samma fil
  utan någon ändring. Vad hade du behövt skriva i stället om bredden var fastlagd i modulen snarare
  än inskickad som en generic?

![Modulen `walking_led`](./images/walking_led.png)

**Självkontroll:** namnge din entitet `walking_led`, med generics `LED_COUNT` och `TICK_COUNT` (båda
`natural`), ingångarna `clock`, `reset_n`, `button_n` och utgången `led`, deklarerade i den
ordningen; dess testbänk ligger i [`exercises/walking_led/`](../exercises/walking_led). Den skriver
över båda generics (`LED_COUNT = 4`, `TICK_COUNT = 3`) så att ett helt varv tar en handfull
klockcykler snarare än två sekunder, och den kontrollerar resetmönstret, att ingenting rör sig före
det första trycket, och att antalet skiftningar över ett fast fönster stämmer med den takt timern
sätter. Kopiera först in de tre moduler den komponerar:

```bash
cd lectures/L07/exercises/walking_led
cp ../../../L04/exercises/reset_sync/reset_sync.vhd .   # the three you wrote yourself
cp ../../../L04/exercises/button_sync/button_sync.vhd .
cp ../timer/timer.vhd .
ghdl -a --std=93 reset_sync.vhd button_sync.vhd timer.vhd \
                 walking_led.vhd walking_led_tb.vhd
ghdl -e --std=93 walking_led_tb
ghdl -r --std=93 walking_led_tb --assert-level=error --stop-time=10ms
```

---

**7.** Gör följande ändringar en i taget, och kör om testbänken efter var och en. Del **a)** och
**b)** ändrar bara testbänkens konstanter - att de inte kräver någon ändring alls i din
`walking_led.vhd` är hela poängen med dem. Del **c)** är den som rör modulen.

**a)** Ändra vandringshastigheten:
* Ändra konstanten `TICK_COUNT` i **testbänken** från `3` till `6`.
* Den ska fortfarande passera, den här gången för att testbänken anpassar sig med dig: dess
  observationsfönster är fasta `PULSES * 6` cykler, och den härleder det antal skiftningar den
  förväntar sig ur `TICK_COUNT`, en skiftning per `TICK_COUNT + 1` cykler.
* Hitta nu var den anpassningen slutar betyda något. Fortsätt höja `TICK_COUNT` förbi fönstrets
  längd och räkna ut vad det förväntade antalet blir, och vad kontrollen då faktiskt bevisar. Ett
  test som passerar av fel skäl är värt att kunna känna igen.
* Förklara sedan varför ett ändrat tickantal inte kan göra sönder *designen*, bara sakta ner den.

**b)** Ändra bredden:
* Ändra testbänkens konstant `LED_COUNT` från `4` till `8`.
* Den ska fortfarande passera, utan någon ändring alls i din `walking_led.vhd`. Förklara hur modulen
  hade behövt se ut för att det här skulle ha krävt en ändring.

**c)** Ladda två tända bitar på var sin sida av registret vid reset (t.ex. `"10001000"` för
`LED_COUNT = 8`), och låt dem vandra i takt:
* Peka ut den enda rad i din `walking_led.vhd` du behöver ändra.
* **Förutsäg** vad referenstestbänken kommer att rapportera, innan du kör någonting.
* Kör den sedan och se. Förklara resultatet: är designen fel, eller kontrollerar testbänken något
  som inte längre är specifikationen?

**Tips:** Både `LED_COUNT` och `TICK_COUNT` är generics, så del **a)** och **b)** kräver ingen
ändring alls i modulens kropp. Det är hela poängen med en generic: en modul, många storlekar, inga
ändringar.

---

**8.** Den nuvarande designen vandrar bara åt ett håll (mot MSB, där den översta biten slår över
tillbaka till botten). Ändra din `walking_led.vhd` så att en **andra** knapp vänder
vandringsriktningen.

**a)** Lägg till en andra, synkroniserad knappingång:
* Dra den genom samma `button_sync`-instans, och skicka `2` till dess generic `COUNT`
  (`generic map(2)`, positionsvis, som överallt annars i den här kursen).

**b)** Lägg till en signal `direction`:
* Växla den vid den nya knappens flank, precis så som `shift_enable` växlas av den första knappen.

**c)** Gör rotationen i `SHIFT_PROCESS` beroende av `direction`:
* När `direction = '0'`, rotera mot MSB (kursens konvention från
  [L06 Appendix A.2](../../L06/appendix/a_counters_and_shift_registers.md#a2-skiftregister), och
  det du skrev i övning 6):

```vhdl
shift_reg <= shift_reg(LED_COUNT-2 downto 0) & shift_reg(LED_COUNT-1);
```

* När `direction = '1'`, rotera åt andra hållet, mot bit 0:

```vhdl
shift_reg <= shift_reg(0) & shift_reg(LED_COUNT-1 downto 1);
```

Det här är det enda stället i kursen där ett skiftregister medvetet går emot kursens konvention: att
vända riktningen är hela poängen med övningen. Lägg märke till att det andra uttrycket är precis den
spegelbild L06 A.2 varnar dig för att hålla utkik efter i andras kod.

**d)** Din entitets portar har nu ändrats: `button_n` är en tvåbitarsvektor snarare än en enda bit.

* Förklara varför [`walking_led_tb.vhd`](../exercises/walking_led/walking_led_tb.vhd) inte längre
  går att köra mot din version, och exakt vad GHDL kommer att klaga på när du försöker.
* Det här är den vanliga kostnaden för att ändra ett gränssnitt, och den är värd att känna en gång:
  en testbänk är skriven mot en bestämd entitet, och att bredda en port gör sönder varje
  instansiering av den, också de du inte skrivit själv.
* Beskriv, i löpande text, den följd av tryck du skulle använda för att övertyga dig själv om att
  designen fungerar, och vad du skulle förvänta dig att lysdioderna gör vid varje steg. Den följden
  är precis vad en testbänk för den nya entiteten skulle behöva driva.

---
