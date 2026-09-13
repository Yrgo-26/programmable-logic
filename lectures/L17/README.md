# L17 - CAN-kontrollern II: mottagning och arbitrering

Att färdigställa `can_controller` med mottagning och arbitrering. Efter det här passet är
CAN-halvan av projektet klar.

---

## Agenda
* Mottagarrollen: tajmingen för `rx_shift_reg`s enable, och den enda cykelns föregripande.
* Att sätta ihop en mottagen ram igen, och att mata `crc15` på mottagarsidan.
* Detektering av förlorad arbitrering, kontrollerad bit för bit över arbitreringsfältet.
* Att köra `can_controller_tb` hela vägen, sändning och mottagning tillsammans.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera mottagarvägen i samma tillståndsmaskin som sänder.
* Förklara hur en nod avgör att den förlorat arbitreringen, och vad den gör då.
* Sätta ihop `rx_id`, `rx_dlc` och `rx_data` ur den mottagna bitströmmen och höja `rx_valid` vid
  rätt tillfälle.
* Köra systemtestbänken med två noder på en buss och läsa vad den rapporterar.
* Säga vad `error` betyder, vilka fyra orsaker som sätter den, och när den nollställs.

---

## Förkunskaper
* [L16](../L16/README.md): tillståndsmaskinen och sändvägen. Mottagarvägen byggs in i samma
  maskin, inte vid sidan av den.
* [L10](../L10/README.md): wired-AND-arbitreringen, arbetad för hand.
* [L15](../L15/README.md): `rx_shift_reg` och dess `real_bit`-utgångar.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 17 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 17.1-17.8, och övningarna i Appendix B är avsnitt 17.10. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

* Läs [Appendix A](./appendix/a_can_controller_receive.md).

### Under föreläsningen
* Live-kodning av mottagarvägen och arbitreringskontrollen.
* `can_controller_tb` körd hela vägen: två noder på en wired-AND-buss, där den ena tar emot den
  andras ram, och ett arbitreringsfall där båda sänder samtidigt.

### Handledd grupptid
* Färdigställ gruppens `can_controller.vhd` och få `can_controller_tb` att passera.
* Systemtestbänken hoppas över av bygget tills kontrollern har en mottagarväg. Ser ni fortfarande
  "skipped" när ni tycker att den borde köra, läs kommentaren i
  [`ci/build_project.sh`](../../ci/build_project.sh) och kör med `CI_BUILD_ALL=1`.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.

---

## Riktvärde
Här går projektet över från CAN till SPI. En grupp som inte fått `can_controller_tb` att passera
bör prioritera det framför registerbanken: SPI-halvan går att bygga och testa mot en kontroller
som ännu inte fungerar, men bring-upen i [L19](../L19/README.md) gör det inte.

---

## Kontrollfrågor
* Hur upptäcker en nod att den förlorat arbitreringen, och exakt vilka bitar jämför den?
* Vad gör en nod som förlorat arbitreringen, och varför är det inte "försök igen omedelbart"?
* Varför måste `rx_shift_reg`s enable föregripas en cykel?
* En nod kan inte sända och ta emot samtidigt. Var i tillståndsmaskinen syns det?
* Vad sätter `error`, och vad nollställer den?
* Vad bevisar `can_controller_tb` som de fyra modultestbänkarna tillsammans inte gör?

---

## Nästa föreläsning
[L18](../L18/README.md): registerbanken, och SPI från vågformen och uppåt. Här börjar den halva
som gör kontrollern nåbar från en AVR32DB28.

---
