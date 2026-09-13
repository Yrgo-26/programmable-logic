# L10 - Projektstart: CAN-bussen, ramen och `can_def`

Första föreläsningen i **grupprojektet**. Passet börjar med hur projektet drivs, fortsätter med
vad CAN faktiskt är, och slutar i projektets första VHDL: det delade paketet `can_def`.

Läs [projektspecifikationen](../../project/README.md) före passet. Grupperna sätts samman här.

---

## Agenda
* Projektet: grupper om 4-5, eget privat Git-repo, feature-branchar, Pull Requests och
  kodgranskning. Vad som bedöms, och vad som inte gör det.
* Varför protokoll behöver ramar alls: nyttolast, längdfält, checksumma, och varför DST/SRC/SEQ
  uppstår så snart en länk delas av fler än två noder.
* CAN:s differentiella buss och multimasterdesign.
* Dominanta och recessiva bitar, och varför arbitrering ersätter en bussmästare.
* Broadcast plus ID-filtrering i stället för adresser.
* SOF, 11-bitars identifierare, RTR, kontrollfält, DLC, data, CRC-15, ACK, EOF.
* Bitstoppning: femregeln, och varför den finns.
* Wired-AND-arbitrering med öppen dränering, med två- och trenodersexempel för hand.
* Bittajming och sampelpunkten, på begreppsnivå.
* Live-kodning av `can_def.vhd`, det delade paketet som håller varje konstant passet definierar.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Säga varför kommunikationsprotokoll använder ramar, checksummor och arbitrering.
* Beskriva CAN-ramens format fält för fält, och konstruera en komplett ram för hand.
* Förklara hur wired-AND-arbitrering löser upp konkurrens utan bussmästare, och avgöra vilken av
  två noder som vinner.
* Tillämpa stoppbitsregeln på en bitföljd, för hand.
* Skriva `can_def.vhd`: konstanterna, subtyperna och CRC-polynomet som resten av projektet läser.
* Redogöra för gruppens arbetssätt: branchning, PR:er och granskning.

---

## Förkunskaper
* Hela [L01](../L01/README.md)-[L08](../L08/README.md). Projektet återanvänder allt: entiteter och
  arkitekturer, processer, signaler kontra variabler, generics, dubbelvippsynkroniseraren och
  Mooremaskiner. Ingenting av det förklaras om.
* Git och GitHub på grundnivå: klona, branch, commit, push, Pull Request.

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
* Live-kodning av `can_def.vhd`.

### Handledd grupptid
* Sätt upp gruppens repo: privat på GitHub, alla medlemmar plus handledare inbjudna,
  `CONTRIBUTORS.md` på plats, skyddad `main`.
* Kopiera in de utdelade testbänkarna från [`controller/`](../../controller/README.md) och
  [`bridge/`](../../bridge/README.md).
* Skriv `can_def.vhd` tillsammans och lägg den i repot via en första Pull Request, så att hela
  gruppen har gått igenom flödet en gång innan det gäller på riktigt.

### Efter föreläsningen
* [Appendix C](./appendix/c_exercises.md) innehåller övningarna. Övning 1 tar ramen från
  introduktionen och skickar den som en CAN-ram.
* [Appendix B](./appendix/b_can_def_package.md) är referensen för paketet, konstant för konstant.
* [Ramningsintroduktionens egna övningar](./appendix/intro_framing_exercises.md) hör till
  [ramningsintroduktionen](./appendix/intro_framing.md) och är de enda i kursen med C++-kod och
  en utdelad testsvit. De är valfria om ni redan är varma i ramningstänket.

---

## Riktvärde
`can_def.vhd` bör vara skriven och mergad när passet är slut. Det är en kort fil och resten av
projektet läser den, så den är värd att göra klar direkt.

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
projektets simuleringsflöde i GHDL.

---
