--------------------------------------------------------------------------------
-- Self-checking testbench for led_toggle_single.
-- Note: reset is ACTIVE-HIGH in this exercise.
--
-- Write your own led_toggle_single.vhd in THIS directory, then run:
--   ghdl -a --std=93 led_toggle_single.vhd led_toggle_single_tb.vhd
--   ghdl -e --std=93 led_toggle_single_tb
--   ghdl -r --std=93 led_toggle_single_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle_single_tb is
end entity;

architecture behaviour of led_toggle_single_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

signal clock, reset, button: std_logic := '0';
signal led : std_logic;
signal done: boolean := false;
begin
    dut: entity work.led_toggle_single
        port map(clock, reset, button, led);

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
        reset  <= '1';
        button <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = '0'
            report "led_toggle_single: reset should clear led!" severity failure;

        reset <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;

        -- Rising edge on button -> led toggles exactly once.
        button <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = '1'
            report "led_toggle_single: should toggle on button rising edge!" severity failure;

        -- Held high -> no further toggles. Checked after every edge, and over an odd number of
        -- them: a design that toggles on the button's level rather than its edge toggles once
        -- per edge, so checking only after an even number would find it back where it started.
        for i in 1 to 3 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '1'
                report "led_toggle_single: should not toggle while held high!" severity failure;
        end loop;

        -- Release then press again -> toggles once more.
        button <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        button <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = '0'
            report "led_toggle_single: should toggle on second press!" severity failure;

        -- Release and press a third time, so the LED is lit when the reset arrives.
        button <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        button <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = '1'
            report "led_toggle_single: should toggle on third press!" severity failure;

        -- Reset is active-HIGH here, and asynchronous: asserting it clears led straight away,
        -- so this check deliberately does not wait for a clock edge first.
        reset <= '1';
        wait for SYNC_UPDATE_NS;
        assert led = '0'
            report "led_toggle_single: reset should clear led without a clock edge!"
            severity failure;

        report "led_toggle_single: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
