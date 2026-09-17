# L11 - Arkitektur, toppnivån, registerkartan och simulering

Från protokoll till blockschema, den toppnivå varje senare modul instansieras i, och det
simuleringsflöde resten av projektet körs på. Passet innehåller också **Git-introduktionen**, och
gruppens repo sätts upp här.

---

## Agenda
* Att avbilda CAN-begrepp på hårdvarublock: bittimer, CRC-motor, skiftregister, och den
  ramsekvenserande tillståndsmaskin som styr dem.
* Vem som äger vad: `bit_timer` äger *när*, skiftregistren äger bitstoppningen, `crc15` vet
  ingenting om ramar, och `can_controller` är det enda block som känner till ramformatet.
* En första titt på registerkartan som drivrutinsklassen ska konsumera, och hur den förhåller sig
  till kontrollerns portar.
* `can_controller` på tavlan: blocket med sina femton portar, och en arkitektur som börjar tom och
  växer föreläsning för föreläsning. Entiteten skriver gruppen själv.
* Vilka av portarna som är asynkrona, och varför kontrollern synkroniserar dem själv.
* Projektets simuleringsflöde: GHDL:s tre steg, analysera, elaborera, simulera.
* Positionell portbindning: varför ordningen och typerna är kontraktet, inte namnen.
* Git-introduktion, ungefär en timme: från ett tomt repo till en granskad och mergad Pull Request.

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
* Ta en ändring från en egen branch till `main` via en granskad Pull Request, lösa en
  mergekonflikt, och redogöra för gruppens arbetssätt: branchning, PR:er och granskning.

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
* Skaffa ett GitHub-konto om du inte redan har ett, och kontrollera att `git --version` fungerar i
  terminalen där du kör GHDL. Ingen förkunskap i Git förutsätts.

### Under föreläsningen
* Blockschemat på tavlan, härlett ur L10:s ramformat snarare än presenterat färdigt.
* `can_controller` på tavlan: blocket med sina femton portar i kontraktets ordning, och en
  arkitektur utan innehåll.
* GHDL:s tre steg, och vad vart och ett kräver, så att flödet är på plats innan det finns något att
  felsöka.

### Git-introduktion
Ungefär en timme, i helgrupp, innan grupptiden börjar. Den börjar från noll och slutar i det flöde
[projektspecifikationen](../../project/README.md) kräver:
* Varför versionshantering: historik, parallellt arbete, och en granskning som finns skriftligt.
* Grundbegreppen: repo, commit, branch och `main`, och skillnaden mellan ert lokala repo och det
  på GitHub.
* Det dagliga flödet: `git clone`, `git switch -c`, `git status`, `git add`, `git commit`,
  `git push`, och `git pull` för att hämta de andras ändringar.
* Commit-meddelanden som säger vad ändringen gör, inte bara att den finns.
* Pull Requests på GitHub: att öppna en, att granska med kommentarer, att begära ändringar eller
  godkänna, och att merga.
* Branchskydd på `main`, så att regeln att all kod går via en granskad PR inte beror på att alla
  kommer ihåg den.
* Mergekonflikter: varför de uppstår och hur de löses. `can_controller.vhd` är den fil där de
  kommer att uppstå, eftersom varje lövmodul instansieras i den från [L12](../L12/README.md) och
  framåt.

### Handledd grupptid
Kortare än i de andra passen, eftersom Git-introduktionen tar sin del av tiden.
* Sätt upp gruppens repo: privat på GitHub, alla medlemmar plus handledare inbjudna,
  `CONTRIBUTORS.md` på plats, skyddad `main`.
* Lägg in de utdelade filerna från [`controller/`](../../controller/README.md) och
  [`bridge/`](../../bridge/README.md), oförändrade: testbänkarna, `can_def.vhd`, `spi_def.vhd` och
  `spi_slave.vhd`. Gör det via gruppens första Pull Request, granskad av någon annan än den som
  öppnade den, så att hela gruppen har gått igenom flödet en gång innan det gäller på riktigt.
* Skriv gruppens `can_controller.vhd` med rätt portordning, kör GHDL:s två första steg på den, och
  lägg in den via en PR.
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
Gruppens repo bör finnas, med skyddad `main`, och de utdelade filerna bör ha nått `main` via en
granskad Pull Request. Toppnivåns entitet bör finnas och analysera rent. Därefter är det upp till gruppen:
någon kan mycket väl börja på `bit_timer` eller `crc15` redan nu.

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
