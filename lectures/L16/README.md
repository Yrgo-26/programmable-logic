# L16 - CAN-kontrollern I: tillståndsmaskinen och sändvägen

Ramen som tillståndsmaskin, först förklarad och sedan byggd på sändarsidan.

---

## Agenda
* Den ramsekvenserande tillståndsmaskinen som begrepp: tillståndsdiagrammet, fälttabellen och
  mönstret `STATE_LOAD_*`/skifta, innan någon VHDL skrivs.
* Att lägga till tillståndstypen och maskinens signaler i `can_controller`, och sedan live-koda
  dess sändväg.
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
* Läs [Appendix A](./appendix/a_can_controller.md). Den är projektets längsta appendix; läs
  åtminstone tillståndsdiagrammet och tabellen över de sju fältgrupper en sändning delas upp i
  (databytegruppen upprepas en gång per byte, så en tvåbytesram blir åtta laddningar).

### Under föreläsningen
* Tillståndsdiagrammet på tavlan, härlett fält för fält ur ramformatet.
* Live-kodning av sändvägen i `can_controller.vhd`.
* Toppnivån analyserad och elaborerad; `can_controller_tb` kan ännu inte köras, eftersom den
  kräver en mottagarväg, och det är [L17](../L17/README.md):s.

### Handledd grupptid
* Skriv gruppens tillståndsmaskin och sändväg.
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
