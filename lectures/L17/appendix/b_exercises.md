# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_can_controller_receive.md), mottagningsvägen och
arbitreringen. När er mottagningslogik är klar verifierar `controller/can_controller_tb.vhd`
sändning och mottagning tillsammans, och `make build-project` slutar hoppa över den: alla sex
testbänkar i `controller/` körs härifrån och framåt. De två i `bridge/` fortsätter hoppas över tills
L18 och L19 skriver modulerna de prövar.

Om den fortfarande rapporteras som överhoppad efter att ni tror att mottagningsvägen är klar, läs
meddelandet före er design. Bygget avgör saken genom att leta efter L17:s CRC-grindning på
mottagningssidan inuti `can_controller.vhd`, så en korrekt kontroller som stavar de två uttrycken
annorlunda hoppas över i stället för att köras. `CI_BUILD_ALL=1 make build-project` tvingar fram
den, och [referensen för simuleringsflödet](../../../info/simulation_workflow.md) förklarar varför
kontrollen fungerar så.

---

## Övning 1 - Resonemang om tajmingfixen på RX-sidan
**a)** Appendix A visar att `rx_shift_reg` måste aktiveras *kombinatoriskt*, under själva
`STATE_LOAD_*`-tillståndet, i stället för att vänta tills `state` synligt blir skifttillståndet.
Förklara med egna ord varför det att först vänta in att tillståndsövergången blir klar skulle få
`rx_shift_reg` att missa just det sampel som utlöste väntan från början.

**b)** `STATE_CRC_LO_WAIT` väntar på `bt_bit_done`, inte på `bt_sample`, till skillnad från varje
väntan vid en gruppgräns i designen (tillstånden `STATE_LOAD_*`). Läs om Appendix A:s förklaring
och förklara med egna ord varför just den övergången måste ligga i linje med en *bitperiodsgräns*
och inte med en sampelpunkt. Vilka andra tillstånd delar utlösaren `bt_bit_done`, och vad har de
gemensamt med den?

**c)** Anta (hypotetiskt) att `STATE_CRC_WAIT` också väntade på `bt_sample` för RX-rollen, utöver
att `STATE_LOAD_CRC_HI` gör detsamma omedelbart efteråt. Förklara vad som skulle gå fel, och varför
det inte så mycket skulle visa sig som ett rent haveri som att en mottagande nod hamnar en bitperiod
längre efter en sändande nod än den borde.

---

## Övning 2 - Arbitrering för hand
Två noder begär sändning på samma cykel: nod A med ID `0x2A0`, nod B med ID `0x2C0`.

**a)** Skriv båda ID:na binärt (11 bitar, MSB först) och markera den första bitposition där de
skiljer sig.

**b)** Säg med L10:s arbitreringsregel (dominant `0` vinner) vilken nod som vinner och vid vilken
bit förloraren faller ur.

**c)** Den förlorande noden upptäcker sin förlust med
`bt_sample = '1' and txsr_tx_bit = '1' and rx_bus_s2 = '0'`. Säg, för förloraren vid den biten, vad
var och en av de tre termerna evalueras till och varför villkoret slår till.

**d)** Förloraren sätter `error <= '1'` och faller ner till `STATE_IDLE` medan vinnaren fortfarande
driver bussen. `error` nollställs i `STATE_START`. Förklara varför förlorarens `error` skulle bli
oobserverbart för en anropare om `STATE_IDLE` gick in i en mottagning på en dominant *nivå*.

**e)** En lockande lagning är att i stället leta efter *flanken* från recessiv till dominant, i
linje med hur L10 Appendix A beskriver SOF. Visa att det egentligen inte fungerar, med hjälp av
stoppbitsregeln: vad sätter sändaren in efter fem dominanta bitar i rad, och vad gör bussen på biten
efter det? Ungefär hur långt in i vinnarens ram hinner förloraren innan flanktestet slår till ändå?

**f)** Ange regeln designen faktiskt använder (L16 Appendix A). Två fakta gör den hållbar; ge båda:
vad stoppbitsregeln begränsar inne i det stoppade området, och vad den ostoppade svansen lägger till
ovanpå det som skjuter tröskeln till elva. Säg sedan varför tomgångsräknaren måste nollställas till
**fullt** och inte till tomt när noden kommer ur reset.

---

## Övning 3 - SOF-biten som ingen behåller

`STATE_SOF` aktiverar `rx_shift_reg` under en bit och kastar sedan värdet. Appendix A förklarar
varför; den här övningen handlar om att se felet med egna ögon.

**a)** Ta ID `0x000`, DLC `0`. Skriv ut bitarna en sändare lägger på ledningen från SOF till och med
kontrollfältets slut, med L16:s fälttabell, och markera var `tx_shift_reg` sätter in varje stoppbit.
Kom ihåg att följdräknaren räknar med SOF.

**b)** Gör nu samma sak sett från en mottagare som hoppade över SOF, så att dess följdräknare ligger
en dominant bit efter. Markera var *den* förväntar sig stoppbitar. Ställ upp de två mot varandra och
ange den första bitposition där de är oense.

**c)** Vid den positionen skickar sändaren en stoppbit och mottagaren väntar sig ingen. Vad gör
mottagaren med den, och vad gör det av varje bit efter den?

**d)** Upprepa (a) och (b) för ID `0x123`, det ID som `can_controller_tb` använder i fall 1, och
bekräfta att de två räknarna är överens hela vägen. Ange den allmänna regeln för vilka identifierare
som går sönder: vad måste gälla för de första identifierarbitarna, och hur många av de 2048
standard-ID:na uppfyller det?

**e)** Fall 2 i `can_controller_tb` skickar *faktiskt* ID `0x000`. Förklara varför buggen ändå inte
skulle visa sig där, och säg vad ni skulle lägga till i testbänken för att fånga den.

---

## Övning 4 - Att ta emot en ram utan data
Gå igenom **mottagningsrollen** genom en komplett ram med `DLC = 0`, med hjälp av tabellen per
tillstånd i [Appendix A](./a_can_controller_receive.md). En mottagare vet inte DLC:n förrän den har
avkodat kontrollfältet, så det här är också den väg som prövar om er övergång i `STATE_CTRL` är
rätt.

**a)** Lista varje tillstånd noden passerar, från `STATE_IDLE` tillbaka till `STATE_IDLE`. Markera
den enda övergång som skiljer sig från en ram som bär data, och säg vad som får den att slå till.

**b)** Ange för varje `STATE_LOAD_*`-tillstånd i er lista det `rxsr_bit_count` som det
kombinatoriska nätet föregriper, och säg vilket `bt_sample` det föregripandet måste vara på plats
för: det som utlöser övergången ut ur `STATE_LOAD_*`, eller nästa.

**c)** Anta att föregripandet vore en cykel för sent överallt, alltså att `rxsr_enable` gick hög
först när `state` synligt läste skifttillståndet. Hur många riktiga bitar skulle `rx_shift_reg` ha
missat för en ram med `DLC = 0` när noden når `STATE_CRC_LO_WAIT`, och vad skulle `crc_valid` läsa
där?

**d)** Ert svar på (c) är ett CRC-fel som rapporteras många bitperioder efter det faktiska
misstaget. Relatera det till Appendix A:s påstående att en felställning på en cykel "ackumuleras
till en tyst felställning som visar sig först senare, långt från sin orsak", och säg varför det gör
den här sortens bugg dyr att felsöka enbart utifrån testbänkens utskrifter.

---

