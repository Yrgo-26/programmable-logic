# L18 - Registerbanken och SPI från vågformen

Här börjar den halva som gör kontrollern nåbar från en mikrokontroller. `can_controller`s portar
är gjorda för en anropare i samma klockdomän som ser varje cykel; en drivrutin som pollar över SPI
gör inte det. Registerbanken är översättningen mellan de två världarna.

---

## Agenda
* Varför `tx_done` och `rx_valid` som encykelspulser är oanvändbara för en pollande drivrutin, och
  vad registerkartan lovar i stället: klibbiga, pollbara nivåer med uttryckliga nollställningar.
* Live-kodning av `register_bank.vhd`: STATUS-låsningen, `TX_SEND` som en skrivutlöst händelse,
  infångning av mottagen ram, och maskning vid skrivning.
* SPI från vågformen och uppåt: lägen, MSB först, SS som ramning.
* Varför slaven **inte** klockar på SCK utan översamplar den i 50 MHz-domänen, och vad `meta_prev`
  har med saken att göra.
* Genomgång av den utdelade `spi_slave.vhd`, byte-motorn som får `SCK`/`MOSI`/`SS` säkert in i
  systemklockdomänen och lämnar över en ren byte i taget.

---

## Mål
Efter den här föreläsningen ska ni kunna:
* Förklara skillnaden mellan en puls och en klibbig nivå, och varför registerlagret måste
  konvertera mellan dem.
* Implementera `register_bank.vhd` enligt registerkartan: STATUS-bitarnas sättning och
  nollställning, `TX_SEND` som encykelspuls, och maskningen vid skrivning.
* Läsa ett SPI-tidsdiagram i läge 0 och säga vilken bit som ligger på MOSI vid varje flank.
* Förklara varför en SPI-slav i en FPGA översamplar SCK i stället för att använda den som klocka.
* Läsa och använda `spi_slave.vhd` utan att skriva den.

---

## Förkunskaper
* [L11](../L11/README.md): `can_controller`s portar på registersidan, som den här modulen
  översätter. Modulen kan skrivas långt innan kontrollern är färdig - den behöver bara `can_def`.
* [L04](../L04/README.md): dubbelvippsynkroniseraren. Den är hela svaret på varför SCK inte får
  vara en klocka.
* [L03](../L03/README.md) och [L06](../L06/README.md): flankdetektering och skiftregister, som är
  allt `spi_slave` består av.
* [SPI- och registerprotokollet](../../project/spi_register_protocol.md), som är den
  auktoritativa specifikationen för hela det här och nästa pass.

---

## Genomförande

### Förberedelse
* Läs [Appendix A](./appendix/a_register_bank.md), som är registerbankens fullständiga
  beskrivning: portlista, STATUS-tabell, maskningstabell och vad testbänken låser fast.
* Läs [protokollspecifikationen](../../project/spi_register_protocol.md), åtminstone avsnitten om
  elektriskt gränssnitt och registersemantik.
* Rita, för hand, vågformen för läge 0 när byten `0xA5` skiftas ut. Ta med den till passet.

### Under föreläsningen
* Live-kodning av `register_bank.vhd`, och dess utdelade testbänk `register_bank_tb` körd direkt.
* SPI-vågformen på tavlan, och sedan `spi_slave.vhd` läst rad för rad.

### Handledd grupptid
* Skriv gruppens `register_bank.vhd` och få `register_bank_tb` att passera. Den är utdelad och
  täcker elva fall, från reset-tillståndet till `TX_ABORT` och de två vägar som ger tillbaka
  TX-klar efter en avbruten sändning.
* Lägg in den utdelade `spi_slave.vhd` i repot oförändrad.

### Efter föreläsningen
* [Appendix B](./appendix/b_exercises.md) innehåller övningarna. Övning 1 är registerbanken
  själv; övning 4 är SPI-transaktionen läst ur vågformen, och den formen av uppgift kan dyka upp
  på [L20](../L20/README.md).
* Läs igenom `spi_reg_bridge_tb.vhd` i [`bridge/`](../../bridge/README.md) inför nästa pass. Den
  är kontraktet för modulen ni skriver då.

---

## Riktvärde
`register_bank` är en avgränsad modul med en fullständig testbänk och bör gå att bli klar med
under passet och veckan efter. Den beror inte på SPI alls, så den kan skrivas parallellt med att
någon annan i gruppen läser in sig på transaktionsformatet.

---

## Kontrollfrågor
* Varför kan en drivrutin som pollar var femte mikrosekund inte se en puls på 20 ns?
* Vad sätter STATUS bit 0, och vad nollställer den?
* Varför låser felbiten på en *stigande flank* av `error` och inte på nivån?
* En andra ram tas emot innan den första kvitterats. Vad händer, och varför är det ett medvetet
  val snarare än en bugg?
* STATUS bit 0 sätts av tre saker under drift, utöver reset. Vilka, och varför räcker det inte
  med `tx_done` ensamt?
* Vad gör `TX_ABORT`, och vad når det *inte*?
* En skrivning av `0xFFFFFFFF` till `TX_DLC` läses tillbaka som `0x0000000F`. Var sker maskningen,
  och varför validerar banken inte att värdet är högst 8?
* Varför använder `spi_slave` inte SCK som klocka? Vad skulle gå fel om den gjorde det?
* Varför byter MISO värde på SCK:s fallande flank?

---

## Nästa föreläsning
[L19](../L19/README.md): SPI-bryggan, toppnivån `can_spi_node`, och bring-up mot en riktig
AVR32DB28. Projektets sista pass.

---
