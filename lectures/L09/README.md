# L09 - Praktisk tentamen 1: sekvensnät

Kursens första examinationstillfälle. Tre timmar, individuellt, vid datorn. Tentamen omfattar
**L01-L08** i sin helhet, med tyngdpunkt på sekvensnät: register, räknare, skiftregister, timers,
synkroniserare och enkla Mooremaskiner.

Se [info/examination.md](../../info/examination.md) för poäng, betygsgränser och hur den här
tentamen förhåller sig till projektet och till [L20](../L20/README.md).

---

## Upplägg
Tentamen består av ett antal fristående uppgifter. Varje uppgift ger dig en **utdelad,
självkontrollerande testbänk** och en beskrivning av den modul den driver: portordning, typer och
beteende. Din uppgift är att skriva modulen så att testbänken passerar.

* Uppgifterna är oberoende av varandra. En modul du inte får att fungera stoppar ingen annan.
* Uppgifterna är ordnade ungefär efter stigande svårighet, men läs igenom alla innan du börjar.
* En modul som inte är helt klar rättas på det som finns. Delvis korrekt logik ger delpoäng, så
  lämna aldrig in en tom fil för att den inte blev färdig.
* Testbänken är facit under skrivningen, inte efter den. `all checks passed!` betyder att den
  uppgiften är klar; rättningen läser dessutom koden.

Ett övningsprov med uppgifter av samma slag och samma omfattning delas ut i förväg.

---

## Detta får du använda
* Allt kursmaterial: föreläsningarnas README, samtliga appendix, och all VHDL du själv skrivit
  under L01-L08, inklusive dina lösningar på övningarna.
* Din egen dator, med GHDL. Se [L02 Appendix C](../L02/appendix/c_testbenches.md) om du behöver
  påminna dig om hur en testbänk körs.
* [CircuitVerse](https://circuitverse.org/simulator), om du vill rita en krets innan du skriver
  den. Det är ofta snabbare, inte långsammare.

Detta får du **inte** använda: kommunikation med andra i någon form, språkmodeller och andra
verktyg som genererar eller förklarar VHDL åt dig, och sökning på nätet efter färdiga lösningar.

Den fullständiga och auktoritativa hjälpmedelslistan står i
[examination.md](../../info/examination.md); står något annat här gäller den.

---

## Före tentamen
* Gå igenom övningsprovet, under tidspress och utan att titta i lösningarna först.
* Övning 6 och 7 i [L08 Appendix B](../L08/appendix/b_exercises.md), kursens två capstones, är den
  bästa förberedelsen som finns: de tvingar dig att konstruera ett tillståndsdiagram själv och
  komponera tidigare moduler runt det, vilket är precis vad tentamen mäter.
* Se till att GHDL fungerar på din maskin *innan* du kommer. En trasig verktygskedja är inget
  skäl till förlängd skrivtid.

---

## Det här mäter tentamen
* Att du kan skriva den synkrona processmallen korrekt, utan att slå upp den.
* Att du kan bygga en räknare, en timer och ett skiftregister och veta vad som skiljer dem.
* Att du synkroniserar varje asynkron ingång, utan att bli påmind.
* Att du kan konstruera en liten Mooremaskin ur en specifikation i ord, och skriva den som en
  uppräknad typ och ett `case`.
* Att du kan läsa en testbänks felutskrift och hitta tillbaka till raden som orsakade den.

---

## Efter tentamen
Nästa föreläsning startar **grupprojektet**, som löper över L10-L19 och står för halva kursens
poäng. Läs [projektspecifikationen](../../project/README.md) före L10; grupperna sätts samman där.

---

## Nästa föreläsning
[L10](../L10/README.md): projektstart, CAN-bussen, ramen och arbitreringen, och projektets första
VHDL: det delade paketet `can_def`.

---
