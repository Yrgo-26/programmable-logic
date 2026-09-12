--------------------------------------------------------------------------------
-- Testbench for register_bank. Run it against your own register_bank.vhd.
--
-- The cases below walk the Register Semantics section of
-- project/spi_register_protocol.md in order; each case comment states what a
-- failure of that case means. Port binding is positional, against the order
-- given in L18 Appendix A.
--
-- Run, from bridge/ (can_def.vhd lives in controller/):
--       ghdl -a --std=93 ../controller/can_def.vhd register_bank.vhd register_bank_tb.vhd
--       ghdl -e --std=93 register_bank_tb
--       ghdl -r --std=93 register_bank_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.can_def.all;

entity register_bank_tb is
end entity;

architecture behaviour of register_bank_tb is
constant CLOCK_PERIOD_NS: time := 20 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant RESET_CYCLES   : natural := 3;

-- Register indices (protocol spec: offset / 4).
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

-- STATUS values (bit 0: TX ready, bit 1: RX valid, bit 2: error).
constant STATUS_IDLE      : std_logic_vector(31 downto 0) := x"00000001";
constant STATUS_SENDING   : std_logic_vector(31 downto 0) := x"00000000";
constant STATUS_RX_PENDING: std_logic_vector(31 downto 0) := x"00000003";
constant STATUS_ERROR_SET : std_logic_vector(31 downto 0) := x"00000005";

constant ZERO_WORD: std_logic_vector(31 downto 0) := (others => '0');

signal clock, reset_s2_n: std_logic := '0';
signal reg_index        : std_logic_vector(3 downto 0) := (others => '0');
signal reg_write        : std_logic := '0';
signal reg_wdata        : std_logic_vector(31 downto 0) := (others => '0');
signal tx_done, rx_valid: std_logic := '0';
signal error_in         : std_logic := '0';
signal rx_id_in         : id_t   := (others => '0');
signal rx_dlc_in        : dlc_t  := (others => '0');
signal rx_data_in       : data_t := (others => '0');
signal reg_rdata        : std_logic_vector(31 downto 0);
signal tx_id_out        : id_t;
signal tx_dlc_out       : dlc_t;
signal tx_data_out      : data_t;
signal tx_req           : std_logic;
signal done             : boolean := false;
begin
    dut: entity work.register_bank
        port map(clock, reset_s2_n, reg_index, reg_write, reg_wdata, tx_done,
                 rx_id_in, rx_dlc_in, rx_data_in, rx_valid, error_in,
                 reg_rdata, tx_id_out, tx_dlc_out, tx_data_out, tx_req);

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
        -- Commit one write: a one-cycle reg_write strobe, exactly as the L19
        -- bridge will drive it.
        procedure write_reg(constant index: in std_logic_vector(3 downto 0);
                            constant value: in std_logic_vector(31 downto 0)) is
        begin
            reg_index <= index;
            reg_wdata <= value;
            reg_write <= '1';
            wait until rising_edge(clock);
            reg_write <= '0';
            wait for SYNC_UPDATE_NS;
        end procedure;

        -- Check one read: reg_rdata is combinational, so no clock edge is
        -- needed - address, settle, compare.
        procedure expect_reg(constant index   : in std_logic_vector(3 downto 0);
                             constant expected: in std_logic_vector(31 downto 0);
                             constant msg     : in string) is
        begin
            reg_index <= index;
            wait for SYNC_UPDATE_NS;
            assert reg_rdata = expected report msg severity error;
        end procedure;

        -- Pulse one controller-side event input for a single clock cycle.
        procedure pulse(signal event_line: out std_logic) is
        begin
            event_line <= '1';
            wait until rising_edge(clock);
            event_line <= '0';
            wait for SYNC_UPDATE_NS;
        end procedure;
    begin
        -- Case 1: reset state.
        -- Expect STATUS = 0x1 (TX ready set - a driver polling a freshly reset
        -- system must see "ready"), and every other register zero. A failure
        -- here means the reset branch is missing a register, or bit 0 does not
        -- start high.
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: STATUS after reset must be 0x1 (TX ready)!");
        expect_reg(REG_TX_ID, ZERO_WORD, "register_bank: TX_ID must reset to zero!");
        expect_reg(REG_TX_DLC, ZERO_WORD, "register_bank: TX_DLC must reset to zero!");
        expect_reg(REG_TX_DATA_LO, ZERO_WORD, "register_bank: TX_DATA_LO must reset to zero!");
        expect_reg(REG_TX_DATA_HI, ZERO_WORD, "register_bank: TX_DATA_HI must reset to zero!");
        expect_reg(REG_TX_SEND, ZERO_WORD, "register_bank: TX_SEND must read as zero (it stores nothing)!");
        expect_reg(REG_RX_ID, ZERO_WORD, "register_bank: RX_ID must reset to zero!");
        expect_reg(REG_RX_DLC, ZERO_WORD, "register_bank: RX_DLC must reset to zero!");
        expect_reg(REG_RX_DATA_LO, ZERO_WORD, "register_bank: RX_DATA_LO must reset to zero!");
        expect_reg(REG_RX_DATA_HI, ZERO_WORD, "register_bank: RX_DATA_HI must reset to zero!");
        expect_reg(REG_RX_ACK, ZERO_WORD, "register_bank: RX_ACK must read as zero (it stores nothing)!");
        expect_reg(REG_ERROR_FLAGS, ZERO_WORD, "register_bank: ERROR_FLAGS must reset to zero!");

        -- Case 2: write/read-back with masking.
        -- Expect TX_ID/TX_DLC to store only their hardware bits (11 and 4),
        -- the data registers all 32, STATUS to ignore writes entirely, and
        -- the controller-facing outputs to follow the stored values. A failure
        -- here means a missing mask, a writable STATUS, or outputs not wired
        -- from the registers.
        write_reg(REG_TX_ID, x"FFFFFFFF");
        expect_reg(REG_TX_ID, x"000007FF", "register_bank: TX_ID must mask to bits 10-0!");
        write_reg(REG_TX_DLC, x"FFFFFFFF");
        expect_reg(REG_TX_DLC, x"0000000F", "register_bank: TX_DLC must mask to bits 3-0!");
        write_reg(REG_TX_DATA_LO, x"AABBCCDD");
        expect_reg(REG_TX_DATA_LO, x"AABBCCDD", "register_bank: TX_DATA_LO must store all 32 bits!");
        write_reg(REG_TX_DATA_HI, x"11223344");
        expect_reg(REG_TX_DATA_HI, x"11223344", "register_bank: TX_DATA_HI must store all 32 bits!");
        write_reg(REG_STATUS, x"FFFFFFFF");
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: STATUS is read-only; writes must be ignored!");
        assert tx_id_out = "11111111111"
            report "register_bank: tx_id must follow the TX_ID register!"
            severity error;
        assert tx_dlc_out = "1111"
            report "register_bank: tx_dlc must follow the TX_DLC register!"
            severity error;
        assert tx_data_out = x"AABBCCDD11223344"
            report "register_bank: tx_data must be TX_DATA_LO & TX_DATA_HI (byte 0 in the MSBs)!"
            severity error;

        -- Case 3: an accepted TX_SEND write.
        -- Expect tx_req high for exactly the one cycle after the write's clock
        -- edge, and TX ready cleared. A failure here means tx_req is a level
        -- rather than an event, or that ready does not clear.
        write_reg(REG_TX_SEND, x"00000001");
        assert tx_req = '1'
            report "register_bank: tx_req must pulse on the cycle after an accepted TX_SEND write!"
            severity error;
        expect_reg(REG_STATUS, STATUS_SENDING, "register_bank: TX ready must clear on an accepted TX_SEND!");
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert tx_req = '0'
            report "register_bank: tx_req must be high for exactly one cycle!"
            severity error;

        -- Case 4: a TX_SEND write while busy.
        -- Expect no pulse and no state change: overwriting a transmission in
        -- flight is exactly what the ready check exists to prevent.
        write_reg(REG_TX_SEND, x"00000001");
        assert tx_req = '0'
            report "register_bank: a TX_SEND write while busy must be dropped!"
            severity error;
        expect_reg(REG_STATUS, STATUS_SENDING, "register_bank: a dropped TX_SEND must not change STATUS!");

        -- Case 5: tx_done restores TX ready.
        pulse(tx_done);
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: tx_done must set TX ready again!");

        -- Case 6: a TX_SEND write of 0x0.
        -- Expect nothing: the register map says write 0x1 to trigger, and the
        -- bank holds it to that.
        write_reg(REG_TX_SEND, x"00000000");
        assert tx_req = '0'
            report "register_bank: TX_SEND with bit 0 clear must not pulse tx_req!"
            severity error;
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: TX_SEND with bit 0 clear must not change STATUS!");

        -- Case 7: RX capture, hold, read-only-ness, and RX_ACK.
        -- Expect the rx_* inputs captured at the rx_valid pulse, held stable
        -- across later input changes (the driver reads them over four separate
        -- transactions), immune to writes, and the flag - only the flag -
        -- cleared by RX_ACK. A failure here usually means the read mux is
        -- wired to the controller's ports instead of to captured registers.
        rx_id_in   <= "10001010110"; -- 0x456
        rx_dlc_in  <= "0001";
        rx_data_in <= x"2A00000000000000"; -- byte 0 = 0x2A, in the MSBs.
        pulse(rx_valid);
        expect_reg(REG_STATUS, STATUS_RX_PENDING, "register_bank: rx_valid must set STATUS bit 1!");
        expect_reg(REG_RX_ID, x"00000456", "register_bank: RX_ID must hold the captured identifier!");
        expect_reg(REG_RX_DLC, x"00000001", "register_bank: RX_DLC must hold the captured DLC!");
        expect_reg(REG_RX_DATA_LO, x"2A000000", "register_bank: RX_DATA_LO must hold data bytes 0-3!");
        expect_reg(REG_RX_DATA_HI, ZERO_WORD, "register_bank: RX_DATA_HI must hold data bytes 4-7!");

        rx_id_in <= (others => '1'); -- The controller's ports move on...
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_RX_ID, x"00000456", "register_bank: RX_ID must be captured, not wired to the port!");
        write_reg(REG_RX_ID, x"FFFFFFFF");
        expect_reg(REG_RX_ID, x"00000456", "register_bank: RX_ID is read-only; writes must be ignored!");

        -- A second frame arriving before RX_ACK overwrites the held registers
        -- (newest wins - the controller has no buffering), while STATUS bit 1
        -- stays set. A failure here means capture is gated on the flag being
        -- clear, or the overwrite is dropped.
        rx_id_in   <= "00110000111"; -- 0x187
        rx_dlc_in  <= "1000";
        rx_data_in <= x"5500000000000000"; -- byte 0 = 0x55, in the MSBs.
        pulse(rx_valid);
        expect_reg(REG_STATUS, STATUS_RX_PENDING, "register_bank: an unacknowledged second frame must keep STATUS bit 1 set!");
        expect_reg(REG_RX_ID, x"00000187", "register_bank: a second frame before RX_ACK must overwrite RX_ID!");
        expect_reg(REG_RX_DLC, x"00000008", "register_bank: a second frame before RX_ACK must overwrite RX_DLC!");
        expect_reg(REG_RX_DATA_LO, x"55000000", "register_bank: a second frame before RX_ACK must overwrite RX_DATA_LO!");

        write_reg(REG_RX_ACK, x"00000001");
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: RX_ACK must clear STATUS bit 1!");
        expect_reg(REG_RX_ID, x"00000187", "register_bank: RX_ACK clears the flag, not the data registers!");

        -- Case 8: the error latch's edge semantics.
        -- Expect a rising edge of "error" to set the latch; a nonzero
        -- ERROR_FLAGS write to be ignored; a zero write to clear it even while
        -- the controller still holds the level; and a new rising edge to set
        -- it again. A failure here usually means the latch follows the level,
        -- which makes the driver's clearError() appear broken.
        error_in <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_STATUS, STATUS_ERROR_SET, "register_bank: a rising error edge must set STATUS bit 2!");
        expect_reg(REG_ERROR_FLAGS, x"00000001", "register_bank: ERROR_FLAGS must read the error latch!");
        write_reg(REG_ERROR_FLAGS, x"000000FF");
        expect_reg(REG_ERROR_FLAGS, x"00000001", "register_bank: only a zero write clears ERROR_FLAGS!");
        write_reg(REG_ERROR_FLAGS, x"00000000");
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: a zero write must clear the latch, level or no level!");
        error_in <= '0';
        wait until rising_edge(clock);
        error_in <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_STATUS, STATUS_ERROR_SET, "register_bank: a new rising edge must set the latch again!");
        write_reg(REG_ERROR_FLAGS, x"00000000");
        error_in <= '0';

        -- Case 9: reserved indices.
        -- Expect reads of every reserved index (13-15) to return zero and
        -- writes to them to change nothing. Index 12 is TX_ABORT and is not
        -- reserved; case 11 covers it.
        expect_reg(REG_RESERVED, ZERO_WORD, "register_bank: reserved index 13 must read as zero!");
        expect_reg("1110", ZERO_WORD, "register_bank: reserved index 14 must read as zero!");
        expect_reg("1111", ZERO_WORD, "register_bank: reserved index 15 must read as zero!");
        write_reg(REG_RESERVED, x"FFFFFFFF");
        write_reg("1110", x"FFFFFFFF");
        write_reg("1111", x"FFFFFFFF");
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: a write to a reserved index must change nothing!");

        -- Case 10: TX ready recovers by itself when a transmission ends badly.
        -- A rising edge of error while TX ready is already low can only mean a
        -- transmission just failed, because a node is never transmitting and
        -- receiving at once. Expect that edge to set BOTH bit 2 (the error
        -- latch) and bit 0 (ready again).
        --
        -- This is the check that stops one lost arbitration from taking the
        -- node out permanently. The controller is meant to pulse tx_done on an
        -- aborted transmission too (L17), but the controller is the group's own
        -- and this bank must not depend on it: without this path, a controller
        -- that pulses tx_done only at EOF leaves ready low forever and every
        -- later TX_SEND is silently dropped.
        write_reg(REG_TX_SEND, x"00000001");
        expect_reg(REG_STATUS, STATUS_SENDING, "register_bank: case 10 setup: TX ready must clear!");
        error_in <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_STATUS, STATUS_ERROR_SET,
                   "register_bank: a rising error edge while TX ready is low must set ready "
                   & "again (and the error latch), or one lost arbitration wedges the node!");
        write_reg(REG_ERROR_FLAGS, x"00000000");
        error_in <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: case 10 cleanup: STATUS must be idle again!");

        -- Case 11: TX_ABORT, the driver's escape hatch.
        -- Expect a write of 0x1 to set TX ready back, a write of anything else
        -- to do nothing, a read to return zero, and no tx_req pulse either way:
        -- TX_ABORT abandons a transmission, it does not start one.
        write_reg(REG_TX_SEND, x"00000001");
        expect_reg(REG_STATUS, STATUS_SENDING, "register_bank: case 11 setup: TX ready must clear!");
        write_reg(REG_TX_ABORT, x"00000000");
        expect_reg(REG_STATUS, STATUS_SENDING, "register_bank: TX_ABORT with bit 0 clear must do nothing!");
        write_reg(REG_TX_ABORT, x"00000001");
        assert tx_req = '0'
            report "register_bank: TX_ABORT must never pulse tx_req!"
            severity error;
        expect_reg(REG_STATUS, STATUS_IDLE, "register_bank: a TX_ABORT write of 0x1 must set TX ready again!");
        expect_reg(REG_TX_ABORT, ZERO_WORD, "register_bank: TX_ABORT must read as zero; it stores nothing!");

        report "register_bank: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
