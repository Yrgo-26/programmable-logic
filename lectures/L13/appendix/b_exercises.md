# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_crc15.md). Konstruera er egen `crc15.vhd` utifrån
specifikationen där; den utdelade testbänken (kör den enligt
[simuleringsflödet](../../../info/simulation_workflow.md)) är kontrollen av att den beter sig
korrekt.

---

## Övning 1 - Implementera om `crc15.vhd` utifrån specifikationen
Skriv er egen `crc15.vhd` utifrån Appendix A:s specifikation. Verifiera den sedan:

```bash
cd controller
ghdl -a --std=93 can_def.vhd crc15.vhd crc15_tb.vhd
ghdl -e --std=93 crc15_tb
ghdl -r --std=93 crc15_tb --assert-level=error
```

Om en kontroll fallerar, läs assertion-meddelandet (se
[simuleringsflödet](../../../info/simulation_workflow.md)).

---

## Övning 2 - CRC för hand, sedan i simulering
**a)** Räkna för hand ut, med Appendix A:s rekursion, vilket CRC-15-resultat som blir följden av att
mata in 4-bitarssekvensen `1010` (MSB först) i en nyss nollställd motor. Visa uträkningen en bit i
taget (återkoppling, skift, villkorlig XOR).

**b)** Bekräfta ert handräknade svar med GHDL: skriv en kort testbänk (eller anpassa strukturen i
`crc15_tb.vhd`) som nollställer `crc15`, matar in `1010` och rapporterar det resulterande
`crc`-värdet, antingen via en `assert` eller via en `report ... severity note;` som ni läser direkt.

**c)** Utgången `valid` hos `crc15` läser `'1'` direkt efter reset, innan någon riktig data alls har
matats in. Förklara varför det inte är en bugg, med hänvisning till vad `can_controller` (L17)
faktiskt gör med `valid`, och när.

---

## Övning 3 - Felet som en summerad checksumma missar

[Ramningsintroduktionen](../../L10/appendix/intro_framing.md) påstod att en CRC "fångar en betydligt
bredare, matematiskt välförstådd klass av fel" än den enkla bytevisa summa som dess eget ramformat
använder. Den här övningen gör det konkret genom att köra en korruption som summan bevisligen inte
kan se genom motorn ni just byggt.

Ta nyttolasten `0x3C, 0x91` och korruptionen `0x34, 0x99`: bit 3 nollställd i den första byten, bit
3 satt i den andra, så att den ena byten förlorar exakt det den andra vinner.

**a)** Räkna ut den bytevisa checksumman för båda nyttolasterna och bekräfta att de är
**identiska**: båda blir `0xCD`. En enkel summa registrerar bara totalen, så en mottagare som
kontrollerar den skulle godta den korrupta ramen som hel.

**b)** Mata nu in alla 16 bitarna av den *ursprungliga* nyttolasten i en nyss nollställd `crc15`
(MSB först, första byten först) och notera det resulterande `crc`-värdet. Nollställ sedan och gör
samma sak med den *korrupta* nyttolasten. Stämmer de två CRC-värdena överens? Använd simulering; en
`report` av båda värdena räcker.

**c)** Egenskapen att generering och kontroll är samma operation (Appendix A) säger att en ram vars
egna CRC-bitar matas tillbaka in återför registret till noll. Mata in den **korrupta** nyttolasten
följd av den **ursprungliga** nyttolastens CRC-bitar, alltså precis det en mottagare skulle se om
den här korruptionen inträffade under transporten. Når registret noll? Går `valid` hög? Förklara vad
mottagaren drar för slutsats.

**d)** Säg med en mening vilken egenskap hos CRC-rekursionen som gör att den märker en förändring
som en summa inte kan, med hänvisning till vad varje bit gör med registret i Appendix A:s rekursion.

---

