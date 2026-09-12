# Appendix A - Räknare och skiftregister

## A.1 Från register till räknare
Ett register (L03) är en bank av D-vippor som lagrar vilket värde som än matas in vid nästa stigande
flank. En **räknare** är samma idé med en vridning: i stället för ett nytt värde utifrån matar du
registret med dess *eget nuvarande värde plus ett*. Vid varje flank fångar det `current_value + 1`,
så det lagrade talet ökar en gång per klockcykel utan någon vidare inmatning.

### Bygg den för hand först
Som med varje krets i den här kursen: bygg den innan du skriver den. En 4-bitars räknare är tre
element, och att se den köra är hela poängen:
* Ett **4-bitars register**: fyra D-vippor som delar en klocka, exakt registret från
  [L03 A.5](../../L03/appendix/a_flip_flops_and_registers.md#a5-register-vippor-parallellt).
* En **adderare** och en **konstant `1`**: registrets fyra utgångar till adderarens ena ingång,
  konstanten till den andra.
* Adderarens summa kopplad tillbaka till registrets fyra `D`-ingångar. Den återkopplingen är hela
  kretsen: registret håller ett tal, adderaren beräknar det talet plus ett, nästa flank lagrar det.
  Det är L03 A.1:s återkopplingsslinga igen, med en adderare i vägen i stället för en ren ledning.

![En 4-bitars räknare: ett register vars egen utgång, plus ett, kopplas tillbaka till dess ingång](./images/counter_circuit.png)

Bekräfta sedan, en klockflank i taget, med en period på `1000 ms`:
* Se utgångarna stega `0000, 0001, 0010, 0011, ...`, en räkning per stigande flank.
* **Låt den köra förbi `1111`.** Den återgår till `0000` av sig själv, och ingenting i din krets
  säger åt den att göra det: det finns ingen jämförelse, ingen nollställningslogik, inget "om
  räkningen står på maxvärdet" någonstans. Adderaren producerade `10000`, den femte biten hade
  ingenstans att ta vägen, och de fyra bitar som överlevde är `0000`. Det är **spill**, och i en
  räknare är det inte en bugg att arbeta runt utan den egenskap som resten av den här föreläsningen
  och hela L07 vilar på.
* **Håll ögonen på `carry_out` på adderaren medan det sker.** Det är den femte biten, och ritningen
  visar exakt var den hamnar: hög under den enda flank där räkningen slår över, kopplad till
  ingenting, ut ur adderaren och stopp där. En bredare räknare skulle mata in den i ett femte steg;
  här kastas den bort, och att kasta bort den *är* överslaget. Så "räkningen slår över för att
  bitarna tar slut" är inte ett bildligt uttryck. Du kan peka på biten som tog slut.

Spara projektet. [L07](../../L07/README.md) utgår från exakt den här kretsen och lägger till två
saker till den, och att öppna den igen är bättre än att rita om den.

### Samma räknare i VHDL
En signal och en process, precis som L03:s register, bortsett från att högerledet refererar till
signalen själv:

```vhdl
signal counter: natural range 0 to 15;
...
process(clock, reset_s2_n) is
begin
    if (reset_s2_n = '0') then
        counter <= 0;
    elsif (rising_edge(clock)) then
        counter <= counter + 1;
    end if;
end process;
```

`natural` är en fördefinierad heltalssubtyp i VHDL: ett icke-negativt heltal, till skillnad från
`std_logic`-typerna som modellerar bitar direkt. VHDL:s aritmetiska operatorer fungerar på den så
som vanlig heltalsmatematik gör, vilket är varför `counter + 1` inte behöver något extra maskineri.
Syntesen gör ändå om den till ett register av vippor, precis som ett `std_logic_vector` skulle bli;
skillnaden ligger enbart i hur du skriver och resonerar om värdet.

Intervallbegränsningen `0 to 15` är inte bara dokumentation. Den talar om för syntesverktyget att
den här räknaren behöver fyra bitar, så att räkna förbi `15` faller tillbaka till `0` gratis, enbart
som en konsekvens av att bitarna tar slut, utan någon uttrycklig "om counter = 15"-logik vare sig i
ritningen eller i VHDL-koden.

Det gratis överslaget har ett villkor värt att säga ut: det inträffar bara när den övre gränsen är
`2^N - 1`. `0 to 15` slår över gratis; `0 to 9` gör det inte, eftersom `10` inte är en
tvåpotensgräns, och en modulo-10-räknare behöver en uttrycklig jämförelse. Det är precis vad övning
4 ber dig skriva.

**Ett ställe där simulatorn är oense med hårdvaran.** Det gratis överslaget är en egenskap hos den
*syntetiserade* kretsen, och ritningen visar att det är verkligt. En VHDL-*simulator* är strängare
än en ledning:
* `natural range 0 to 15` intervallkontrolleras, så GHDL behandlar `15 + 1 = 16` som ett fel och
  avbryter i stället för att slå över.
* Den syntetiserade hårdvaran har ingen sådan föreställning. Det finns inget sextonde värde för
  bitarna att anta, så de landar på `0000`, precis som dina fyra lysdioder gjorde.

Grindnätet och chippet slår båda över; bara simulatorn invänder, eftersom ett intervallbegränsat
heltal är ett löfte du gett och `16` bryter det. Regeln som följer är inte "lita på hårdvaran": den
är att allt du tänker verifiera bör säga vad det menar. Skriv ut jämförelsen, så som `timer.vhd` och
`serial_rx8.vhd` gör, så är ritningen, simulatorn och chippet alla överens.

Det här överslaget som följer av bitbredden är räknarens enskilt viktigaste egenskap, och det är av
det [L07](../../L07/README.md) bygger en timer: en räknare som håller utkik efter ett bestämt
räknarvärde och höjer en flagga när det kommer.

---

## A.2 Skiftregister
Ett **skiftregister** är, återigen, N D-vippor, kopplade så att varje vippas utgång matar *nästa*
vippas ingång i stället för sin egen. Vid varje klockflank flyttar varje bit en position nedåt i
kedjan, samtidigt:

```text
serial_in -> [D Q]-->[D Q]-->[D Q]-->[D Q] -> serial_out
              FF0     FF1     FF2     FF3
             bit 0   bit 1   bit 2   bit 3
               ^clock  ^clock  ^clock  ^clock  (alla delar samma klocka)
```

Efter en flank ligger `FF0`:s innehåll i `FF1`, `FF1`:s i `FF2`, och så vidare; en ny bit kommer in
i `FF0` från `serial_in`, och det som låg i den sista vippan faller av änden som `serial_out`. Kör
den i N flanker så har N seriella bitar vandrat hela vägen igenom.

**Ett håll, som används genomgående i den här kursen.** Ett skiftregister kan flytta bitar åt båda
hållen, och båda är lika giltiga; det är att blanda dem inom en och samma design som skapar
förvirring. Så varje skiftregister här följer diagrammet ovan:
* kedjan avbildas på ett `std_logic_vector` med `FF0` som **bit 0** och `FF(N-1)` som bit `N-1`.
* seriella data **kommer in vid bit 0** och **lämnar från bit `N-1`**.
* varje bit flyttar en position mot den **mest signifikanta** biten per flank.

I VHDL är det hållet ett enda uttryck, identiskt i varje exempel nedan:

```vhdl
shift_reg <= shift_reg(N-2 downto 0) & serial_in;
```

`shift_reg(N-2 downto 0)` är allt utom den översta biten, flyttat upp en position; den översta
biten har ingenstans att ta vägen och faller av som `serial_out`; `serial_in` fyller den
lediggjorda bit 0.

När du möter ett skiftregister utanför den här kursen: kontrollera dess håll innan du antar något.
Spegelbilden, `serial_in & shift_reg(N-1 downto 1)`, är precis lika vanlig och ser vid en snabb
blick nästan likadan ut.

Skiftregister namnges efter hur data kommer in och lämnar:

| Utförande | Data in | Data ut | Typisk användning |
|---|---|---|---|
| SISO (serie in/serie ut) | en bit per klocka | en bit per klocka | en ren fördröjningslinje |
| **SIPO** (serie in/parallell ut) | en bit per klocka | alla N bitar på en gång | att ta emot en ström av seriella bitar, t.ex. en inkommande byte på en enda ledning |
| **PISO** (parallell in/serie ut) | alla N bitar på en gång (laddade) | en bit per klocka | att sända ut N bitar över en enda ledning, t.ex. att driva en kedja av lysdioder eller ett externt skiftregisterchip |
| PIPO (parallell in/parallell ut) | alla N bitar på en gång | alla N bitar på en gång | i praktiken ett vanligt register (L03 A.5) |

Den här föreläsningen tar upp de två praktiskt användbara, SIPO och PISO.

---

## A.3 Serie in/parallell ut (SIPO)
Ett SIPO-register är det du griper efter när bitar anländer en i taget på en enda ledning och du
behöver det ackumulerade värdet på en gång. Klassikern är att deserialisera en inkommande byte,
vilket är vad mottagarvägen i vilket seriellt protokoll som helst i grunden gör.

Vilken ände av byten som anländer först är varje protokolls eget beslut. SPI och CAN sänder som
förval den mest signifikanta biten först, vilket är vad A.2:s håll förutsätter: den första biten som
anländer hamnar i MSB när alla N har skiftats in. (Bitordningen i SPI går att ställa om på de flesta
styrkretsar, så kontrollera komponenten.) Ett protokoll som sänder den minst signifikanta biten
först, som UART, skiftar åt det spegelvända hållet, och dess idiom är också spegelbilden.

Idiomet är en rad inuti en klockad process, A.2:s skiftuttryck ordagrant:

```vhdl
signal shift_reg: std_logic_vector(7 downto 0);
...
process(clock, reset_s2_n) is
begin
    if (reset_s2_n = '0') then
        shift_reg <= (others => '0');
    elsif (rising_edge(clock)) then
        shift_reg <= shift_reg(6 downto 0) & serial_in;
    end if;
end process;
parallel_out <= shift_reg;
```

Efter 8 flanker har de mottagna bitarna helt ersatt registrets ursprungliga innehåll, och
`parallel_out` exponerar alla 8 på en gång.

---

## A.4 Parallell in/serie ut (PISO)
Ett PISO-register vänder på SIPO:s uppgift: ladda N bitar på en gång, sänd sedan ut dem en i taget.
Det är det du griper efter när ett fast mönster ska ut över en enda ledning, till exempel till en
kedja av lysdioder eller en display driven av ett externt skiftregisterchip.

Det behöver en styrsignal mer än SIPO: något som skiljer att *ladda* ett nytt parallellt värde från
att *skifta* ut det befintliga.

```vhdl
process(clock, reset_s2_n) is
begin
    if (reset_s2_n = '0') then
        shift_reg <= (others => '0');
    elsif (rising_edge(clock)) then
        if (load = '1') then
            shift_reg <= parallel_in;                          -- Parallel load.
        elsif (shift = '1') then
            shift_reg <= shift_reg(N-2 downto 0) & serial_in;  -- Shift toward the MSB.
        end if;
    end if;
end process;
serial_out <= shift_reg(N-1);
```

Bit `N-1` är alltid nästa bit att lämna, så ett laddat värde går ut med den mest signifikanta biten
först: ladda `"1010"` i ett 4-bitars register så presenterar `serial_out` `1`, `0`, `1`, `0` under
de följande cyklerna.

Lägg märke till hur lite som skiljer det här från A.3:s SIPO. **Skiftuttrycket är identiskt**, samma
håll, samma rad VHDL. Bara två saker skiljer: PISO lägger till en `load`-gren, och den tappar av
`shift_reg(N-1)` som seriell utgång där SIPO exponerar hela vektorn. "SIPO" och "PISO" namnger hur
du *kopplar* ett skiftregister, inte två sorters hårdvara, vilket är varför A.2 kunde beskriva
skiftningen en gång innan något av namnen dök upp.

Om en design behöver ett verkligt nytt `serial_in` vid varje skiftning, eller nöjer sig med att
återcirkulera det som faller av änden, avgörs av hur den är kopplad. Den återcirkulationen är precis
det trick som exemplet med den vandrande lysdioden i [L07](../../L07/README.md) använder, när det
väl har en timer som taktar skiftningen.

---

## A.5 Genomgånget exempel: en 8-bitars seriemottagare
Föreläsningens två halvor möts i en modul. Ett skiftregister kan ta emot seriella bitar i all
evighet men kan inte tala om *när* en komplett byte anlänt, eftersom det inte har någon
föreställning om "hur många bitar hittills". Det är ett räkneproblem, och A.1 löste det redan.
[`serial_rx8/serial_rx8.vhd`](../serial_rx8/serial_rx8.vhd) kombinerar de två, plus en
`data_ready`-puls på en cykel när den åttonde biten landar.

Det här är ingen leksak: det är främre halvan av varje seriemottagare som finns. Mottagarvägarna i
SPI, CAN och UART börjar alla med ett skiftregister och en biträknare, och skiljer sig bara i vad
som avgör när en bit är giltig.

| Port | Riktning | Typ | Betydelse |
|---|---|---|---|
| `clock` | in | `std_logic` | Systemklocka. |
| `reset_s2_n` | in | `std_logic` | Aktiv låg, **redan synkroniserad** reset; nollställer registret och biträkningen. Asynkron, så den nollställer dem utan att någon klockflank är inblandad. |
| `shift_enable` | in | `std_logic` | Hög under exakt en klockcykel per inkommande bit. |
| `serial_in` | in | `std_logic` | Den inkommande biten, samplad vid varje aktiverad stigande flank. |
| `data_out` | out | `std_logic_vector(7 downto 0)` | Byten som mottagits hittills, mest signifikanta biten först. |
| `data_ready` | out | `std_logic` | Puls på en cykel när den åttonde biten landar. |

**Resetporten är den synkroniserade, och `_s2` säger det.** Den heter `reset_s2_n` snarare än
`reset_n` eftersom det som hör hemma på den är utgången från en
[`reset_sync`](../../L04/appendix/a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront),
modulen du skrev i [L04 övning 8](../../L04/appendix/b_exercises.md): aktivera asynkront, släpp
synkront. **Instansiera en i den design som omsluter den här mottagaren och koppla dess
`reset_s2_n` hit**, vilket är precis vad A.7:s omslagsmodul på kortet gör. Koppla i stället en
tryckknapp rakt in på den här porten så får du den kapplöpning L04 finns till för att förhindra:
skiftregistret och biträknaren är ett dussin vippor, och en asynkront *släppt* reset låter dem lämna
reset vid olika flanker, så mottagaren kan börja räkna en byte en cykel innan den börjar skifta in
en. Regeln är densamma som [L07 A.3](../../L07/appendix/a_timers.md) ställer upp för `timer`, och
den gäller varje subkomponent i den här kursen: en modul som komponeras in i en större design rör
aldrig själv en rå asynkron ingång.

`counter`, `sipo8` och `piso8` i [Appendix B](./b_exercises.md) tar `reset_s2_n` av samma skäl.
Ingen av dem är en design du sätter på ett kort för sig själv: en räknare, ett skiftregister och en
mottagare är delar, och en del har rätt att anta att designen omkring den har skött
synkroniseringen. Så hela den här föreläsningen tar den synkroniserade reset-signalen, och bara
omslagsmodulerna i A.6 och A.7, som äger pinnarna, får någonsin se en rå `reset_n`.

En **toppnivå** namnges tvärtom: den tar `reset_n` och instansierar `reset_sync` själv, eftersom det
är den som håller pinnen. `blinker` och `walking_led` i [L07](../../L07/README.md), och båda
capstones i [L08](../../L08/README.md), är skrivna så.

Skaffa dig vanan att läsa `_s2` som ett krav på anroparen, för härifrån och framåt är det mesta du
skriver en subkomponent.

Vid varje stigande flank där `shift_enable = '1'` skiftas `serial_in` in i bit 0 med A.3:s idiom
oförändrat, så den första biten som anländer har vandrat upp till bit 7 när den åttonde landar, och
en intern biträknare av typen `natural range 0 to 7` (A.1) räknar upp. Vid den flank där den
räknaren redan står på `7` pulsar `data_ready` hög under en cykel och räknaren nollställs tillbaka
till `0`, redo för nästa byte. `data_out` drivs av en konkurrent tilldelning från skiftregistret, så
den kompletta byten ligger på den under den cykel då `data_ready` är hög.

Lägg märke till att räknaren *nollställs* här snarare än lämnas att slå över: `0 to 7` är ett
tvåpotensintervall så den skulle slå över gratis, men att skriva ut det håller simulatorn överens
med hårdvaran, enligt A.1.

Två detaljer är värda att dröja vid, eftersom båda är mönster du mött mer än en gång:
* **`data_ready` är en puls, inte en nivå.** Den drivs låg villkorslöst högst upp i den klockade
  grenen och höjs bara vid den flank som fullbordar en byte: samma encykelsform som flankdetektorn i
  L03 A.7. En konsument som missar den har missat byten, vilket är precis därför den är parad med
  ett `data_out` som *håller* sitt värde efteråt. En riktig kringkrets skulle sätta ett hållregister
  eller en liten FIFO här så att en långsam konsument inte kan förlora data.
* **`shift_enable` grindar biträknaren, inte bara skiftningen.** Båda går framåt tillsammans eller
  ingendera, så ett avbrott i den inkommande strömmen pausar mottagaren mitt i en byte i stället för
  att korrumpera den, och den återupptar på exakt den bit den väntade på.

**Att kontrollera den:** till exemplet hör en utdelad
[`serial_rx8_tb.vhd`](../serial_rx8/serial_rx8_tb.vhd), som skiftar in två byte med en paus emellan
och kontrollerar att `data_ready` pulsar en gång per byte, aldrig för tidigt:

```bash
cd lectures/L06/serial_rx8
ghdl -a --std=93 serial_rx8.vhd serial_rx8_tb.vhd
ghdl -e --std=93 serial_rx8_tb
ghdl -r --std=93 serial_rx8_tb --assert-level=error --stop-time=10ms
```

Taktad på `50 MHz` och kontinuerligt aktiverad sväljer den här mottagaren en byte på 160 ns, vilket
ingen lysdiod kan visa dig. Det är därför testbänken spelar roll här på ett sätt den inte gjorde för
en blinkande lysdiod, och så är det för det mesta av verklig digitalkonstruktion. Men det är inget
skäl att hoppa över kortet, för `shift_enable` är just utvägen: se A.7.

---

## A.6 FPGA-demonstration: att se en räknare slå över
Räknaren demonstreras på DE0-CV under föreläsningen, byggd på samma sätt som varje design sedan L01:
ett Quartus Prime Lite-projekt mot `5CEBA4F23C7N`, `.vhd`-filen tillagd, kompilera, tilldela varje
port en fysisk pinne i Pin Planner, kompilera sedan om och programmera kortet.

En sak måste ändras först, och det är värt att se varför. Taktad på `50 MHz` går en 4-bitars räknare
igenom alla sexton tillstånd och slår över var `320 ns`, ungefär tre miljoner gånger i sekunden. En
lysdiod driven direkt från den blinkar inte, den lyser helt enkelt med halv styrka. För att se ett
överslag måste du titta på en mycket långsammare bit: räkna i ett bredare register, säg 28 bitar,
och tilldela de **översta** fyra bitarna till lysdioderna.

Demonstrationen är därför en omslagsmodul kring två moduler snarare än övningens entitet för sig: en
`reset_sync` som tar den råa `reset_n` från pinnen, och den breddade räknaren som tar sin
`reset_s2_n` därifrån. Räknarens port heter `reset_s2_n` just för att den här kopplingen ska vara
den enda som typkontrollerar, och A.7 upprepar mönstret med en tredje modul.

* `clock` till 50 MHz-oscillatorn, `reset_n` till en tryckknapp (in i `reset_sync`, aldrig rakt in i
  räknaren), `count(27 downto 24)` till fyra lysdioder.
* Bit 24 ändras en gång var `2^24` klockcykler, ungefär en tredjedels sekund, så de fyra lysdioderna
  räknar synligt från `0000` upp till `1111` och sedan, utan att något i kretsen gör det, tillbaka
  till `0000`. Ett helt varv tar ungefär fem sekunder.

Att dela en klocka genom att titta på en hög bit är den grövsta tänkbara timern, och dess
begränsning är värd att namnge redan nu: perioden är låst till en tvåpotens, och det enda sättet att
ändra den är att välja en annan bit. [L07](../../L07/README.md) ersätter den med en räknare jämförd
mot ett målvärde du väljer, vilket är allt en timer egentligen är.

---

## A.7 FPGA-demonstration: att skifta in en byte för hand
A.5 sa att en byte anländer för fort för att kunna följas. Lösningen är inte att sakta ned klockan,
vilket vore mjukvaruinstinkten och är fel drag i hårdvara: klockan är den enda sak i en synkron
design som du inte pillar på. `serial_rx8` har redan rätt styrning, och det är `shift_enable`, som
"grindar biträknaren, inte bara skiftningen". Håll den låg så stannar mottagaren tvärt, mitt i en
byte, hur länge du vill. Höj den under exakt en cykel så går exakt en bit in.

Driv alltså `shift_enable` från en **knapp** i stället för att hålla den hög. Ett tryck, en bit.

Demonstrationen är en liten omslagsmodul kring tre moduler du redan har, och ingen ny logik utöver
en enda vippa. Den byggs live under föreläsningen:

* `reset_sync`
  ([L04 A.5](../../L04/appendix/a_metastability_and_synchronization.md#a5-att-synkronisera-en-resetsignal-aktivera-asynkront-släpp-synkront)),
  som gör den råa `reset_n` till `reset_s2_n` för allt annat.
* `button_sync`
  ([L04 A.6](../../L04/appendix/a_metastability_and_synchronization.md#a6-att-återanvända-kedjan-för-flankdetektering---och-i-förbigående-studsfiltrering))
  med `COUNT = 1`, som gör ett tryck till den encykelspuls som `shift_enable` vill ha. Det här är
  ingen valfri utsmyckning: en rå knapp kopplad till `shift_enable` skulle skifta in en slumpmässig
  handfull bitar per tryck, en per klockcykel så länge kontakterna studsar.
* `serial_rx8` själv, oförändrad, med sin `reset_s2_n` tagen från `reset_sync` ovan snarare än från
  knappen. Det är hela skälet till att porten heter `reset_s2_n`: omslagsmodulen äger den råa
  `reset_n`, och mottagaren får bara någonsin se den synkroniserade.
* En vippa som låser `data_ready`, satt när pulsen anländer och nollställd av reset. Utan den finns
  ingenting att se: `data_ready` är hög i 20 ns, och det kan ingen lysdiod visa dig.

På kortet:

* `clock` till 50 MHz-oscillatorn, `reset_n` till en tryckknapp.
* `serial_in` till en strömbrytare: det är den bit du är på väg att skicka.
* Skiftknappen till en andra tryckknapp.
* `data_out(7 downto 0)` till åtta lysdioder, och den låsta `data_ready` till en nionde.

Ställ nu strömbrytaren, tryck på knappen, och se en bit komma in vid lysdioden längst till höger och
hela mönstret stega åt vänster. Skicka `10110010` en bit i taget så byggs byten upp över lysdioderna
framför dig, mest signifikanta biten först, precis som A.3:s idiom säger att den måste. Vid det
åttonde trycket tänds den nionde lysdioden och biträknaren börjar om.

Tre saker som det här gör synliga och som testbänken bara kan hävda:
* **Bitordningen.** Den första biten du skickar hamnar i bit 7. Att läsa av det ur en vågform är ett
  tjatgöra; att se den vandra över en rad lysdioder är det inte.
* **Vad `shift_enable` är till för.** Släpp knappen en minut mitt i en byte så rör sig ingenting,
  ingenting går förlorat, och den åttonde biten fullbordar ändå byten. Det är egenskapen "pausar
  mitt i en byte i stället för att korrumpera den", demonstrerad snarare än påstådd.
* **Puls mot nivå, en gång till.** Skälet till att en vippa måste läggas till för `data_ready` är
  hela den distinktionen, och det är samma skäl som flankdetektorn i L03 fanns till för.

---
