# Examination

Kursen examineras genom **ett grupprojekt** och **två praktiska tentamina**. Totalt 100 poäng.

| Moment | När | Form | Poäng |
|---|---|---|---:|
| Praktisk tentamen 1 - sekvensnät | [L09](../lectures/L09/README.md) | Individuell, 3 h | 25 |
| Grupprojekt - en CAN-nod i VHDL | [L10](../lectures/L10/README.md)-[L19](../lectures/L19/README.md) | Grupp om 4-5 | 50 |
| Praktisk tentamen 2 - CAN-moduler | [L20](../lectures/L20/README.md) | Individuell, 3 h | 25 |

---

## Betygsgränser

| Betyg | Krav |
|---|---|
| **IG** | Under 50 poäng, eller ett underkänt projekt. |
| **G** | Minst 50 poäng totalt **och** godkänt projekt. |
| **VG** | Minst 80 poäng totalt **och** väl godkänt projekt. |

Projektet är alltså en spärr i båda riktningarna. Det står för halva kursen, det är där det mesta
av arbetet ligger, och ett underkänt projekt går inte att kompensera med två starka tentor.

---

## Grupprojektet (50 p)

Bedöms i tre delar. Kriterierna i sin helhet står i
[projektspecifikationen](../project/README.md), avsnitt 9.

| Del | Poäng |
|---|---:|
| Designen: modulerna fungerar och testbänkarna passerar | 30 |
| Arbetssättet: Git-historik, PR:er, granskningar, seminariet | 12 |
| Redovisningen | 8 |

Betyget sätts på gruppen. Är insatsen påtagligt ojämn kan enskilda betyg justeras, utifrån
`CONTRIBUTORS.md` och repots historik.

**Godkänt projekt** kräver en **komplett nod**, inte bara en kontroller: alla nio utdelade
testbänkar ska passera, `can_controller_tb` och `can_spi_node_tb` inräknade. Skälet ligger efter
den här kursen. Noden följer med er till CAN-labben i *Inbyggda system 2*, där en drivrutin ska
nå den över SPI, och en kontroller utan registerbank och brygga går inte att nå från någon
drivrutin alls.

**Väl godkänt** kräver dessutom den egna verifieringen i projektspecifikationens avsnitt 8.3, att
koden är genomgående dokumenterad och stilistiskt konsekvent, och att granskningskulturen syns i
historiken.

Bring-up på riktig hårdvara bedöms inte. Allt som bedöms går att köra i GHDL på en vanlig laptop,
så ett trasigt kit kostar aldrig poäng.

---

## De praktiska tentorna (25 p vardera)

Båda är individuella, tre timmar, vid datorn med GHDL.

Formen är densamma i båda: fristående uppgifter, oberoende av varandra och ordnade ungefär efter
stigande svårighet.

De flesta uppgifterna är **skrivuppgifter**: en utdelad, självkontrollerande testbänk och en
beskrivning av modulen den driver, med portordning och beteende. Uppgiften är att skriva modulen
så att testbänken passerar.

[L20](../lectures/L20/README.md) har därutöver **läsuppgifter**: ett tidsdiagram eller en
SPI-transaktion att tolka på papper. De har ingen testbänk, av precis det skäl som gör dem värda
att ställa - att läsa en vågform är en färdighet i sig, och den examineras inte av att skriva
VHDL. De rättas mot ett facit, och delvis rätt svar ger delpoäng på samma sätt som delvis korrekt
logik gör.

* **Delvis korrekt logik ger delpoäng.** Lämna aldrig in en tom fil för att modulen inte blev
  klar. Samma sak gäller ett halvt uttolkat tidsdiagram.
* Rättningen läser koden, inte bara testbänkens utfall. En modul som passerar genom att göra något
  annat än det som efterfrågades ger inte full poäng.

### Hjälpmedel
Det här avsnittet är den **auktoritativa** listan. Står något annat i en föreläsnings README
gäller det som står här.

Tillåtet vid båda tentorna:
* Allt kursmaterial i det här repot: föreläsningarnas README och samtliga appendix. Vid
  [L20](../lectures/L20/README.md) hör [registerkartan](../project/register_map.md) och
  [protokollspecifikationen](../project/spi_register_protocol.md) förstås dit; vid
  [L09](../lectures/L09/README.md) finns de också tillgängliga, men examineras inte.
* All VHDL du själv skrivit under kursen, och vid L20 även gruppens projektkod.
* Egen dator med GHDL, och [CircuitVerse](https://circuitverse.org/simulator). Båda tentorna,
  även L20: att rita en krets innan man skriver den är ofta snabbare.

Inte tillåtet:
* **Kommunikation med andra**, i någon form.
* **Verktyg som genererar eller förklarar VHDL åt dig**: språkmodeller, kodassistenter och
  liknande, oavsett om de skriver koden eller bara resonerar om den. Gränsen går inte vid vem som
  trycker på tangenterna utan vid vems förståelse som prövas.
* **Sökning på nätet efter lösningar.** CircuitVerse körs i en webbläsare, så datorn är uppkopplad,
  och det förutsätter att ni håller er till kursmaterialet av egen kraft. Att slå upp GHDL:s eller
  VHDL:s dokumentation är tillåtet; att söka efter en färdig modul är det inte.

Är du osäker på om något är tillåtet: fråga före tentan, inte under.

Att gruppens projektkod är tillåten vid L20 är ett medvetet val. Ni byggde den. Uppgifterna är i
stället skrivna som varianter och reparationer, så att de skiljer sig från projektets moduler på
just den punkt som kräver att man förstått dem.

### Omfattning
* **[L09](../lectures/L09/README.md)** omfattar L01-L08, med tyngdpunkt på sekvensnät: register,
  räknare, skiftregister, timers, synkroniserare och enkla Mooremaskiner. Ett övningsprov delas ut
  i förväg.
* **[L20](../lectures/L20/README.md)** omfattar projektets moduler: bittajming, CRC,
  bitstoppning åt båda hållen, ramsekvensering, registersemantik och SPI-transaktionen.

---

## Omexamination

Båda tentorna går att skriva om. Projektet lämnas in en gång, med möjlighet till komplettering
efter besked från handledaren: en komplettering rättas mot godkänt, inte mot väl godkänt.

---

## Frånvaro

Kodgranskningsseminariet i [L15](../lectures/L15/README.md) och slutredovisningen i
[L19](../lectures/L19/README.md) är projektets två obligatoriska hållpunkter. Missad närvaro tas
igen efter överenskommelse med handledaren.

Övriga pass har ingen närvaroplikt. Grupprojektet har däremot en gruppdynamik som inte tål att
någon uteblir, vilket är ett annat och starkare skäl att komma.

---
