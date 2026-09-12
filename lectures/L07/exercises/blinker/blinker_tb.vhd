--------------------------------------------------------------------------------
-- Self-checking testbench for blinker (once-per-second LED blinker).
-- Overrides TICK_COUNT so the blink is fast enough to simulate. See the
-- exercise for the entity name, ports, and the TICK_COUNT generic.
-- Copy in the two modules this one reuses: the reset_sync.vhd you wrote in
-- L04 and the timer.vhd you wrote in exercise 4. Then write your own
-- blinker.vhd here and:
--
--   ghdl -a --std=93 reset_sync.vhd timer.vhd blinker.vhd blinker_tb.vhd
--   ghdl -e --std=93 blinker_tb
--   ghdl -r --std=93 blinker_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity blinker_tb is
end entity;

architecture behaviour of blinker_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant TICK_COUNT     : natural := 3;
-- Rising edges between reset_n going high and the reset reaching the design: one per
-- flip-flop in the reset_sync the blinker instantiates.
constant SYNC_STAGES    : natural := 2;

signal clock, reset_n, led: std_logic := '0';
signal done               : boolean := false;
begin
    dut: entity work.blinker
        generic map(TICK_COUNT)
        port map(clock, reset_n, led);

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
    constant RESET_CYCLES  : natural := 4;
    constant OBSERVE_CYCLES: natural := 80;
    constant MIN_CHANGES   : natural := 4;
    variable prev: std_logic;
    variable changes, hold, min_gap, max_gap, first_toggle: natural;
    begin
        -- Case 1: reset_n = '0' (system reset). This is the raw, asynchronous
        -- reset: the blinker synchronizes it itself, with its own reset_sync.
        -- Expect led = '0' (LED off during reset).
        reset_n <= '0';
        for i in 1 to RESET_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = '0'
            report "blinker: reset should leave the LED off!"
            severity failure;

        -- Case 2: reset_n = '1' (blinker running).
        -- Expect the LED to toggle repeatedly, holding steady between timer
        -- timeouts (it must not free-run and toggle on every clock cycle).
        -- The reset releases synchronously, two edges after reset_n goes high,
        -- so the first toggle arrives late. The gap measurement below only
        -- starts once a first toggle has been seen, so that latency is not
        -- measured and the reset pattern cannot skew the result.
        reset_n <= '1';
        prev         := led;
        changes      := 0;
        hold         := 0;
        first_toggle := 0;
        min_gap      := OBSERVE_CYCLES + 1;
        max_gap      := 0;
        for i in 1 to OBSERVE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if led /= prev then
                if changes > 0 then
                    if hold < min_gap then
                        min_gap := hold;
                    end if;
                    if hold > max_gap then
                        max_gap := hold;
                    end if;
                end if;
                if changes = 0 then
                    first_toggle := i;
                end if;
                changes := changes + 1;
                prev    := led;
                hold    := 0;
            else
                hold := hold + 1;
            end if;
        end loop;
        assert changes >= MIN_CHANGES
            report "blinker: the LED should blink (toggle) repeatedly!"
            severity failure;
        -- The reset arrives raw, so it has to cross your reset_sync before anything inside can
        -- come out of reset: SYNC_STAGES edges to release, then a full timer period before the
        -- first timeout, then one more edge for your LED flip-flop to sample that pulse. Wiring
        -- reset_n straight to the timer instead skips the two stages and the first toggle lands
        -- early, which is the only difference visible from out here.
        assert first_toggle = SYNC_STAGES + TICK_COUNT + 2
            report "blinker: the first toggle came " & integer'image(first_toggle)
                 & " clock edges after reset_n was released, expected "
                 & integer'image(SYNC_STAGES + TICK_COUNT + 2) & " ("
                 & integer'image(SYNC_STAGES) & " to release the synchronized reset, then "
                 & integer'image(TICK_COUNT + 1) & " for the first timer period, then one more "
                 & "for your LED flip-flop to see the pulse) - the timer must be reset by your "
                 & "reset_sync's output, not by reset_n directly!"
            severity failure;
        -- The gap between toggles must be the timer's period exactly, every time. A lower
        -- bound on its own accepts a blinker that ignores the timer it is supposed to reuse
        -- and divides the clock by some other number of its own, which is the one thing
        -- this exercise asks you not to do.
        assert min_gap = TICK_COUNT and max_gap = TICK_COUNT
            report "blinker: the LED should hold for exactly " & integer'image(TICK_COUNT)
                 & " clock edges between toggles, but the gaps ran from "
                 & integer'image(min_gap) & " to " & integer'image(max_gap)
                 & " - pace it with the timer's timeout pulse, do not count clock cycles!"
            severity failure;

        -- Case 3: reset_n = '0' again, without waiting for a clock edge.
        -- Expect led = '0' at once, because the reset is asynchronous.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert led = '0'
            report "blinker: reset should turn the LED off without a clock edge!"
            severity failure;

        report "blinker: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
