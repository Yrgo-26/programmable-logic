# Appendix A - Tillståndsmaskiner

## A.1 Vad en ändlig tillståndsmaskin är
En ändlig tillståndsmaskin (FSM) är en krets vars beteende inte bara beror på dess aktuella
ingångar utan på en ändlig mängd *historik*, sammanfattad i ett enda värde som kallas dess
**tillstånd**. I varje ögonblick befinner sig maskinen i exakt ett tillstånd; vid varje klockflank
kan den gå vidare till ett nytt, bestämt av dess aktuella tillstånd och ingångar; och dess utgång
beräknas ur det tillståndet.

Inget av det här är ny hårdvara. En tillståndsmaskin kombinerar två saker du redan kan: ett
**register** (L03) som håller det aktuella tillståndet, en vippa per tillståndsbit, och
**kombinatorik** som beräknar nästa tillstånd och utgången ur det aktuella tillståndet och
ingångarna.

Det nya är disciplinen. I stället för ad hoc-logik som matar en ad hoc-uppsättning vippor arbetar
du i en fast ordning: rita först ett **tillståndsdiagram**, några namngivna tillstånd med märkta
övergångar mellan sig, och härled tillståndstabellen först när det är rätt, sedan logiken för
nästa tillstånd, sedan grindnätet eller VHDL-koden.

Varje synkron krets hittills är tekniskt sett en trivial tillståndsmaskin: en räknares tillstånd
är dess räkning, ett skiftregisters är dess bitmönster. Det som skiljer en tillståndsmaskin är att
tillståndet varken är en räkning eller ett skiftat mönster utan en godtycklig etikett
(`STATE_OFF`, `STATE_BLINK`, ...) vars innebörd du väljer och vars nästa värde får bero på ingången
hur du vill.

Det finns två varianter, och skillnaden avgör vad en utgång får titta på:
* **Mooremaskiner**: utgången beror *bara* på det aktuella tillståndet. Det är den sorten som
  konstrueras för hand här.
* **Mealymaskiner**: utgången beror på det aktuella tillståndet *och* den aktuella ingången. A.5
  går kort igenom dem, bara i VHDL, så att du känner igen en när du möter den och kan skillnaden
  på en klockcykel.

---

## A.2 Att konstruera en Mooremaskin för hand: tillståndsdiagram, tillståndstabell och Karnaughhärledd logik
Samma process som för varje grindnät i L01 och L02, tillämpad på en krets med minne. Det
genomarbetade exemplet är en liten, sluten Mooremaskin med fyra tillstånd: en cirkulär räknare
genom en Graykodssekvens, som stegas ett steg per knapptryck.

### Specifikation
* Fyra tillstånd, vart och ett representerat av två vippor `{Q1, Q2}`:

  | Tillstånd | `{Q1, Q2}` |
  |---|---|
  | `STATE_0` | `00` |
  | `STATE_1` | `01` |
  | `STATE_2` | `11` |
  | `STATE_3` | `10` |

* En systemklocka `clock`, och en aktiv låg reset `reset_n` som återför maskinen till `STATE_0`.
* En aktiv låg tryckknapp `button_n`, ur vilken en synkroniserad, flankdetekterad puls `X` härleds
  på exakt det sätt L04:s dubbelvippsynkroniserare gör. `X` är hög i exakt en klockcykel vid en
  fallande flank på `button_n`.
* En utgång `Y`, kopplad till en lysdiod, hög bara i `STATE_3`.
* Maskinen är **sluten**: tillståndet efter `STATE_3` är `STATE_0`.
* Det är en **Moore**-maskin: `Y` beror bara på `{Q1, Q2}`, aldrig på `X`.

Kodningen är en Graykod (`00 -> 01 -> 11 -> 10 -> 00`), där tillstånd som följer på varandra
skiljer sig i exakt en bit. Det är ett medvetet val, inte en slump:
* Med en vanlig binärräkning (`00 -> 01 -> 10 -> 11`) vänder en övergång som `01 -> 10` två bitar
  på en gång, och de två vipporna kommer inte att slå om vid *exakt* samma ögonblick.
* Den skevheten är harmlös för maskinen själv. Båda vipporna uppdateras vid samma klockflank, och
  ingenting samplar tillståndsregistret däremellan, så maskinen agerar aldrig på mellanvärdet. Det
  är samma argument som L05:s kritiska väg: så länge allt hinner stabilisera sig före nästa flank
  spelar det ingen roll vad som händer under tiden.
* Vad skevheten *kan* störa är allt som läser tillståndet kombinatoriskt. En utgång som avkodas
  direkt ur tillståndsbitarna, som `Y` nedan, kan glitcha kort medan de är skeva. Detsamma gäller
  ett värde som samplas av en *annan* klockdomän, vilket är fallet L04 A.3 varnade för.
* En Graykod tar bort båda, eftersom bara en bit någonsin ändras per övergång. Därför spelar den
  störst roll för en räknare som korsar klockdomäner, och minst för en maskin vars utgång är
  registrerad.

Kodning är i allmänhet ett designbeslut, och det här är det enda stället i kursen där du fattar det
för hand. Binärt använder färrest vippor; Gray minimerar antalet bitar som ändras per övergång;
**one-hot** lägger en vippa per tillstånd så att logiken för nästa tillstånd blir en enda bred
OR-grind per tillstånd, vilket ofta är snabbast på en FPGA där vippor finns i överflöd. Så snart du
skriver maskinen i VHDL som en uppräknad typ (A.4) lämnar du beslutet till syntesverktyget, som
väljer en kodning åt dig och omkodar fritt om du inte säger något annat.

### Tillståndsdiagram

![Tillståndsdiagram för Mooremaskinen med fyra tillstånd och Graykod](./images/fsm_state_diagram.png)

Varje tillståndsbubbla visar det aktuella tillståndet och utgången som `Q1Q2/Y`, och varje pil är
märkt med den ingång `X` som utlöser den. Varje tillstånd går tillbaka till sig självt så länge
`X=0`, och en synkroniserad puls från knappen (`X=1`) stegar vidare till nästa tillstånd och slår
runt från `STATE_3` tillbaka till `STATE_0`.

### Tillståndstabell
Varje kombination av aktuellt tillstånd och ingång, med nästa tillstånd `{Q1+, Q2+}` och utgången
`Y`:

| Q1 | Q2 | X | Q1+ | Q2+ | Y |
|----|----|---|-----|-----|---|
| 0  | 0  | 0 | 0   | 0   | 0 |
| 0  | 0  | 1 | 0   | 1   | 0 |
| 0  | 1  | 0 | 0   | 1   | 0 |
| 0  | 1  | 1 | 1   | 1   | 0 |
| 1  | 0  | 0 | 1   | 0   | 1 |
| 1  | 0  | 1 | 0   | 0   | 1 |
| 1  | 1  | 0 | 1   | 1   | 0 |
| 1  | 1  | 1 | 1   | 0   | 0 |

### Karnaughhärledd logik
Om `Q1+` och `Q2+` var för sig behandlas som en boolesk funktion av `{Q1, Q2, X}` och körs genom
ett Karnaughdiagram, samma teknik som i L02:

```text
Q1+ = Q1X' + Q2X
Q2+ = Q2X' + Q1'X
```

Lägg märke till formen på båda:
* var och en är "håll kvar när `X` är `0`, ta något från den andra biten när `X` är `1`."
* hållhalvorna, `Q1X'` och `Q2X'`, är verkligen spegelbilder av varandra.
* stegningshalvorna är `Q2X` och `Q1'X`, och komplementet på den andra är inte ett skrivfel: det är
  det som gör sekvensen till en Graykod i stället för en enkel rotation.

Utgången `Y` förenklas ytterligare, direkt ur tillståndstabellen, utan något beroende av `X` alls,
vilket bekräftar att det här är en giltig Mooremaskin:

```text
Y = Q1Q2'
```

### Att realisera den som ett grindnät
`{Q1, Q2}` är var sin D-vippa, precis som L03:s register: `Q1+`/`Q2+` matar D-ingångarna och
`Q1`/`Q2` läses tillbaka från Q-utgångarna. `Y` är en enda AND-grind med två ingångar där den ena
är inverterad, och den läser det aktuella tillståndet. Det är hela maskinen: två vippor och en
handfull grindar som beräknar `Q1+`, `Q2+` och `Y` ur `{Q1, Q2, X}`.

---

## A.3 Från grindnät till CircuitVerse
Innan något av det här skrivs i VHDL, realisera det för hand i
[CircuitVerse](https://circuitverse.org/simulator), precis som varje grindnät i L01:
dubbelvippsynkronisera `button_n` och `reset_n`, flankdetektera den synkroniserade knappen för att
producera `X`, koppla `Q1+`/`Q2+` till ett par D-vippor, och koppla `Y` rakt in i lysdioden.

![Grindnät som realiserar Mooremaskinen med fyra tillstånd, inklusive dubbelvippsynkronisering och flankdetektering för button_n](./images/fsm_gate_network.png)

Läst från vänster till höger:
* `button_n` går genom tre synkroniseringsvippor
  (`button_s1_n`/`button_s2_n`/`button_s3_n`).
* En AND-grind härleder `button_edge_s2` (den här kretsens `X`) ur andra och tredje steget.
* De fyra lodräta ledningarna märkta `Q1Q2XX'` bär tillståndsbitarna och flankpulsen vidare till
  grindarna till höger, som implementerar A.2:s ekvationer för `Q1+`/`Q2+`.
* De två märkta vipporna lagrar `Q1`/`Q2` och matar de avslutande AND-/NOT-grindarna som producerar
  `Y`, kopplad till `led`.
* `reset_n` synkroniseras av sitt eget vippapar nere till vänster, precis som varje annan
  synkroniserad reset i den här kursen.

Öppna den körbara kretsen själv: [fsm_gate_network.cv](./images/fsm_gate_network.cv). Stega den för
hand, ett knapptryck i taget, och bekräfta att den besöker `STATE_0 -> STATE_1 -> STATE_2 ->
STATE_3 -> STATE_0` i ordning, med lysdioden tänd bara i `STATE_3`.

---

## A.4 Samma maskin i VHDL
Det var sista gången i den här kursen du konstruerar en maskin för hand. Allt härifrån skriver den
direkt i VHDL, vilket är värt att ha förtjänat snarare än att ha börjat med: syntesverktyget gör
exakt det du just gjorde på papper, och när en tillståndsmaskin beter sig fel är det diagrammet du
felsöker, inte VHDL-koden.

Översättningen ersätter den explicita tillståndstabellen och Karnaughekvationerna med en
**uppräknad typ** som namnger varje tillstånd, en **case-sats** som beskriver varje tillstånds
övergångar, och ett syntesverktyg som lämnas att lista ut vippkodningen och logiken på grindnivå.

### Den uppräknade tillståndstypen
Anta en maskin med tre tillstånd som styr en lysdiod: `STATE_OFF`, `STATE_BLINK` (blinkar i en fast
takt) och `STATE_ON`. VHDL deklarerar exakt de tre värdena som en ny typ:

```vhdl
type state_t is (STATE_OFF, STATE_BLINK, STATE_ON);
signal state: state_t;
...
state <= STATE_ON;
```

### Mönstret med case-satsen
Maskinen är nästan alltid en synkron process som uppdaterar `state` vid stigande flank via ett
`case`, en gren per tillstånd, med en asynkron reset som återför den till ett känt starttillstånd.
Antag att `to_next_state` och `to_prev_state` är synkroniserade, flankdetekterade pulser
producerade på exakt samma sätt som `X` i A.2 och A.3:

```vhdl
process(clock, reset_s2_n) is
begin
    if (reset_s2_n = '0') then
        -- On reset, go to STATE_OFF.
        state <= STATE_OFF;
    elsif (rising_edge(clock)) then
        case (state) is
            when STATE_OFF =>
                if (to_next_state = '1') then
                    state <= STATE_BLINK;
                elsif (to_prev_state = '1') then
                    state <= STATE_ON;
                end if;
            -- STATE_BLINK and STATE_ON follow the same shape.
            when others =>
                state <= STATE_OFF;
        end case;
    end if;
end process;
```

`case (state) is ... end case;` måste täcka varje värde `state_t` kan anta, och `when others` håller
det uttömmande om du lägger till ett tillstånd senare och glömmer en gren.

Vad `when others` *inte* är, är ett skyddsnät mot ett korrumperat tillståndsregister. Varje värde
`state_t` kan anta är redan namngivet ovanför den, så grenen är onåbar i källkoden och syntesen
optimerar normalt bort den i stället för att bygga återhämtningslogik. När Quartus väl har omkodat
maskinen är de flesta bitmönster otillåtna, och att ta sig ur ett av dem kräver Quartus inställning
Safe State Machine snarare än något du kan skriva i VHDL.

### Genomarbetat exempel: `fsm_led`
[`fsm_led/fsm_led.vhd`](../fsm_led/fsm_led.vhd) implementerar exakt den maskinen med tre tillstånd,
utökad till två knappar: `button_n(0)` stegar framåt, `button_n(1)` går bakåt, tillstånden är
slutna i en loop, och `STATE_BLINK` växlar lysdioden var 100:e ms.

Tre delblock återanvänds, alla moduler du skrivit själv:
* `reset_sync`: L04:s resetsynkroniserare, oförändrad
  ([L04 övning 8](../../L04/appendix/b_exercises.md)).
* `button_sync`: L04:s knappsynkroniserare, också oförändrad, men instansierad med `generic map(2)`
  så att den hanterar båda knapparna på en gång och producerar en pulsvektor på två bitar. Det är
  utdelningen från denna generic: filen är identisk med den L04 och L07 instansierar med `1`
  ([L04 övning 9](../../L04/appendix/b_exercises.md)).
* `timer`: L07:s timer, oförändrad ([L07 övning 4](../../L07/appendix/b_exercises.md)). `fsm_led`
  deklarerar en egen generic `TIMER_TICK_COUNT` och skickar den rakt vidare, med förvalet
  `5_000_000` för 100 ms vid `50 MHz`, och aktiverar timern bara i `STATE_BLINK`.

Ingen av de tre är utdelad i `fsm_led/`: kopiera in dina egna innan du bygger exemplet. Vid det här
laget i kursen är det fyra föreläsningars egna moduler komponerade till en enda design, vilket är
det som är värt att lägga märke till.

Två synkrona processer implementerar maskinen:
* `STATE_PROCESS` är övergångslogiken med `case` ovan, driven av `to_next_state`/`to_prev_state`,
  som härleds kombinatoriskt ur `button_edge_s2`. Var och en kräver att den *andra* knappens puls
  är `'0'` i samma cykel, så att trycka ned båda så nära i tid att deras pulser hamnar på samma
  klockcykel flyttar maskinen ingenstans i stället för att godtyckligt utse en vinnare. En tvetydig
  ingång förtjänar ett definierat svar, och "gör ingenting" är det som inte kan överraska dig.
* `LED_PROCESS` driver `led_s` enbart ur det aktuella tillståndet: släckt i `STATE_OFF`, tänd i
  `STATE_ON`, växlande vid varje timeout från timern i `STATE_BLINK`. Eftersom den aldrig läser
  `button_n` eller `button_edge_s2` direkt, bara `state`, är det här en äkta Mooremaskin:
  lysdioden reagerar på ett tryck bara indirekt, genom det tillstånd trycket orsakade.

---

## A.5 Mealymaskiner: skillnaden på en klockcykel
Allt hittills har varit en **Moore**-maskin, med flit: Moore är det säkrare standardvalet och den
form du konstruerar för hand. En **Mealy**-maskin luckrar upp regeln som definierar en
Mooremaskin: utgången får bero på det aktuella tillståndet *och* den aktuella ingången, beräknad
kombinatoriskt. Den lagras inte i ett register, och den ändras inom samma klockcykel som ingången
gör.

### Beteendet: detektera två `1`-bitar i följd
En seriell ingång `din` bär en bit per klockcykel, och `y` ska indikera att de två senaste bitarna
båda var `1`, där överlappande träffar räknas, så `111` rapporterar en träff två gånger.

Som Mealymaskin behöver det här bara två tillstånd, eftersom utgången kan reagera på ingången
*innan* den syns i nästa tillstånd: `STATE_IDLE` (föregående bit var `0`, eller det här är den
första) och `STATE_ONE` (föregående bit var `1`).

| Tillstånd | `din` | Nästa tillstånd | `y` |
|---|---|---|---|
| `STATE_IDLE` | 0 | `STATE_IDLE` | 0 |
| `STATE_IDLE` | 1 | `STATE_ONE`  | 0 |
| `STATE_ONE`  | 0 | `STATE_IDLE` | 0 |
| `STATE_ONE`  | 1 | `STATE_ONE`  | **1** |

Tillståndsprocessen är A.4:s `case`-mönster; bara utgången skiljer sig. Det här är
[`seq_detect_mealy/seq_detect_mealy.vhd`](../seq_detect_mealy/seq_detect_mealy.vhd), och dess
tilldelning av utgången är en enda konkurrent sats, helt utanför varje klockad process:

```vhdl
y <= '1' when (state = STATE_ONE and din = '1') else '0';
```

Det är en **villkorlig signaltilldelning**, och det är den sista biten VHDL-syntax den här kursen
introducerar. Den är en konkurrent sats, så den hör hemma i arkitekturkroppen snarare än inuti en
process, och den beskriver en multiplexer: välj det första värde vars villkor gäller, annars värdet
efter `else`. Det är samma hårdvara du skulle få ur ett `if`/`else` inuti en kombinatorisk process,
skriven på en rad i stället för fem, och den är värd att ha eftersom en tilldelning av utgången på
en rad gör det uppenbart vid en blick vad utgången beror på.

```vhdl
-- These two describe exactly the same multiplexer.
x <= a when sel = '1' else b;

process(sel, a, b) is
begin
    if (sel = '1') then
        x <= a;
    else
        x <= b;
    end if;
end process;
```

Ge den alltid ett `else`. Utelämnar du ett har du beskrivit en signal som behåller sitt gamla värde
när inget villkor gäller, vilket är ett lås, precis som i A.3 i L05. `fsm_led` använder den här
formen tre gånger, och övning 4 ber dig använda den.

**Den enda raden är hela skillnaden.** Den läser `din`, alltså är den Mealy. Flytta samma villkor
in i den klockade processen, eller ta bort `din` ur det, så har du en Mooremaskin i stället.

### Vad den kostar och vad den köper
Mooreversionen av den här detektorn behöver ett **tredje** tillstånd, `M_TWO`, som finns enbart
för att i en cykel minnas att träffen inträffade, så att utgången har något att läsa som inte beror
på ingången. Mata båda maskinerna med `1, 1, 0, 1, 1, 1`:

| Cykel | `din` | Mealytillstånd (före) | Mealy `y` | Mooretillstånd (före) | Moore `y` |
|---|---|---|---|---|---|
| 1 | 1 | `STATE_IDLE` | 0 | `M_IDLE` | 0 |
| 2 | 1 | `STATE_ONE`  | **1** | `M_ONE`  | 0 |
| 3 | 0 | `STATE_ONE`  | 0 | `M_TWO`  | **1** |
| 4 | 1 | `STATE_IDLE` | 0 | `M_IDLE` | 0 |
| 5 | 1 | `STATE_ONE`  | **1** | `M_ONE`  | 0 |
| 6 | 1 | `STATE_ONE`  | **1** | `M_TWO`  | **1** |

Moores `y`-kolumn är exakt Mealys `y`-kolumn förskjuten en rad nedåt. Det är hela avvägningen:
Mealy rapporterar träffen *samma* cykel som den andra `1`:an kommer där Moore tar en till, och
Mealy behöver 2 tillstånd där Moore behöver 3.

### Vilken du ska välja
Moore, nästan alltid, och det är den resten av kursen använder, grupprojektet inräknat:
* dess utgång beror inte på någon primär ingång, så den kan inte följa en brusig sådan.
* en Mealyutgång kan i princip glitcha kombinatoriskt om dess ingångar inte redan är rena.
* observera att "Moore" i sig inte betyder glitchfri. En utgång som avkodas kombinatoriskt ur flera
  tillståndsbitar, som A.2:s `Y = Q1Q2'`, kan fortfarande glitcha medan de bitarna är skeva vid en
  övergång. Det som gör en utgång glitchfri är att *registrera* den, så som `fsm_led`:s
  `LED_PROCESS` gör, och det är vad du vill ha på allt som driver en ledning ut från kretsen. En
  seriell `tx`-ledning som avkodas direkt ur tillståndsbitarna kommer att sända ut falska flanker.
* en maskin vars utgång beror på färre saker är en maskin med färre sätt att bli fel på.

Ta till Mealy bara när du specifikt behöver den lägre latensen eller det mindre antalet tillstånd,
och var medveten om att du då byter en synkron utgång mot en kombinatorisk.

---

## A.6 FPGA-demonstration
`fsm_led` syntetiseras och körs precis som varje VHDL-design gjort sedan L01: skapa ett Quartus
Prime Lite-projekt med DE0-CV:s `5CEBA4F23C7N` som målkrets, lägg till `.vhd`-filerna för exemplet
och dess delblock, kompilera, tilldela varje port en fysisk pinne i Pin Planner, och kompilera
sedan om och programmera kortet.

För `fsm_led`, tilldela `clock` pinnen för 50 MHz-oscillatorn, `reset_n` och `button_n(1 downto 0)`
tre tryckknappar, och `led` en lysdiod på kortet. Bekräfta sedan att upprepade tryck på "nästa" får
lysdioden att cykla `släckt -> blinkande -> tänd -> släckt`, att "föregående" går åt andra hållet,
och att reset återför den till släckt.

`seq_detect_mealy` demonstreras med flit **inte** på kortet. Den konsumerar en bit per klockcykel,
och en omkopplare som slås om för hand håller sitt värde i miljontals cykler, så det enda en
lysdiod kan visa är det degenererade fallet: `din` hållen hög, `y` hög från andra cykeln och framåt.
Skillnaden på en klockcykel som hela A.5 handlar om sker alldeles för fort för att se. Kör dess
testbänk i stället, vilket är den allmänna lärdomen snarare än ett undantag:

```bash
cd lectures/L08/seq_detect_mealy
cp ../../L04/exercises/reset_sync/reset_sync.vhd .     # the one you wrote in L04
ghdl -a --std=93 reset_sync.vhd seq_detect_mealy.vhd seq_detect_mealy_tb.vhd
ghdl -e --std=93 seq_detect_mealy_tb
ghdl -r --std=93 seq_detect_mealy_tb --assert-level=error --stop-time=10ms
```

Exakta pinnummer beror på vilka knappar och lysdioder på DE0-CV du väljer, tilldelade på samma sätt
som för varje design sedan L01. Slå upp DE0-CV:s egen dokumentation för dess fysiska
pinnkonfiguration om du behöver bekräfta vilken headerpinne som motsvarar vilken märkt knapp,
omkopplare eller lysdiod.
