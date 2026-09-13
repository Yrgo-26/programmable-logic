# L20 - Praktisk tentamen 2: CAN-moduler

Kursens andra och sista examinationstillfälle. Tre timmar, individuellt, vid datorn. Tentamen
omfattar **projektets moduler**: bittajming, CRC, bitstoppning, ramsekvensering, registersemantik
och SPI-transaktionen.

Se [info/examination.md](../../info/examination.md) för poäng och betygsgränser.

---

## Varför en individuell tentamen på ett grupparbete
Projektet bedöms i grupp och står för halva kursen. Den här tentamen mäter något annat: att var
och en förstår det gruppen byggde, inte bara den del man själv skrev. Uppgifterna är därför
hämtade ur alla delar av projektet, oavsett vem i gruppen som skrev vilken modul.

---

## Upplägg
Samma form som [L09](../L09/README.md): fristående uppgifter, var och en med en utdelad,
självkontrollerande testbänk och en beskrivning av modulen den driver. Skriv modulen så att
testbänken passerar.

Uppgifterna är av dessa slag:
* **Varianter.** En `bit_timer` med en annan sampelpunkt eller en annan bithastighet. En
  stoppningsdetektor som räknar ett annat antal. En CRC med ett annat polynom.
* **Reparationer.** En given tillståndsmaskin eller ett givet skiftregister som är nästan rätt.
  Hitta felet med hjälp av testbänkens utskrift och åtgärda det.
* **Ett enskilt register.** Ett register ur registerbanken, med sin sättnings- och
  nollställningsregel, isolerat från resten.
* **Läsning.** Ett tidsdiagram eller en SPI-transaktion att tolka på papper: vad ligger på bussen,
  och vad borde ha legat där?

Uppgifterna är oberoende av varandra och ordnade ungefär efter stigande svårighet. Delvis korrekt
logik ger delpoäng.

---

## Detta får du använda
* Allt kursmaterial, inklusive samtliga appendix,
  [protokollspecifikationen](../../project/spi_register_protocol.md) och
  [registerkartan](../../project/register_map.md).
* **Gruppens egen projektkod.** Ni byggde den; det vore konstigt att låtsas annat. Uppgifterna är
  skrivna så att avskrift inte hjälper: varianterna skiljer sig på just den punkt som kräver att
  man förstått modulen.
* Din egen dator med GHDL, och [CircuitVerse](https://circuitverse.org/simulator) om du vill rita
  en krets eller en vågform innan du skriver den.

Detta får du **inte** använda: kommunikation med andra i någon form, språkmodeller och andra
verktyg som genererar eller förklarar VHDL åt dig, och sökning på nätet efter färdiga lösningar.

Den fullständiga och auktoritativa hjälpmedelslistan står i
[examination.md](../../info/examination.md); står något annat här gäller den.

---

## Före tentamen
> **Hellre boken?** Den här sidan är också kapitel 20 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Kontrollfrågorna finns i sammanfattningen sist i
> kapitel 12 till 19.

* Gå igenom de moduler i projektet som *någon annan* i gruppen skrev. Det är där luckorna finns.
* Kontrollfrågorna sist i [L12](../L12/README.md) till [L19](../L19/README.md) är avsiktligt
  skrivna som repetitionsmaterial. Kan du svara på alla utan att slå upp något är du klar.
* Läs igenom de utdelade testbänkarna en gång till. De är det tydligaste som finns om exakt vad
  varje modul lovar.

---

## Det här mäter tentamen
* Att du kan omsätta en specifikation i ord till en korrekt modul, med rätt portordning.
* Att du förstår bittajmingen: varför sampelpunkten ligger där den ligger, och vilken puls som gör
  vad.
* Att du kan resonera om bitstoppning åt båda hållen.
* Att du kan skilja en puls från en klibbig nivå, och veta vilket lager som ansvarar för vilket.
* Att du kan läsa en testbänks utskrift och hitta tillbaka till orsaken.

---

## Efter kursen
Kontrollern ni byggt går vidare till parallellklassen, som skriver C++-drivrutinen mot samma
register över samma SPI-transport. Det som håller ihop de två halvorna är
[registerkartan](../../project/register_map.md) och
[protokollspecifikationen](../../project/spi_register_protocol.md).

Över tjugo pass har kursen gått från en grind på ett papper till en CAN-nod som en mikrokontroller
kan prata med. Varje mönster på vägen, dubbelvippsynkroniseraren, den klockade processmallen,
Mooremaskinen, och till sist uppdelningen i block med ett tydligt ansvar var, är allmängods i
digital konstruktion och följer med oförändrat in i vad ni än bygger härnäst.

---
