# Appendix B

## Övningar
De här övningarna befäster [Appendix A](./a_architecture_and_register_map.md): blockarkitekturen,
gränssnittet den landar i, och registerkartan den avbildas på. Paketet `can_def` som de alla vilar
på skrevs i L10.

Övning 1 och 2 görs på papper. Övning 3 och 4 görs vid tangentbordet, mot den
`controller/can_controller.vhd` som skrevs under den här föreläsningen. `meta_prev` och dess
övningar hör till L12, tillsammans med `bit_timer`.

---

## Övning 1 - Resonemang om arkitekturen
**a)** `tx_shift_reg` och `rx_shift_reg` vet inte om bitarna de skiftar hör till ID:t,
kontrollfältet, en databyte eller CRC-värdet. Förklara, med hänvisning till blockschemat, *vilket*
block som vet det, och hur det kan återanvända samma skiftregister till alltihop i stället för att
behöva fem olika.

**b)** `crc15` matas en bit i taget och får veta när den ska sluta av den av `tx_shift_reg` och
`rx_shift_reg` som är aktiv för tillfället (via respektive utgångar `stuff`/`real_bit_valid`, som
grindar `crc15.enable`). Varför måste `crc15` få veta att den ska *hoppa över* just stoppbitar, i
stället för att bara matas med varje bit som dyker upp på ledningen?

**c)** `can_controller` instansierar de fyra andra blocken inuti sig, så utifrån sett är hela
kontrollern en enda komponent. Anta att någon föreslår att kontrollen av arbitreringsförlust bryts
ut till ett eget block *bredvid* `can_controller`. Förklara vad det blocket skulle behöva tillgång
till, och varför det gör lösningen sämre än att låta kontrollen ligga kvar där den är.

---

## Övning 2 - Att dela upp en annan ram i grupper
Appendix A följer en ram med DLC `2` genom blocken och kommer fram till att den når bussen som åtta
laddningar av `tx_shift_reg`, tillsammans 50 bitar, plus en 10-bitars svans som drivs direkt.

**a)** Gör om den uppdelningen för en ram med ID `0x7A0` och DLC `5`. Ange listan av grupper (varje
grupps innehåll och antal bitar, i sändningsordning), det totala antalet bitar i det stoppade
området, och det totala antalet bitar i ramen innan någon stoppbit satts in.

**b)** Hur många grupper skulle en ram med DLC `0` behöva, och vilka poster ur er lista i (a)
försvinner? Vad säger det er om hur `can_controller` måste vara strukturerad kring datafältet,
jämfört med identifieraren eller CRC:n?

**c)** Fyra av grupperna i er lista är smalare än 8 bitar, och `tx_shift_reg`:s dataingång är
alltid en hel byte. Namnge dem, och säg vad `can_controller` måste skicka med tillsammans med datan
för att registret ska sända rätt antal bitar. (Ni behöver inte L14:s svar på *hur*; frågan är vilken
information registret inte kan räkna ut på egen hand.)

**d)** Inget av era gruppantal är antalet bitar som faktiskt drivs ut på ledningen. Förklara vad
som saknas, varför det inte går att veta enbart utifrån DLC:n, och vilket block som ansvarar för
det.

---

## Övning 3 - Entiteten, kontrollerad
**a)** Kör `make build-project` från roten av gruppens repo, precis som i L10. Två egna filer bör nu
rapporteras, vid sidan av de två utdelade `bridge/`-filerna, och varje testbänk bör fortfarande
hoppas över:

```text
--> controller/can_def.vhd analyzes cleanly
--> controller/can_controller.vhd analyzes cleanly
--> bridge/spi_def.vhd analyzes cleanly
--> bridge/spi_slave.vhd analyzes cleanly

==> meta_prev_tb (skipped: no meta_prev.vhd yet)
==> bit_timer_tb (skipped: no bit_timer.vhd yet)
==> crc15_tb (skipped: no crc15.vhd yet)
==> tx_shift_reg_tb (skipped: no tx_shift_reg.vhd yet)
==> rx_shift_reg_tb (skipped: no rx_shift_reg.vhd yet)
==> can_controller_tb (skipped: no meta_prev.vhd bit_timer.vhd crc15.vhd tx_shift_reg.vhd rx_shift_reg.vhd yet)
==> register_bank_tb (skipped: no register_bank.vhd yet)
==> spi_reg_bridge_tb (skipped: no spi_reg_bridge.vhd yet)

0 testbench(es) run, 8 skipped.
```

Den andra raden är hela poängen med den här övningen: en entitet med en tom arkitektur är ändå en
komplett, giltig designenhet. Gå nu längre än vad `make build-project` gör och elaborera den för
hand, vilket är det andra av GHDL:s tre steg:

```bash
cd controller
ghdl -a --std=93 can_def.vhd can_controller.vhd
ghdl -e --std=93 can_controller
```

Den elaboreras rent, utan några underblock inuti sig och utan något att simulera. Det finns inget
tredje steg att köra här, eftersom en design utan beteende inte har något att kontrollera och ingen
egen testbänk; `can_controller_tb` driver den *färdiga* kontrollern och väntar på L17. Det är i L12
det tredje steget dyker upp, med den första modulen som har en egen testbänk.

**b)** `can_controller_tb` ligger redan i `controller/`, och den behöver sju moduler, varav ni har
skrivit två. Säg vilka fem som saknas och i vilken föreläsning var och en kommer. Varför är det
bättre att bygget hoppar över den testbänken än att det försöker och misslyckas?

**c)** *Valfritt, och bara om ni har Quartus Prime Lite installerat.* Ta samma fil genom Quartus,
enligt [Quartus-flödet](../../../info/quartus_workflow.md): New Project Wizard, enhet
`5CEBA4F23C7N`, lägg till
`can_def.vhd` och `can_controller.vhd`, sätt `can_controller` som toppnivåentitet, och kompilera.

Det går igenom. Läs varningarna i stället för att hoppa över dem, och säg vilka av dem som är
oundvikliga för en arkitektur som inte driver någonting alls. Leta sedan upp antalet pinnar i
fitterns rapport och jämför det med vad ett DE0-CV faktiskt erbjuder en människa: tio omkopplare,
fyra knappar, tio lysdioder. Skriv ner vad ni tror måste sitta mellan den här entiteten och kortet,
och spara anteckningen; L18 och L19 bygger precis det, och kallar det `register_bank` och
`can_spi_node`.

Ingenting senare i kursen beror på det här, och L12 till L19 behöver bara GHDL; L19:s bring-up körs
på utdelade kort. Det står här för att just det antalet pinnar är hela argumentet för de två lagren
ovanför kontrollern, sju föreläsningar i förväg, och att läsa av det ur en riktig fitterrapport gör
det till ert eget i stället för en siffra som det här appendixet påstår.

**d)** Byt tillfälligt plats på `tx_bus` och `bus_en` i entitetens portlista, så att de står i
omvänd ordning, och kör om `make build-project`. Båda är utgångar av typen `std_logic`, så filen
analyseras fortfarande rent. Förklara varför ingenting fångar det nu, i vilken föreläsning det först
skulle ställa till skada, och hur den skadan skulle se ut på bussen (ledtråden är Appendix A:s
avsnitt om bussidans fem portar). Säg sedan varför en förväxling mellan två portar av samma typ är
svårare att hitta än ett felstavat namn skulle ha varit, givet att allt i den här kursen binds
positionsvis. Byt tillbaka dem.

---

## Övning 4 - Att läsa gränssnittet
**a)** En anropare vill sända en ram med ID `0x123`, DLC `3` och databytesen `AA BB CC`. Lista varje
port den måste driva, och värdet på var och en. `tx_data` är `data_t`, 64 bitar bred, och byte 0
ligger i de mest signifikanta bitarna: ange den i sin helhet.

**b)** Samma anropare vill nu veta om ramen blev sänd. Den har tre statusportar till sitt förfogande
(`tx_done`, `rx_valid`, `error`). Vilken pollar den, och vad är den enda sak den *aldrig* kan få
veta av dem, hur ofta den än pollar? (Ledtråden är Appendix A:s anmärkning om vad `error` betyder;
skälet är L10:s ACK-fält.)

**c)** `error` ligger hög tills nästa ram börjar, medan `tx_done` och `rx_valid` är pulser på en
cykel. Förklara vad som skulle gå fel för parallellklassens C++-drivrutin om `error` vore en puls
som de andra två.

---

