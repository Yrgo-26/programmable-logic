# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_register_bank.md). Skriv er egen `register_bank.vhd`
utifrån specifikationen där; den utdelade testbänken (kör den enligt
[simuleringsflödet](../../../info/simulation_workflow.md)) är kontrollen av att den beter sig
korrekt. Övning 4 och 5 handlar om `spi_slave.vhd`, som delas ut i stället för att skrivas - den
läser ni, och L20 förväntar sig att ni kan det.

Den auktoritativa källan för varje registernummer nedan är
[`project/register_map.md`](../../../project/register_map.md) och
[`project/spi_register_protocol.md`](../../../project/spi_register_protocol.md). Där en övning och
en specifikation är oense vinner specifikationen, och det är övningen som är buggen.

---

## Övning 1 - Implementera om `register_bank.vhd` utifrån specifikationen
Skriv er egen `register_bank.vhd` utifrån Appendix A. Verifiera den:

```bash
cd bridge
ghdl -a --std=93 ../controller/can_def.vhd register_bank.vhd register_bank_tb.vhd
ghdl -e --std=93 register_bank_tb
ghdl -r --std=93 register_bank_tb --assert-level=error
```

`can_def.vhd` ligger i `controller/`, en katalog bort: banken läser `can_def` för sina typer mot
kontrollern men hör hemma på SPI-sidan av protokollgränsen.

Om en kontroll fallerar, läs assertion-meddelandet; vart och ett av de elva fallen säger vad ett
haveri i just det fallet betyder.

---

## Övning 2 - De tre STATUS-bitarna
**a)** Ur reset läser STATUS `0x00000001`. Säg vilken bit det är och varför resetvärdet är `'1'` och
inte `'0'`. Beskriv sedan vad en drivrutins `send()` skulle göra, i all evighet, om det vore `'0'`.

**b)** Bit 2 låser en **stigande flank** hos kontrollerns `error`, inte dess nivå. Anta att den i
stället låste nivån. Skriv ner den följd av drivrutinsoperationer - polla, nollställ, polla - som då
skulle bete sig annorlunda, och säg vad drivrutinens författare skulle dra för slutsats om vad som
var trasigt.

**c)** Bit 1 sätts av `rx_valid` och nollställs av en skrivning till `RX_ACK`. Bit 0:s huvudsakliga
sättvillkor är `tx_done`, och den nollställs av en skrivning till `TX_SEND`. Det ena av de paren har
sina villkor för att sätta och nollställa i den "naturliga" ordningen, och det andra är omvänt. Säg
vilket som är vilket, och varför det omvända ändå är rätt.

**d)** Appendix A ger en ordningsregel: kontrollerhändelser tillämpas **efter** bryggans skrivningar
i den klockade processen. Konstruera den enda klockflank där den regeln ändrar utfallet, namnge båda
händelserna, och säg vilken av de två möjliga lösningarna som kan låsa systemet och vilken som inte
kan det.

**e)** Bit 0 har *tre* sättvillkor, och ett av dem är en stigande flank hos `error` medan bit 0
redan är låg. Förklara varför det villkoret inte behöver veta något om huruvida kontrollern sände
eller tog emot - vad är det i en nods beteende som gör att "error steg medan vi var upptagna"
betyder "en sändning tog just slut"?

**f)** Ta bort det villkoret ur er bank och kör om testbänken. Vilket fall fallerar, och vilken
konsekvens säger dess meddelande att det skulle ha fått? Förklara sedan varför det här är skydd i
flera lager snarare än dubbelarbete, givet att L17 redan låter kontrollern pulsa `tx_done` vid en
avbruten sändning. (Vem skriver `can_controller`? Vem skrev testbänken som skulle fånga det?)

**g)** `TX_ABORT` är den tredje vägen, och till skillnad från de andra två motsvarar den inte något
hårdvaran gjorde - det är drivrutinen som går förbi banken. Säg vad den *inte* gör: namnge minst två
saker ni kanske skulle vänta er att ett register som heter `TX_ABORT` når fram till, och förklara
varför den inte når någondera. (Ledtråden är `can_controller`s portlista, som fastställdes i L11.)

---

## Övning 3 - `TX_SEND` och pulsdisciplinen
**a)** En skrivning av `0x1` till `TX_SEND` höjer `tx_req` under exakt en cykel. Säg exakt vilken
cykel, i förhållande till den klockflank som bar `reg_write`, och vilka två saker
`register_bank_tb` kontrollerar om den.

**b)** Gör nu sönder det med flit. Ändra er `TX_SEND`-gren så att `tx_req` blir en **nivå**: sätt
den vid en accepterad skrivning och nollställ den först när `tx_done` kommer. Kör om
`register_bank_tb`. Vilken kontroll fallerar först, och vad säger dess meddelande?

**c)** Er trasiga version från (b) skulle fortfarande *se* korrekt ut på ett oscilloskop som tittar
på en enda ram. Beskriv, med L16:s regel för när `can_controller` agerar på `tx_req`, vad den gör
vid den andra ramen och varje ram därefter. Säg sedan varför det här är en bugg som simulering
fångar lätt och ett test på bänken inte gör.

**d)** En skrivning till `TX_SEND` medan STATUS bit 0 är låg kastas helt - ingen puls, ingen
tillståndsändring. En annan design skulle i stället kunna köa den och avfyra när kontrollern
rapporterar redo. Ge ett konkret argument för regeln att kasta den, givet att drivrutinen kan polla
STATUS. Ställ tillbaka modulen som den var.

---

## Övning 4 - Att läsa av en SPI-transaktion ur vågformen
Den här föreläsningen heter "från vågformen" av ett skäl: L20 kan mycket väl räcka er en och fråga
vad den betyder. Läge 0 rakt igenom - SCK vilar lågt, MOSI samplas på **stigande** flank, MISO
ändras på **fallande** flank, MSB först.

**a)** Rita för hand hela fembytestransaktionen som skriver `0x00000001` till `TX_SEND`. Räkna ut
kommandobyten ur formatet i protokollspecifikationen i stället för att kopiera den: bit 7 är
skrivbiten, bit 6-4 är reserverade, bit 3-0 är registerindexet, och `TX_SEND` är index 5. Märk upp
`SS`, `SCK` och `MOSI`, och markera de 40 stigande flankerna i grupper om åtta.

**b)** Markera på samma ritning var mastern inte får släppa `SS`, och vad slaven måste göra om den
ändå gör det. Återge regeln ur protokollspecifikationens avsnitt om avbrott med egna ord.

**c)** En läsning av `STATUS` är spegelbilden: kommandobyte `0x00`, fyra dummybytes ut, fyra bytes
registervärde tillbaka på MISO. Protokollspecifikationen säger att slaven låser registervärdet **en
gång**, vid slutet av kommandobyten. Förklara vad en drivrutin skulle kunna observera om slaven i
stället läste registret på nytt för var och en av de fyra bytesen, och varför just `STATUS` är det
register där det skulle göra ont.

**d)** Räkna SCK-flankerna i en hel transaktion och räkna, vid det maximum på 1 MHz som
protokollspecifikationen tillåter, ut hur lång tid en transaktion tar. Jämför det med den 20 ns
långa puls som registerbanken finns till för att översätta. Det förhållandet är hela argumentet för
det här lagret, i ett enda tal.

---

## Övning 5 - Att läsa `spi_slave.vhd`
Ni skriver inte den här modulen, men ni måste kunna läsa den.

**a)** `spi_slave` använder inte `SCK` som klocka. Den synkroniserar in den i 50 MHz-domänen och
detekterar dess flanker i stället. Ge två skilda skäl, ett om metastabilitet (L04) och ett om vad en
design med två orelaterade klockor kostar i en FPGA.

**b)** Posten `sync_t` har tre fält, men bara två av dem är synkroniseringssteg. Säg vad det tredje
är till för, och varför `mosi` behöver två fält där `sclk` och `ss` behöver tre.

**c)** I resetgrenen nollställs `sclk_s` till idel nollor och `ss_s` till idel **ettor**. Förklara
varför de skiljer sig, och följ sedan vad `ss_active` skulle läsa under de två första klockflankerna
efter reset om `ss_s` nollställdes till nollor utan någon master inkopplad. Det här är samma regel
som L04:s övning `button_sync` byggdes kring; säg vilken kontroll i `button_sync_tb` som motsvarar
den.

**d)** Hanteringen av SCK-flanker ligger inuti `else`-armen i ett test på `ss_s.s2`, så en avvald
slav ignorerar SPI-ledningarna helt. Konstruera felet som skulle följa om den inte gjorde det: utgå
från en vilsen SCK-flank medan `SS` är hög, och följ den fram till vad *nästa* registerskrivning
hamnar på. Ledtråden är att `SCK` är en klocka bara för mastern; för slaven är den en asynkron
ingång som kommer in över en ledning på ett kopplingsdäck, och en störning på den ledningen ser
likadan ut som en flank.

**e)** Grenen `ss_falling` är ett `elsif` före SCK-grenarna i stället för ett separat `if` bredvid
dem. Säg vid vilken enda klockflank den ordningen spelar roll, och vad som skulle vara fel med de
mottagna bytesen om de två grenarna kördes i omvänd ordning.

---

## Övning 6 - Infångningen, och gapet den inte täpper till
**a)** När `rx_valid` pulsar fångar banken in `rx_id`, `rx_dlc` och `rx_data` i `RX_*`-registren i
stället för att koppla kontrollerns portar rakt in i läsmultiplexern. Förklara vad en drivrutin som
läser fyra separata SPI-transaktioner skulle se utan den infångningen.

**b)** En skrivning till `RX_ACK` nollställer STATUS bit 1 men lämnar `RX_*`-registren med sitt
innehåll kvar. Säg varför det är ofarligt, och citera meningen i registerkartan som gör det så.

**c)** En andra ram anländer innan den första har kvitterats. Säg exakt vad drivrutinen observerar,
och varför det här är ett dokumenterat gap som ärvts från `can_controller` (L11) snarare än en brist
hos registerbanken.

**d)** Konstruera, enbart på papper, den minsta ändring i *registerkartan* som skulle låta en
drivrutin upptäcka att den missat en ram. Ni lägger inte till någon mottagningskö; ni lägger till
möjligheten att veta att en behövdes. Säg vad det kostar i hårdvara, och i vilket befintligt
register det skulle kunna bo utan att bryta det kontrakt parallellklassen redan skriver mot.

---
