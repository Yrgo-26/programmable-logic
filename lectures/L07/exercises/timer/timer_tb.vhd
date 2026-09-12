--------------------------------------------------------------------------------
-- Self-checking testbench for the timer module (see the exercise for the
-- entity name, ports, and the TICK_COUNT generic).
-- Overrides TICK_COUNT with a tiny value so the simulation runs fast.
--
-- Write your own timer.vhd in THIS directory, then run:
--   ghdl -a --std=93 timer.vhd timer_tb.vhd
--   ghdl -e --std=93 timer_tb
--   ghdl -r --std=93 timer_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity timer_tb is
end entity;

architecture behaviour of timer_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant TICK_COUNT     : natural := 3;

signal clock, reset_s2_n, enable, timeout: std_logic := '0';
signal done                              : boolean := false;
begin
    dut: entity work.timer
        generic map(TICK_COUNT)
        port map(clock, reset_s2_n, enable, timeout);

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
        -- Case 1: reset_s2_n = '0', enable = '0' (system reset).
        -- Expect timeout = '0' (cleared by reset).
        reset_s2_n <= '0';
        enable     <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert timeout = '0'
            report "timer: reset should clear timeout!"
            severity failure;

        -- Case 2: reset_s2_n = '1', enable = '1', three consecutive periods.
        -- Expect timeout = '0' for TICK_COUNT edges, then '1' on the next, three times over.
        -- Watching more than one period is what makes this a check: a timer that fires once
        -- and then latches "done" forever, or one that stops counting after its first
        -- timeout, satisfies a single period perfectly.
        reset_s2_n <= '1';
        enable     <= '1';
        for period in 1 to 3 loop
            for i in 1 to TICK_COUNT loop
                wait until rising_edge(clock);
                wait for SYNC_UPDATE_NS;
                assert timeout = '0'
                    report "timer: timed out early, in period " & integer'image(period) & "!"
                    severity failure;
            end loop;

            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert timeout = '1'
                report "timer: no timeout in period " & integer'image(period)
                     & " - the timer must keep running, not fire once!"
                severity failure;
        end loop;

        -- Case 3: the next clock cycle.
        -- Expect timeout = '0' (the pulse is a single cycle wide).
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert timeout = '0'
            report "timer: timeout should be a single-cycle pulse!"
            severity failure;

        -- Case 4: enable = '0' part way through a period.
        -- Expect timeout = '0' (no timeout while disabled).
        enable <= '0';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert timeout = '0'
                report "timer: must not time out while disabled!"
                severity failure;
        end loop;

        -- Case 5: enable = '1' again, resuming the period Case 4 interrupted.
        -- One edge of that period had already been counted before the timer was disabled,
        -- so exactly TICK_COUNT more edges remain. Expect timeout = '0' for TICK_COUNT - 1
        -- of them and '1' on the last. A timer that clears its counter when disabled needs
        -- a whole fresh period instead and is still low when this fires. The header says
        -- "0 holds the count", and L08's fsm_led depends on it: it parks the timer between
        -- states and expects the count to survive.
        enable <= '1';
        for i in 1 to TICK_COUNT - 1 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert timeout = '0'
                report "timer: timed out too early after being re-enabled!"
                severity failure;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert timeout = '1'
            report "timer: disabling must pause the count, not clear it - on being "
                 & "re-enabled the timer should finish the period it was part way through!"
            severity failure;

        -- Case 6: reset_s2_n = '0' with no clock edge in between, while timeout is still high
        -- from the check above. Expect timeout = '0' immediately.
        --
        -- This is the case that separates an asynchronous reset from a synchronous one, and it
        -- has to be taken here rather than mid-count: at any other moment timeout is already '0'
        -- and both kinds of reset look identical. A design that tests reset_s2_n inside
        -- "if rising_edge(clock)" holds timeout high until the next edge arrives.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert timeout = '0'
            report "timer: reset must clear timeout with no clock edge - test reset_s2_n "
                 & "outside the rising_edge(clock) branch, not inside it!"
            severity failure;

        -- Still reset, still enabled: nothing may count while the reset is held.
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert timeout = '0'
                report "timer: must not time out while reset is held, even when enabled!"
                severity failure;
        end loop;

        -- Case 7: reset released, enable still '1'. The reset cleared the counter as well as
        -- timeout, so what follows is a whole fresh period rather than the remainder of one:
        -- TICK_COUNT edges low, then '1'. Case 5 proved disabling *pauses*; this proves
        -- resetting *clears*, and the two are the only ways the count can change.
        reset_s2_n <= '1';
        for i in 1 to TICK_COUNT loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert timeout = '0'
                report "timer: timed out early after reset - reset must clear the counter, so "
                     & "the first period afterwards is a full one!"
                severity failure;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert timeout = '1'
            report "timer: no timeout in the first period after reset!"
            severity failure;

        report "timer: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
