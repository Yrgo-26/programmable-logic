# L11 - Arkitektur, toppnivån, registerkartan och simulering

Från protokoll till blockschema, den toppnivå varje senare modul instansieras i, och det
simuleringsflöde resten av projektet körs på.

---

## Agenda
* Att avbilda CAN-begrepp på hårdvarublock: bittimer, CRC-motor, skiftregister, och den
  ramsekvenserande tillståndsmaskin som styr dem.
* Vem som äger vad: `bit_timer` äger *när*, skiftregistren äger bitstoppningen, `crc15` vet
  ingenting om ramar, och `can_controller` är det enda block som känner till ramformatet.
* En första titt på registerkartan som drivrutinsklassen ska konsumera, och hur den förhåller sig
  till kontrollerns portar.
* Att skriva `can_controller.vhd` från grunden: dess femton portar, och en arkitektur som börjar
  tom och växer föreläsning för föreläsning.
* Vilka av portarna som är asynkrona, och varför kontrollern synkroniserar dem själv.
* Projektets simuleringsflöde: GHDL:s tre steg, analysera, elaborera, simulera.
* Positionell portbindning: varför ordningen och typerna är kontraktet, inte namnen.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Rita kontrollerns blockschema och säga vad varje block ansvarar för, och lika viktigt, vad det
  inte ansvarar för.
* Skriva toppnivåns entitet med rätt portordning och rätt typer.
* Förklara varför arkitekturen är tom nu och vilken föreläsning som fyller vilken del av den.
* Köra GHDL:s två första steg på den tomma toppnivån, läsa vad vart och ett rapporterar, och säga
  vad det tredje steget kräver som ännu inte finns.
* Säga vad positionell portbindning köper och vad den ger upp.

---

## Förkunskaper
* [L10](../L10/README.md): CAN-ramen, arbitreringen och paketet `can_def`.
* [L02](../L02/README.md): submoduler och positionell `port map`.
* [L04](../L04/README.md): varför en asynkron ingång måste synkroniseras innan den används.

---

## Genomförande

### Förberedelse
> **Hellre boken?** Den här föreläsningen är också kapitel 11 i kursboken, på
> [svenska](../../book/sv/programmerbar-logik.pdf) och
> [engelska](../../book/en/programmable-logic.pdf). Appendix A är avsnitt 11.1-11.6, och övningarna
> i Appendix B är avsnitt 11.8. Simuleringsflödet är bokens bilaga A. Läs antingen appendixen eller
> kapitlet; innehållet är detsamma.

* Läs [Appendix A](./appendix/a_architecture_and_register_map.md), som är föreläsningens
  kärnmaterial: arkitekturen, portlistan och registerkartan.
* Läs [simuleringsflödet](../../info/simulation_workflow.md), projektets permanenta GHDL-referens.

### Under föreläsningen
* Blockschemat på tavlan, härlett ur L10:s ramformat snarare än presenterat färdigt.
* Live-kodning av `can_controller.vhd`: entiteten, och en arkitektur utan innehåll.
* GHDL körs på den tomma toppnivån, så att flödet är på plats innan det finns något att felsöka.

### Handledd grupptid
* Skriv gruppens `can_controller.vhd` med rätt portordning, och få den att analysera.
* Bestäm hur arbetet ska delas. De fyra lövmodulerna, `bit_timer`, `crc15`, `tx_shift_reg` och
  `rx_shift_reg`, beror inte på varandra och har var sin egen testbänk. En grupp om 4-5 kan bygga
  dem parallellt, och det är den enda punkt i projektet där ordningen på riktigt spelar roll för
  hur snabbt ni går framåt.
* Bestäm gruppens branch- och granskningsrutin konkret: vem granskar vad, och hur snabbt.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna, inklusive en frivillig som tar
  den tomma toppnivån genom Quartus och läser ut pinnantalet ur fitterns rapport. Det är det
  tydligaste argumentet för varför lagren ovanpå kontrollern, registerbanken i
  [L18](../L18/README.md) och `can_spi_node` i [L19](../L19/README.md), måste finnas, och det
  behöver inget kort.

---

## Riktvärde
Toppnivåns entitet bör finnas och analysera rent. Därefter är det upp till gruppen: någon kan
mycket väl börja på `bit_timer` eller `crc15` redan nu.

---

## Kontrollfrågor
* Varför äger `bit_timer` bara *när*, och inte *vad*?
* Vilket block känner till CAN-ramens format, och varför bara ett?
* Varför synkroniserar `can_controller` sina egna asynkrona ingångar i stället för att kräva att
  den som instansierar den gör det?
* Vad går sönder om ni byter plats på två portar av samma typ, och när skulle ni märka det?
* Vad gör `ghdl -a`, `ghdl -e` och `ghdl -r`, var för sig?
* Vilken registerkarterad operation svarar mot `tx_req`, och vilken mot `tx_done`?

---

## Nästa föreläsning
[L12](../L12/README.md): de två första byggblocken som går in i den tomma arkitekturen, båda
små. Synkroniseraren `meta_prev`, som inte vet någonting alls, och `bit_timer`, det första
blocket som vet något om CAN.

---
