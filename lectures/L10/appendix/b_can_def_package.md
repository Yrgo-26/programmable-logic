# Appendix B

## Paketet `can_def`

### Varför använda ett VHDL-paket?
* L01-L08 behövde aldrig något: varje exempel där var självständigt, och där en övning återanvände
  en modul ni redan skrivit - `reset_sync`, `button_sync`, `timer` - kopierade ni filen till den
  katalog som behövde den.
* Det här projektet är annorlunda. `TICKS_PER_BIT`, `SAMPLE_TICK`, `ID_WIDTH`, `CRC_WIDTH` och fler
  behövs var och en av *flera* av blocken som byggs från L12 och framåt, och de måste stämma exakt
  överens, överallt, annars går designen sönder i tysthet. Så mycket delad information är värd att
  definiera en gång.
* Varje konstant i det kommer från något den här föreläsningen just lärt ut: fältbredderna är de ni
  lägger ut för hand i Appendix C, och `SAMPLE_TICK` är den 70 %-punkt Appendix A resonerade om. Det
  här paketet är där de siffrorna slutar vara prosa och blir den enda källan till de definitioner
  varje modul använder.
* Det ändrar också upplägget av *filerna*. Varje modul här är del av **en enda** design, så de bor
  allihop i `controller/` och läser den enda `can_def.vhd` bredvid sig. Ingenting dupliceras, och
  det finns exakt en fil att ändra när en konstant ändras.

---

### Att läsa `can_def.vhd`
Utdelat, i [`controller/can_def.vhd`](../../../controller/can_def.vhd), och genomgånget på tavlan
under den här föreläsningen. Paketet är en del av kontraktet och inte något att konstruera: sex av
de utdelade testbänkarna läser dess namn och typer direkt, så det läggs in i gruppens repo
**oförändrat**, precis som testbänkarna. Varje modul ni skriver från L11 och framåt hamnar i samma
katalog, och alla utom `meta_prev` läser den här enda filen; se
[referensen för simuleringsflödet](../../../info/simulation_workflow.md) för upplägget.

Listningarna nedan är paketets innehåll, avsnitt för avsnitt, i samma ordning som i filen.

**Bittajmingskonstanterna**, härledda snarare än handplockade, så att de förblir konsekventa med
varandra:

```vhdl
constant CLOCK_FREQ_HZ: natural := 50_000_000;                  -- System clock frequency: 50 MHz.
constant BIT_RATE_HZ  : natural := 1_000_000;                   -- CAN bit rate: 1 Mbit/s.
constant TICKS_PER_BIT: natural := CLOCK_FREQ_HZ / BIT_RATE_HZ; -- Clock ticks per CAN bit: 50.
constant SAMPLE_TICK  : natural := (TICKS_PER_BIT * 7) / 10;    -- Sample point: 35 (70%).
```

`TICKS_PER_BIT` måste gå jämnt ut för att den här enkla designen ska träffa en exakt bithastighet:
50 000 000 / 1 000 000 = exakt 50. `SAMPLE_TICK` beräknas medvetet som en *procentandel* av
`TICKS_PER_BIT`, inte som ett hårdkodat ticknummer, så att en senare ändring av bithastigheten inte
i tysthet lämnar sampelpunkten fel. Det här är Appendix A:s 70 %-sampelpunkt, förvandlad till ett
tal som `bit_timer` kan räkna till i L12; Appendix C övar den direkt.

**Ramfältens bredder**, direkt från Appendix A:s ramdiagram:

```vhdl
constant ID_WIDTH  : natural := 11;          -- Standard CAN identifier width in bits.
constant DLC_WIDTH : natural := 4;           -- Data Length Code field width in bits.
constant CRC_WIDTH : natural := 15;          -- CAN CRC-15 sequence width in bits.
constant DLC_MAX   : natural := 8;           -- Maximum payload length in bytes.
constant DATA_WIDTH: natural := DLC_MAX * 8; -- Maximum data-field width in bits.
```

**Stoppbitsregelns följdlängd**, från Appendix A:s regel om fem identiska bitar:

```vhdl
constant MAX_RUN: natural := 5; -- Maximum run of identical bits before a stuff bit is inserted.
```

Båda skiftregistren räknar följdar mot det här enda talet (L14, L15): sändaren för att avgöra när en
stoppbit måste *sättas in*, mottagaren för att förutsäga var en måste *dyka upp*. Att länkens båda
ändar är överens om det exakt är hela det här paketets argument i miniatyr - en definition, flera
moduler, ingen möjlighet att glida isär.

**Gemensamma subtyper**, så att varje modul namnger likadant formade signaler på samma sätt:

```vhdl
subtype byte_t is std_logic_vector(7 downto 0);            -- 8-bit byte.
subtype id_t   is std_logic_vector(ID_WIDTH-1 downto 0);   -- Standard CAN identifier.
subtype dlc_t  is std_logic_vector(DLC_WIDTH-1 downto 0);  -- Data Length Code field.
subtype crc_t  is std_logic_vector(CRC_WIDTH-1 downto 0);  -- CAN CRC-15 sequence.
subtype data_t is std_logic_vector(DATA_WIDTH-1 downto 0); -- CAN data field.
```

Varje modul utom `meta_prev` börjar med `use work.can_def.all;` och använder de här namnen direkt:
* `bit_timer`s räknarintervall.
* `crc15`s registerbredd.
* `tx_shift_reg`/`rx_shift_reg`s byteportar.

Allt går tillbaka till den här enda filen.

**CRC-15-polynomet**, som en 15 bitar bred konstant (L13:s `crc15` använder det direkt; matematiken
tas upp där, inte här; behandla det tills vidare som en fast standardkonstant som varje
CAN-kontroller använder):

```vhdl
constant CRC_POLY: crc_t := "100010110011001";
```

---

### Vad som kommer härnäst
L11 avbildar den här föreläsningens protokoll på en blockarkitektur och skriver kontrollerns
toppnivå, `can_controller.vhd`, vars portar typas ur det här paketet (`id_t`, `dlc_t`, `data_t`).
Den introducerar också simuleringsflödet (GHDL) och lämnar den toppnivåns arkitektur tom. L12 bygger
de två första blocken som ska in i den, `meta_prev.vhd` och `bit_timer.vhd`.

---

