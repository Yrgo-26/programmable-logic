# Appendix A

## Att verifiera hela systemet
`can_controller` är färdig från och med L17: sändning, mottagning och arbitrering. Den instansierar
`bit_timer`, `crc15` och båda skiftregistren inuti sig själv, så utifrån sett är hela kontrollern
en enda komponent med det 15-portars gränssnitt på registernivå som L11 förhandsvisade.

Sedan går två lager framför den, och de är vad det här passet och det förra är till för:
`register_bank` (L18) gör om det gränssnittet till registerkartan, och `spi_reg_bridge` plus den
utdelade `spi_slave` gör om registerkartan till en fembytes SPI-transaktion. Det parallellklassen
skriver sin drivrutin mot är den bortre änden av den kedjan - registerkartan och
protokollspecifikationen, aldrig `can_controller`s portar.

Det här appendixet handlar om lagret under alltihop. Innan någon del av transporten går att lita på
måste kontrollern visas fungera som ett *system*.

Det betyder inte en modul mot en attrapp, utan två oberoende noder på en ledning som bråkar om den
så som riktiga noder gör.

---

### Att modellera bussen
Ingenting i konstruktionen modellerar den delade bussen, och det är medvetet. `can_controller`
driver ett par `(tx_bus, bus_en)` och läser `rx_bus`, vilket är precis vad en riktig CAN-transceiver
presenterar på sin digitala sida (L10). Wired-AND:et bor i testbänken, och på hårdvara bor det i
transceivern.

`can_controller_tb.vhd` instansierar två noder på en ledning och kombinerar dem direkt. Varje nods
effektiva utgång är dess drivna värde när `bus_en = '1'`, annars släppt (`'1'`), och bussen är
deras AND, så den läser dominant i samma ögonblick som *någon* av noderna drar låg:

```vhdl
bus_line <= (a_tx_bus or not a_bus_en) and (b_tx_bus or not b_bus_en);
```

Den enda raden är hela L10:s "vilken dominant som helst slår alla recessiva", och det är den som
gör arbitreringen testbar i simulering.

Värd att räkna igenom snarare än att läsa. Varje nod bidrar med `tx_bus or not bus_en`, som är `1`
så fort den släppt bussen, och ledningen är de två bidragen AND:ade:

| Nod A  | Nod B  | `a_tx_bus` | `a_bus_en` | `b_tx_bus` | `b_bus_en` | `bus_line` |
|--------|--------|:----------:|:----------:|:----------:|:----------:|:----------:|
| släppt | släppt | `-` | `0` | `-` | `0` | `1` recessiv |
| driver dominant | släppt | `0` | `1` | `-` | `0` | `0` dominant |
| släppt | driver dominant | `-` | `0` | `0` | `1` | `0` dominant |
| driver dominant | driver dominant | `0` | `1` | `0` | `1` | `0` dominant |

En släppt nods `tx_bus` är `-` därför att den faktiskt inte spelar någon roll: `not bus_en` ensamt
gör dess bidrag till `1`, så en nod som släppt taget kan inte påverka ledningen oavsett vad dess
utgång råkar ligga på. Över alla sexton ingångskombinationer läser ledningen dominant exakt när
minst en nod har `bus_en = '1'` med `tx_bus = '0'`, vilket är regeln uttryckt som hårdvara.

Två rader bär arbitreringsargumentet. **Rad två är själva tvekampen:** A driver dominant, B sänder
recessivt och har därför släppt, och ledningen läser dominant. B, som övervakar medan den sänder,
ser att den sänt recessivt och att bussen läser dominant, och det är precis det förlustvillkor L17
kontrollerar. Samtidigt läser A tillbaka exakt den bit den sände och märker ingenting.

**Rad ett är varför förloraren kan gå.** När B slutat driva bidrar den med `1` för alltid, så
ledningen är A:s ensam. Förlorarens reträtt är osynlig för vinnaren, och det är det som gör en
kollision till en icke-händelse i stället för något båda noderna måste återhämta sig från.

Rad fyra är värd en blick också: när båda noderna driver dominant är ledningen dominant och var och
en läser tillbaka det den sände, så ingen av dem kan märka att den andra finns. Det är det normala
tillståndet för varje dominant bit i identifieraren innan de två ID:na skiljer sig åt.

---

### De två scenarierna
1. **Mottagning.** Nod A sänder en ram på 5 bytes (ID `0x123`, data `11 22 F8 44 55`) medan nod B
   tar emot den. `0xF8` framtvingar en stoppbit inne i datafältet, så båda sidors CRC-motorer måste
   hoppa över den. Testbänken kontrollerar A:s `tx_done` och B:s `rx_valid`, att B rekonstruerade
   ID:t, DLC:n och **varje** databyte på sin fasta position, och att ingen av noderna höjde `error`.
2. **Arbitrering.** Noderna A (ID `0x000`) och B (ID `0x001`) begär båda under samma cykel, och
   skiljer sig bara i identifierarens sista bit. A måste vinna och fullborda normalt, ovetande om
   att någon tvekamp ägt rum; B måste upptäcka förlusten vid den biten, höja `error` och sluta
   driva. Kontrollen körs efter att A:s ram är klar, så den bekräftar också att B:s `error`
   fortfarande går att läsa då, i stället för att ha suddats av ett återinträde i `STATE_START`
   (L16:s regel om ledig buss).

En sändande nod tar aldrig emot sin egen ram (`rx_shift_reg` går bara medan `role = '0'`), så båda
scenarierna behöver verkligen två noder; inget av dem skulle gå att testa med en ensam nod.

De två encykelspulser det första scenariot väntar på, A:s `tx_done` och B:s `rx_valid`, **låses** i
testbänken, eftersom två oberoende tillståndsmaskiner inte behöver pulsa på samma flank, och ett
rakt `wait until (a = '1' or b = '1')` skulle återuppta på den första och missa den andra.

---

### Vad testbänken inte täcker
Två godkända scenarier är inte samma sak som en bevisad konstruktion, och att veta var en testbänk
slutar hör till att läsa den. Fem luckor är värda att namnge, eftersom var och en är ett ställe där
den här konstruktionen antingen är förenklad med flit eller helt enkelt otestad:
* **Båda noderna delar en `clock` och en `reset_n`.** Riktiga noder går på oberoende oscillatorer
  och driver isär. Var precisa med vad det lämnar otestat, för det är inte `resync` självt: båda
  noderna pulsar `resync` vid varje rams början (L16), och den pulsen är det som fasriktar B:s
  sampelpunkter mot det godtyckliga ögonblick då A började sända, så fall 1 misslyckas utan den.
  Vad en delad klocka aldrig kan pröva är **drift**, två timrar som startar i fas och vandrar isär
  mitt i ramen, fallet som L12 övning 4 kvantifierar och skälet till att riktig CAN synkroniserar
  om vid varje flank från recessiv till dominant i stället för en gång per ram. Det här är den
  största luckan, och att sluta den i simulering kräver en andra klockgenerator med en avsiktlig
  frekvensavvikelse. Bring-upen i [Appendix B](./b_fpga_bringup_and_review.md) får en ram tvärs
  över **två kort** med två separata kristaller, äntligen genuint oberoende klockor, med ett
  ärligt förbehåll noterat där: kristalltoleranser ligger på tiotals ppm, så över en hel ram - ett
  sextiotal bitar för
  [L11:s genomräknade tvåbytesram](../../L11/appendix/a_architecture_and_register_map.md) -
  demonstrerar korten mest godtycklig start*fas*, som `resync` absorberar, snarare än att de
  sätter press på driften.
* **Ingen ram förvanskas någonsin.** Ingenting matar in ett stoppfel, vänder en bit på ledningen
  eller skadar en CRC, så mottagarsidans `error`-vägar prövas bara på modulnivå av
  `rx_shift_reg_tb` och `crc15_tb`, aldrig hela vägen igenom.
* **ACK-luckan drivs men läses aldrig tillbaka.** En mottagare med giltig CRC drar den dominant
  (L17), men sändaren kontrollerar den aldrig, så en ram som ingen kvitterat fullbordas precis som
  en som blev kvitterad. Det är en medveten förenkling (Appendix B), och testbänken ärver den i
  stället för att fånga den.
* **Arbitreringen är alltid tvåvägs, och förloras alltid vid samma bit.** `0x000` mot `0x001`
  skiljer sig i identifierarens sista bit, så förlusten upptäcks i samma tillstånd varje körning.
  Övning 1 lägger till en tredje nod och flyttar den förlorande biten tidigare.
* **Ingen nod sänder någonsin igen efter ett avbrott.** Nod B förlorar arbitreringen i fall 2 och
  blir aldrig ombedd att skicka en ram till, så ingenting här kontrollerar att en nod över huvud
  taget återhämtar sig från ett avbrott. Det spelar större roll än det låter: `can_controller`
  nollställer `crc15` i `STATE_START` (L16) just för att en övergiven ram inte ska kunna lämna sina
  rester efter sig, och den här testbänken skulle passera precis lika glatt med den
  nollställningen borttagen. Övning 7 är där ni får reda på vad den gjorde.

---

### Vad som kommer härnäst
[Appendix B](./b_fpga_bringup_and_review.md) tar den verifierade konstruktionen ut på riktig
DE0-CV-hårdvara bakom en liten wrapper på kortnivå, går igenom var den här kontrollern är förenklad
jämfört med en produktionsfärdig, och sammanfattar registerkartan som bryggar över till
drivrutinssidan.

---

