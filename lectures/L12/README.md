# L12 - Synkronisering och bittimern

De två första byggblocken som går in i [L11](../L11/README.md):s tomma arkitektur, båda små: det
som inte vet någonting alls, och det första som vet något om CAN.

---

## Agenda
* `meta_prev` på tavlan: dubbelvippsynkroniseraren, med en breddgeneric, och varför den
  instansieras två gånger inuti `can_controller`, för `reset_n` och `rx_bus`.
* `bit_timer` på tavlan: en fritt löpande räknare som producerar pulserna `sample` och `bit_done`,
  med beteendet som ett tidsdiagram över en bitperiod.
* Att köra en utdelad testbänk mot vardera modulen och läsa dess rapport. Det här är passet där
  GHDL-flödet får sitt tredje steg.
* Att instansiera båda inuti `can_controller`.

Två moduler i stället för en, eftersom båda är små och de är designens enda block som inte håller
något protokolltillstånd: `meta_prev` vet ingenting alls, och `bit_timer` vet bara *när*.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera en breddgenerisk dubbelvippsynkroniserare, och förklara varför den inte behöver
  någon reset och vad en breddning *inte* löser.
* Implementera en räknarbaserad bittimer som producerar rätt tajmade `sample`- och
  `bit_done`-pulser, med en `resync`-ingång.
* Förklara vad `resync` gör och varför `sample` kommer före `bit_done`.
* Läsa ett spår på tickvis nivå över en bitperiod och för varje tick säga vad varje utgång bör
  vara.
* Köra en utdelad testbänk hela vägen och spåra ett fel tillbaka till den tick i designen som
  orsakade det.

---

## Förkunskaper
* [L11](../L11/README.md): arkitekturen, toppnivån och simuleringsflödet.
* [L10](../L10/README.md): paketet `can_def`; `bit_timer` använder `TICKS_PER_BIT` och
  `SAMPLE_TICK` direkt ur det. `meta_prev` läser inget paket alls.
* [L04](../L04/README.md): dubbelvippsynkroniseraren, och [L07](../L07/README.md): räknare med
  målvärde.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 12 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 12.1, Appendix B är
> avsnitt 12.2, och övningarna i Appendix C är avsnitt 12.4. Simuleringsflödet är bokens bilaga A.
> Läs antingen appendixen eller kapitlet; innehållet är detsamma.

* Läs [Appendix A](./appendix/a_meta_prev.md) och [Appendix B](./appendix/b_bit_timer.md).
* Läs [simuleringsflödet](../../info/simulation_workflow.md) om ni inte redan gjort det; det här
  passet använder alla tre stegen snarare än de två första.

### Under föreläsningen
* `meta_prev` på tavlan: blocket med sina portar och sin generic, och varför det inte behöver
  någon reset.
* `bit_timer` på tavlan: blocket med sina sex portar, och en bitperiod tick för tick, först
  ostörd och sedan med en `resync` mitt i.

### Handledd grupptid
* Implementera de två modulerna utifrån specifikationen i Appendix A och B, och få
  `meta_prev_tb` och `bit_timer_tb` att passera.
* Instansiera vardera modulen inuti `can_controller` så snart den passerar sin testbänk, och
  kontrollera att toppnivån fortfarande analyserar.
* De här är de första riktiga PR:erna. Använd granskningen: kontrollera portordning, att
  testbänken passerar, och att inga konstanter är hårdkodade förbi `can_def`.

### Efter föreläsningen
* [Appendix C](./appendix/c_exercises.md) innehåller övningarna.

---

## Riktvärde
`meta_prev` och `bit_timer` bör vara klara och mergade inom ungefär en vecka. Båda är korta, och
de är de enda modulerna som ingen annan modul kan ersätta.

---

## Kontrollfrågor
* Varför behöver en synkroniserare två vippor snarare än en, och varför behöver den ingen reset?
* En breddad `meta_prev` tar bort metastabilitet men inte skevhet mellan bitarna. Vad är
  skillnaden, och när slutar en synkroniserare vara rätt verktyg?
* Vad gör `bit_timer.resync`, och när används den?
* Varför kommer `sample` före `bit_done` snarare än tvärtom?
* `bit_timer` håller sin räknare medan `enable = '0'`. Vilket tillstånd i `can_controller` är det
  enda som någonsin skulle vilja ha det, och varför visar det sig inte vilja det heller?
* När en utdelad testbänk misslyckas, vad skriver GHDL ut, och hur hittar ni vilken kontroll som
  fallerade?

---

## Nästa föreläsning
[L13](../L13/README.md): CRC-15-motorn. En bitseriell checksummemotor som både genererar och
kontrollerar en CRC med samma logik och utan lägesomkoppling.

---
