# Appendix A

## Att färdigställa `can_controller.vhd` (del 2: mottagning och arbitrering)
L16 byggde sändvägen. Den här föreläsningen färdigställer `can_controller` med `role = '0'`-vägen
(mottagning) och den arbitreringslogik som avgör vilken av två tävlande sändare som får fortsätta.
Ramuppställningen, tillståndssekvensen och gruppstorlekarna per fält är desamma som i L16;
mottagarsidan läser bara tillbaka varje fält i stället för att driva det.

---

### Att läsa tillbaka bussen
En mottagande nod samlar in riktiga (avstoppade) bitar genom `rx_shift_reg`, grindade vid
`bit_timer.sample`-punkten (mitt i perioden, när bussen hunnit stabilisera sig), inte vid
`bit_done`. Den sätter `rx_shift_reg.bit_count` till samma gruppstorlekar som sändarsidan använder,
och läser varje färdig grupp ur `rx_shift_reg.data`, som är **högerjusterad** i sina lägsta
`bit_count` bitar (L15). Den sätter ihop ramen igen i ackumulatorer:
* ID: de höga 8 bitarna från `ARB_HI` (`rxsr_data(7 downto 0)`), de låga 3 från `ARB_LO`
  (`rxsr_data(3 downto 1)`). Gruppens sista bit, `rxsr_data(0)`, är RTR: dominant markerar de
  dataramar den här kursen stöder, så en recessiv RTR höjer `error` och avbryter ramen (en
  fjärram, som inte stöds).
* DLC: från `CTRL` (`rxsr_data(3 downto 0)`). Gruppens två översta bitar, IDE och r0, kontrolleras
  **inte**: båda är alltid dominanta i den här kursens ramar (L10). En mottagare som mötte den
  recessiva IDE:n i en riktig ram med utökad identifierare skulle feltolka den som en standardram
  ända tills CRC-kontrollen misslyckades; att kontrollera IDE och hantera det den annonserar hör
  hemma i en produktionskontroller (L19 listar det bland luckorna).
* Data: varje mottagen byte placeras på sin **fasta** position efter byteindex, byte 0 i bitarna
  63 downto 56, byte 1 i 55 downto 48, och så vidare. Det här är en positionsstyrd `case`, **inte**
  en löpande vänsterskiftning (som bara skulle landa byte 0 högst upp för en full 8-bytesram).

I slutet av `STATE_EOF`, lås `rx_id`/`rx_dlc`/`rx_data` från ackumulatorerna och pulsa `rx_valid`.

---

### Mottagarvägen, tillstånd för tillstånd
Samma tillståndssekvens som L16:s sändväg, gången som mottagare. `role = '0'` hela vägen. Läs det
här vid sidan av L16:s fälttabell: gruppstorlekarna är identiska, bara det som händer med varje
grupp skiljer sig. Tabellen är specifikationen; "Att färdigställa processerna" nedan samlar de
regler som inte ryms i den.

"Föregriper" är det `rxsr_bit_count`/`rxsr_enable` som det **kombinatoriska** blocket driver medan
`state` fortfarande läser `STATE_LOAD_*`-värdet, en cykel innan skifttillståndet blir synligt;
nästa avsnitt förklarar varför det är nödvändigt.

| Tillstånd | Föregriper | Går vidare på | Ackumulator / åtgärd |
|---|---|---|---|
| `STATE_IDLE` | inget | dominant `rx_bus_s2`, `idle_bits` full | lås `role = '0'`, nollställ `idle_bits` |
| `STATE_START` | inget | omedelbart | nollställ `error`, återställ byteindexet, `bt_resync` |
| `STATE_SOF` | 1 | `rxsr_valid` | samla in SOF som en enbitsgrupp; själva biten kastas (se nedan) |
| `STATE_LOAD_ARB_HI` | 8 | `bt_sample` | (väntan: förra gruppens sista bit ligger fortfarande på ledningen; samplet som avslutar tillståndet samlar in nästa grupps första bit) |
| `STATE_ARB_HI` | 8 | `rxsr_valid` | `rx_id_acc(10 downto 3) <= rxsr_data(7 downto 0)` |
| `STATE_LOAD_ARB_LO` | 4 | `bt_sample` | |
| `STATE_ARB_LO` | 4 | `rxsr_valid` | `rx_id_acc(2 downto 0) <= rxsr_data(3 downto 1)`; `rxsr_data(0)` är RTR: om recessiv, `error <= '1'` och avbryt |
| `STATE_LOAD_CTRL` | 6 | `bt_sample` | |
| `STATE_CTRL` | 6 | `rxsr_valid` | `rx_dlc_acc <= rxsr_data(3 downto 0)`; `DLC = 0` hoppar till `STATE_CRC_WAIT` |
| `STATE_LOAD_DATA` | 8 | `bt_sample` | |
| `STATE_DATA` | 8 | `rxsr_valid` | placera `rxsr_data` på den fasta positionen för byte `data_byte_idx` |
| `STATE_CRC_WAIT` | inget | omedelbart | en stabiliseringscykel; **ingen** väntan på `bt_sample` (se övning 1c) |
| `STATE_LOAD_CRC_HI` | 8 | `bt_sample` | |
| `STATE_CRC_HI` | 8 | `rxsr_valid` | fortsätt mata `crc15`; själva värdet behålls inte |
| `STATE_LOAD_CRC_LO` | 7 | `bt_sample` | |
| `STATE_CRC_LO` | 7 | `rxsr_valid` | sista bitarna in i `crc15` |
| `STATE_CRC_LO_WAIT` | inget | `bt_bit_done` | kontrollera `crc_valid`: om låg, `error <= '1'` och avbryt |
| `STATE_CRC_DELIM` | inget | `bt_bit_done` | |
| `STATE_ACK_SLOT` | inget | `bt_bit_done` | driv bussen dominant för att kvittera (`crc_valid` kontrollerades vid `STATE_CRC_LO_WAIT`) |
| `STATE_ACK_DELIM` | inget | `bt_bit_done` | armera 7-bitars EOF-nedräkningen |
| `STATE_EOF` | inget | `bt_bit_done` ×7 | vid den sista biten, lås `rx_id`/`rx_dlc`/`rx_data`, pulsa `rx_valid` |

Två mönster löper genom hela tabellen. Varje `STATE_LOAD_*`-rad finns enbart för att förbruka den
förra gruppens avslutande bitperiod: tillståndsmaskinen skördar ingenting där, även om det
`bt_sample` som avslutar tillståndet är precis det som `rx_shift_reg` samlar in nästa grupps första
bit på; cykeltabellerna nedan gör det konkret. Varje avslutande (ostoppad) rad går vidare på
`bt_bit_done` i stället för `bt_sample`, eftersom de fälten går förbi `rx_shift_reg` helt och räknas
som hela bitperioder.

**Varför `STATE_SOF` aktiverar `rx_shift_reg` för en bit som ingen behåller.** Det insamlade värdet
kastas; SOF är alltid dominant och `STATE_IDLE` visste redan det när den startade den här ramen.
Det som spelar roll är att biten passerar genom avstoppningens följdspårare. Den spåraren
(`consecutive`, `last_bit`) lever kvar över gruppgränser och nollställs bara av reset (L15), och
sändarens kopia inuti `tx_shift_reg` räknade SOF, eftersom L16 skickar den genom `tx_shift_reg` som
vilket annat stoppat fält som helst. Hoppa över den här, och mottagaren kör hela ramen en dominant
bit efter sändaren.

Det är inte något litet fönster. Varje identifierare vars fyra översta bitar är noll, alltså
**varje ID under `0x080`**, ger SOF plus fyra dominanta identifierarbitar: sändarens följd når fem
och den sätter in en stoppbit, medan en mottagare som missade SOF bara står på fyra, inte väntar
sig någon, och tar den för en riktig bit. Allt efter den är förskjutet. Felet dyker upp långt senare
som ett CRC-fel eller ett stoppbitsbrott, och det slår mot precis de högprioriterade identifierare
som en riktig design reserverar för sina viktigaste meddelanden.

Regeln under det är värd att formulera för sig: **båda följdspårarna måste se exakt samma bitar, SOF
till och med slutet av CRC-fältet, och inget annat.** Svansen utesluts på båda sidor eftersom inget
av skiftregistren är aktiverat för den. Över *ramgränser* är däremot "samma bitar" ingen garanti som
designen kan luta sig mot alls, vilket är nästa avsnitt.

`STATE_SOF` behöver inget föregripande för det här. `STATE_START` pulsar `bt_resync`, så SOF-bitens
sampelpunkt ligger ett helt `SAMPLE_TICK` framåt (L12); tillståndsmaskinen är med god marginal inne
i `STATE_SOF` vid det laget, och en vanlig kombinatorisk enable räcker.

---

### Ett rent bord mellan ramar
Följdspårarna nollställs bara av sin reset (L14, L15), och inom en och samma ram är den
beständigheten precis rätt. Låt den sträcka sig *över* ramgränser, och en subtil asymmetri dyker
upp: en spårares tillstånd vid SOF beror nu på vilka bitar just den noden råkade skicka genom den
tidigare, och olika noder har olika historia. En nod som sände den förra ramen avslutar den med sin
`tx_shift_reg`-spårare hållande CRC-fältets svans; en nod som bara tog emot håller den historien i
sin `rx_shift_reg`-spårare i stället, och dess sändarspårare visar fortfarande vad nu dess *egen*
senaste sändning lämnade, eller ingenting alls efter reset.

Låt nu två sådana noder börja sända vid samma SOF, vilket är precis vad arbitrering finns till för.
Identiska identifierarbitar kommer ut ur båda, men noden som bär på en kvarlämnad följd når fem lika
bitar *tidigare* och sätter in sin stoppbit en position före den andra noden. På den positionen
sänder den en recessiv stoppbit medan den andra noden fortfarande sänder en riktig dominant bit;
wired-AND:en läser dominant, den stoppande noden sänder recessivt inne i arbitreringsfältet, och den
drar slutsatsen att den förlorat arbitreringen. Ingen tvist ägde rum: den *blivande vinnaren* går
ifrån sin egen ram med `error` höjd. Det här är inte hypotetiskt; det är precis så
`can_controller_tb`s fall 2 misslyckas om spårarna lever kvar, med nod A som går in i det
fortfarande hållande svansen av fall 1:s CRC.

Riktig CAN har inget sådant fel, eftersom stoppbitsräkningen börjar om från noll vid varje SOF, och
den här designen får samma garanti med en enda signal: båda skiftregistren **hålls i reset medan
bussen är ledig**, så varje ram börjar med rena spårare på varje nod, vad var och en än gjorde
innan.

Konkret betyder det en egen, aktivt låg reset för skiftregistren, konkurrent tilldelad: låg när
`reset_s2_n` är låg **eller** tillståndsmaskinen står i `STATE_IDLE`, hög annars. Båda
skiftregisterinstanserna från L14 och L15 kopplar sin resetport, den andra i deras portlistor, till
den signalen i stället för till `reset_s2_n`. Ingenting annat i instansieringarna ändras.

Reseten släpper på den flank som lämnar `STATE_IDLE`, en hel cykel innan SOF-laddningen klockas in
i `tx_shift_reg`, så registren är vakna i tid inför varje ram. Lägg märke till vad det här *inte*
ändrar: inom en ram nollställs aldrig något, så det kedjade omladdningsbeteende som L14:s test 3
låser fast (en följd som fortsätter över en gruppgräns) är orört, och argumentet om SOF-hoppet ovan
står sig bit för bit. Det rena bordet börjar vid `STATE_IDLE`, och `STATE_IDLE` går bara att nå
mellan ramar.

---

### Att mata `crc15` på mottagarsidan
Spegelbilden av L16:s grindning på sändarsidan: aktivera `crc15` på `rx_shift_reg.real_bit_valid`
(som redan utesluter både "ingen ny bit än" och varje kastad stoppbit), matad med
`rx_shift_reg.real_bit`, över SOF till och med CRC-fältet. Att mata tillbaka det mottagna
CRC-fältets egna bitar återför registret till exakt noll om ramen kom fram intakt (L13:s
generera-och-sedan-kontrollera), vilket rapporteras av `crc_valid`.

Det finns en `crc15` och en enable, så det här ersätter L16:s regel i stället för att stå vid sidan
av den. `role` väljer nu källa i stället för att stänga av motorn.

Det här är det enda stället i appendixet där formen på koden är given, och skälet är bygget, inte
designen: `make build-project` avgör om kontrollern har en mottagarväg genom att leta efter just de
här två uttrycken i `can_controller.vhd` (se
[`controller/README.md`](../../../controller/README.md)). Stavar ni dem annorlunda hoppas
`can_controller_tb` över i stället för att köras. Skriv dem så här:

```vhdl
crc_enable  <= (txsr_bit_valid and not txsr_stuff and role) or
               (rxsr_real_bit_valid and not role);
crc_data_in <= txsr_tx_bit when role = '1' else rxsr_real_bit;
```

Låt L16:s version stå kvar, och en mottagande nod ackumulerar aldrig något, så `crc_valid` läser
`'1'` (resetvärdet) hela vägen och kontrollen i `STATE_CRC_LO_WAIT` passerar för varje ram,
korrumperad eller inte.

`crc_clear` berörs inte av något av det här och står kvar exakt som L16 skrev den, en puls i
`STATE_START` oavsett roll. Den spelar större roll nu än den gjorde då: det är i den här
föreläsningen noden får tre sätt att gå ur en ram i förtid, och vart och ett lämnar motorn mitt i
ett meddelande den aldrig kommer att avsluta. Ingen av avbrottsvägarna nedan behöver nollställa den
på vägen ut, eftersom nästa ram nollställer den på vägen in.

---

### Väntan på ett extra sampel - den avgörande tajminglärdomen
På sändarsidan lägger `tx_shift_reg.done` redan en extra bitperiod på att låta en grupps sista bit
löpa ut innan nästa grupp laddas. En mottagare reagerar på `rx_shift_reg.valid` utan någon sådan
inbyggd väntan, så `can_controller` måste lägga till den uttryckligen vid vart och ett av
RX-sidans `STATE_LOAD_*`-tillstånd: **vänta på ytterligare ett `bt_sample`** innan den går vidare,
eftersom ledningen fortfarande visar förra gruppens sista bit under hela dess avslutande period.

Det finns en andra hake: `state` blir skifttillståndet först **en cykel efter** det `bt_sample` som
utlöste övergången, en cykel för sent för att aktivera `rx_shift_reg` för just det samplet. Därför
**föregriper** det kombinatoriska styrblocket `rxsr_enable` (och sätter den kommande gruppens
`bit_count`) för exakt det samplet medan det fortfarande står i `STATE_LOAD_*`-tillståndet.

**Hur det ser ut cykel för cykel.** Här är en gruppgräns på mottagarsidan, där den 8 bitar breda
höga ID-gruppen lämnar över till den 4 bitar breda gruppen med låga ID plus RTR. Cyklerna är
50 MHz-klockans, så de två `bt_sample`-pulserna ligger 50 cykler isär; följden av identiska cykler
mellan dem är utelämnad.

```text
klockcykel     bt_sample             state  rxsr_bit_count  rxsr_enable  rxsr_valid
n                      0         STATE_ARB_HI               8            1           0
n + 1                  1         STATE_ARB_HI               8            1           0
n + 2                  0         STATE_ARB_HI               8            1           1
n + 3                  0    STATE_LOAD_ARB_LO               4            1           0
...                    0    STATE_LOAD_ARB_LO               4            1           0
n + 51                 1    STATE_LOAD_ARB_LO               4            1           0
n + 52                 0         STATE_ARB_LO               4            1           0
```

Läs de två sampelcyklerna mot varandra. Vid **n + 1** tas den åttonde biten av den höga ID-gruppen,
och `rxsr_valid` dyker upp en cykel senare vid **n + 2**, vilket är när tillståndsmaskinen bestämmer
sig för att gå vidare. `state` läser inte `STATE_LOAD_ARB_LO` förrän vid **n + 3**.

Titta nu på **n + 51**, samplet som måste fånga den *första* biten av den låga ID-gruppen. `state`
läser fortfarande `STATE_LOAD_ARB_LO` i det ögonblicket. Den blir inte `STATE_ARB_LO` förrän vid
**n + 52**, en cykel efter att biten redan kommit och gått. Det är hela problemet på en rad:
tillståndet som namnger gruppen anländer alltid en cykel senare än samplet som startar den.

Föregripandet är det som gör `rxsr_bit_count = 4` och `rxsr_enable = '1'` sanna vid **n + 51** ändå,
genom att driva dem från `STATE_LOAD_ARB_LO`-armen i stället för `STATE_ARB_LO`-armen. Driv dem från
`STATE_ARB_LO` i stället, och samma gräns ser ut så här:

```text
klockcykel     bt_sample             state  rxsr_bit_count  rxsr_enable  rxsr_valid
n + 3                  0    STATE_LOAD_ARB_LO               0            0           0
...                    0    STATE_LOAD_ARB_LO               0            0           0
n + 51                 1    STATE_LOAD_ARB_LO               0            0           0
n + 52                 0         STATE_ARB_LO               4            1           0
```

`rx_shift_reg` är avstängt över det enda sampel som spelade roll. Den första biten av
identifierarens låga grupp samlas aldrig in, så gruppen blir färdig en bit kort mot ledningen,
varje senare grupp är förskjuten med en, och `crc15` matas med en ström som aldrig stämmer.
Ingenting rapporterar något fel vid **n + 51**; felet dyker upp vid `STATE_CRC_LO_WAIT`, ungefär
fyrtio bitperioder senare, som en CRC som inte går till noll.

Lägg märke till att det här inte kostar något extra på ledningen. `STATE_LOAD_ARB_LO` förbrukar
redan förra gruppens avslutande bitperiod, vilket är varför den går vidare på `bt_sample` och samlar
inget eget; föregripandet ställer bara registret i rätt konfiguration innan den perioden är slut.

Det här mönstret upprepas vid varje gruppgräns och är designens allra viktigaste lärdom: **en signal
som ser "klar" ut en cykel för tidigt eller för sent tar inte ut sig själv över gruppgränserna; den
ackumuleras till en tyst felinriktning** mellan sändare och mottagare som först långt senare dyker
upp som ett CRC-fel eller ett stoppbitsbrott, långt ifrån sin orsak.

---

### Detektering av förlorad arbitrering
Exakt L10:s regel, kontrollerad en gång per bit vid sampelpunkten enbart under
`STATE_ARB_HI`/`STATE_ARB_LO`, vilket är precis arbitreringsfältet, ID plus RTR. Unika ID:n
garanterar att arbitreringen avgörs inom den 11 bitar långa identifieraren; kontrollen täcker
harmlöst även RTR, där varje nod här sänder dominant, en bit som aldrig kan förlora.

I `STATE_ARB_HI` och `STATE_ARB_LO`, medan `role = '1'`, har noden förlorat när
`bt_sample = '1'`, `txsr_tx_bit = '1'` och `rx_bus_s2 = '0'`: den sände recessivt och läser
dominant. På den flanken:
* `error` går till `'1'`.
* `tx_done` pulsar: försöket är över, vunnet eller förlorat.
* `role` går till `'0'` och `idle_bits` till 0.
* Tillståndsmaskinen går tillbaka till `STATE_IDLE`.

Att kontrollen bara gäller medan `role = '1'` är det som avgränsar den till en sändande nod; de tre
termerna är själva avkänningsvillkoret, och det är dem övning 2 ber er gå igenom bit för bit.

**Varför `tx_done` pulsar även här, på en ram som aldrig sändes.** Det läser fel först: `tx_done`
betyder "ramen blev klar", och det blev den här inte. Läs den i stället som *"sändningsförsöket är
över, och porten är er igen"* - vilket är den enda fråga en anropare kan agera på. `error` är det
som säger om försöket lyckades, och tillsammans bär de två hela utfallet: `tx_done` ensam betyder
sänd, `tx_done` med `error` betyder förlorad.

Utelämna den, och anroparen har ingen flank alls att vänta på. En nod som förlorar arbitreringen
återvänder till `STATE_IDLE` och är fullt kapabel att sända igen, men ingenting annonserar det
någonsin, så varje anropare som väntar på `tx_done` innan den begär om väntar för evigt. Det är inte
hypotetiskt: det är precis så [`register_bank`](../../L18/appendix/a_register_bank.md) sätter sin
TX-redo-bit, och utan den här pulsen skulle en enda förlorad arbitrering - normalfallet på en buss
med två noder - lämna hela noden oförmögen att sända tills den resettades. Se
[projektspecifikationen, avsnitt 6.7](../../../project/README.md).

Lägg märke till att det är `rx_bus_s2`, den synkroniserade kopian, och inte porten `rx_bus`. L11:s
regel gäller överallt, den här jämförelsen inräknad: ingenting i designen läser den råa pinnen. Det
vore lätt att prata sig ur den här, eftersom sampelpunkten ligger 35 tick in i en bit som
stabiliserade sig nära tick 0, så nivån är med säkerhet stabil vid det laget. Det argumentet handlar
om *när* värdet är stabilt på ledningen, och metastabilitet handlar om vad en vippa gör när den
samplar en signal som ingen klocka i det här chippet styr. De två extra vipporna kostar två
klocktick av femtio och köper den enda jämförelse hela arbitreringsupplägget vilar på.

Att nollställa `idle_bits` är inte städning i bokföringen. Utan den landar noden tillbaka i
`STATE_IDLE` med `idle_bits` fullt medan vinnaren är mitt i sin ram, så vinnarens nästa dominanta
bit läses som ett nytt SOF, noden går in i `STATE_START`, och `STATE_START` suddar den `error` den
just höjde. Samma nollställning krävs vid varje annat avbrott nedan, av samma skäl.

---

### Att färdigställa processerna
Ingenting från L16 skrivs om. Varje ställe där L16 lämnade mottagarrollen till den här
föreläsningen fylls i enligt tabellen i "Mottagarvägen, tillstånd för tillstånd", och reglerna nedan
är de som inte ryms i tabellen. När de alla är på plats är de två processerna färdiga, och
`can_controller_tb` har äntligen något att döma om.

**Den kombinatoriska processen** får två tillägg, och `crc_valid` behöver in i dess
känslighetslista, eftersom kvitteringen läser den:

* **Föregripandet.** När `role = '0'` driver processen `rxsr_enable = '1'` och `rxsr_bit_count`
  enligt tabellens kolumn *Föregriper*: i `STATE_SOF` med bredden 1, och i varje stoppat fält i
  **både** `STATE_LOAD_*`-tillståndet och dess skifttillstånd. I alla andra tillstånd gäller
  förvalen från L16. Att paret delar samma värde är det som gör föregripandet automatiskt: det
  `bt_sample` som faller medan `state` fortfarande läser `STATE_LOAD_*` samlas in med den kommande
  gruppens bredd, precis som "Väntan på ett extra sampel" härledde.
* **Kvitteringen.** I `STATE_ACK_SLOT`, när `role = '0'` och `crc_valid = '1'`: `bus_en = '1'` och
  `tx_bus = '0'`. Det är den enda bit en mottagare någonsin driver.

**Den sekventiella processen.** Mottagarhalvan av varje tillstånd följer en av två former, och
tabellen säger vilken:

* Ett mottagande `STATE_LOAD_*`-tillstånd går vidare till sitt skifttillstånd på nästa `bt_sample`,
  och gör inget annat.
* Ett mottagande skifttillstånd går vidare på `rxsr_valid` och skördar sin grupp enligt tabellens
  sista kolumn. `STATE_CRC_HI` och `STATE_CRC_LO` skördar ingenting: deras bitar når `crc15` en i
  taget genom `real_bit`, och de hopsatta grupperna betyder ingenting.

Tre regler till, som tabellen inte uttrycker:

* **Arbitreringskontrollen och `done`.** I `STATE_ARB_HI` och `STATE_ARB_LO` har
  sändarhalvan nu två villkor: förlorad arbitrering enligt föregående avsnitt, och `txsr_done` som i
  L16. De två kan aldrig slå till samma cykel, eftersom `bt_sample` ligger mitt i perioden och
  `done` följer ett `bit_done`, så ordningen handlar om läsbarhet snarare än prioritet; en förlust
  på en grupps sista bit vinner ändå helt enkelt genom att komma först, vid den bitens sampelpunkt.
* **Två läsningar före flanken**, båda samma regel som L14:s `MAX_RUN - 1`. `STATE_CTRL` avgör
  DLC-grenen direkt utifrån `rxsr_data(3 downto 0)`, eftersom `rx_dlc_acc` tilldelas på just den
  flanken och fortfarande läser den förra ramens värde. Och `STATE_DATA` jämför mot `rx_dlc_acc`,
  som vid det laget *är* stabil, låst ett helt fält tidigare.
* **Ett stoppbitsbrott avbryter från vilket tillstånd som helst.** När `role = '0'` och
  `rxsr_stuff_error = '1'`: `error` till `'1'`, `idle_bits` till 0, och tillbaka till `STATE_IDLE`.
  Regeln måste vinna över vad tillståndets egen regel bestämde på samma flank, vilket är hela
  poängen: ett brott är fatalt var det än slår till, och ett sampel kan slå till i vilket som helst
  av tillstånden för stoppade fält, LOAD-tillstånden inräknade (deras föregripna sampel behandlas
  som vilket annat som helst). I en klockad process är det den sista tilldelningen till en signal
  som gäller, så att skriva regeln en gång, efter alla tillstånd, är bättre än att upprepa den i ett
  dussin.

---

### Att kvittera, kontrollera och avbryta
* **ACK-luckan:** en mottagare vars `crc_valid` är satt driver bussen dominant under den enda biten
  för att kvittera ramen.
* **CRC-kontrollen:** i `STATE_CRC_LO_WAIT` läser en mottagare `crc_valid`. Är den satt väntar den
  på `bt_bit_done` (de avslutande ostoppade fälten räknar hela perioder) och går sedan vidare till
  `STATE_CRC_DELIM`; är den det inte avbryter den: `error <= '1'`, `idle_bits <= 0`, tillbaka till
  `STATE_IDLE`.
* **Stoppbitsbrott:** `rx_shift_reg.stuff_error` avbryter mottagningen från vilket tillstånd som
  helst (`error <= '1'`, `idle_bits <= 0`, `STATE_IDLE`). En sändare kan inte bryta mot
  stoppbitsregeln, så det här gäller bara RX.
* **Arbitreringsförlust** är det enda avbrott som sker under *sändning*, och därmed det enda som
  också pulsar `tx_done`. Avbrotten på mottagarsidan ovan avslutar en mottagning, och en mottagning
  har ingen anropare som väntar på en färdigpuls: `rx_valid` uteblir helt enkelt, vilket är precis
  rätt, eftersom ingen ram anlände.
* **`error` ligger kvar:** nollställd i `STATE_START`, hållen i övrigt, så att en anropare ser den
  ända tills nästa ram börjar.
  * Det är precis därför `STATE_IDLE` kräver en **ledig buss** innan noden lämnar det tillståndet
    över huvud taget, för att sända eller ta emot (L16 Appendix A), och varför varje avbrott här
    måste nollställa `idle_bits` på vägen ut. Varje avbrott landar tillbaka i `STATE_IDLE` mitt i
    en ram, medan bussen fortfarande är upptagen. Utan kravet på ledig buss skulle noden gå in i
    `STATE_START` igen inom några få bitperioder och sudda den `error` den höjde, så att en anropare
    som pollar `error` aldrig skulle se den. Att först kräva elva recessiva bitperioder är exakt den
    garanti som "ända tills nästa ram börjar" utfärdar.

---

### Att verifiera den - `can_controller_tb`
Nu när mottagarvägen är komplett körs `controller/can_controller_tb.vhd` äntligen hela vägen. Den
kopplar **två** `can_controller`-noder till en enda buss med öppen dränering, kombinerar varje nods
par `(tx_bus, bus_en)` på det sätt L10 beskrev en wired-AND, och kör två fall.

**Fall 1, mottagning.** Nod A sänder ID `0x123`, DLC 5, data `11 22 F8 44 55` medan nod B tar emot.
Den kontrollerar `tx_done` och `rx_valid`, och att B återskapar ID:t, DLC:n och **varje** databyte
på sin fasta position. Byten `0xF8` är vald för att tvinga fram en stoppbit inne i datafältet, så
det här övar sändvägen, mottagarvägen, avstoppningen och flerbytesplaceringen i en och samma ram. En
ensam nod kan inte testa något av det: `rx_shift_reg` är aktivt bara medan `role = '0'`, så en
sändare tar aldrig emot sin egen ram.

**Fall 2, arbitrering.** Båda noderna begär under samma cykel, A med ID `0x000` och B med `0x001`,
åtskilda bara i den sista identifierarbiten. B måste upptäcka förlusten på exakt den biten och sluta
driva bussen; A måste bli klar som vanligt, ovetande om att en tvist ägt rum. Den sista assertionen
är den att lägga märke till: den läser B:s `error` *efter* att A:s ram blivit klar, så den faller om
inte både den kvarliggande `error` och disciplinen kring `idle_bits` ovan håller. Det här är
kontrollen som avsnittet "Att kvittera, kontrollera och avbryta" finns till för att uppfylla.

---

### Vad som kommer härnäst
L18 kapslar in den här kontrollern i registerbanken som gör dess pulser pollbara, och L19 sätter
SPI-transporten framför den och gör bring-up på hela noden på DE0-CV som `can_spi_node`. L19
dissekerar också hur den här testbänken modellerar en delad buss, och redogör för vad en
produktions-CAN-kontroller gör som den här inte gör.

---

