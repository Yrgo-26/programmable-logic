--------------------------------------------------------------------------------
-- Testbench for tx_shift_reg. Run it against your own tx_shift_reg.vhd.
-- Expected wire sequences were computed independently in Python, not derived
-- from this same VHDL.
--
-- Run, from controller/:
--       ghdl -a --std=93 can_def.vhd tx_shift_reg.vhd tx_shift_reg_tb.vhd
--       ghdl -e --std=93 tx_shift_reg_tb
--       ghdl -r --std=93 tx_shift_reg_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.can_def.all;

entity tx_shift_reg_tb is
end entity;

architecture behaviour of tx_shift_reg_tb is
constant CLOCK_PERIOD_NS: time := 20 ns; -- 50 MHz.
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := 1 ns;
constant RESET_CYCLES   : natural := 3;

type bit_array_t is array(natural range <>) of std_logic;

-- Test 1: "11111000" - a mid-chunk stuff bit after five consecutive '1's.
constant BITS_1  : bit_array_t(0 to 8) := ('1', '1', '1', '1', '1', '0', '0', '0', '0');
constant STUFF_1 : bit_array_t(0 to 8) := ('0', '0', '0', '0', '0', '1', '0', '0', '0');

-- Test 2: "00001111" - a run of exactly four must NOT be stuffed.
constant BITS_2 : bit_array_t(0 to 7) := ('0', '0', '0', '0', '1', '1', '1', '1');

-- Test 3: "10101010" loaded right after test 2 (no reset): the run of four
-- '1's carried over from test 2 plus this chunk's leading '1' reaches five,
-- so a stuff bit is forced before this chunk's own second real bit.
constant BITS_3  : bit_array_t(0 to 8) := ('1', '0', '0', '1', '0', '1', '0', '1', '0');
constant STUFF_3 : bit_array_t(0 to 8) := ('0', '1', '0', '0', '0', '0', '0', '0', '0');

signal clock, reset_s2_n                : std_logic                    := '0';
signal load                           : std_logic                    := '0';
signal data                           : byte_t                       := (others => '0');
signal bit_count                      : std_logic_vector(3 downto 0) := (others => '0');
signal shift                          : std_logic                    := '0';
signal tx_bit, stuff, done_p, bit_valid : std_logic;
signal done                           : boolean := false;

begin
    dut: entity work.tx_shift_reg
        port map(clock, reset_s2_n, load, data, bit_count, shift,
            tx_bit, stuff, done_p, bit_valid);

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
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        wait until rising_edge(clock);

        -- Case 1: load "11111000", bit_count = 8.
        -- Expect the wire sequence in BITS_1/STUFF_1, a stuff bit inserted
        -- mid-chunk after the fifth consecutive '1'.
        data      <= "11111000";
        bit_count <= "1000";
        load      <= '1';
        wait until rising_edge(clock);
        load      <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_1(0) and stuff = STUFF_1(0)
            report "tx_shift_reg: test 1: tx_bit/stuff wrong immediately after load!"
            severity error;
        assert bit_valid = '1'
            report "tx_shift_reg: test 1: bit_valid must be '1' on load!"
            severity error;

        -- bit_valid is a one-cycle *pulse*, not a level held until the next
        -- presentation: can_controller gates crc15's enable straight off it,
        -- so a level would feed the same bit in for a whole bit period.
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert bit_valid = '0'
            report "tx_shift_reg: test 1: bit_valid must drop the cycle after load "
                   & "(it is a one-cycle pulse, not a level)!"
            severity error;

        for i in 1 to BITS_1'high loop
            wait until rising_edge(clock);
            shift <= '1';
            wait until rising_edge(clock);
            shift <= '0';
            wait for SYNC_UPDATE_NS;
            assert tx_bit = BITS_1(i)
                report "tx_shift_reg: test 1, shift " & natural'image(i) & ": wrong tx_bit!"
                severity error;
            assert stuff = STUFF_1(i)
                report "tx_shift_reg: test 1, shift " & natural'image(i) & ": wrong stuff flag!"
                severity error;
            assert done_p = '0'
                report "tx_shift_reg: test 1: done pulsed early!"
                severity error;
            assert bit_valid = '1'
                report "tx_shift_reg: test 1, shift " & natural'image(i)
                       & ": bit_valid must be '1' on a real/stuff shift!"
                severity error;

            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert bit_valid = '0'
                report "tx_shift_reg: test 1, shift " & natural'image(i)
                       & ": bit_valid must drop the cycle after a shift "
                       & "(it is a one-cycle pulse, not a level)!"
                severity error;
        end loop;

        -- One more "closing" shift: presents nothing new, but is what
        -- actually raises "done", one full bit period after the last real
        -- (or stuff) bit was presented.
        wait until rising_edge(clock);
        shift <= '1';
        wait until rising_edge(clock);
        shift <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_1(BITS_1'high)
            report "tx_shift_reg: test 1: the closing shift must not change tx_bit!"
            severity error;
        assert done_p = '1'
            report "tx_shift_reg: test 1: done did not pulse on the closing shift!"
            severity error;
        assert bit_valid = '0'
            report "tx_shift_reg: test 1: bit_valid must be '0' on the closing shift!"
            severity error;

        -- Reset before test 2: tests 2 and 3 are their own scenario (a
        -- baseline run of four, then a chained reload), independent of
        -- whatever stuffing state test 1 left behind.
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        wait until rising_edge(clock);

        -- Case 2: load "00001111".
        -- Expect the 8 bits unchanged - a run of four is not stuffed.
        data      <= "00001111";
        bit_count <= "1000";
        load      <= '1';
        wait until rising_edge(clock);
        load      <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_2(0) and stuff = '0'
            report "tx_shift_reg: test 2: tx_bit/stuff wrong immediately after load!"
            severity error;
        assert bit_valid = '1'
            report "tx_shift_reg: test 2: bit_valid must be '1' on load!"
            severity error;

        -- bit_valid is a one-cycle *pulse*, not a level held until the next
        -- presentation: can_controller gates crc15's enable straight off it,
        -- so a level would feed the same bit in for a whole bit period.
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert bit_valid = '0'
            report "tx_shift_reg: test 2: bit_valid must drop the cycle after load "
                   & "(it is a one-cycle pulse, not a level)!"
            severity error;

        for i in 1 to BITS_2'high loop
            wait until rising_edge(clock);
            shift <= '1';
            wait until rising_edge(clock);
            shift <= '0';
            wait for SYNC_UPDATE_NS;
            assert tx_bit = BITS_2(i)
                report "tx_shift_reg: test 2, shift " & natural'image(i) & ": wrong tx_bit!"
                severity error;
            assert stuff = '0'
                report "tx_shift_reg: test 2, shift " & natural'image(i) & ": unexpected stuff bit!"
                severity error;
            assert done_p = '0'
                report "tx_shift_reg: test 2: done pulsed early!"
                severity error;
            assert bit_valid = '1'
                report "tx_shift_reg: test 2, shift " & natural'image(i)
                       & ": bit_valid must be '1' on a real shift!"
                severity error;

            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert bit_valid = '0'
                report "tx_shift_reg: test 2, shift " & natural'image(i)
                       & ": bit_valid must drop the cycle after a shift "
                       & "(it is a one-cycle pulse, not a level)!"
                severity error;
        end loop;

        wait until rising_edge(clock);
        shift <= '1';
        wait until rising_edge(clock);
        shift <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_2(BITS_2'high)
            report "tx_shift_reg: test 2: the closing shift must not change tx_bit!"
            severity error;
        assert done_p = '1'
            report "tx_shift_reg: test 2: done did not pulse on the closing shift!"
            severity error;
        assert bit_valid = '0'
            report "tx_shift_reg: test 2: bit_valid must be '0' on the closing shift!"
            severity error;

        -- Case 3: load "10101010" right after test 2 - still no reset.
        -- Expect the run of four '1's carried over from test 2 to force a
        -- stuff bit before this chunk's own second real bit.
        wait until rising_edge(clock);
        data      <= "10101010";
        bit_count <= "1000";
        load      <= '1';
        wait until rising_edge(clock);
        load      <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_3(0) and stuff = STUFF_3(0)
            report "tx_shift_reg: test 3: tx_bit/stuff wrong immediately after load!"
            severity error;
        assert bit_valid = '1'
            report "tx_shift_reg: test 3: bit_valid must be '1' on load!"
            severity error;

        -- bit_valid is a one-cycle *pulse*, not a level held until the next
        -- presentation: can_controller gates crc15's enable straight off it,
        -- so a level would feed the same bit in for a whole bit period.
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert bit_valid = '0'
            report "tx_shift_reg: test 3: bit_valid must drop the cycle after load "
                   & "(it is a one-cycle pulse, not a level)!"
            severity error;

        for i in 1 to BITS_3'high loop
            wait until rising_edge(clock);
            shift <= '1';
            wait until rising_edge(clock);
            shift <= '0';
            wait for SYNC_UPDATE_NS;
            assert tx_bit = BITS_3(i)
                report "tx_shift_reg: test 3, shift " & natural'image(i) & ": wrong tx_bit!"
                severity error;
            assert stuff = STUFF_3(i)
                report "tx_shift_reg: test 3, shift " & natural'image(i) & ": wrong stuff flag!"
                severity error;
            assert done_p = '0'
                report "tx_shift_reg: test 3: done pulsed early!"
                severity error;
            assert bit_valid = '1'
                report "tx_shift_reg: test 3, shift " & natural'image(i)
                       & ": bit_valid must be '1' on a real/stuff shift!"
                severity error;

            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert bit_valid = '0'
                report "tx_shift_reg: test 3, shift " & natural'image(i)
                       & ": bit_valid must drop the cycle after a shift "
                       & "(it is a one-cycle pulse, not a level)!"
                severity error;
        end loop;

        wait until rising_edge(clock);
        shift <= '1';
        wait until rising_edge(clock);
        shift <= '0';
        wait for SYNC_UPDATE_NS;
        assert tx_bit = BITS_3(BITS_3'high)
            report "tx_shift_reg: test 3: the closing shift must not change tx_bit!"
            severity error;
        assert done_p = '1'
            report "tx_shift_reg: test 3: done did not pulse on the closing shift!"
            severity error;
        assert bit_valid = '0'
            report "tx_shift_reg: test 3: bit_valid must be '0' on the closing shift!"
            severity error;

        report "tx_shift_reg: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
