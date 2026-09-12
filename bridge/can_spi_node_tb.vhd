--------------------------------------------------------------------------------
-- System testbench for can_spi_node. Run it against your own can_spi_node.vhd.
--
-- Two complete nodes share one open-drain (wired-AND) bus - the pattern
-- can_controller_tb established - and a modeled mode 0 SPI master drives each
-- node's four SPI pins. The cases below play the worked example from
-- project/spi_register_protocol.md through the whole chain (spi_slave,
-- spi_reg_bridge, register_bank, your can_controller) and watch a frame leave
-- node A and arrive at node B.
--
-- This is the only testbench in the course that drives sclk, mosi and ss as
-- real waveforms. spi_reg_bridge_tb hands the bridge finished bytes and never
-- touches a pin, so everything between the wire and the byte - the
-- synchronizers, the SCK edge detector, the ss_active framing - is exercised
-- here or nowhere.
--
-- Nothing here asserts a bit pattern on the CAN wire, a frame duration, or
-- anything about stuffing, CRC, the ACK slot or arbitration. The controller
-- under this design is yours, and can_controller_tb already proved it; this
-- testbench checks the layer L18 and L19 build, through two windows only - the
-- SPI pins, and the level of the shared bus. Each case comment states what a
-- failure of that case means. Port binding is positional, against the order
-- given in project/README.md section 7.3 and L19 Appendix B.
--
-- Run, with your sources from controller/ and bridge/ in one place:
--       ghdl -a --std=93 can_def.vhd meta_prev.vhd bit_timer.vhd crc15.vhd \
--            tx_shift_reg.vhd rx_shift_reg.vhd can_controller.vhd \
--            register_bank.vhd spi_def.vhd spi_slave.vhd spi_reg_bridge.vhd \
--            can_spi_node.vhd can_spi_node_tb.vhd
--       ghdl -e --std=93 can_spi_node_tb
--       ghdl -r --std=93 can_spi_node_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity can_spi_node_tb is
end entity;

architecture behaviour of can_spi_node_tb is
constant CLOCK_PERIOD_NS: time := 20 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;

-- Half an SCK period at 1 MHz, the fastest the protocol promises.
constant SCK_HALF_NS: time := 500 ns;
constant SAMPLE_NS  : time := 1 ns;

-- The quiet time held around every SS edge. The protocol's minimum is 60 ns,
-- three system clocks; this sits far above it deliberately, so a failure of any
-- case below is a logic fault and never a timing one. Appendix C exercise 4(b)
-- is about what happens as this approaches the documented minimum.
constant SETTLE_NS: time := 200 ns;

constant RESET_CYCLES: natural := 5;

-- How long the bus is given to leave idle after a TX_SEND write, and how many
-- polls of STATUS the test makes before it gives up on tx_done. Both are taken
-- from the contract rather than measured, with generous slack, so a slower but
-- conforming controller still passes. BUS_START_US bounds only the start of the
-- frame, which a conforming controller on an idle bus reaches within a few
-- clocks of the trigger. POLL_LIMIT bounds the whole frame: each poll is two
-- transactions of roughly 41 us (node B's RX_DATA_LO, then node A's STATUS), so
-- 24 of them allow about 2 ms, against a dlc = 2 frame of 60 bit times nominal
-- and 72 with worst-case stuffing - 63 and 75 counting the 3-bit intermission.
constant BUS_START_US: time    := 150 us;
constant POLL_LIMIT  : natural := 24;

-- Register indices (register_map.md: offset / 4). Index 12 is TX_ABORT, a live
-- write register; the first reserved index is 13.
constant REG_STATUS     : std_logic_vector(3 downto 0) := "0000";
constant REG_TX_ID      : std_logic_vector(3 downto 0) := "0001";
constant REG_TX_DLC     : std_logic_vector(3 downto 0) := "0010";
constant REG_TX_DATA_LO : std_logic_vector(3 downto 0) := "0011";
constant REG_TX_DATA_HI : std_logic_vector(3 downto 0) := "0100";
constant REG_TX_SEND    : std_logic_vector(3 downto 0) := "0101";
constant REG_RX_ID      : std_logic_vector(3 downto 0) := "0110";
constant REG_RX_DLC     : std_logic_vector(3 downto 0) := "0111";
constant REG_RX_DATA_LO : std_logic_vector(3 downto 0) := "1000";
constant REG_RX_DATA_HI : std_logic_vector(3 downto 0) := "1001";
constant REG_RX_ACK     : std_logic_vector(3 downto 0) := "1010";
constant REG_ERROR_FLAGS: std_logic_vector(3 downto 0) := "1011";
constant REG_TX_ABORT   : std_logic_vector(3 downto 0) := "1100";
constant REG_RESERVED   : std_logic_vector(3 downto 0) := "1101";

-- Command byte upper nibbles: W in bit 7, bits 6-4 reserved and must be zero.
constant CMD_READ      : std_logic_vector(3 downto 0) := "0000";
constant CMD_WRITE     : std_logic_vector(3 downto 0) := "1000";
constant CMD_VOID_READ : std_logic_vector(3 downto 0) := "0100";
constant CMD_VOID_WRITE: std_logic_vector(3 downto 0) := "1100";

-- STATUS values (bit 0: TX ready, bit 1: RX valid, bit 2: error).
constant STATUS_IDLE      : std_logic_vector(31 downto 0) := x"00000001";
constant STATUS_SENDING   : std_logic_vector(31 downto 0) := x"00000000";
constant STATUS_RX_PENDING: std_logic_vector(31 downto 0) := x"00000003";

-- The protocol spec's worked example: id 0x123, dlc 2, data AA BB.
constant DEMO_ID     : std_logic_vector(31 downto 0) := x"00000123";
constant DEMO_DLC    : std_logic_vector(31 downto 0) := x"00000002";
constant DEMO_DATA_LO: std_logic_vector(31 downto 0) := x"AABB0000";
constant DEMO_DATA_HI: std_logic_vector(31 downto 0) := x"00000000";
constant TRIGGER     : std_logic_vector(31 downto 0) := x"00000001";
constant ZERO_WORD   : std_logic_vector(31 downto 0) := (others => '0');

signal clock, reset_n: std_logic := '0';
signal bus_line      : std_logic;

signal a_sclk, a_mosi: std_logic := '0';
signal a_ss          : std_logic := '1';
signal a_miso        : std_logic;
signal a_tx_bus      : std_logic;
signal a_bus_en      : std_logic;

signal b_sclk, b_mosi: std_logic := '0';
signal b_ss          : std_logic := '1';
signal b_miso        : std_logic;
signal b_tx_bus      : std_logic;
signal b_bus_en      : std_logic;

signal done: boolean := false;
begin
    -- Shared open-drain bus: any node pulling it low wins. A node's effective
    -- output is its driven value when bus_en = '1', else released ('1').
    bus_line <= (a_tx_bus or not a_bus_en) and (b_tx_bus or not b_bus_en);

    -- Nine ports: clock, reset_n, sclk, mosi, ss, miso, rx_bus, tx_bus, bus_en.
    -- miso sits with the three SPI inputs it belongs to, before the CAN group,
    -- so the SPI pins stay together in the order the wiring table lists them.
    node_a: entity work.can_spi_node
        port map(clock, reset_n, a_sclk, a_mosi, a_ss, a_miso,
                 bus_line, a_tx_bus, a_bus_en);

    node_b: entity work.can_spi_node
        port map(clock, reset_n, b_sclk, b_mosi, b_ss, b_miso,
                 bus_line, b_tx_bus, b_bus_en);

    CLOCK_PROCESS: process is
    begin
        if done then
            wait;
        end if;
        clock <= '0';
        wait for CLOCK_EVENT_NS;
        clock <= '1';
        wait for CLOCK_EVENT_NS;
    end process;

    SIMULATION_PROCESS: process is
        -- One mode 0 byte exchange on one node's pins.
        procedure spi_byte(signal sclk_line: out std_logic;
                           signal mosi_line: out std_logic;
                           signal miso_line: in  std_logic;
                           constant tx     : in  std_logic_vector(7 downto 0);
                           variable rx     : out std_logic_vector(7 downto 0)) is
        begin
            for i in 7 downto 0 loop
                mosi_line <= tx(i);
                wait for SCK_HALF_NS;
                sclk_line <= '1';
                wait for SAMPLE_NS;
                rx(i) := miso_line;
                wait for SCK_HALF_NS - SAMPLE_NS;
                sclk_line <= '0';
            end loop;
        end procedure;

        -- One complete transaction: SS falls, command byte, four data bytes
        -- most significant first, SS rises. On a read the master sends zeros
        -- and collects what MISO returned; on a write the returned bytes are
        -- meaningless and discarded by the caller.
        procedure spi_txn(signal sclk_line: out std_logic;
                          signal mosi_line: out std_logic;
                          signal ss_line  : out std_logic;
                          signal miso_line: in  std_logic;
                          constant cmd    : in  std_logic_vector(7 downto 0);
                          constant wdata  : in  std_logic_vector(31 downto 0);
                          variable rdata  : out std_logic_vector(31 downto 0)) is
            variable tx : std_logic_vector(7 downto 0);
            variable rx : std_logic_vector(7 downto 0);
            variable acc: std_logic_vector(31 downto 0);
        begin
            acc     := (others => '0');
            ss_line <= '0';
            wait for SETTLE_NS;
            for k in 0 to 4 loop
                case k is
                    when 0      => tx := cmd;
                    when 1      => tx := wdata(31 downto 24);
                    when 2      => tx := wdata(23 downto 16);
                    when 3      => tx := wdata(15 downto 8);
                    when others => tx := wdata(7 downto 0);
                end case;
                spi_byte(sclk_line, mosi_line, miso_line, tx, rx);
                case k is
                    when 1      => acc(31 downto 24) := rx;
                    when 2      => acc(23 downto 16) := rx;
                    when 3      => acc(15 downto 8)  := rx;
                    when 4      => acc(7 downto 0)   := rx;
                    when others => null;
                end case;
            end loop;
            wait for SCK_HALF_NS;
            ss_line <= '1';
            wait for SETTLE_NS;
            rdata := acc;
        end procedure;

        -- A transaction cut short: SS rises after `bytes` of the five.
        procedure spi_txn_abort(signal sclk_line: out std_logic;
                                signal mosi_line: out std_logic;
                                signal ss_line  : out std_logic;
                                signal miso_line: in  std_logic;
                                constant cmd    : in  std_logic_vector(7 downto 0);
                                constant wdata  : in  std_logic_vector(31 downto 0);
                                constant bytes  : in  natural) is
            variable tx: std_logic_vector(7 downto 0);
            variable rx: std_logic_vector(7 downto 0);
        begin
            ss_line <= '0';
            wait for SETTLE_NS;
            for k in 0 to bytes - 1 loop
                case k is
                    when 0      => tx := cmd;
                    when 1      => tx := wdata(31 downto 24);
                    when 2      => tx := wdata(23 downto 16);
                    when 3      => tx := wdata(15 downto 8);
                    when others => tx := wdata(7 downto 0);
                end case;
                spi_byte(sclk_line, mosi_line, miso_line, tx, rx);
            end loop;
            wait for SCK_HALF_NS;
            ss_line <= '1';
            wait for SETTLE_NS;
        end procedure;

        -- Ten bytes under one SS: a complete transaction, then five more the
        -- slave must not act on.
        procedure spi_txn_overrun(signal sclk_line: out std_logic;
                                  signal mosi_line: out std_logic;
                                  signal ss_line  : out std_logic;
                                  signal miso_line: in  std_logic;
                                  constant cmd_1  : in  std_logic_vector(7 downto 0);
                                  constant wdata_1: in  std_logic_vector(31 downto 0);
                                  constant cmd_2  : in  std_logic_vector(7 downto 0);
                                  constant wdata_2: in  std_logic_vector(31 downto 0)) is
            variable tx: std_logic_vector(7 downto 0);
            variable rx: std_logic_vector(7 downto 0);
        begin
            ss_line <= '0';
            wait for SETTLE_NS;
            for k in 0 to 9 loop
                case k is
                    when 0      => tx := cmd_1;
                    when 1      => tx := wdata_1(31 downto 24);
                    when 2      => tx := wdata_1(23 downto 16);
                    when 3      => tx := wdata_1(15 downto 8);
                    when 4      => tx := wdata_1(7 downto 0);
                    when 5      => tx := cmd_2;
                    when 6      => tx := wdata_2(31 downto 24);
                    when 7      => tx := wdata_2(23 downto 16);
                    when 8      => tx := wdata_2(15 downto 8);
                    when others => tx := wdata_2(7 downto 0);
                end case;
                spi_byte(sclk_line, mosi_line, miso_line, tx, rx);
            end loop;
            wait for SCK_HALF_NS;
            ss_line <= '1';
            wait for SETTLE_NS;
        end procedure;

        -- Node-bound shorthands, so the cases below read as transactions.
        procedure write_a(constant cmd  : in std_logic_vector(3 downto 0);
                          constant index: in std_logic_vector(3 downto 0);
                          constant value: in std_logic_vector(31 downto 0)) is
            variable ignored: std_logic_vector(31 downto 0);
        begin
            spi_txn(a_sclk, a_mosi, a_ss, a_miso, cmd & index, value, ignored);
        end procedure;

        procedure read_a(constant cmd   : in  std_logic_vector(3 downto 0);
                         constant index : in  std_logic_vector(3 downto 0);
                         variable result: out std_logic_vector(31 downto 0)) is
        begin
            spi_txn(a_sclk, a_mosi, a_ss, a_miso, cmd & index, ZERO_WORD, result);
        end procedure;

        procedure expect_a(constant index   : in std_logic_vector(3 downto 0);
                           constant expected: in std_logic_vector(31 downto 0);
                           constant msg     : in string) is
            variable got: std_logic_vector(31 downto 0);
        begin
            read_a(CMD_READ, index, got);
            assert got = expected report msg severity error;
        end procedure;

        procedure write_b(constant index: in std_logic_vector(3 downto 0);
                          constant value: in std_logic_vector(31 downto 0)) is
            variable ignored: std_logic_vector(31 downto 0);
        begin
            spi_txn(b_sclk, b_mosi, b_ss, b_miso, CMD_WRITE & index, value, ignored);
        end procedure;

        procedure read_b(constant index : in  std_logic_vector(3 downto 0);
                         variable result: out std_logic_vector(31 downto 0)) is
        begin
            spi_txn(b_sclk, b_mosi, b_ss, b_miso, CMD_READ & index, ZERO_WORD, result);
        end procedure;

        procedure expect_b(constant index   : in std_logic_vector(3 downto 0);
                           constant expected: in std_logic_vector(31 downto 0);
                           constant msg     : in string) is
            variable got: std_logic_vector(31 downto 0);
        begin
            read_b(index, got);
            assert got = expected report msg severity error;
        end procedure;

        variable got      : std_logic_vector(31 downto 0);
        variable polls    : natural;
        variable tx_ready : boolean;
        variable rx_ready : boolean;
        variable bus_moved: boolean;
    begin
        reset_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_n <= '1';
        wait for SETTLE_NS;

        -- Case 1: the reset state, read back over SPI.
        -- Expect STATUS = 0x1, and TX_ID, TX_DLC, RX_ID and ERROR_FLAGS zero,
        -- fetched through spi_slave, spi_reg_bridge, register_bank and back out.
        -- A failure here means the read path is broken somewhere in that chain;
        -- nothing else in this testbench can pass until it works, so debug this
        -- case first and ignore everything below it.
        expect_a(REG_STATUS, STATUS_IDLE, "can_spi_node: STATUS must read 0x1 out of reset, over SPI!");
        expect_a(REG_TX_ID, ZERO_WORD, "can_spi_node: TX_ID must read zero out of reset!");
        expect_a(REG_TX_DLC, ZERO_WORD, "can_spi_node: TX_DLC must read zero out of reset!");
        expect_a(REG_RX_ID, ZERO_WORD, "can_spi_node: RX_ID must read zero out of reset!");
        expect_a(REG_ERROR_FLAGS, ZERO_WORD, "can_spi_node: ERROR_FLAGS must read zero out of reset!");

        -- Case 2: the protocol spec's worked example, verbatim.
        -- Expect the four writes 81/82/83/84 to land in the TX registers and
        -- read back unchanged. A failure here means the write bit or the
        -- register index is decoded wrong, or the four data bytes are assembled
        -- in the wrong order - byte 0 sits in the most significant position,
        -- and that convention has to cross the wire unchanged.
        write_a(CMD_WRITE, REG_TX_ID, DEMO_ID);
        write_a(CMD_WRITE, REG_TX_DLC, DEMO_DLC);
        write_a(CMD_WRITE, REG_TX_DATA_LO, DEMO_DATA_LO);
        write_a(CMD_WRITE, REG_TX_DATA_HI, DEMO_DATA_HI);
        expect_a(REG_TX_ID, DEMO_ID, "can_spi_node: TX_ID must hold the written identifier!");
        expect_a(REG_TX_DLC, DEMO_DLC, "can_spi_node: TX_DLC must hold the written DLC!");
        expect_a(REG_TX_DATA_LO, DEMO_DATA_LO, "can_spi_node: TX_DATA_LO must hold data bytes 0-3, byte 0 in the MSBs!");
        expect_a(REG_TX_DATA_HI, DEMO_DATA_HI, "can_spi_node: TX_DATA_HI must hold data bytes 4-7!");

        -- Case 3: void commands and reserved indices.
        -- Expect a command byte with any of bits 6-4 set to do nothing at all -
        -- no write committed, and a read returning zero rather than whatever
        -- the previous transaction latched. A failure here means the bridge
        -- decodes the index without checking the reserved bits, so a corrupted
        -- command byte writes a live register.
        write_a(CMD_VOID_WRITE, REG_TX_ID, x"000007FF");
        expect_a(REG_TX_ID, DEMO_ID, "can_spi_node: a command byte with a reserved bit set must not write!");
        read_a(CMD_VOID_READ, REG_TX_ID, got);
        assert got = ZERO_WORD
            report "can_spi_node: a void read must return zero, not the previous transaction's value!"
            severity error;
        expect_a(REG_RESERVED, ZERO_WORD, "can_spi_node: a reserved register index must read zero!");
        write_a(CMD_WRITE, REG_RESERVED, x"FFFFFFFF");
        expect_a(REG_STATUS, STATUS_IDLE, "can_spi_node: a write to a reserved index must change nothing!");

        -- Case 3b: index 12 is TX_ABORT, not a reserved index.
        -- Expect a write to it to be accepted and to leave TX ready set, since
        -- the node is idle and already ready. A failure here means the bridge
        -- or the bank stopped decoding one index short, which a driver meets as
        -- an abort that never takes effect - and only after a transmission has
        -- already gone wrong, which is the worst moment to discover it.
        write_a(CMD_WRITE, REG_TX_ABORT, TRIGGER);
        expect_a(REG_STATUS, STATUS_IDLE, "can_spi_node: TX_ABORT while idle must leave TX ready set!");

        -- Case 4: the SS abort rule.
        -- Expect a write abandoned after three data bytes to commit nothing,
        -- and the next transaction to run normally. A failure here means the
        -- bridge commits a partial write or does not return to idle when SS
        -- rises, and the link stops being self-recovering after a glitch or a
        -- master reset.
        spi_txn_abort(a_sclk, a_mosi, a_ss, a_miso, CMD_WRITE & REG_TX_ID, x"000007FF", 4);
        expect_a(REG_TX_ID, DEMO_ID, "can_spi_node: an aborted write must commit nothing!");

        -- Case 5: extra bytes under one SS.
        -- Expect the sixth byte onwards to start nothing: one transaction per
        -- SS low period, as the protocol says. A failure here means the bridge
        -- restarts its byte counter inside a transaction, so a master that
        -- mistimes SS silently writes a register it never addressed.
        spi_txn_overrun(a_sclk, a_mosi, a_ss, a_miso,
                        CMD_WRITE & REG_TX_DLC, x"00000004",
                        CMD_WRITE & REG_TX_ID, x"000007FF");
        expect_a(REG_TX_DLC, x"00000004", "can_spi_node: the first transaction under an overrun SS must still commit!");
        expect_a(REG_TX_ID, DEMO_ID, "can_spi_node: bytes after the fifth must start no second transaction!");
        write_a(CMD_WRITE, REG_TX_DLC, DEMO_DLC);

        -- Case 6: TX_SEND puts a frame on the bus.
        -- Expect the bus to be idle, then to go dominant after the trigger
        -- write, then TX ready to come back once the controller reports
        -- tx_done. A failure here means the TX_SEND write never became a
        -- tx_req pulse, the controller was never handed a startable request, or
        -- tx_done never reached the bank - in which case a real driver polling
        -- STATUS would wait forever.
        assert bus_line = '1'
            report "can_spi_node: the bus must be recessive while both nodes are idle!"
            severity error;
        write_a(CMD_WRITE, REG_TX_SEND, TRIGGER);

        -- Watch the wire before spending another transaction on it. Observing
        -- the bus costs no SPI time and so cannot race the frame: a read here
        -- would take tens of microseconds and could outlast a short frame
        -- entirely, and the test would then blame the trigger for arriving.
        bus_moved := false;
        if bus_line = '0' then
            bus_moved := true;
        else
            wait until bus_line = '0' for BUS_START_US;
            bus_moved := bus_line = '0';
        end if;
        assert bus_moved
            report "can_spi_node: the bus must go dominant after a TX_SEND write!"
            severity error;

        -- Now STATUS. A read latches its value at the end of the command byte,
        -- one fifth of the way into the transaction, so this samples early in
        -- the frame rather than at the end of it.
        expect_a(REG_STATUS, STATUS_SENDING, "can_spi_node: TX ready must clear once a frame is under way!");

        -- Poll STATUS until TX ready returns, reading node B's RX_DATA_LO in
        -- between. That register changes two whole bytes at once, at the
        -- rx_valid pulse, asynchronously to whatever transaction is in flight:
        -- every sample of it must be one value or the other, never a stitch of
        -- both. A latching read cannot produce a stitch; a bridge that re-reads
        -- the register for each of the four data bytes eventually will.
        polls    := 0;
        tx_ready := false;
        while polls < POLL_LIMIT and not tx_ready loop
            read_b(REG_RX_DATA_LO, got);
            assert got = ZERO_WORD or got = DEMO_DATA_LO
                report "can_spi_node: a read must latch its value once, not stitch two samples together!"
                severity error;
            read_a(CMD_READ, REG_STATUS, got);
            if got(0) = '1' then
                tx_ready := true;
            end if;
            polls := polls + 1;
        end loop;
        assert tx_ready
            report "can_spi_node: TX ready must return once the controller reports tx_done!"
            severity error;
        expect_a(REG_ERROR_FLAGS, ZERO_WORD, "can_spi_node: a clean transmission must not set the error latch!");

        -- Case 7: the frame arrives at the other node.
        -- Expect node B to have latched the frame node A sent, readable over
        -- its own SPI link, and RX_ACK to clear the flag without clearing the
        -- data. A failure here is the whole system failing: an SPI write on one
        -- node became a CAN frame and had to reappear as an SPI read on the
        -- other.
        polls    := 0;
        rx_ready := false;
        while polls < POLL_LIMIT and not rx_ready loop
            read_b(REG_STATUS, got);
            if got(1) = '1' then
                rx_ready := true;
            end if;
            polls := polls + 1;
        end loop;
        assert rx_ready
            report "can_spi_node: the receiving node must report RX valid after a frame arrives!"
            severity error;

        -- The whole word, not just bit 1: a node that latched an error while
        -- receiving would otherwise sail through to the ERROR_FLAGS check below
        -- and blame the wrong thing.
        expect_b(REG_STATUS, STATUS_RX_PENDING, "can_spi_node: a node holding a received frame must read STATUS 0x3 exactly!");

        expect_b(REG_RX_ID, DEMO_ID, "can_spi_node: the received identifier must match what was sent!");
        expect_b(REG_RX_DLC, DEMO_DLC, "can_spi_node: the received DLC must match what was sent!");
        expect_b(REG_RX_DATA_LO, DEMO_DATA_LO, "can_spi_node: the received data bytes 0-3 must match what was sent!");
        expect_b(REG_RX_DATA_HI, DEMO_DATA_HI, "can_spi_node: the received data bytes 4-7 must match what was sent!");
        expect_b(REG_ERROR_FLAGS, ZERO_WORD, "can_spi_node: a cleanly received frame must not set the error latch!");

        write_b(REG_RX_ACK, TRIGGER);
        expect_b(REG_STATUS, STATUS_IDLE, "can_spi_node: RX_ACK must clear the RX valid flag!");
        expect_b(REG_RX_ID, DEMO_ID, "can_spi_node: RX_ACK clears the flag, not the data registers!");

        report "can_spi_node: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
