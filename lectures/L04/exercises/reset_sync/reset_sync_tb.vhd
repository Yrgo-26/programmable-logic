--------------------------------------------------------------------------------
-- Self-checking testbench for reset_sync.
--
-- Checks the two halves of "assert asynchronously, release synchronously":
-- pulling reset_n low takes reset_s2_n low straight away, with no clock edge
-- involved, while letting reset_n go only releases reset_s2_n two rising edges
-- later, once the release has been clocked through both flip-flops.
--
-- Write your own reset_sync.vhd in THIS directory, then run:
--   ghdl -a --std=93 reset_sync.vhd reset_sync_tb.vhd
--   ghdl -e --std=93 reset_sync_tb
--   ghdl -r --std=93 reset_sync_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity reset_sync_tb is
end entity;

architecture behaviour of reset_sync_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant SYNC_STAGES    : natural := 2;

signal clock, reset_n: std_logic := '0';
signal reset_s2_n    : std_logic;
signal done          : boolean := false;
begin
    dut: entity work.reset_sync
        port map(clock, reset_n, reset_s2_n);

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
        -- Case 1: reset_n = '0' (system reset).
        -- Expect reset_s2_n = '0'.
        reset_n <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert reset_s2_n = '0'
            report "reset_sync: reset_s2_n should be low while reset_n is low!"
            severity failure;

        -- Case 2: reset_n = '1' (release).
        -- Expect reset_s2_n to stay low for one more rising edge, and to go high on the
        -- second. The release is what has to be synchronous: a reset that comes back exactly
        -- when the asynchronous input says so puts every flip-flop in the design at risk of
        -- leaving reset on a different clock cycle.
        reset_n <= '1';
        for i in 1 to (SYNC_STAGES - 1) loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert reset_s2_n = '0'
                report "reset_sync: reset_s2_n released after only "
                     & integer'image(i) & " clock edge(s)!"
                severity failure;
        end loop;
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert reset_s2_n = '1'
            report "reset_sync: reset_s2_n should be released after two clock edges!"
            severity failure;

        -- Case 3: reset_s2_n must stay high while reset_n does.
        for i in 1 to 4 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert reset_s2_n = '1'
                report "reset_sync: reset_s2_n should stay high while reset_n is high!"
                severity failure;
        end loop;

        -- Case 4: reset_n = '0' again, between clock edges.
        -- Expect reset_s2_n to go low immediately. This check deliberately does not wait
        -- for a rising edge: the assert has to be asynchronous, so that a reset arriving
        -- while the clock is stopped still takes effect.
        wait until falling_edge(clock);
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert reset_s2_n = '0'
            report "reset_sync: reset should assert without waiting for a clock edge!"
            severity failure;

        report "reset_sync: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
