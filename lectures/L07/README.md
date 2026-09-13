# L07 - Timers

## Agenda
* Timers: en räknare som höjer en flagga när den nått ett målvärde.
* Att göra klockcykler till riktig tid, och likhetsjämföraren som gör det.
* Samma timer i VHDL, återanvändbar tack vare en `generic` snarare än genom omkoppling.
* Att komponera en design av färdiga moduler i stället för att skriva om deras logik.
* `walking_led` demonstrerad på DE0-CV: en enda tänd bit som vandrar längs en rad lysdioder.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **En 4-bitars timer, i CircuitVerse.** L06:s räknare, plus en XNOR-likhetsjämförare och den
   nollställning som får den att upprepa. Se `timeout` slå till en gång var elfte flank, i exakt
   en flank.
2. **Samma timer i VHDL,** som en återanvändbar modul med sitt målvärde som `generic`.
3. **`walking_led`, live.** Timern som just skrevs, plus L04:s `reset_sync` och `button_sync`
   oförändrade, plus en loop som roterar mönstret. Nästan ingen ny logik: den här handlar om att
   komponera det som redan finns.
4. **Ut på kortet.**

Innan timern körs: förutsäg vid vilket räknarvärde `timeout` slår till, och varför det är var
elfte flank snarare än var tionde. Det där ettfelet är hela skälet till att modulens generic
heter `TICK_COUNT` och inte `PERIOD`.

`walking_led` är utdelningen från de fyra senaste föreläsningarna: tre moduler, två av dem
oförändrade från L04 och en skriven i dag, komponerade till något du kan se från bakre raden.

---

## Före föreläsningen
> **Hellre boken?** Den här föreläsningen är också kapitel 7 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 7.1-7.5, och övningarna i
> Appendix B är avsnitt 7.7. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

> **Repetera grunderna?** Timern som en räknare med en jämförelse står i avsnitt 6.3 i [Digital
> Electronics](https://github.com/qrtech-academy/digital-electronics/blob/main/book/digital-electronics.pdf).

* Läs [Appendix A](./appendix/a_timers.md).
* Var bekväm med räknare från
  [L06 A.1](../L06/appendix/a_counters_and_shift_registers.md#a1-från-register-till-räknare). En
  timer är en räknare plus en jämförelse, och den här föreläsningen förutsätter räknaren.

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md).

---

## Det här ska du kunna efteråt
* Förklara vad som skiljer en timer från en vanlig räknare, och varför skillnaden är en jämförelse.
* Bygga en timer som grindnät: en likhetsjämförare av en XNOR per bit, och den nollställning som
  får den att upprepa i stället för att slå över.
* Implementera en timer i VHDL som en återanvändbar modul, omvandla en period i sekunder till ett
  `TICK_COUNT`, och säga varför `timeout` är en puls på en klockcykel snarare än en nivå.
* Komponera en design av färdiga moduler i stället för att skriva om dem, och säga varför en knapp
  som styr en timer ändå måste passera en synkroniserare först.

---

## Frågor att testa dig själv med
* I vilken mening är en timer "bara en räknare med en jämförelse"?
* Varför måste den interna räknaren nollställas till `0` när den når sitt mål, i stället för att
  lämnas att räkna vidare?
* Varför är `timeout` en puls på en enda cykel snarare än en nivå som ligger kvar hög?
* I CircuitVerse-versionen innebär ett ändrat målvärde att jämföraren måste kopplas om. Vad
  ersätter den omkopplingen i VHDL-versionen, och när låses dess värde fast?
* Varför är det fortfarande nödvändigt att köra en knapp genom en synkroniserare innan dess flank
  används för att aktivera en timer, trots att knappen inte har med räkningen att göra?
* `walking_led` skriver nästan ingen egen logik. Nämn de tre moduler den komponerar och vilken
  föreläsning var och en kom från.

---

## Referens
* [Appendix A](./appendix/a_timers.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* [info/quartus_workflow.md](../../info/quartus_workflow.md) täcker uppsättningen av
  Quartus-projektet, pinnplacering, kompilering och programmering som används i
  kortdemonstrationen.
* Synkroniserarna `reset_sync` och `button_sync` är oförändrade från [L04](../L04/README.md), och
  förklaras inte om här utöver en kort repetition.

---

## Nästa föreläsning
* Tillståndsmaskiner, kursens sista byggblock, först konstruerade för hand: tillståndsdiagram,
  tillståndstabell, Karnaughhärledd logik och ett grindnät i CircuitVerse, precis som den här
  föreläsningens timer ritades innan den skrevs.
* Därefter i VHDL, där en uppräkningstyp och ett `case` ersätter tillståndstabellen och
  Karnaughdiagrammen helt.
* En timer är i sig en tillståndsmaskin med två tillstånd och ett enda syfte. L08 generaliserar
  det till kretsar med många tillstånd och många övergångar mellan dem.

---
