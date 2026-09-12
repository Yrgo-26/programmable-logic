--------------------------------------------------------------------------------
-- Self-checking testbench for spi_reg_bridge.
--
-- Models the spi_slave interface: pulses rx_valid once per received byte, framed
-- by ss_active, drives reg_rdata as the register file would, and checks both the
-- register-bus write and the tx_data read the bridge produces.
--
-- Four cases, in order:
--    1. A write transaction commits once, at the right address, with the right value.
--    2. A read latches once and shifts the four bytes out MSB first, writing nothing.
--    3. ss_active falling mid-transaction abandons it with no side effects, and the
--       transaction straight afterwards still lands. This is the rule a bridge that
--       ignores ss_active and counts bytes modulo five gets wrong.
--    4. A command byte with a reserved bit (6-4) set is void, and the slave still
--       consumes all five bytes before returning to idle.
--
-- Cases 3 and 4 are the two rules that make this module more than a byte counter; see
-- the Aborts and Invalid commands sections of project/spi_register_protocol.md.
--
-- Run, from bridge/:
--       ghdl -a --std=93 spi_def.vhd spi_reg_bridge.vhd spi_reg_bridge_tb.vhd
--       ghdl -e --std=93 spi_reg_bridge_tb
--       ghdl -r --std=93 spi_reg_bridge_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.spi_def.all;   -- to_hex, for the failure messages

entity spi_reg_bridge_tb is
end entity;

architecture behaviour of spi_reg_bridge_tb is
constant CLOCK_PERIOD_NS: time := 20 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;

-- Case 1: write transaction (command byte = write bit '1' + register index 1).
constant WR_CMD  : std_logic_vector(7 downto 0)  := x"81";
constant WR_ADDR : std_logic_vector(3 downto 0)  := x"1";
constant WR_VALUE: std_logic_vector(31 downto 0) := x"DEADBEEF";

-- Case 2: read transaction (command byte = write bit '0' + register index 2).
constant RD_CMD  : std_logic_vector(7 downto 0)  := x"02";
constant RD_ADDR : std_logic_vector(3 downto 0)  := x"2";
constant RD_VALUE: std_logic_vector(31 downto 0) := x"12345678";

-- Case 3: the value written straight after an aborted transaction, to prove the bridge
-- recovered rather than carrying the aborted frame's bytes into the next one.
constant AB_VALUE: std_logic_vector(31 downto 0) := x"CAFEF00D";

-- Case 4: a command byte with reserved bit 4 set. W and the index are otherwise a valid
-- write to register 1, so only the reserved bit can make the difference.
constant VOID_CMD: std_logic_vector(7 downto 0)  := x"91";

signal clock, reset_s2_n: std_logic := '0';
signal ss_active        : std_logic := '0';
signal rx_data          : std_logic_vector(7 downto 0)  := (others => '0');
signal rx_valid         : std_logic := '0';
signal reg_rdata        : std_logic_vector(31 downto 0) := (others => '0');
signal tx_data          : std_logic_vector(7 downto 0);
signal reg_addr         : std_logic_vector(3 downto 0);
signal reg_wdata        : std_logic_vector(31 downto 0);
signal reg_write        : std_logic;
signal done             : boolean := false;

-- Captured by the monitor below: the write bus and a count of reg_write strobes.
signal write_count: natural := 0;
signal wrote_addr : std_logic_vector(3 downto 0)  := (others => '0');
signal wrote_data : std_logic_vector(31 downto 0) := (others => '0');
begin

    dut: entity work.spi_reg_bridge
        port map(clock, reset_s2_n, ss_active, rx_data, rx_valid, reg_rdata,
                 tx_data, reg_addr, reg_wdata, reg_write);

    CLOCK_PROCESS: process is
    begin
        if (done) then
            wait;
        else
            clock <= '0';
            wait for CLOCK_EVENT_NS;
            clock <= '1';
            wait for CLOCK_EVENT_NS;
        end if;
    end process;

    MONITOR_PROCESS: process(clock) is
    begin
        if (rising_edge(clock)) then
            if (reg_write = '1') then
                write_count <= write_count + 1;
                wrote_addr  <= reg_addr;
                wrote_data  <= reg_wdata;
            end if;
        end if;
    end process;

    SIM_PROCESS: process is
        -- Present one received byte to the bridge (one rx_valid pulse).
        procedure send(constant b: in std_logic_vector(7 downto 0)) is
        begin
            rx_data  <= b;
            rx_valid <= '1';
            wait for CLOCK_PERIOD_NS;
            rx_valid <= '0';
            wait for 2 * CLOCK_PERIOD_NS;
        end procedure;
    begin
        reset_s2_n <= '0';
        wait for 4 * CLOCK_PERIOD_NS;
        reset_s2_n <= '1';
        wait for 2 * CLOCK_PERIOD_NS;

        -- Case 1: write 0xDEADBEEF to register 1 (command byte, then four data bytes MSB first).
        -- Expect exactly one reg_write strobe, reg_addr = 1, reg_wdata = 0xDEADBEEF.
        ss_active <= '1';
        send(WR_CMD);
        send(WR_VALUE(31 downto 24));
        send(WR_VALUE(23 downto 16));
        send(WR_VALUE(15 downto 8));
        send(WR_VALUE(7 downto 0));      -- fourth data byte: the bridge pulses reg_write
        wait for 2 * CLOCK_PERIOD_NS;
        assert write_count = 1
            report "spi_reg_bridge_tb: a write should produce exactly one reg_write pulse!"
            severity error;
        assert wrote_addr = WR_ADDR
            report "spi_reg_bridge_tb: write reg_addr wrong, expected 1, got 0x" & to_hex(wrote_addr) & "!"
            severity error;
        assert wrote_data = WR_VALUE
            report "spi_reg_bridge_tb: write reg_wdata wrong, expected 0xDEADBEEF, got 0x" & to_hex(wrote_data) & "!"
            severity error;
        ss_active <= '0';
        wait for 4 * CLOCK_PERIOD_NS;

        -- Case 2: read register 2 (command byte 0x02), the file presenting 0x12345678.
        -- Expect tx_data to shift out 0x12, 0x34, 0x56, 0x78 MSB first, and no register write.
        reg_rdata <= RD_VALUE;
        ss_active <= '1';
        send(RD_CMD);                    -- command byte; the bridge latches reg_rdata next cycle
        assert tx_data = RD_VALUE(31 downto 24)
            report "spi_reg_bridge_tb: read tx_data byte 1 wrong, expected 0x12, got 0x" & to_hex(tx_data) & "!"
            severity error;
        send(x"00");
        assert tx_data = RD_VALUE(23 downto 16)
            report "spi_reg_bridge_tb: read tx_data byte 2 wrong, expected 0x34, got 0x" & to_hex(tx_data) & "!"
            severity error;
        send(x"00");
        assert tx_data = RD_VALUE(15 downto 8)
            report "spi_reg_bridge_tb: read tx_data byte 3 wrong, expected 0x56, got 0x" & to_hex(tx_data) & "!"
            severity error;
        send(x"00");
        assert tx_data = RD_VALUE(7 downto 0)
            report "spi_reg_bridge_tb: read tx_data byte 4 wrong, expected 0x78, got 0x" & to_hex(tx_data) & "!"
            severity error;
        send(x"00");
        assert write_count = 1
            report "spi_reg_bridge_tb: a read must not write the register bus!"
            severity error;
        assert reg_addr = RD_ADDR
            report "spi_reg_bridge_tb: read reg_addr wrong, expected 2, got 0x" & to_hex(reg_addr) & "!"
            severity error;
        ss_active <= '0';
        wait for 4 * CLOCK_PERIOD_NS;

        -- Case 3: abort. ss_active falls after three of the five bytes, so the protocol's
        -- "no side effects" rule says nothing may be committed. A bridge that ignores
        -- ss_active and simply counts bytes modulo five passes Cases 1 and 2 and fails here.
        ss_active <= '1';
        send(WR_CMD);
        send(x"AA");
        send(x"BB");
        ss_active <= '0';
        wait for 4 * CLOCK_PERIOD_NS;
        assert write_count = 1
            report "spi_reg_bridge_tb: an aborted transaction must not commit a write!"
            severity error;

        -- Still Case 3: the abort must leave the bridge idle, not two bytes into a frame.
        -- Raising SS is the documented way for the master to resynchronise, so the very next
        -- transaction has to land intact.
        ss_active <= '1';
        send(WR_CMD);
        send(AB_VALUE(31 downto 24));
        send(AB_VALUE(23 downto 16));
        send(AB_VALUE(15 downto 8));
        send(AB_VALUE(7 downto 0));
        wait for 2 * CLOCK_PERIOD_NS;
        assert write_count = 2
            report "spi_reg_bridge_tb: the transaction after an abort must still commit once!"
            severity error;
        assert wrote_addr = WR_ADDR and wrote_data = AB_VALUE
            report "spi_reg_bridge_tb: write after abort wrong, expected 0xCAFEF00D at 1, got 0x"
                & to_hex(wrote_data) & " at 0x" & to_hex(wrote_addr) & "!"
            severity error;
        ss_active <= '0';
        wait for 4 * CLOCK_PERIOD_NS;

        -- Case 4: reserved command bits. 0x91 is 0x81 with bit 4 set, so it addresses the same
        -- register with the same W bit; only the reserved bit differs. The command is void:
        -- nothing is committed, and the slave still consumes all five bytes.
        ss_active <= '1';
        send(VOID_CMD);
        send(x"11");
        send(x"22");
        send(x"33");
        send(x"44");
        wait for 2 * CLOCK_PERIOD_NS;
        assert write_count = 2
            report "spi_reg_bridge_tb: a command byte with a reserved bit set must not write!"
            severity error;
        ss_active <= '0';
        wait for 4 * CLOCK_PERIOD_NS;

        -- Still Case 4: "consumes the full 5-byte frame before returning to idle" is the half
        -- that is easy to miss. If the void command left the byte counter anywhere but idle,
        -- this next transaction lands at the wrong address or not at all.
        ss_active <= '1';
        send(WR_CMD);
        send(WR_VALUE(31 downto 24));
        send(WR_VALUE(23 downto 16));
        send(WR_VALUE(15 downto 8));
        send(WR_VALUE(7 downto 0));
        wait for 2 * CLOCK_PERIOD_NS;
        assert write_count = 3
            report "spi_reg_bridge_tb: the transaction after a void command must commit once!"
            severity error;
        assert wrote_addr = WR_ADDR and wrote_data = WR_VALUE
            report "spi_reg_bridge_tb: write after a void command wrong, expected 0xDEADBEEF at 1, got 0x"
                & to_hex(wrote_data) & " at 0x" & to_hex(wrote_addr) & "!"
            severity error;
        ss_active <= '0';

        report "spi_reg_bridge_tb: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
