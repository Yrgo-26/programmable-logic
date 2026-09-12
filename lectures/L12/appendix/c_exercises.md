# Appendix C

## Övningar
Övning 1 befäster [Appendix A](./a_meta_prev.md); övning 2 till 4 befäster
[Appendix B](./b_bit_timer.md). Konstruera varje modul utifrån specifikationen i dess eget
appendix; de utdelade testbänkarna (kör dem enligt
[simuleringsflödet](../../../info/simulation_workflow.md)) är kontrollen av att de beter sig
korrekt.

---

## Övning 1 - `meta_prev`
Ni har byggt den här modulen förut, så det mesta här handlar om de två sakerna som är nya.

**a)** Skriv er egen `meta_prev.vhd` utifrån Appendix A:s specifikation och kör dess testbänk:

```bash
cd controller
ghdl -a --std=93 meta_prev.vhd meta_prev_tb.vhd
ghdl -e --std=93 meta_prev_tb
ghdl -r --std=93 meta_prev_tb --assert-level=error
```

Lägg märke till att ingen `can_def.vhd` står med på den första raden. `meta_prev` är den enda
modulen i kursen som inte läser något paket alls, vilket också är skälet till att det är den som
återanvänds tre gånger.

**b)** Ta bort den ena av de två vipporna, så att ett enda register blir kvar, och kör om. Vilken
kontroll fallerar, och vad säger dess meddelande er? Sätt tillbaka den. (En version med en vippa är
inte bara svagare; den är precis den bugg testbänken finns till för att fånga, och den skulle annars
passera varje funktionell simulering i kursen, eftersom ingenting i en simulator någonsin är
metastabilt.)

**c)** `meta_prev` har ingen reset. Säg vad `sync_out` läser på den första klockflanken efter
uppstart, varför det är ofarligt här, och vad som skulle gå fel i `can_controller` självt om modulen
*hade* haft en ingång `reset_s2_n`: instansen `reset_sync` är den som producerar `reset_s2_n`, så
vad skulle den ta för sin egen reset?

**d)** `can_controller` instansierar den två gånger, båda med standardbredden. Säg vilka två av dess
femton portar det gäller, och varför just de två och inga andra. Säg sedan vad den tredje instansen
i designen synkroniserar - den som `can_spi_node` äger på sin toppnivå i L19 - och varför just den
inte kan ligga inuti `can_controller` i stället.

**e)** Två omkopplare slås om i samma ögonblick in i en instans med `WIDTH = 10`. Förklara varför
`sync_out` under ett kort ögonblick kan visa den ena omkopplarens nya värde och den andras gamla,
varför det inte är en bugg i `meta_prev`, och varför det skulle spela betydligt större roll om de
tio bitarna vore en räknare som lästes över en klockdomängräns i stället för omkopplare som ställs
för hand.

---

## Övning 2 - Implementera om `bit_timer.vhd` utifrån specifikationen
Skriv er egen `bit_timer.vhd` utifrån Appendix B:s specifikation. Verifiera den sedan:

```bash
cd controller
ghdl -a --std=93 can_def.vhd bit_timer.vhd bit_timer_tb.vhd
ghdl -e --std=93 bit_timer_tb
ghdl -r --std=93 bit_timer_tb --assert-level=error
```

Om en kontroll fallerar, läs assertion-meddelandet (se
[simuleringsflödet](../../../info/simulation_workflow.md)); det namnger exakt vilket tick och vilket
förväntat värde det gäller.

---

## Övning 3 - En konfigurerbar omsynkroniseringsoffset
Riktig CAN-hårdvara behöver ibland en bittimer som kan omsynkronisera *och* omedelbart hoppa fram
ett fast antal tick (en förenklad ersättare för de justeringar av "fassegment" som riktig
CAN-bittajmingslogik utför, nämnda i L10 Appendix A).

**a)** Lägg till en ny generic, `RESYNC_OFFSET: natural := 0`, i `bit_timer`. När `resync = '1'` ska
räknaren sättas till `RESYNC_OFFSET` (i stället för alltid `0`) på nästa klockflank.

**b)** Med `RESYNC_OFFSET = 0` måste er ändrade entitet bete sig exakt som originalet; bekräfta det
genom att köra den *oförändrade* `bit_timer_tb.vhd` mot den; den ska fortfarande passera utan några
ändringar i testbänken.

**c)** Räkna ut på papper var **båda** utgångarna hamnar när `RESYNC_OFFSET` är `10`: hur många
tick efter en `resync`-puls som `sample` slår till, och hur många tick efter den som `bit_done`
gör det. Båda flyttar sig, och av samma skäl - räknaren startar om på `10` i stället för `0`, så
hela perioden är tio tick kortare.

Låt sedan den utdelade testbänken mäta upp det åt er. Ändra tillfälligt er generics standardvärde
till `10` och kör om `bit_timer_tb`. Den binder ingen generic map, så den plockar upp vilket
standardvärde ni än sätter, och fall 4 är det som märker det:

```text
bit_timer_tb.vhd:132:17:@6832ns:(assertion error): bit_timer: unexpected sample at tick 25 after resync!
```

Lägg märke till **vilken** av de två kontrollerna som fallerar först. Fall 4 kontrollerar inte bara
att `bit_done` kommer på rätt tick utan också att sampelpunkten flyttar med om, och sampelpunkten
ligger först i perioden - så det är den som slår till, fjorton tick innan `bit_done`-kontrollen
skulle ha gjort det. Under `--assert-level=error` stannar simuleringen där, så meddelandet om
`bit_done` får ni aldrig se.

Meddelandet namnger själv ticket: `sample` kom på tick 25, alltså `SAMPLE_TICK - RESYNC_OFFSET`.
Vill ni se `bit_done` också, sänk sampelkontrollens `severity error` till `severity note` i er egen
kopia av testbänken och kör om; den rapporterar då tick 39, alltså
`TICKS_PER_BIT - 1 - RESYNC_OFFSET`. Bekräfta att båda stämmer med ert pappersvar, sätt sedan
tillbaka standardvärdet till `0` och kontrollera att den *oförändrade* testbänken passerar igen.

Det är värt att lägga märke till i sig: en testbänk som fallerar *användbart* säger inte bara att en
design är fel utan också hur mycket, vilket är skälet till att assertion-meddelandena i den här
kursen alla namnger det tick eller det värde de förväntade sig.

---

## Övning 4 - Hur länge kan en bittimer frilöpa?
`bit_timer` omsynkroniserar **en gång per ram**, vid SOF, och frilöper därifrån (L10:s resonemang om
klockåtervinning). Det fungerar bara om nodens egen oscillator håller sig tillräckligt nära varenda
annan nods under hela ramen. Den här övningen sätter en siffra på "tillräckligt nära".

Anta att en nods 50 MHz-oscillator i själva verket går 1 % för fort, så att dess tick är 1 % kortare
än sändarens, och att allt annat är som specificerat: `TICKS_PER_BIT = 50`, `SAMPLE_TICK = 35`.

**a)** Hur många tick har den här nodens räknare vunnit på sändarens efter en bitperiod? (Uttryck
det som en andel av ett tick.)

**b)** Noden samplar vid tick 35 av 50, så i förhållande till den sanna biten kan den driva 15 tick
*senare* innan den samplar bortom bitens slut, eller 35 tick *tidigare* innan den samplar innan
biten börjar. En snabb klocka driver sampelpunkten tidigare. Efter hur många bitperioder har den
drivit hela 35 tick?

**c)** En standardram med 8 databytes går på ungefär 110-130 bitar på ledningen när stoppbitarna är
inräknade. Jämför det med ert svar på (b): samplar den här noden fortfarande rätt vid EOF? Vid
ungefär vilket fält börjar den sampla fel bit?

**d)** Riktiga CAN-kontrollrar omsynkroniserar *under* en ram, inte bara vid SOF, med hjälp av de
fassegment och den synchronization jump width som L10 Appendix A nämner. Förklara med en eller två
meningar vad det ger dem, uttryckt i ert svar på (b).

---

