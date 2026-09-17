# L10 - Projektstart: CAN-bussen, ramen och `can_def`

Första föreläsningen i **grupprojektet**. Passet börjar med hur projektet drivs, fortsätter med
vad CAN faktiskt är, och slutar i det delade paketet `can_def`, som resten av projektet läser.

Läs [projektspecifikationen](../../project/README.md) före passet. Grupperna sätts samman här.

---

## Agenda
* Projektet: grupper om 4-5, hur arbetet drivs, och vad som bedöms och vad som inte gör det.
  Git-flödet med branchar, Pull Requests och granskning gås igenom i [L11](../L11/README.md).
* Varför protokoll behöver ramar alls: nyttolast, längdfält, checksumma, och varför DST/SRC/SEQ
  uppstår så snart en länk delas av fler än två noder.
* CAN:s differentiella buss och multimasterdesign.
* Dominanta och recessiva bitar, och varför arbitrering ersätter en bussmästare.
* Broadcast plus ID-filtrering i stället för adresser.
* SOF, 11-bitars identifierare, RTR, kontrollfält, DLC, data, CRC-15, ACK, EOF.
* Bitstoppning: femregeln, och varför den finns.
* Wired-AND-arbitrering med öppen dränering, med två- och trenodersexempel för hand.
* Bittajming och sampelpunkten, på begreppsnivå.
* `can_def` på tavlan: det delade paketet som håller varje konstant passet definierar. Paketet är
  utdelat, eftersom de utdelade testbänkarna läser dess namn och typer.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Säga varför kommunikationsprotokoll använder ramar, checksummor och arbitrering.
* Beskriva CAN-ramens format fält för fält, och konstruera en komplett ram för hand.
* Förklara hur wired-AND-arbitrering löser upp konkurrens utan bussmästare, och avgöra vilken av
  två noder som vinner.
* Tillämpa stoppbitsregeln på en bitföljd, för hand.
* Läsa `can_def.vhd`: säga var varje konstant, subtyp och CRC-polynomet kommer ifrån, och varför
  de konstanter som går att räkna ut är uträknade i stället för inskrivna.

---

## Förkunskaper
* Hela [L01](../L01/README.md)-[L08](../L08/README.md). Projektet återanvänder allt: entiteter och
  arkitekturer, processer, signaler kontra variabler, generics, dubbelvippsynkroniseraren och
  Mooremaskiner. Ingenting av det förklaras om.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 10 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Introduktionen om ramar är avsnitt 10.1,
> Appendix A är avsnitt 10.2-10.7, Appendix B är avsnitt 10.8, och övningarna, både Appendix C och ramningsintroduktionens, är avsnitt 10.10. Projektspecifikationen är bokens bilaga C. Läs antingen
> appendixen eller kapitlet; innehållet är detsamma.

* Läs [projektspecifikationen](../../project/README.md) i sin helhet.
* Läs [introduktionen om ramar](./appendix/intro_framing.md), åtminstone fram till avsnittet om
  serialisering. Den bygger upp ett eget litet ramformat och motiverar varje fält CAN sedan har.
* Läs [Appendix A](./appendix/a_can_frame_format.md).

### Under föreläsningen
* Projektupplägget och gruppindelningen, först.
* Genomgång av CAN från bussen och uppåt, med arbitrering och stoppbitar arbetade på tavlan.
* `can_def` på tavlan: vilka konstanter och subtyper paketet håller, vilka som räknas ut ur
  andra, och varför.

### Handledd grupptid
* Gör övningarna 2-6 i [Appendix C](./appendix/c_exercises.md) på papper: arbitrering,
  bitstoppning och en hel ram för hand.
* Läs det utdelade [`controller/can_def.vhd`](../../controller/can_def.vhd) tillsammans i gruppen,
  med [Appendix B](./appendix/b_can_def_package.md) vid sidan, och gör övning 7.
* Gruppens repo sätts upp i [L11](../L11/README.md), efter Git-introduktionen. Då läggs
  `can_def.vhd` in oförändrad, tillsammans med de utdelade testbänkarna.

### Efter föreläsningen
* [Appendix C](./appendix/c_exercises.md) innehåller övningarna. Övning 1 tar ramen från
  introduktionen och skickar den som en CAN-ram.
* [Appendix B](./appendix/b_can_def_package.md) är referensen för paketet, konstant för konstant.
* [Ramningsintroduktionens egna övningar](./appendix/intro_framing_exercises.md) hör till
  [ramningsintroduktionen](./appendix/intro_framing.md) och är de enda i kursen med C++-kod och
  en utdelad testsvit. De är valfria om ni redan är varma i ramningstänket.

---

## Riktvärde
När passet är slut bör var och en i gruppen kunna säga var konstanterna i `can_def.vhd` kommer
ifrån. Det är en kort fil och resten av projektet läser den, så den är värd att förstå direkt.

Riktvärdena i de här föreläsningarna är just riktvärden. De är inte milstolpar, de betygsätts
inte, och gruppen bestämmer själv i vilken ordning modulerna byggs.

---

## Kontrollfrågor
* Varför behöver ett protokoll ett längdfält när ramen ändå har en tydlig början?
* Varför har CAN ingen destinationsadress, och vad använder den i stället?
* Två noder börjar sända samtidigt. Vilken vinner, och vad gör förloraren?
* Varför måste en sändare stoppa in en bit efter fem lika i rad, och varför gäller regeln inte
  hela ramen?
* Vad händer med CRC-beräkningen för en instoppad bit?
* Varför ligger sampelpunkten runt 70 % in i bitperioden i stället för i mitten?

---

## Nästa föreläsning
[L11](../L11/README.md): från protokoll till blockschema. Kontrollerns arkitektur, den toppnivå
varje senare modul instansieras i, registerkartan som drivrutinsklassen ska konsumera, och
projektets simuleringsflöde i GHDL. Passet innehåller också Git-introduktionen, och där sätts
gruppens repo upp.

---
