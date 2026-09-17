# Appendix C

## Övningar
Övningarna är upplagda så här:
* **Övning 1** slår bron mellan ramningsintroduktionens ramformat och CAN.
* **Övning 2-6** befäster [Appendix A](./a_can_frame_format.md):
  * De görs på papper, och bygger upp till att sätta ihop en hel ram för hand.
* **Övning 7** läser det utdelade paketet `can_def` mot [Appendix B](./b_can_def_package.md), och
  arbetar sedan mot det vid tangentbordet.

---

## Övning 1 - Samma ram, fast som CAN
Ta den `StatusResp`-ram ni byggde för hand i ramningsövningarna, del I(b), och skicka den som en
CAN-ram i stället.

Dess fält, som påminnelse:
* `TYPE = StatusResp`
* `DST = 0x17`
* `SRC = 0x25`
* `SEQ = 0x7F05`
* Nyttolast:
  * 2 byte.
  * Värdet `0x3201`.

Utgå från konventionen i Appendix A:s exempel om broadcast i stället för adressering:
identifieraren kombinerar en bas per typ med id:t för den sensornod meddelandet gäller, alltså den
nod som frågas i en förfrågan och den nod som svarar i ett svar (nod 3 frågas på `0x303` och svarar
på `0x403`):

```text
ID = TYPE_BASE + nodeId
```

Typbaserna är:
* `StatusReq = 0x300`
* `StatusResp = 0x400`
* `Ping = 0x500`
* `Pong = 0x600`

**a)** Skriv motsvarande CAN-ram på följande form:

```text
ID | DLC | DATA
```

**b)** Ange vilka fält i ramningsintroduktionens ram som saknar motsvarighet i CAN-ramen.

För varje saknat fält:
* Säg vad CAN gör i stället.
* Eller förklara varför CAN inte behöver något motsvarande fält.

**c)** Anta att två noder börjar sända på CAN-bussen i exakt samma ögonblick.

Förklara kort:
* Hur bussen avgör vilken nod som fortsätter sända.
* Hur den förlorande noden upptäcker att den har förlorat.

Det här är arbitreringsmekanismen som beskrivs i Appendix A; återge den med egna ord.

**d)** Förklara varför det inte finns något separat checksummefält att fylla i när man
konstruerar en CAN-ram, till skillnad från ramningsintroduktionens ramformat.

---

## Övning 2 - Bitstoppning för hand
**a)** Tillämpa stoppbitsregeln på följande 10-bitarssekvens:

```text
0011111111
```

Skriv den kompletta sända bitströmmen:
* Ta med alla ursprungliga bitar.
* Markera varje instoppad stoppbit tydligt.

**b)** En mottagare observerar följande sända ström på 9 bitar:

```text
101111101
```

Mottagaren vet att bitstoppning är i bruk.

Avstoppa strömmen:
* Identifiera eventuella stoppbitar.
* Ta bort dem.
* Återskapa den ursprungliga följden av riktiga databitar.

**c)** En mottagare observerar sex dominanta (`0`) bitar i rad på ett ställe där en stoppbit skulle
ha brutit en följd av fem.

Förklara:
* Vad mottagaren drar för slutsats.
* Vad mottagaren bör göra härnäst.

**d)** Appendix A påpekar att räknaren för lika bitar i rad inte nollställs vid fältgränser.

Anta att ett fält slutar med tre lika bitar och att nästa börjar med två till av samma värde. Använd
regeln och:
* Säg var stoppbiten hamnar, räknat från fältgränsen.
* Förklara varför inget av fälten på egen hand skulle ha orsakat den.

---

## Övning 3 - Att avkoda en riktig bitström
En mottagare observerar följande ström på 21 bitar:

```text
0 00000010101 0 00 0010 11
```

Strömmen är redan avstoppad, så att den här övningen håller fokus på fältens uppdelning i stället
för på stoppningen.

Mellanrummen finns bara med för läsbarhetens skull:
* Den riktiga CAN-bussen har inga glapp mellan fälten.

**a)** Dela upp strömmen i dess namngivna fält, med bredderna som Appendix A definierar:
* SOF
* ID
* RTR
* IDE
* r0
* DLC

Bestäm sedan:
* Identifieraren i hexadecimal form.
* DLC-värdet.
* Vilket fält som har börjat i de två bitar som blir över när alla namngivna fält är avräknade.

**b)** Bestäm utifrån DLC:n från (a):
* Hur många databitar mottagaren förväntar sig totalt.
* Hur många ytterligare databitar som återstår innan CRC-fältet börjar.

**c)** Anta att DLC i stället hade varit:

```text
0000
```

Vilket fält skulle då följa omedelbart efter kontrollfältet?

---

## Övning 4 - Arbitrering mellan tre noder
Tre noder försöker sända vid samma SOF:
* Nod R:
  * ID `0x155`
* Nod S:
  * ID `0x154`
* Nod T:
  * ID `0x1D5`

**a)** Arbeta igenom arbitreringen bit för bit, i samma stil som Appendix A:s genomräknade exempel.

Bestäm:
* Vilken nod som vinner.
* Vid vilken identifierarbit varje förlorande nod faller ur.

**b)** De två förlorande noderna faller ur vid olika bitpositioner.

Förklara varför genom att ange:
* Var varje förlorande nods identifierare först skiljer sig från vinnarens identifierare.
* Varför just den första avvikande biten avgör när noden förlorar arbitreringen.

**c)** En förlorande nod måste sluta driva bussen, och den intressanta frågan är *när*. (L11
introducerar portparet `tx_bus`/`bus_en` som kursens kontroller slutar driva med, och L16-L17 bygger
logiken; här resonerar ni på protokollnivå.)

Förklara, med en eller två meningar:
* Vad varje förlorande nods `can_controller` måste göra på allra första klockcykeln efter att den
  upptäckt avvikelsen.
* Varför den tajmingen spelar roll.

**Ledtråd:** Tänk igenom vad "ögonblicket" betyder i Appendix A:s genomräknade arbitreringsexempel.

---

## Övning 5 - Resonemang om sampelpunkten
Den här kursen samplar varje bit 70 % in i bitperioden.

Den samplar inte vid:
* 0 %, allra först i perioden.
* 100 %, allra sist i perioden.

**a)** Förklara vad som skulle kunna gå fel om en mottagare samplade vid 0 %.

Utgå från:
* Signalutbredning.
* Varför en bitperiod behöver en minsta varaktighet.
* Om det sända värdet har hunnit stabilisera sig.

**b)** Förklara vad som skulle kunna gå fel om en mottagare samplade vid 100 %, på den sista möjliga
klockpulsen.

Gör förklaringen specifik för att det i kursens design gäller att:
* Varje nod har sin egen lokala bittimer.
* Timern omsynkroniseras bara vid SOF.
* Den omsynkroniseras aldrig mitt i ramen (riktig CAN omsynkroniserar på flanker även mitt i ramen;
  kursens kontroller gör inte det).

**c)** Arbitrering kräver att varje konkurrerande nod läser bussen under *samma* bitperiod som den
driver den.

Förklara:
* Varför en sampelpunkt för nära periodens början är riskabel.
* Varför en sampelpunkt för nära periodens slut är riskabel.
* Varför faran växer ju längre in i ramen man kommer.

Appendix B gör 70 %-sampelpunkten till den konkreta konstanten `SAMPLE_TICK`, och övning 7 upprepar
uträkningen för andra kombinationer av klockfrekvens och CAN-bithastighet.

---

## Övning 6 - Att konstruera en CAN-ram för hand
Övning 2-5 arbetade med enskilda regler. Den här sätter ihop en komplett ram utifrån Appendix A:s
ramdiagram, på samma sätt som ni satte ihop ramningsintroduktionens ram i den föreläsningens del I.

**En anmärkning om CRC:n.** Ni får CRC-15-värdet för varje ram nedan. Att räkna ut en 15-bitars CRC
över drygt 30 bitar för hand är mekaniskt snarare än lärorikt; i L13 arbetar ni igenom rekursionen
ordentligt, över en 4-bitarssekvens, när motorn i sig är ämnet.

**a)** Ta CAN-ramen ni tog fram i övning 1: `ID = 0x425`, `DLC = 2`, data `32 01`.

Skriv ut varje fält som bitar, i sändningsordning, med Appendix A:s bredder:
* SOF
* ID (11 bitar, MSB först)
* RTR
* IDE och r0
* DLC
* Data (MSB först, byte 0 först)
* CRC (given: `010101100100011`)
* CRC-avgränsare, ACK-plats, ACK-avgränsare, EOF

**b)** Hur många bitar blir det totalt, före all stoppning?

**c)** Tillämpa nu stoppbitsregeln från övning 2 över SOF till och med CRC-fältet, och kom ihåg att
följdräknaren inte nollställs vid fältgränser. Hur många stoppbitar sätts in, och hur många bitar
upptar ramen på ledningen?

**d)** Vid kursens bithastighet på 1 Mbit/s, hur lång tid tar det att sända den ramen?

**e)** Upprepa (a) till (d) för en ram **utan nyttolast**: `ID = 0x100`, `DLC = 0`, CRC
`011100000001010`. Notera vilka delar av ramen som är strukturellt oförändrade trots det saknade
datafältet, och var CRC-fältet nu börjar.

**f)** Jämför era två svar på (c). Den andra ramen bär ingen data alls, och ändå behöver dess
stoppade område *fler* stoppbitar än den första. Förklara varför, utifrån vad stoppbitsregeln
faktiskt reagerar på.

---

## Övning 7 - Att arbeta med paketet
Varje konstant i `can_def` går att spåra tillbaka till något den här föreläsningen definierat. De
här frågorna läser paketet, kontrollerar att härledningarna håller när indata ändras, och utökar en
kopia av det med värden som Appendix A namngav men som paketet ännu inte håller.

**a)** Läs det utdelade `controller/can_def.vhd` med Appendix B vid sidan. Säg för varje konstant
var i Appendix A den kommer ifrån, och dela upp dem i de som är satta och de som är uträknade ur
andra konstanter. Vilka två av de uträknade skulle bli tyst fel, utan att något klagade vid analys,
om de skrevs in som tal och någon sedan ändrade klockfrekvensen?

Paketet delas ut i sin helhet i stället för som en specifikation, och det av två skäl värda att
nämna: ett paket innehåller inget beteende att designa, så det finns
ingenting mellan värdena och koden för er att lista ut, och de utdelade testbänkarna läser dess
namn och typer, så det är en del av kontraktet. Det nya här är själva VHDL-koden, eftersom en
paketdeklaration är en konstruktion kursen inte använt tidigare. Namnen är de kommande åtta
föreläsningarnas vokabulär, och att ha läst dem en gång, ordentligt, är billigare än att slå upp
dem åtta gånger.

Gör (e) och (f) i en kladdkopia av paketet, utanför det som blir gruppens repo: det utdelade paketet
läggs in oförändrat.

**b)** Anta att DE0-CV:ns klocka vore 40 MHz i stället för 50 MHz, med bithastigheten fortfarande
1 Mbit/s. Räkna om `TICKS_PER_BIT` och `SAMPLE_TICK` (fortfarande 70 %).

**c)** Anta i stället att klockan ligger kvar på 50 MHz men att bussen körs på 125 kbit/s, en
verklig CAN-hastighet för "low speed". Räkna om båda konstanterna.

**d)** `TICKS_PER_BIT` är `CLOCK_FREQ_HZ / BIT_RATE_HZ`, med VHDL:s heltalsdivision för `natural`,
som trunkerar. Ge ett par av klocka och bithastighet där divisionen *inte* går jämnt ut, och
förklara med en mening varför det vore ett problem för den här designen, trots att VHDL-koden
fortfarande skulle kompilera och elaboreras utan invändningar.

**e)** Lägg till en konstant `BIT_PERIOD_NS`, längden på en CAN-bitperiod i nanosekunder, härledd ur
`BIT_RATE_HZ` i stället för hårdkodad. Ange sedan sambandet mellan den, `TICKS_PER_BIT` och
50 MHz-systemklockans periodtid på 20 ns, och bekräfta att de tre stämmer överens.

**f)** Appendix A anger CRC-avgränsaren, ACK-fältet och EOF som 1, 2 respektive 7 bitar, men paketet
håller ingen av dem: `can_controller` kommer att använda de talen som nakna literaler. Lägg till
`CRC_DELIM_BITS`, `ACK_BITS` och `EOF_BITS`, och säg vilken av de två formerna en senare läsare är
bäst betjänt av.

**g)** Kontrollera att paketet faktiskt kompilerar. Installera GHDL om ni inte redan gjort det (se
[referensen för simuleringsflödet](../../../info/simulation_workflow.md), avsnitt 2), och kör sedan
`make build-project` från roten av kursrepot. Ni bör se:

```text
--> controller/can_def.vhd analyzes cleanly
```

följt av de två utdelade `bridge/`-filerna, och därefter varje testbänk rapporterad som överhoppad,
eftersom modulerna de kontrollerar inte finns ännu:

```text
0 testbench(es) run, 9 skipped.
```

Gör nu sönder något med flit i paketet, ett saknat semikolon eller en felstavad typ, kör om, och läs
vad GHDL säger om det. Ställ tillbaka det, så att filen är exakt som den delades ut.

Det här är hela verifieringsberättelsen för ett paket: ett paket har inget beteende att simulera, så
"den analyseras" är allt som finns att kontrollera. L11 introducerar verktyget ordentligt, och
därifrån får varje modul en testbänk också.

---

