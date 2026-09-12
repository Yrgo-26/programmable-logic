--------------------------------------------------------------------------------
-- Self-checking testbench for led_toggle_sync.
-- Each button press (falling edge on button_n) toggles the LED once, after the
-- synchronizer latency.
--
-- Copy in the two modules this one reuses, the reset_sync.vhd and button_sync.vhd
-- you wrote in L04 exercises 8 and 9, and then:
--
--   cp ../exercises/reset_sync/reset_sync.vhd .
--   cp ../exercises/button_sync/button_sync.vhd .
--   ghdl -a --std=93 reset_sync.vhd button_sync.vhd \
--                    led_toggle_sync.vhd led_toggle_sync_tb.vhd
--   ghdl -e --std=93 led_toggle_sync_tb
--   ghdl -r --std=93 led_toggle_sync_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle_sync_tb is
end entity;

architecture behaviour of led_toggle_sync_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant SYNC_STAGES    : natural := 2;

signal clock, reset_n: std_logic := '0';
-- Active low, so '1' is the released, idle state. Starting at '0' would mean starting with
-- the button held down.
signal button_n      : std_logic := '1';
signal led           : std_logic;
signal done          : boolean := false;
begin
    dut: entity work.led_toggle_sync
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
    constant PULSES: natural := 10;
    begin
        -- Case 1: reset_n = '0', button_n = '1' (system reset).
        -- Expect led = '0' (LED cleared).
        reset_n  <= '0';
        button_n <= '1';
        for i in 0 to SYNC_STAGES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '0'
            report "led_toggle_sync: reset should turn the LED off!"
            severity failure;

        -- Case 2: reset_n = '1', no button press.
        -- Expect led = '0' (LED stays off).
        reset_n <= '1';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '0'
            report "led_toggle_sync: LED should stay off with no press!"
            severity failure;

        -- Case 3: button_n = '0' (press, falling edge).
        -- Expect led = '1', but not before the press has travelled the synchronizer: the
        -- press reaches button_s2_n and button_s3_n on the second edge, so the pulse is
        -- only visible to the toggle process on the third. That is SYNC_STAGES edges
        -- through the synchronizer, then one more to register the toggle. A design that
        -- feeds the raw button straight into the edge detector toggles on the very first
        -- edge and settles to the same '1' long before this case ends, so checking only
        -- the settled value would pass it, and the synchronizer is the point of L04.
        button_n <= '0';
        for i in 1 to SYNC_STAGES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '0'
                report "led_toggle_sync: LED toggled after only " & integer'image(i)
                     & " clock edge(s) - button_n must pass through the synchronizer "
                     & "flip-flops before it reaches the edge detector!"
                severity failure;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert led = '1'
            report "led_toggle_sync: a press should toggle the LED on!"
            severity failure;

        -- Settle out the rest of the original window before the next case.
        for i in SYNC_STAGES + 2 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Case 4: button_n held at '0' (still pressed).
        -- Expect led = '1' (no further toggle).
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '1'
            report "led_toggle_sync: a held button should not toggle again!"
            severity failure;

        -- Case 5: button_n = '1' then '0' (release, then a second press).
        -- Expect led = '0' (toggles back off).
        button_n <= '1';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        button_n <= '0';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '0'
            report "led_toggle_sync: a second press should toggle the LED off!"
            severity failure;

        -- Case 6: release and press a third time, so the LED is lit when the reset arrives.
        -- Expect led = '1'.
        button_n <= '1';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        button_n <= '0';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '1'
            report "led_toggle_sync: a third press should toggle the LED back on!"
            severity failure;

        -- Case 7: reset_n = '0' with the LED lit.
        -- Expect it cleared without waiting for a clock edge. A reset synchronizer asserts
        -- asynchronously and only releases in step with the clock, so the LED goes out the
        -- moment reset_n does. A design that clears the LED inside its rising_edge branch
        -- instead fails here.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert led = '0'
            report "led_toggle_sync: reset should turn the LED off without a clock edge!"
            severity failure;

        report "led_toggle_sync: all checks passed!"
        severity note;
        done <= true;
        wait;
    end process;
end architecture;
