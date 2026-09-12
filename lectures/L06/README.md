# L06 - Räknare och skiftregister

## Agenda
* Räknare: ett register, en adderare och en konstant `1`, och varför överslaget kommer gratis.
* Skiftregister: att flytta data en bit per klockflank, åt ett håll som används konsekvent.
* Serial-in/parallel-out och parallel-in/serial-out, och vilket som passar vilket jobb.
* En 8-bitars seriemottagare: ett skiftregister plus en biträknare, som vet när en byte anlänt.
* Två demonstrationer på DE0-CV: en rad lysdioder som räknar och slår över, och en byte som
  skiftas in en knapptryckning i taget.

---

## Föreläsningsupplägg
Byggs live, i denna ordning:
1. **En 4-bitars räknare, i CircuitVerse.** Ett register, en adderare och en konstant `1`. Kör den
   förbi `1111` och se den slå över.
2. **Samma räknare i VHDL.**
3. **Ett skiftregister i VHDL.** Först spårat en klockflank i taget, på papper, innan något av det
   skrivs.
4. **`serial_rx8`, live.** Skiftregistret som just skrevs, plus biträknaren som talar om för det
   när en byte är klar. Föreläsningens två halvor möts i en modul.
5. **Ut på kortet, två gånger.** Först räknaren, med sina översta bitar på en rad lysdioder,
   nedsaktad till något ögat hinner följa: se den räkna upp till idel ettor och slå över till noll
   av sig självt. Sedan `serial_rx8` med `shift_enable` driven av en tryckknapp i stället för
   hållen hög, så att ett tryck skiftar en bit och byten byggs upp över åtta lysdioder, mest
   signifikanta biten först.

Innan räknaren når `1111`: förutsäg vad den kommer att visa härnäst, och leta sedan upp det
element i ritningen som får det att hända. Det finns inget, vilket är poängen: ingenting i kretsen
utför överslaget, och det är en konsekvens av registrets bredd snarare än logik någon lagt dit.

[`serial_rx8`](./serial_rx8/serial_rx8.vhd) är kursens första design vars korrekthet du inte kan
kontrollera med ögat i full fart: kontinuerligt aktiverad sväljer den en byte på 160 ns. Det är
därför den har en referenstestbänk, och därför kortdemonstrationen driver `shift_enable` från en
knapp i stället. Att sakta ned *klockan* vore mjukvaruinstinkten och fel drag; modulen har redan
den styrning som låter dig ta en bit i taget.

---

## Före föreläsningen
* Läs [Appendix A](./appendix/a_counters_and_shift_registers.md).

## Efter föreläsningen
* Arbeta igenom [Appendix B](./appendix/b_exercises.md).

---

## Det här ska du kunna efteråt
* Bygga en 4-bitars räknare som grindnät, och förklara, med fingret på din egen ritning, varför
  ingenting i den får räkningen att återgå till noll.
* Implementera samma räknare i VHDL, förklara överslaget som en konsekvens av registrets bitbredd,
  och säga varför en simulator invänder mot ett överslag som hårdvaran utför utan att blinka.
* Implementera ett skiftregister i både SIPO- och PISO-utförande, veta vilket som passar vilket
  jobb, och veta vilket håll kursen skiftar åt och varför det spelar roll att hålla sig till ett.
* Kombinera en räknare med ett skiftregister för att upptäcka att ett komplett ord anlänt, och
  verifiera en klockad design genom att köra dess testbänk.

---

## Frågor att testa dig själv med
* Varför återgår en räknare av typen `natural range 0 to 15` till `0` efter `15` utan någon
  uttrycklig "om maxvärdet, nollställ"-logik? Vad måste gälla för intervallet? Vilket element
  utför överslaget?
* En VHDL-simulator avbryter på det överslag din CircuitVerse-ritning utför utan invändning.
  Vilken av de två modellerar hårdvaran, och vad säger det om att lita på någondera ensam?
* Vad är den praktiska skillnaden mellan ett SIPO- och ett PISO-skiftregister? Vilket skulle du
  gripa efter för att ta emot en ström av seriella bitar, och vilket för att driva en kedja av
  lysdioder från ett fast mönster?
* Ett skiftregister och en räknare är båda "N vippor som delar en klocka". Det som skiljer är vad
  som matar varje vippas ingång. Beskriv den skillnaden för respektive.
* Varför är `data_ready` i `serial_rx8` en puls på en klockcykel snarare än en nivå som blir
  liggande hög när en byte anlänt?
* Varför måste `shift_enable` grinda biträknaren och inte bara skiftningen?
* Kortdemonstrationen driver `shift_enable` från en knapp i stället för att sakta ned klockan.
  Varför är nedsaktad klocka fel svar, och vad skulle gå sönder om knappen kopplades till
  `shift_enable` utan att först passera `button_sync`?
* `data_ready` behöver en egen vippa innan en lysdiod kan visa den. Vilken föreläsnings problem är
  det, i annan skepnad?

---

## Referens
* [Appendix A](./appendix/a_counters_and_shift_registers.md) är kursmaterialet.
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.
* Att köra testbänkarna beskrivs i [L02 Appendix C](../L02/appendix/c_testbenches.md).
* [`serial_rx8`](./serial_rx8/serial_rx8.vhd) är A.5:s mottagare, och har en referenstestbänk.
  A.7:s kortdemonstration lindar in den i [L04](../L04/README.md):s `reset_sync` och
  `button_sync`, båda oförändrade, så den är lika mycket en kompositionsövning som en mottagare.

---

## Nästa föreläsning
* Timers: en räknare med ett målvärde, vilket är det som gör klockcykler till riktig tid.
* Byggd genom att lägga exakt två saker till räknaren du ritade här, en jämförare och en
  nollställning, så spara det CircuitVerse-projektet.
* Den vandrande lysdioden: den här föreläsningens skiftregister, taktat av den timern och startat
  av en synkroniserad knapp, live-kodat och kört på DE0-CV-kortet.

---
