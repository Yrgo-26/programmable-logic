# Kontrollern

Här byggs CAN-kontrollern. I det här repot innehåller katalogen bara de **utdelade filerna**:
testbänkarna och paketet `can_def.vhd`. Modulerna är gruppens att skriva, i gruppens eget repo.
Kopiera in katalogen där, eller lägg modulerna bredvid testbänkarna här, så börjar varje testbänk
köra så snart alla filer den namnger finns.

Allt ligger platt i en katalog: modulerna bredvid testbänkarna som kontrollerar dem. Ingenting
kopieras mellan föreläsningskataloger, och `can_def.vhd` finns en gång och läses av allt. Paketet
läggs in oförändrat: sex av testbänkarna läser dess namn och typer, så det är en del av kontraktet.

---

## Vad som hamnar här, och när

| Fil | Skrivs i | Utdelad |
|---|---|:---:|
| `can_def.vhd` | | ja |
| `meta_prev.vhd` | L12 | |
| `meta_prev_tb.vhd` | | ja |
| `bit_timer.vhd` | L12 | |
| `bit_timer_tb.vhd` | | ja |
| `crc15.vhd` | L13 | |
| `crc15_tb.vhd` | | ja |
| `tx_shift_reg.vhd` | L14 | |
| `tx_shift_reg_tb.vhd` | | ja |
| `rx_shift_reg.vhd` | L15 | |
| `rx_shift_reg_tb.vhd` | | ja |
| `can_controller.vhd` | L11 (entiteten), L16 (sändning), L17 (mottagning) | |
| `can_controller_tb.vhd` | | ja |

`can_controller.vhd` skrivs tidigt och växer sedan: L16 och L17 lägger till beteende i den snarare
än en ny fil.

SPI-halvan ligger inte här utan i [`bridge/`](../bridge/README.md): registerbanken,
transaktionsbryggan och toppnivån `can_spi_node`. Gränsen går vid protokollet. Allt i den här
katalogen känner till CAN och ingenting om SPI.

---

## Att köra en testbänk

Från den här katalogen, GHDL:s tre steg, beroenden först:

```bash
ghdl -a --std=93 can_def.vhd bit_timer.vhd bit_timer_tb.vhd
ghdl -e --std=93 bit_timer_tb
ghdl -r --std=93 bit_timer_tb --assert-level=error
```

`can_controller_tb` är systemtestbänken: två noder på en wired-AND-buss, som kontrollerar både
mottagning och arbitrering. Den behöver alla moduler analyserade först:

```bash
ghdl -a --std=93 can_def.vhd meta_prev.vhd bit_timer.vhd crc15.vhd tx_shift_reg.vhd \
     rx_shift_reg.vhd can_controller.vhd can_controller_tb.vhd
ghdl -e --std=93 can_controller_tb
ghdl -r --std=93 can_controller_tb --assert-level=error
```

Eller allt som är färdigt, från repots rot:

```bash
make build-project
```

som hoppar över (snarare än underkänner) varje testbänk vars moduler ännu inte finns, och hoppar
över den här sista tills `can_controller` faktiskt kan ta emot, vilket är [L17](../lectures/L17/README.md):s
arbete. Se [simuleringsflödet](../info/simulation_workflow.md) för hela förklaringen av de tre
stegen, `--assert-level=error`, hur ett fel läses, och hur den sista överhoppningen avgörs.

> **Den sista överhoppningen tittar på era interna signalnamn.** Ingen ny fil dyker upp när
> mottagarvägen skrivs, så `ci/build_project.sh` letar i stället efter L17:s CRC-grindning inuti
> `can_controller.vhd`:
>
> ```vhdl
> crc_enable <= (txsr_bit_valid and not txsr_stuff and role) or
>               (rxsr_real_bit_valid and not role);
> ```
>
> Det är en gissning, inte ett beroende, och den slår fel åt ett håll: en **korrekt**
> mottagarväg som stavar de här uttrycken annorlunda rapporteras som *skipped* när den skulle ha
> körts. Överhoppad är aldrig underkänd, så ingenting annat säger ifrån - och `can_controller_tb`
> är den testbänk som avgör godkänt på projektet ([examination](../info/examination.md)).
>
> Ser ni den överhoppningen när mottagarvägen är klar: kör
>
> ```bash
> CI_BUILD_ALL=1 make build-project
> ```
>
> som kör varje testbänk oavsett. Det är utfallet därifrån som gäller. Behåll gärna namnen ovan
> ändå; de är appendixens och kostar ingenting.

---

## Portordning

Varje testbänk binder till modulen den driver **positionellt**, och det gör varje instansiering
inuti `can_controller` också. Ingenting i det här projektet binder en port vid namn.

Kontraktet är alltså **ordningen och typerna** på portarna, exakt som varje appendix
gränssnittstabell listar dem, uppifrån och ned. Portarnas *namn* är era: döp `bit_done` till något
annat och allt binder fortfarande, så länge den förblir `bit_timer`s sjätte port och fortfarande
är en `std_logic`-utgång.

Den affären är värd att förstå snarare än bara följa. Positionell bindning är kortare att skriva
och att läsa, och den gör gränssnittstabellen till enda sanningskälla. Det den ger upp är
kompilatorns hjälp: byt plats på två portar av samma typ och ingenting klagar vid analys, utan
designen beter sig helt enkelt fel i simuleringen i stället. Appendixen behåller ändå sina
portnamn, så att texten och er kod talar om samma signaler.

---
