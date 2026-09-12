--------------------------------------------------------------------------------
-- Self-checking testbench for led_toggle.
-- Each active-low button press (falling edge) toggles the matching LED once.
--
-- Run:  ghdl -a --std=93 led_toggle.vhd led_toggle_tb.vhd
--       ghdl -e --std=93 led_toggle_tb
--       ghdl -r --std=93 led_toggle_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle_tb is
end entity;

architecture behaviour of led_toggle_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

signal clock, reset_n: std_logic := '0';
-- Active low, so "11" is both buttons released. Starting them at "00" would mean starting
-- with both held down, which is not the idle state the design is written for.
signal button_n      : std_logic_vector(1 downto 0) := (others => '1');
signal led           : std_logic_vector(1 downto 0);
signal done          : boolean := false;
begin
    dut: entity work.led_toggle
        port map(clock, reset_n, button_n, led);

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
        -- Expect led = "00" (all LEDs cleared).
        reset_n  <= '0';
        button_n <= "11";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = "00"
            report "led_toggle: reset should clear all LEDs!"
            severity failure;

        reset_n <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;

        -- Case 2: button_n(0) = '0' (press event).
        -- Expect led(0) = '1' (toggle event).
        button_n <= "10";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = "01"
            report "led_toggle: pressing button_n(0) should toggle led(0)!"
            severity failure;

        -- Case 3: button_n(0) = '0' (button held down).
        -- Expect led(0) = '1' (no further toggles). Checked after every edge, and over an odd
        -- number of them: a design that toggles on the button's level rather than its edge
        -- toggles once per edge, so checking only after an even number would find it back
        -- where it started.
        for i in 1 to 3 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = "01"
                report "led_toggle: a held button should not toggle again!"
                severity failure;
        end loop;

        -- Case 4: button_n(0) = '1' (release event), then button_n(1) = '0' (press event).
        -- Expect led(1) = '1' (toggle event).
        button_n <= "11";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        button_n <= "01";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = "11"
            report "led_toggle: pressing button 1 should toggle led(1)!"
            severity failure;

        -- Case 5: reset_n = '0' with both LEDs lit.
        -- Expect them cleared, and cleared asynchronously: this check does not wait for a
        -- clock edge, so a design that clears its LEDs inside the rising_edge branch, rather
        -- than in the reset branch above it, fails here.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert led = "00"
            report "led_toggle: reset should clear the LEDs without waiting for a clock edge!"
            severity failure;

        report "led_toggle: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
