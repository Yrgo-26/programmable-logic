--------------------------------------------------------------------------------
-- Self-checking testbench for led_toggle_sync2 (two-button synchronized LED toggle).
-- Each button, once synchronized, toggles only its own LED on a falling edge.
--
-- Write your own led_toggle_sync2.vhd in THIS directory, then run:
--   ghdl -a --std=93 led_toggle_sync2.vhd led_toggle_sync2_tb.vhd
--   ghdl -e --std=93 led_toggle_sync2_tb
--   ghdl -r --std=93 led_toggle_sync2_tb --assert-level=error --stop-time=10ms
--
-- That is the whole build if you inlined the synchronizers, which is the route
-- the exercise recommends. If you split them out into subcomponents instead,
-- copy in your own reset_sync.vhd and button_sync.vhd and name them first:
--   ghdl -a --std=93 reset_sync.vhd button_sync.vhd \
--                    led_toggle_sync2.vhd led_toggle_sync2_tb.vhd
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle_sync2_tb is
end entity;

architecture behaviour of led_toggle_sync2_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

signal clock, reset_n: std_logic := '0';
-- Active low, so "11" is both buttons released.
signal button_n: std_logic_vector(1 downto 0) := (others => '1');
signal led     : std_logic_vector(1 downto 0);
signal done: boolean := false;
begin
    dut: entity work.led_toggle_sync2
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
        -- Case 1: reset_n = '0', button_n = "11" (system reset).
        -- Expect led = "00" (both LEDs cleared).
        reset_n  <= '0';
        button_n <= "11";
        for k in 1 to 4 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = "00"
            report "led_toggle_sync2: reset should clear both LEDs!" severity failure;

        -- Case 2: reset_n = '1', no button press.
        -- Expect led = "00" (both LEDs stay off).
        reset_n <= '1';
        for k in 1 to 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = "00"
            report "led_toggle_sync2: LEDs should stay off with no press!" severity failure;

        -- Case 3: button_n(0) = '0' (press button 0, falling edge).
        -- Expect led = "01" (led(0) toggles, led(1) untouched), but not before the press has
        -- travelled the synchronizer. This case checks *when* the LED changes, not just that
        -- it ends up right: the press reaches button_s2_n/button_s3_n on the second edge, so
        -- the pulse is only visible to the toggle process on the third. A design that feeds
        -- the raw button straight into an edge detector toggles on the first edge instead,
        -- and would settle to the same "01" a few edges later. Checking only the settled
        -- value is what lets an unsynchronized design pass, and the synchronizer is the
        -- entire point of this lecture.
        button_n <= "10";
        for k in 1 to 2 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = "00"
                report "led_toggle_sync2: led toggled after only " & integer'image(k)
                     & " clock edge(s) - button_n must pass through the synchronizer "
                     & "flip-flops before it reaches the edge detector!"
                severity failure;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = "01"
            report "led_toggle_sync2: pressing button 0 should toggle led(0) only!" severity failure;

        -- Settle out the rest of the original six-edge window before the next case.
        for k in 1 to 3 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Case 4: button_n(0) held at '0' (still pressed).
        -- Expect led = "01" (no further toggle).
        for k in 1 to 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = "01"
            report "led_toggle_sync2: a held button should not toggle again!" severity failure;

        -- Case 5: release button 0, then button_n(1) = '0' (press button 1).
        -- Expect led = "11" (led(1) toggles, led(0) unchanged).
        button_n <= "11";
        for k in 1 to 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        button_n <= "01";
        for k in 1 to 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = "11"
            report "led_toggle_sync2: pressing button 1 should toggle led(1) only!" severity failure;

        -- Case 6: reset_n = '0' with both LEDs lit.
        -- Expect them cleared without waiting for a clock edge. A reset synchronizer asserts
        -- asynchronously and only releases in step with the clock, so the LEDs go out the
        -- moment reset_n does.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert led = "00"
            report "led_toggle_sync2: reset should clear the LEDs without a clock edge!"
            severity failure;

        report "led_toggle_sync2: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
