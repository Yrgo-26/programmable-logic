--------------------------------------------------------------------------------
-- Self-checking testbench for fsm_led.
-- Overrides TIMER_TICK_COUNT (3) so the blink is fast. Walks the state cycle
-- STATE_OFF -> STATE_BLINK -> STATE_ON -> STATE_OFF via presses on button_n(0),
-- then walks it backwards via button_n(1), and checks the LED in each state.
-- Also checks that two presses landing on the same cycle move the machine nowhere.
--
-- Copy in the three modules this one reuses, the reset_sync.vhd and button_sync.vhd
-- you wrote in L04 and the timer.vhd you wrote in L07, and then:
--
--   cp ../../L04/exercises/reset_sync/reset_sync.vhd .
--   cp ../../L04/exercises/button_sync/button_sync.vhd .
--   cp ../../L07/exercises/timer/timer.vhd .
--   ghdl -a --std=93 reset_sync.vhd button_sync.vhd timer.vhd \
--                    fsm_led.vhd fsm_led_tb.vhd
--   ghdl -e --std=93 fsm_led_tb
--   ghdl -r --std=93 fsm_led_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsm_led_tb is
end entity;

architecture behaviour of fsm_led_tb is
constant CLOCK_PERIOD_NS : time := 10 ns;
constant CLOCK_EVENT_NS  : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS  : time := CLOCK_PERIOD_NS / 10;
constant TIMER_TICK_COUNT: natural := 3;

signal clock, reset_n: std_logic := '0';
signal button_n      : std_logic_vector(1 downto 0) := "11";
signal led           : std_logic := '0';
signal done          : boolean := false;

-- A press: drive the given active-low button pattern, then release, with time for
-- the button synchronizer and the state transition to settle.
procedure press(signal btn: out std_logic_vector(1 downto 0);
                signal clk: in  std_logic;
                pattern   : in  std_logic_vector(1 downto 0)) is
constant PRESS_CYCLES  : natural := 6;
constant RELEASE_CYCLES: natural := 10;
begin
    btn <= pattern;
    for i in 1 to PRESS_CYCLES loop
        wait until rising_edge(clk);
    end loop;
    btn <= "11";
    for i in 1 to RELEASE_CYCLES loop
        wait until rising_edge(clk);
    end loop;
end procedure;

-- Step forward: falling edge on button_n(0) alone.
procedure press_next(signal btn: out std_logic_vector(1 downto 0);
                     signal clk: in std_logic) is
begin
    press(btn, clk, "10");
end procedure;

-- Step backward: falling edge on button_n(1) alone.
procedure press_prev(signal btn: out std_logic_vector(1 downto 0);
                     signal clk: in std_logic) is
begin
    press(btn, clk, "01");
end procedure;

-- Both buttons on the same cycle: the machine must not move.
procedure press_both(signal btn: out std_logic_vector(1 downto 0);
                     signal clk: in std_logic) is
begin
    press(btn, clk, "00");
end procedure;
begin
    dut: entity work.fsm_led
        generic map(TIMER_TICK_COUNT)
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
    constant RESET_CYCLES : natural := 4;
    constant SETTLE_CYCLES: natural := 8;
    constant HOLD_CYCLES  : natural := 12;
    constant BLINK_CYCLES : natural := 40;

    variable changes                : natural;
    variable hold, min_gap, max_gap : natural;
    variable prev_led               : std_logic;
    begin
        -- Case 1: reset_n = '0' (system reset).
        -- Expect led = '0' (machine resets to STATE_OFF).
        reset_n  <= '0';
        button_n <= "11";
        for i in 1 to RESET_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '0'
            report "fsm_led: reset should enter STATE_OFF (led '0')!"
            severity failure;

        reset_n <= '1';
        for i in 1 to SETTLE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Case 2: reset released, no button press (STATE_OFF).
        -- Expect led = '0' (LED stays low in STATE_OFF).
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '0'
                report "fsm_led: STATE_OFF should hold the LED low!"
                severity failure;
        end loop;

        -- Case 3: press button_n(0) (STATE_OFF -> STATE_BLINK).
        -- Expect led to toggle, and to toggle at the timer's rate rather than the clock's.
        press_next(button_n, clock);
        changes  := 0;
        hold     := 0;
        min_gap  := BLINK_CYCLES + 1;
        max_gap  := 0;
        prev_led := led;
        for i in 1 to BLINK_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if led /= prev_led then
                -- Skip the first two toggles before measuring. The timer pauses rather
                -- than clears when STATE_BLINK is left, so on re-entry it resumes part
                -- way through a period and the first blink interval is legitimately
                -- short. Everything after it is the steady blink rate.
                if changes > 1 then
                    if hold < min_gap then
                        min_gap := hold;
                    end if;
                    if hold > max_gap then
                        max_gap := hold;
                    end if;
                end if;
                changes  := changes + 1;
                prev_led := led;
                hold     := 0;
            else
                hold := hold + 1;
            end if;
        end loop;
        assert changes >= 2
            report "fsm_led: STATE_BLINK should toggle the LED!"
            severity failure;
        -- Counting changes alone is not a check: a STATE_BLINK that toggles on every clock
        -- edge produces BLINK_CYCLES of them and satisfies the assertion above. The blink
        -- has to be paced by the timer, which is why fsm_led instantiates one at all.
        assert min_gap = TIMER_TICK_COUNT and max_gap = TIMER_TICK_COUNT
            report "fsm_led: STATE_BLINK should hold the LED for exactly "
                 & integer'image(TIMER_TICK_COUNT) & " clock edges between toggles, but "
                 & "the gaps ran from " & integer'image(min_gap) & " to "
                 & integer'image(max_gap) & " - pace the blink with the timer's timeout!"
            severity failure;

        -- Case 4: press button_n(0) (STATE_BLINK -> STATE_ON).
        -- Expect led = '1' (held high in STATE_ON).
        press_next(button_n, clock);
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '1'
                report "fsm_led: STATE_ON should hold the LED high!"
                severity failure;
        end loop;

        -- Case 5: press button_n(0) (STATE_ON -> STATE_OFF).
        -- Expect led = '0' (held low in STATE_OFF).
        press_next(button_n, clock);
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '0'
                report "fsm_led: STATE_OFF should hold the LED low!"
                severity failure;
        end loop;

        -- Case 6: press both buttons on the same cycle, from STATE_OFF.
        -- Expect led = '0'. Each direction requires the other button's edge to be low, so
        -- two presses landing together cancel and the machine stays where it is. Without
        -- this case nothing distinguishes that from a machine that just picks a winner.
        press_both(button_n, clock);
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '0'
                report "fsm_led: two presses on the same cycle should move the machine "
                     & "nowhere, so it should still be in STATE_OFF!"
                severity failure;
        end loop;

        -- Case 7: press button_n(1) (STATE_OFF -> STATE_ON, stepping backwards).
        -- Expect led = '1'. Everything above walks the cycle in one direction only.
        press_prev(button_n, clock);
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '1'
                report "fsm_led: button_n(1) should step backwards, STATE_OFF -> STATE_ON!"
                severity failure;
        end loop;

        -- Case 8: press button_n(1) (STATE_ON -> STATE_BLINK).
        -- Expect the LED to toggle again.
        press_prev(button_n, clock);
        changes  := 0;
        prev_led := led;
        for i in 1 to BLINK_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if led /= prev_led then
                changes  := changes + 1;
                prev_led := led;
            end if;
        end loop;
        assert changes >= 2
            report "fsm_led: button_n(1) should step backwards, STATE_ON -> STATE_BLINK!"
            severity failure;

        -- Case 9: press button_n(1) (STATE_BLINK -> STATE_OFF), closing the reverse lap.
        -- Expect led = '0'.
        press_prev(button_n, clock);
        for i in 1 to HOLD_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = '0'
                report "fsm_led: button_n(1) should step backwards, "
                     & "STATE_BLINK -> STATE_OFF!"
                severity failure;
        end loop;

        report "fsm_led: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
