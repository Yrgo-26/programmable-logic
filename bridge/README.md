# Bryggan

SPI-halvan av projektet: lagret som gör [`controller/`](../controller/README.md)s CAN-kontroller
nåbar från en AVR32DB28. Kontrollerns portar är gjorda för en anropare i samma klockdomän som ser
varje cykel; en drivrutin som pollar över SPI gör inte det, och den här katalogen är
översättningen mellan de två världarna.

Kontraktet är [SPI- och registerprotokollet](../project/spi_register_protocol.md) och
[registerkartan](../project/register_map.md). Där de och en implementation säger emot varandra är
det specifikationen som gäller, eftersom parallellklassens drivrutin skrivs mot den och inte mot
er kod.

---

## Vad som hamnar här, och när

| Fil | Skrivs i | Utdelad |
|---|---|:---:|
| `register_bank.vhd` | L18 | |
| `register_bank_tb.vhd` | | ja |
| `spi_def.vhd` | | ja |
| `spi_slave.vhd` | | ja |
| `spi_reg_bridge.vhd` | L19 | |
| `spi_reg_bridge_tb.vhd` | | ja |
| `can_spi_node.vhd` | L19 | |
| `can_spi_node_tb.vhd` | | ja |

Tre lager, med varsitt ansvar och inget överlapp:

* **`spi_slave`** talar bara *bytes*. Den synkroniserar in `sclk`/`mosi`/`ss` i 50 MHz-domänen,
  detekterar flanker på SCK i stället för att klocka på den, och lämnar över en färdig byte i
  taget. Den vet ingenting om register. **Utdelad**, eftersom den är transport och inte kursens
  ämne; läs den i [L18](../lectures/L18/README.md), skriv den inte.
* **`spi_reg_bridge`** talar *transaktioner*: kommandobyten, de fyra databytesen, låsningen en
  gång vid läsning, verkställandet på femte byten, och avbrottet när SS går hög för tidigt. Den
  vet ingenting om vilka register som finns.
* **`register_bank`** talar *registersemantik*: klibbiga STATUS-bitar, `TX_SEND` som en
  encykelspuls, infångning av mottagen ram, maskning vid skrivning. Den vet ingenting om SPI.

`can_spi_node` är toppnivån som instansierar de tre plus `can_controller`. Den är rent
strukturell.

`spi_def.vhd` är ett litet utdelat paket med transportens egen konstant och testbänkarnas
`to_hex`. Registerindexen står medvetet inte där utan enbart i registerkartan: att namnge dem två
gånger är precis så de två sidorna glider isär. Varje konsument härleder sina egna lokala
konstanter ur indexkolumnen, så som testbänkarna gör.

---

## Att köra en testbänk

Från den här katalogen, med `can_def.vhd` från `controller/`:

```bash
ghdl -a --std=93 ../controller/can_def.vhd register_bank.vhd register_bank_tb.vhd
ghdl -e --std=93 register_bank_tb
ghdl -r --std=93 register_bank_tb --assert-level=error
```

Bryggan läser inget register alls och behöver därför bara `spi_def`:

```bash
ghdl -a --std=93 spi_def.vhd spi_reg_bridge.vhd spi_reg_bridge_tb.vhd
ghdl -e --std=93 spi_reg_bridge_tb
ghdl -r --std=93 spi_reg_bridge_tb --assert-level=error
```

Eller allt som är färdigt, från repots rot, med `make build-project`.

`register_bank_tb` går igenom elva fall: reset-tillståndet, skrivning och återläsning med maskning,
en accepterad `TX_SEND`, en `TX_SEND` medan sändning pågår, `tx_done` som återställer, en
`TX_SEND` av `0x0`, infångning och överskrivning av mottagen ram plus `RX_ACK`, felflaggans
flanksemantik, de reserverade indexen, och de två vägar som ger tillbaka TX-klar efter en avbruten
sändning - en automatisk, på en stigande flank av `error`, och en via `TX_ABORT`.

De två sista är värda att läsa innan ni skriver modulen. Utan dem fastnar noden efter sin första
förlorade arbitrering, och eftersom en tvånodsbuss provocerar det i normal drift är det inte ett
hörnfall.

Portordningen är kontraktet, precis som i `controller/`: bindningen är positionell överallt.

---
