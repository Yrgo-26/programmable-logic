--------------------------------------------------------------------------------
-- Self-checking testbench for counter.
--
-- Elaborates two instances, so the RADIX generic is exercised rather than merely
-- declared: an architecture that ignores RADIX and hard-codes 10 passes the first
-- instance and fails the second.
--
-- Write your own counter.vhd in THIS directory, then run:
--   ghdl -a --std=93 counter.vhd counter_tb.vhd
--   ghdl -e --std=93 counter_tb
--   ghdl -r --std=93 counter_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity counter_tb is
end entity;

architecture behaviour of counter_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

-- The radix the exercise gives as the default, and a small one that wraps far more often.
-- Nothing in the design should care which of the two it was given.
constant RADIX_DEFAULT  : natural range 1 to 2**16 := 10;
constant RADIX_SMALL    : natural range 1 to 2**16 := 4;

signal clock, reset_s2_n       : std_logic := '0';
signal tick_default, tick_small: std_logic;
signal count_default           : natural range 0 to RADIX_DEFAULT-1 := 0;
signal count_small             : natural range 0 to RADIX_SMALL-1   := 0;
signal done                    : boolean := false;

-- One body of checks, run against each instance in turn. Passing the signals in rather
-- than writing the process out twice is what holds both instances to the same standard.
procedure check_counter(signal   count: in natural;
                        signal   tick : in std_logic;
                        signal   clk  : in std_logic;
                        constant radix: in natural;
                        constant name : in string) is
begin
    -- Two full 0..radix-1 cycles. Expect count to increment by one each clock edge, with
    -- tick low the whole way, then wrap to 0 and pulse tick. One pass is not enough: a
    -- counter that wraps correctly once and then stops satisfies a single pass, and so
    -- does a tick that goes high on the first wrap and stays there.
    for cycle in 1 to 2 loop
        for expected in 1 to radix-1 loop
            wait until rising_edge(clk);
            wait for SYNC_UPDATE_NS;
            assert count = expected
                report "counter (" & name & "): wrong count value in cycle "
                     & integer'image(cycle) & ": expected " & integer'image(expected)
                     & ", got " & integer'image(count) & "!"
                severity failure;
            -- Checking tick low on every counting edge, not just after the wrap, is what
            -- rules out a tick that also fires part way through the cycle.
            assert tick = '0'
                report "counter (" & name & "): tick must only pulse on the wrap edge, "
                     & "but it was high at count = " & integer'image(expected) & "!"
                severity failure;
        end loop;

        wait until rising_edge(clk);
        wait for SYNC_UPDATE_NS;
        assert count = 0
            report "counter (" & name & "): should wrap from "
                 & integer'image(radix-1) & " to 0!"
            severity failure;
        assert tick = '1'
            report "counter (" & name & "): tick should pulse on the wrap edge!"
            severity failure;
    end loop;

    -- The edge after the wrap: tick is a single-cycle pulse, so it must be back down.
    wait until rising_edge(clk);
    wait for SYNC_UPDATE_NS;
    assert count = 1 and tick = '0'
        report "counter (" & name & "): tick should be high for exactly one cycle!"
        severity failure;
end procedure;
begin
    dut_default: entity work.counter
        generic map(RADIX_DEFAULT)
        port map(clock, reset_s2_n, count_default, tick_default);

    dut_small: entity work.counter
        generic map(RADIX_SMALL)
        port map(clock, reset_s2_n, count_small, tick_small);

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
        -- Expect count = 0 in both instances (counter cleared).
        reset_s2_n <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert count_default = 0 and count_small = 0
            report "counter: reset should clear count!"
            severity failure;

        -- Case 2: RADIX = 10, the default the exercise specifies.
        reset_s2_n <= '1';
        check_counter(count_default, tick_default, clock, RADIX_DEFAULT, "RADIX = 10");

        -- Case 3: RADIX = 4, the same module wrapping more than twice as often. Reset
        -- first, so this instance is checked from a known count rather than from wherever
        -- the previous case happened to leave it.
        reset_s2_n <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        reset_s2_n <= '1';
        check_counter(count_small, tick_small, clock, RADIX_SMALL, "RADIX = 4");

        -- Case 4: reset_s2_n = '0' without waiting for a clock edge (asynchronous reset).
        -- Expect count = 0 and tick = '0' immediately, in both instances.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert count_default = 0 and tick_default = '0'
           and count_small = 0 and tick_small = '0'
            report "counter: reset should clear count without waiting for a clock edge!"
            severity failure;

        report "counter: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
