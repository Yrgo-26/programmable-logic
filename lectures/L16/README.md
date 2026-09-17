# L16 - CAN-kontrollern I: tillståndsmaskinen och sändvägen

Ramen som tillståndsmaskin, först förklarad och sedan byggd på sändarsidan.

---

## Agenda
* Den ramsekvenserande tillståndsmaskinen som begrepp: tillståndsdiagrammet, fälttabellen och
  mönstret `STATE_LOAD_*`/skifta, innan någon VHDL skrivs.
* Sändvägen på tavlan: tillståndstypen och maskinens signaler i `can_controller`, vad varje
  `STATE_LOAD_*` laddar, och vilken puls som för maskinen vidare.
* Att driva den öppna dräneringsbussen från skiftregistrets aktuella bit.
* Att mata `crc15` korrekt: grinda på `bit_valid`, inte på `bit_done`.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Rita CAN-ramens tillståndsdiagram och säga vilket fält varje tillstånd svarar mot.
* Förklara varför varje fält behöver ett `LOAD`-tillstånd före sitt skifttillstånd.
* Implementera sändvägen: ladda skiftregistret, skifta ut, och gå vidare vid rätt puls.
* Driva bussen med öppen dränering korrekt: `bus_en` styr, `tx_bus` bestämmer vad.
* Grinda CRC-motorn rätt, och säga varför fel grindning ger en CRC som ser rimlig ut och är fel.

---

## Förkunskaper
* [L12](../L12/README.md) till [L15](../L15/README.md): alla fyra delblock. Den här föreläsningen
  skriver ingen ny modul, den sätter de fyra i arbete.
* [L08](../L08/README.md): Mooremaskiner, den uppräknade tillståndstypen och `case`-mönstret.
* [L10](../L10/README.md): ramens fält och deras bredder.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 16 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 16.1-16.8, och övningarna i Appendix B är avsnitt 16.10. Läs antingen appendixen eller kapitlet; innehållet är detsamma.

* Läs [Appendix A](./appendix/a_can_controller.md). Den är projektets längsta appendix; läs
  åtminstone tillståndsdiagrammet och tabellen över de sju fältgrupper en sändning delas upp i
  (databytegruppen upprepas en gång per byte, så en tvåbytesram blir åtta laddningar).

### Under föreläsningen
* Tillståndsdiagrammet på tavlan, härlett fält för fält ur ramformatet.
* Sändvägen på tavlan: vad varje tillstånd laddar i `tx_shift_reg`, vad det driver på bussen, och
  när `crc15` får uppdatera sig.

### Handledd grupptid
* Implementera tillståndsmaskinen och sändvägen utifrån specifikationen i Appendix A.
* Få toppnivån att analysera och elaborera. `can_controller_tb` kan ännu inte köras, eftersom den
  kräver en mottagarväg, och det är [L17](../L17/README.md):s.
* Det här är projektets största enskilda kodinsats och den enda del som är svår att dela upp på
  flera personer. Ett rimligt upplägg är att två skriver och resten granskar tätt, snarare än att
  fyra skriver var sin del av samma process.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.

---

## Riktvärde
Sändvägen bör vara på plats när [L17](../L17/README.md) börjar, eftersom mottagarvägen byggs in i
samma maskin. Kommer ni inte hela vägen: gör klart sändningen fram till och med CRC-fältet, och
lämna ACK och EOF till nästa pass.

---

## Kontrollfrågor
* Varför behöver varje fält ett eget `LOAD`-tillstånd?
* En nod som sänder släpper bussen under ACK-luckan. Varför, och vad förväntar den sig se där?
* `bus_en` och `tx_bus` är två separata signaler. Vad hade gått förlorat med bara en?
* Varför grindas `crc15` på `bit_valid and not stuff` och inte på `bit_done`?
* Vilka fält täcks av CRC:n, och var slutar täckningen exakt?
* Varför är tillståndsmaskinen en Mooremaskin här?

---

## Nästa föreläsning
[L17](../L17/README.md): att färdigställa `can_controller` med mottagning och arbitrering, och
att köra systemtestbänken hela vägen.

---
