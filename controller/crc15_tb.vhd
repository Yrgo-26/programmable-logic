--------------------------------------------------------------------------------
-- Testbench for crc15. Run it against your own crc15.vhd. Test vectors were
-- computed independently in Python, not derived from this same VHDL.
--
-- Run, from controller/:
--       ghdl -a --std=93 can_def.vhd crc15.vhd crc15_tb.vhd
--       ghdl -e --std=93 crc15_tb
--       ghdl -r --std=93 crc15_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.can_def.all;

entity crc15_tb is
end entity;

architecture behaviour of crc15_tb is
constant CLOCK_PERIOD_NS: time := 20 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := 1 ns;
constant RESET_CYCLES   : natural := 3;

-- SOF(0) + 11-bit ID 0x123 + RTR(0) + 6-bit control-field placeholder, 19 bits total.
constant SEQ_19 : std_logic_vector(0 to 18) := "0" & "00100100011" & "0" & "000000";

-- Independently-computed CRC-15 of SEQ_19 (see the file header).
constant EXPECTED_CRC : std_logic_vector(14 downto 0) := "110100001011000";

signal clock      : std_logic := '0';
signal reset_s2_n : std_logic := '0';
signal clear      : std_logic := '0';
signal enable     : std_logic := '0';
signal data       : std_logic := '0';
signal crc        : crc_t;
signal valid      : std_logic;
signal done       : boolean := false;
begin
    dut: entity work.crc15
        port map(clock, reset_s2_n, clear, enable, data, crc, valid);

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
    begin
        -- Case 1: reset_s2_n = '0', then released.
        -- Expect valid = '1' and crc = all zeros (the register reads all zeros).
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        wait for SYNC_UPDATE_NS;
        assert valid = '1' and crc = (crc'range => '0')
            report "crc15: crc must be all zeros just after reset!"
            severity error;

        -- Case 2: feed a single '1' bit.
        -- Expect crc = CRC_POLY exactly (feedback = 1, shifted = 0).
        enable <= '1';
        data   <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert crc = CRC_POLY
            report "crc15: crc after a single '1' bit must equal CRC_POLY!"
            severity error;
        enable <= '0';

        -- Case 3: clear the register without touching reset_s2_n.
        -- Expect crc back to all zeros and valid = '1'. can_controller pulses
        -- this at the start of every frame, so that a frame aborted partway
        -- through (arbitration loss, stuffing violation, failed CRC) cannot
        -- leave its residue behind to corrupt the next one.
        clear <= '1';
        wait until rising_edge(clock);
        clear <= '0';
        wait for SYNC_UPDATE_NS;
        assert valid = '1' and crc = (crc'range => '0')
            report "crc15: clear must return the register to all zeros!"
            severity error;

        -- Case 4: reset again, then feed SEQ_19 one bit per enabled clock edge.
        -- Expect crc = EXPECTED_CRC, the independently-computed value.
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';

        enable <= '1';
        for i in SEQ_19'range loop
            data <= SEQ_19(i);
            wait until rising_edge(clock);
        end loop;
        wait for SYNC_UPDATE_NS;
        assert crc = EXPECTED_CRC
            report "crc15: crc after SEQ_19 did not match the independently-computed expected value!"
            severity error;

        -- Case 5: continue feeding the CRC's own bits back in (generate-then-check).
        -- Expect valid = '1' and crc = all zeros (the register returns to zero).
        for i in EXPECTED_CRC'range loop
            data <= EXPECTED_CRC(i);
            wait until rising_edge(clock);
        end loop;
        wait for SYNC_UPDATE_NS;
        assert valid = '1' and crc = (crc'range => '0')
            report "crc15: feeding the frame's own CRC bits back in must zero the register!"
            severity error;
        enable <= '0';

        report "crc15: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
