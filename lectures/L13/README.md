# L13 - CRC-15-motorn

En motor, två jobb.

---

## Agenda
* Live-kodning av `crc15.vhd`, en bitseriell CRC-15-motor.
* Varför samma motor både genererar och kontrollerar en CRC, utan lägesomkoppling.
* Varför den ändå behöver ett `clear`, och vad en avbruten ram lämnar efter sig utan det.
* En kort CRC arbetad genom rekursionen för hand.
* Verifiering mot den utdelade testbänken.
* Att instansiera `crc15` inuti `can_controller`.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Implementera en bitseriell CRC-15-motor som matchar CAN:s polynom.
* Förklara varför generering och kontroll är samma operation, och vad ett nollställt CRC-register
  vid slutet av en mottagen ram bevisar.
* Räkna några bitar genom rekursionen för hand och jämföra med simuleringen.
* Säga varför motorn behöver nollställas mellan ramar, och vilket fel som uppstår om den inte gör
  det.

---

## Förkunskaper
* [L12](../L12/README.md): den första modulen och den första testbänken.
* [L10](../L10/README.md): `CRC_POLY` och `CRC_WIDTH` ur `can_def`, och varför CRC:n bara täcker
  de riktiga bitarna och inte stoppbitarna.
* [L03](../L03/README.md) och [L06](../L06/README.md): skiftregister och den klockade
  processmallen. En CRC-motor är ett skiftregister med återkoppling.

---

## Genomförande

### Förberedelse
* Läs [Appendix A](./appendix/a_crc15.md).

### Under föreläsningen
* Rekursionen på tavlan först: XOR av insignalen med högsta CRC-biten, skifta, och XOR:a med
  polynomet när det behövs.
* Live-kodning av `crc15.vhd`.
* Testbänken körd direkt, och en kort sekvens jämförd mot handräkningen.

### Handledd grupptid
* Skriv gruppens `crc15.vhd` och få `crc15_tb` att passera.
* `crc15` beror inte på `bit_timer` och kan mycket väl ha byggts redan. Är den klar är det här
  passet ett bra tillfälle att komma ikapp med det som inte är det.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna, däribland en som gör konkret
  varför en CRC fångar fel som en enkel bytesumma missar.

---

## Riktvärde
Vid det här laget bör två av de fyra lövmodulerna vara klara. Vilka två spelar ingen roll.

---

## Kontrollfrågor
* Varför behöver motorn inget läge för "generera" respektive "kontrollera"?
* Vad betyder det att CRC-registret är noll efter att en mottagen ram matats igenom?
* Vad händer om en ram avbryts och nästa ram börjar matas in utan `clear`?
* Varför matas en instoppad bit inte in i CRC-motorn?
* Vilken signal i `can_controller` avgör när `crc15` får uppdatera sig, och varför är det inte
  `bit_done`?

---

## Nästa föreläsning
[L14](../L14/README.md): sändningsskiftregistret. Att serialisera ut på bussen, med samma
stoppbitsregel som i [L10](../L10/README.md), nu i VHDL.

---
