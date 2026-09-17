# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_tx_shift_reg.md). Konstruera er egen
`tx_shift_reg.vhd` utifrån specifikationen där; den utdelade testbänken (kör den enligt
[simuleringsflödet](../../../info/simulation_workflow.md)) är kontrollen av att den beter sig
korrekt.

---

## Övning 1 - Implementera om `tx_shift_reg.vhd` utifrån specifikationen
Skriv er egen `tx_shift_reg.vhd` utifrån Appendix A. Verifiera den:

```bash
cd controller
ghdl -a --std=93 can_def.vhd tx_shift_reg.vhd tx_shift_reg_tb.vhd
ghdl -e --std=93 tx_shift_reg_tb
ghdl -r --std=93 tx_shift_reg_tb --assert-level=error
```

Om en kontroll fallerar, läs assertion-meddelandet; det namnger exakt vilket skift det gäller och
vad som förväntades.

---

## Övning 2 - Följ en stoppad sekvens för hand, sedan i simulering
**a)** Följ för hand `tx_shift_reg` laddad med `data = "11100000"`, `bit_count = 8`, med start vid
en gruppgräns där den föregående gruppens sista bit var `0` med en följdlängd på 3 (alltså
`consecutive = 3` och `last_bit = '0'` in i gruppen). Skriv ut, bit för bit: vad som presenteras vid
`load`, och sedan vid varje efterföljande `shift`, med varje instoppad stoppbit markerad och med
angivande av vilket skift som höjer `done`.

**b)** Bekräfta er handföljning i simulering: skriv en kort testbänk (eller återanvänd strukturen i
`tx_shift_reg_tb.vhd`) som förladdar samma startvillkor med följdlängd 3, sedan laddar `"11100000"`
och vid varje skift `assert`:ar `tx_bit`/`stuff`/`done` mot värdena ni förutsade (eller `report`:ar
dem så att ni kan läsa dem). Stämmer dess utfall av passera/fallera med er handföljning?

---

## Övning 3 - Enbitsgruppen som ändå är skyldig en stoppbit
Appendix A:s sista tajmingpunkt namnger ett gränsfall utan att arbeta igenom det: *"om
`bit_count = 1` och den enda biten utlöser en stoppbit, väntar `done` ändå på att stoppbiten skickas
först."* Det är inte hypotetiskt; `can_controller` laddar enbitsgrupper (SOF) och fyrabitsgrupper
(ID:ts undre halva plus RTR), så en grupp kan verkligen sluta mitt i en följd.

Sätt upp det precis som test 2 och 3 i `tx_shift_reg_tb` gör, utan reset emellan: ladda `"00001111"`
med `bit_count = 8` och skifta ut den helt, så att följdräknaren står på fyra `'1'`:or i rad. Ladda
sedan en **enbitsgrupp** vars enda bit också är `'1'` (`data = "1-------"`, `bit_count = 1`).

**a)** Följ vad som händer, presentation för presentation: vad `load` lägger på `tx_bit`, vad
följdräknaren når, och sedan vad varje följande `shift` gör. Markera vilken presentation som bär
stoppbiten och vilken som höjer `done`.

**b)** Hur många `shift`-pulser förbrukar den här enbitsgruppen totalt, och hur många skulle det ha
förbrukat om följdräknaren i stället stått på noll? Säg var skillnaden kommer ifrån.

**c)** Anta att `done` hade fått pulsa så snart gruppens enda riktiga bit presenterats, utan hänsyn
till den väntande stoppbiten. `can_controller` skulle då ladda nästa grupp under nästa bitperiod.
Beskriv exakt vad den mottagande noden i så fall skulle se på ledningen, och vilken av
`rx_shift_reg`:s utgångar som till slut skulle rapportera det (L15).

**d)** Bekräfta er genomgång i simulering, genom att utöka mönstret från test 2 och test 3 i
`tx_shift_reg_tb.vhd` med den här enbitsgruppen som ett fjärde fall.

---

## Övning 4 - Varifrån `track_run` anropas
Appendix A lägger följdräknaren i en procedur och är tydlig med var den proceduren får anropas: från
en gren som placerar en bit, aldrig från processens toppnivå. Båda halvorna av den regeln är värda
att bryta med flit, i en kladdkopia av er modul.

**a)** Flytta ut anropet `track_run(data(7));` ur grenen `load`, så att `load` låser gruppen och
presenterar dess första bit men räknaren aldrig ser den biten. Förutsäg vad följdräknaren då visar
under resten av ramen, och vilket av testbänkens tre tester som fallerar först. Kör det.

**b)** Lägg nu ett enda `track_run(tx_bit);` högst upp i grenen `elsif (rising_edge(clock))`,
ovanför standardvärdena, och ta bort alla tre anropen inuti grenarna. `tx_bit` är en `out`-port, så
börja med att säga varför det inte ens kompilerar, och upprepa sedan experimentet med en intern
kopia av den sända biten i dess ställe. Med `TICKS_PER_BIT` satt till 50, hur många gånger körs
räknaren nu per CAN-bit, och vad gör `consecutive` på den andra klockflanken i den allra första
bitperioden?

**c)** Appendix A säger också att proceduren måste deklareras *inuti* processen i stället för i
arkitekturen. Flytta ut den till arkitekturens deklarativa del, oförändrad, och analysera filen. Den
kompilerar inte; läs felen, ett per signaltilldelning i proceduren, innan ni går vidare. Gör sedan
en version på arkitektursnivå som *faktiskt* kompilerar, med identiskt beteende och en testbänk som
passerar. Jämför de två anropsställena och säg vad den andra versionen kostar, och vilken ny fråga
den väcker som versionen inuti processen inte kan väcka.

---

