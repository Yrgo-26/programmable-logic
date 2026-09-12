--------------------------------------------------------------------------------
-- Testbench for bit_timer. Run it against your own bit_timer.vhd.
--
-- Run, from controller/:
--       ghdl -a --std=93 can_def.vhd bit_timer.vhd bit_timer_tb.vhd
--       ghdl -e --std=93 bit_timer_tb
--       ghdl -r --std=93 bit_timer_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.can_def.all;

entity bit_timer_tb is
end entity;

architecture behaviour of bit_timer_tb is
constant CLOCK_PERIOD_NS    : time := 20 ns;
constant CLOCK_EVENT_NS     : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS     : time := CLOCK_PERIOD_NS / 10;
constant RESET_CYCLES       : natural := 3;
constant CHECKED_PERIODS    : natural := 3;  -- Full bit periods checked in case 3.
constant TICKS_BEFORE_RESYNC: natural := 11; -- Ticks into the period before resync fires.

signal clock, reset_s2_n, enable, resync: std_logic := '0';
signal sample, bit_done                 : std_logic := '0';
signal done                             : boolean   := false;
begin
    dut: entity work.bit_timer
        port map(clock, reset_s2_n, enable, resync, sample, bit_done);

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
        -- Case 1: reset_s2_n = '0' (system reset).
        -- Expect sample = '0' and bit_done = '0' (both cleared by reset).
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        assert sample = '0' and bit_done = '0'
            report "bit_timer: sample/bit_done must be '0' while held in reset!"
            severity error;

        -- Case 2: reset_s2_n = '1', enable = '0'.
        -- Expect sample = '0' and bit_done = '0' (the counter never advances
        -- while disabled).
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        for i in 0 to TICKS_PER_BIT * 2 - 1 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert sample = '0' and bit_done = '0'
                report "bit_timer: advanced while enable = '0'!"
                severity error;
        end loop;

        -- Enable, then synchronize to the first bit_done pulse so the
        -- counted checks below start at a known period boundary, regardless
        -- of exactly which clock edge "enable" took effect on.
        enable <= '1';
        wait until bit_done = '1';

        -- Case 3: enable = '1', three full bit periods.
        -- Expect sample to pulse once per period at SAMPLE_TICK, and bit_done
        -- to pulse once per period on its last tick.
        for period in 1 to CHECKED_PERIODS loop
            for i in 0 to TICKS_PER_BIT - 1 loop
                wait until rising_edge(clock);
                wait for SYNC_UPDATE_NS;

                if (i = SAMPLE_TICK) then
                    assert sample = '1'
                        report "bit_timer: expected sample at tick " & natural'image(i) & "!"
                        severity error;
                else
                    assert sample = '0'
                        report "bit_timer: unexpected sample at tick " & natural'image(i) & "!"
                        severity error;
                end if;

                if (i = TICKS_PER_BIT - 1) then
                    assert bit_done = '1'
                        report "bit_timer: expected bit_done at tick " & natural'image(i) & "!"
                        severity error;
                else
                    assert bit_done = '0'
                        report "bit_timer: unexpected bit_done at tick " & natural'image(i) & "!"
                        severity error;
                end if;
            end loop;
        end loop;

        -- Case 4: resync mid-period.
        -- Expect the next bit_done exactly TICKS_PER_BIT ticks after the
        -- resync, not wherever the interrupted period would have finished --
        -- and, just as importantly, sample at SAMPLE_TICK of the *restarted*
        -- period. Adopting the sender's bit boundary is only useful if the
        -- sample point moves with it; a timer that restarts its wrap counter
        -- but leaves the sample comparison on the old phase reads the bus at
        -- the wrong instant and passes a bit_done-only check.
        for i in 1 to TICKS_BEFORE_RESYNC loop
            wait until rising_edge(clock);
        end loop;

        resync <= '1';
        wait until rising_edge(clock);
        resync <= '0';

        -- The edge that saw resync = '1' set the counter back to 0, so this loop's
        -- iteration i is the tick where the restarted period has counter = i.
        for i in 0 to TICKS_PER_BIT - 2 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert bit_done = '0'
                report "bit_timer: bit_done fired early after resync!"
                severity error;

            if (i = SAMPLE_TICK) then
                assert sample = '1'
                    report "bit_timer: expected sample at tick " & natural'image(i)
                        & " of the period restarted by resync!"
                    severity error;
            else
                assert sample = '0'
                    report "bit_timer: unexpected sample at tick " & natural'image(i)
                        & " after resync!"
                    severity error;
            end if;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert bit_done = '1'
            report "bit_timer: expected bit_done exactly TICKS_PER_BIT ticks after resync!"
            severity error;
        assert sample = '0'
            report "bit_timer: sample fired on the same tick as bit_done after resync!"
            severity error;

        report "bit_timer: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
