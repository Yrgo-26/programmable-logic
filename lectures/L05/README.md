# L05 - Variabler och hårdvaran under

## Agenda
* `variable`: processlokal lagring, som uppdateras direkt där en `signal` schemalägger.
* Varför samma ackumulering ger två olika svar beroende på vilken du griper efter.
* Vad en FPGA fysiskt består av: uppslagstabeller och vippor, och ingenting som är en grind.
* Kritiska vägen och Fmax, och låset du råkar beskriva av misstag.
* Självstudier: L04:s dubbelvippsynkroniserare utbruten som en generisk modul (övning 4), och vad
  en generic kostar i den hårdvara Quartus bygger.
* `parity_gen` demonstrerad på DE0-CV: lysdioden växlar varje gång exakt en strömbrytare ändras.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **`parity_gen` med en signalackumulator.** Skriven som en programmerare skulle skriva den, och
   sedan spårad för hand, en loopiteration i taget, fram till fel svar.
2. **`parity_gen` med en `variable`.** Samma loop, spårad på samma sätt, fram till rätt svar.
3. **Vad Quartus gjorde av det.** Vad den faktiskt byggde, hur snabbt den säger att designen
   kommer att gå, och en varning om ett oavsiktligt lås, framkallad med flit.
4. **Ut på kortet.** `parity_gen` på DE0-CV: åtta strömbrytare in, en lysdiod ut, som växlar
   varje gång exakt en strömbrytare ändras.

Steg 1 är föreläsningens poäng. Koden ser korrekt ut, simulerar utan invändningar, och är fel,
och enda sättet att se varför är att spåra den snarare än att läsa den.

---

## Före föreläsningen
* Läs [Appendix A](./appendix/a_variables_and_hardware.md).
* Inget nytt förutsätts utöver L01-L04. Varje konstruktion utom `variable` har redan dykt upp i
  en design du själv skrivit.

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md), som innehåller två skriftliga övningar om
  vad verktygskedjan gör med din VHDL, och en kodgranskning av en design som kompilerar rent och
  ändå är fel.

---

## Det här ska du kunna efteråt
* Säga vad som skiljer en `signal` från en `variable`, förutsäga det olika resultat var och en ger
  ur samma kod, och välja mellan dem medvetet.
* Förklara vad en FPGA fysiskt består av, varför två olika utseende beskrivningar av samma krets
  ger samma hårdvara, och varför ett Karnaughdiagram köper mindre här än på diskret logik.
* Förklara vad som begränsar en designs klockfrekvens, och varför fler register kan göra en design
  snabbare snarare än långsammare.
* Känna igen ett oavsiktligt lås på dess varning, säga vad som orsakade det och åtgärda det, och
  säga varför "det kompilerade utan fel" lovar mindre för en FPGA-design än för ett C-program.

---

## Frågor att testa dig själv med
* En `signal` tilldelas två gånger, med olika värden, i ett varv genom en `process`. Vad hamnar på
  den, och när sker den uppdateringen egentligen?
* Samma fråga för en `variable`.
* Varför ger ackumulering över en loop med en `signal` ett annat, oftast felaktigt, resultat?
* Ingenting på en FPGA blir en grind. Vad blir en boolesk funktion i stället, och varför kostar en
  funktion av fyra variabler lika mycket oavsett om du minimerade den först?
* Vad är kritiska vägen, och varför kan fler vippor få en design att gå snabbare?
* Ett kombinatoriskt `case` tilldelar sin utgång i tre grenar av fyra. Vad bygger syntesverktyget
  för den fjärde, och varför är det det enda det *kan* bygga?
* Varför är ett oavsiktligt lås en varning och inte ett fel, och varför gör det saken farligare
  snarare än mindre farlig?

---

## Referens
* [Appendix A](./appendix/a_variables_and_hardware.md) är kursmaterialet: `variable` kontra
  `signal` med `parity_gen` som genomarbetat exempel, sedan LUT:ar och vippor, kritiska vägen och
  Fmax, och låset du råkar beskriva av misstag.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* [info/quartus_workflow.md](../../info/quartus_workflow.md) är verktygsreferensen bakom den här
  föreläsningens demonstrationer. Ingen övning kräver att du har Quartus eller ett kort.
* Testbänkar beskrivs i [L02 Appendix C](../L02/appendix/c_testbenches.md).

---

## Nästa föreläsning
* Räknare och skiftregister: de första designerna vars tillstånd går framåt av sig självt, i
  stället för att följa en ingång så som L03:s och L04:s register gör.
* Byggda av L03:s klockade processidiom, med den här föreläsningens schemaläggningsregel som gör
  det verkliga arbetet: ett skiftregister är en kedja av signaler som alla uppdateras samtidigt,
  vilket är precis därför det skiftar i stället för att kollapsa.

---
