# Appendix C

## Övningar
Övning 1, 2 och 7 befäster [Appendix A](./a_system_verification.md). Övning 3 till 6 befäster
[Appendix B](./b_fpga_bringup_and_review.md) och
[protokollspecifikationen](../../../project/spi_register_protocol.md), som är auktoriteten överallt
där den och en övning är oense.

---

## Övning 1 - En tredje nod, och ett nytt arbitreringsutfall
**a)** Utöka `can_controller_tb.vhd` med en tredje nod, C, som delar samma `bus_line`. Ge C ID:t
`0x002` och låt den begära sändning på samma cykel som nod A (`0x000`) och B (`0x001`). Bekräfta
(genom simulering, inte bara förutsägelse) att A fortfarande vinner, och att *både* B och C
upptäcker arbitreringsförlust.

**b)** Nod A:s `0x000` är den lägsta identifierare en standardram kan bära, så inget val av ID låter
C slå den. Höj A:s ID till `0x010`, och välj sedan ett ID till C som gör C till vinnare medan B
(`0x001`) fortfarande förlorar. Motivera ert val med L10:s arbitreringsregel, och bekräfta sedan
den nya vinnaren i simulering. En följd att lägga märke till innan era assertions överraskar er:
med A på `0x010` slår B:s `0x001` även A, så i den här omgången **förlorar A också** och höjer
`error`; bara C fullföljer.

---

## Övning 2 - En funktion ur en riktig kontroller, som designskiss
Välj **en** post ur Appendix B:s lista över vad riktiga CAN-kontrollrar gör som den här designen
inte gör. Skissa, utan att nödvändigtvis implementera den i VHDL, (i prosa, plus ett tillägg i
tillståndsdiagrammet eller en ny portlista om det hjälper) vad som skulle behöva ändras i
`can_controller` för att stödja den. Ange vilket eller vilka befintliga block (`bit_timer`, `crc15`,
`tx_shift_reg`/`rx_shift_reg`, eller `can_controller` självt) som skulle behöva ändras, och vilka
som kunde stå exakt som de är.

---

## Övning 3 - Implementera om `spi_reg_bridge.vhd` utifrån specifikationen
Skriv er egen `spi_reg_bridge.vhd` utifrån protokollspecifikationens avsnitt om transaktioner och
portlistan i [projektspecifikationen](../../../project/README.md). Verifiera den:

```bash
cd bridge
ghdl -a --std=93 spi_def.vhd spi_reg_bridge.vhd spi_reg_bridge_tb.vhd
ghdl -e --std=93 spi_reg_bridge_tb
ghdl -r --std=93 spi_reg_bridge_tb --assert-level=error
```

Testbänken modellerar `spi_slave` i stället för att instansiera den: den pulsar `rx_valid` en gång
per byte, inramat av `ss_active`, så att ni kan skriva och kontrollera bryggan innan någon
SPI-vågform är inblandad.

**a)** Få alla fyra fallen att passera. Fall 3 och 4 är de två som gör den här modulen till mer än
en byteräknare - läs deras kommentarer innan ni börjar, inte efteråt.

**b)** Gör nu sönder den med flit. Ta bort varje användning av `ss_active` och räkna bytes modulo
fem i stället. Fall 1 och 2 passerar fortfarande. Säg vilken kontroll i fall 3 som fallerar, citera
värdet som felmeddelandet rapporterar, och förklara var de bytesen kom ifrån.

**c)** En brygga som ignorerar de reserverade kommandobitarna passerar också fall 1 och 2. Förklara
varför protokollspecifikationen lägger regeln om reserverade bitar i *det här* lagret i stället för
i `register_bank`, givet att banken aldrig ser mer än ett 4-bitars index.

**d)** Läsvägen låser `reg_rdata` **en gång**, vid slutet av kommandobyten. Säg vad `register_bank`
skulle behöva göra i stället om bryggan läste det på nytt för varje databyte, och varför det vore
fel plats att skjuta ner regeln i banken. Ställ tillbaka modulen.

---

## Övning 4 - Komponera `can_spi_node.vhd`
Skriv toppnivån utifrån Appendix B: `spi_slave`, `spi_reg_bridge`, `register_bank` och
`can_controller`, plus en `meta_prev` för reseten.

**a)** Skriv den, och kör `can_spi_node_tb` mot den. Fyra utdelade testbänkar täcker redan allt
*inuti* filen; säg vilka fyra, och säg sedan den enda sortens fel som `can_spi_node_tb` kan fälla
och som ingen av de fyra kan. Ledtråden står i projektspecifikationens avsnitt 4.1.

**b)** `can_spi_node_tb` håller 200 ns tyst kring varje `SS`-flank, där
[protokollspecifikationen](../../../project/spi_register_protocol.md) kräver minst 60 ns. Den är
alltså snäll mot tidskraven med flit, och ingen utdelad testbänk pressar dem. Kopiera den, krymp
`SETTLE_NS` stegvis ner mot 60 ns, och ta reda på vid vilket värde er nod slutar svara.

Säg sedan **varför** just där, i klockcykler räknat, och var i `spi_slave` gränsen sitter. Jämför
det uppmätta värdet med de 60 ns specifikationen lovar: har ni marginal, eller ligger er nod precis
på gränsen? Det här är enda stället i kursen där ni *mäter* en marginal i stället för att läsa
den, och det är värt att göra noga: en drivrutin som ni inte har skrivit möter noden först i
*Inbyggda system 2*, och då sitter ni i en annan kurs utan den här testbänken framför er.

**c)** Räkna `meta_prev`-instanserna i den färdiga designen och säg vad var och en synkroniserar.
Säg sedan varför `can_spi_node` räcker `can_controller` den *råa* `reset_n` i stället för den
`reset_s2_n` den ger varje annat block, och vad som skulle gå fel om den synkroniserade den två
gånger.

**d)** `tx_bus` och `bus_en` lämnar designen som två skilda portar i stället för en ledning.
Förklara vad som måste hända mellan dem och en fysisk ledning som delas med ett andra kort, och vad
som skulle fallera om ni tilldelade `tx_bus` rakt till en pinne och band ihop två kort.

---

## Övning 5 - Vad kortet visade
Bring-upen kördes i åtta steg, i två halvor: tre på två DE0-CV och fem med hatten som master.
Den här övningen handlar om vad de fastställde och vad de inte gjorde. Den kräver ingen egen
hårdvara; varje del går att svara på utifrån vad passet visade, plus Appendix B och
bring-up-stegen i [föreläsningens README](../README.md).

**a)** Stegen är ordnade så att varje steg utesluter en felklass innan nästa beror på den. Säg
för vart och ett av steg 1, 4 och 5 (ensamt kort, loopback på hatten, registereko) vilken enda sak
det bevisar som steget före inte gjorde. Säg sedan vilka av de åtta stegen som `can_spi_node_tb`
**redan** hade fastställt i simulering, och vilka som bara hårdvara kan fastställa.

**b)** Två kopplingsfel att skilja åt. Säg vilket steg som fallerar först om MISO och MOSI är
förväxlade, och vilket som fallerar först om `VDDIO2` aldrig kopplades in, så att `PORTC` står
utan matning. Förklara varför de fallerar vid olika steg, och vad den skillnaden låter er sluta er
till utan att röra en mätare. Säg också vad `MVIO.STATUS` hade svarat i det andra fallet, och
varför det svaret är snabbare än mätaren.

**b2)** Testprogrammet som delades ut är skrivet för att lyckas: det håller `SS` låg i god tid,
skickar aldrig en sjätte byte och avbryter aldrig mitt i en transaktion. Säg vilken av
protokollspecifikationens regler - de 60 ns kring `SS`, `MISO` under kommandobyten, eller
avbrottsregeln - som **inget** av de åtta stegen skulle ha avslöjat som trasig, och varför just
den därför är den dyraste att ha fel i när en drivrutin ni inte skrivit möter noden.

**c)** En ensam nod kan aldrig få `rx_valid` att pulsa, hur dess pinnar än är kopplade, vilket är
skälet till att passet lade en ram över **två** kort. Säg varför en nod aldrig kan ta emot sin egen
ram (skälet är L17:s `role`), och vad det andra kortet därmed bevisar som varken en loopback eller
`can_controller_tb` kan.

**d)** De två korten går på två oberoende 50 MHz-oscillatorer. Appendix A kallar den delade
`clock`:an i `can_controller_tb` för testbänkens **största** gap av precis det skälet. Var noga med
vad som ändras: `bit_timer.resync` gör redan riktigt arbete i simulering (den fasriktar mottagarens
timer mot sändarens SOF i varje ram), så säg vad de två oberoende klockorna lägger till som ingen
simulering med delad klocka kan visa, och ungefär hur långt isär de två oscillatorerna skulle kunna
driva innan en ram slutade komma fram hel (L12 övning 4 gjorde den uträkningen; återanvänd den).
Jämför den gränsen med en typisk kristalls tolerans och säg om demonstrationen egentligen sätter den
på prov.

**e)** `rx_bus` kommer utifrån FPGA:n, och `can_spi_node` skickar den osynkroniserad vidare till
`can_controller` med flit, eftersom `can_controller` innehåller sin egen `meta_prev` (L12). Förklara
vad som skulle kunna gå fel om den instansen togs bort, varför felet skulle vara betydligt svårare
att diagnostisera än en felkopplad ledning, och varför ingen mängd simulering i den här kursen
någonsin skulle återskapa det.

---

## Övning 6 - Att följa ett `send()` från ände till ände
**a)** Följ en enskild ramförfrågan hela vägen ner. Utgå från de fem bytesen på MOSI som skriver
`0x1` till `TX_SEND`, och följ dem genom `spi_slave` (bytes), `spi_reg_bridge` (en
registerskrivning) och `register_bank` (ett `tx_req` på en cykel) fram till `can_controller`s
portar. Namnge vad varje lager räcker vidare till nästa. Gör sedan detsamma uppåt, för hur
drivrutinen får veta att ramen är klar.

**b)** Fyra lager är tre fler än `can_controller_tb` behöver. Namnge för varje gräns den utdelade
testbänk som spikar fast den, och säg vad som skulle vara oprövat om den testbänken inte fanns.

**c)** Pollning är det enda den här designen erbjuder: det finns ingen avbrottsutgång någonstans.
Säg vad som skulle behöva läggas till för att ge drivrutinen en sådan, ur vilken befintlig signal
den skulle härledas, och i vilket lager den skulle behöva ligga. Förklara sedan varför det hade
varit hopplöst för en drivrutin att polla ett `tx_done` som varar en cykel, och vilken modul som
gjorde att det inte är det.

**d)** En drivrutin skriver `TX_ID`, sedan `TX_DLC`, sedan `TX_SEND`, som tre separata
transaktioner. Mellan den andra och den tredje går bussen till tomgång och en annan nod sänder. Säg
om något av det drivrutinen skrivit är i fara, och vilken regel i registerkartan det är som gör ert
svar sant.

---

## Övning 7 - Livet efter ett avbrott
Appendix A listar "ingen nod sänder någonsin igen efter ett avbrott" som något systemtestbänken inte
täcker. Den här övningen täcker det, och visar vad `clear`-ingången hos `crc15` var till för.

**a)** Utöka `can_controller_tb.vhd` med ett tredje fall. Ge båda noderna tid att återgå till
tomgång efter att fall 2 körts, alltså efter att nod B förlorat arbitreringen och övergett sin ram
mitt i identifieraren, och låt sedan **B** sända en egen ram (ID `0x123`, DLC 2, valfri nyttolast)
med A som mottagare. Bekräfta i simulering att A tar emot den: `a_rx_valid` pulsar, `a_error`
förblir låg, och ID:t kommer tillbaka korrekt.

**b)** Ta nu bort nollställningen: ändra `crc_clear` till en konstant `'0'` och kör om. Fall 1 och 2
passerar fortfarande. Fall 3 gör det inte. Säg vilken nod som höjer `error`, vid vilket tillstånd,
och förklara varför det *inte* är den noden som har buggen.

**c)** Räkna ut vad B:s `crc15`-register håller i det ögonblick den avbryter i fall 2, och varför
ingen mängd korrekt beteende därefter någonsin återför det till noll. (Ledtråden är L13:s egenskap
att generering och kontroll är samma operation: vad förutsätter den om registret vid en rams
*början*?)

**d)** Hur många ramar måste nod B skicka innan den fungerar igen, med nollställningen fortfarande
borttagen? Förklara ert svar, och säg vad en drivrutin som pollar `STATUS` och `ERROR_FLAGS` över
SPI skulle observera varje gång, med L18:s regel för hur felbiten låses.

**e)** L16 lägger nollställningen i `STATE_START` i stället för i `STATE_CRC_WAIT` eller på vägen ut
ur ett avbrott. Ge ett skäl vardera till varför de andra två placeringarna är sämre.

---
