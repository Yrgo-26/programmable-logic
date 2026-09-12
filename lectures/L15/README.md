# L15 - Mottagningsskiftregister och avstoppning

Mottagarsidans spegelbild: deserialisering, borttagning av stoppbitar, och flaggning av
stoppningsfel. Passet innehåller också projektets **obligatoriska kodgranskningsseminarium**.

---

## Agenda
* Live-kodning av `rx_shift_reg.vhd`: deserialisering, avstoppning och detektering av
  stoppningsfel.
* Att sampla mitt i bitperioden (`bit_timer.sample`) snarare än vid `bit_done`.
* `real_bit`/`real_bit_valid`: att mata `crc15` en avstoppad bit i taget.
* Verifiering mot den utdelade testbänken.
* Att instansiera `rx_shift_reg` inuti `can_controller`.
* **Kodgranskningsseminarium**: varje grupp presenterar en mergad PR och en granskning de skrivit.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera ett skiftregister som deserialiserar från bussen och kastar stoppbitar.
* Upptäcka ett stoppningsfel och säga exakt vilket villkor som utgör det.
* Förklara varför mottagaren samplar vid `sample` och sändaren skiftar vid `bit_done`.
* Mata CRC-motorn från mottagarsidan utan att räkna stoppbitar.
* Läsa någon annans VHDL och skriva en granskning som är användbar snarare än artig.

---

## Förkunskaper
* [L14](../L14/README.md): sändarsidans stoppning. Den här modulen är dess spegelbild, och
  appendixet förutsätter att ni läst den.
* [L12](../L12/README.md): `bit_timer`, och skillnaden mellan dess två pulser.
* [L06](../L06/README.md): SIPO-skiftregister.

---

## Genomförande

### Förberedelse
* Läs [Appendix A](./appendix/a_rx_shift_reg.md).
* Välj ut, i gruppen, **en mergad Pull Request** och **en granskning någon i gruppen skrivit**,
  att visa på seminariet. Det behöver inte vara den finaste; en PR som fick befogad kritik är
  mer värd att visa än en som ingen läste.

### Under föreläsningen
* Live-kodning av `rx_shift_reg.vhd`.
* Testbänken körd, med särskild vikt vid fallen för stoppningsfel.

### Kodgranskningsseminarium
Ungefär en timme, i helgrupp. Varje grupp får tio minuter och visar:
* En mergad PR: vad den ändrade, hur den var uppdelad, och vad commit-meddelandena säger.
* En granskning gruppen skrivit: vad granskaren tittade efter, och vad som faktiskt ändrades av
  kommentarerna.
* En sak som inte fungerat i arbetssättet, och vad ni gjort åt det.

Seminariet är obligatoriskt och är den ena av projektets två fasta hållpunkter. Det betygsätts
inte för sig, men det ingår i den helhetsbedömning av arbetssättet som beskrivs i
[projektspecifikationen](../../project/README.md).

### Handledd grupptid
* Skriv gruppens `rx_shift_reg.vhd` och få `rx_shift_reg_tb` att passera.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna.

---

## Riktvärde
Med `rx_shift_reg` klar finns alla fyra lövmoduler, och `can_controller` är den enda som återstår
på CAN-sidan. Grupper som ligger efter bör lägga tiden här snarare än att börja på
tillståndsmaskinen: den behöver alla fyra.

---

## Kontrollfrågor
* Varför samplar mottagaren vid `sample` snarare än vid `bit_done`?
* Exakt vilket villkor utgör ett stoppningsfel, och varför är det sex lika bitar som är gränsen
  på mottagarsidan när sändaren räknar fem?
* Vad händer med stoppbiten när den är korrekt?
* Varför får `crc15` bara se `real_bit`, och vad skulle en felaktigt matad stoppbit ställa till?
* Varför räcker det inte att räkna mottagna bitar för att veta när en byte är klar?

---

## Nästa föreläsning
[L16](../L16/README.md): ramen som tillståndsmaskin, först förklarad och sedan byggd på
sändarsidan.

---
