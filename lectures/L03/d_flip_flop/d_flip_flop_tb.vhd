--------------------------------------------------------------------------------
-- Self-checking testbench for d_flip_flop.
-- Checks reset dominance, capture on enable, hold when disabled, and async reset.
--
-- Run:  ghdl -a --std=93 d_flip_flop.vhd d_flip_flop_tb.vhd
--       ghdl -e --std=93 d_flip_flop_tb
--       ghdl -r --std=93 d_flip_flop_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop_tb is
end entity;

architecture behaviour of d_flip_flop_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

signal clock, reset_n, d, enable, q, q_n: std_logic := '0';
signal done                             : boolean := false;
begin
    dut: entity work.d_flip_flop
        port map(clock, reset_n, d, enable, q, q_n);

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
    variable q_prev: std_logic := '0';
    begin
        -- Case 1: reset_n = '0' (system reset).
        -- Expect q = '0' and q_n = '1'.
        reset_n <= '0';
        d       <= '0';
        enable  <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = '0', q_n = '1' on system reset!"
            severity failure;

        d <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = '0', q_n = '1' on system reset!"
            severity failure;

        enable <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = '0', q_n = '1' on system reset!"
            severity failure;

        -- Case 2: enable = '1' (open mode).
        -- Expect q = d and q = !d.
        reset_n <= '1';
        d       <= '1';
        enable  <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '1' and q_n = '0'
            report "d_flip_flop: should give q = d when enable = '1'!"
            severity failure;

        -- Drop d in the middle of a cycle, with enable still '1' and no clock edge in
        -- between. A flip-flop cannot see this until the next rising edge; a transparent
        -- latch follows it at once. Every other case in this file passes either one, so
        -- this is the check that tells the two apart.
        d <= '0';
        wait for SYNC_UPDATE_NS;
        assert q = '1' and q_n = '0'
            report "d_flip_flop: q followed d with no clock edge - that is a transparent "
                 & "latch, not a flip-flop!"
            severity failure;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = d when enable = '1'!"
            severity failure;

        -- Case 3: enable = '0' (locked mode).
        -- Expect q = q_prev and q_n = !q_prev (state held despite changes in d).
        -- Hold a '1' first. Holding a '0' is not enough on its own: a flip-flop
        -- that clears when disabled looks identical to one that holds, because
        -- the value it would be holding is '0' either way.
        reset_n <= '1';
        d       <= '1';
        enable  <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '1' and q_n = '0'
            report "d_flip_flop: should give q = d when enable = '1'!"
            severity failure;

        q_prev := q;
        d      <= '0';
        enable <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = q_prev and q_n = (not q_prev)
            report "d_flip_flop: should hold q when enable = '0'!"
            severity failure;

        d <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = q_prev and q_n = (not q_prev)
            report "d_flip_flop: should hold q when enable = '0'!"
            severity failure;

        -- Then hold a '0', so both polarities are covered.
        d      <= '0';
        enable <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = d when enable = '1'!"
            severity failure;

        q_prev := q;
        d      <= '1';
        enable <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = q_prev and q_n = (not q_prev)
            report "d_flip_flop: should hold q when enable = '0'!"
            severity failure;

        -- Case 4: reset_n = '0' without waiting for rising clock edge (asynchronous reset).
        -- Expect q = '0' and q_n = '1'.
        -- Start by setting q = '1', then generate asynchronous reset.
        reset_n <= '1';
        d       <= '1';
        enable  <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = '1' and q_n = '0'
            report "d_flip_flop: should give q = d when enable = '1'!"
            severity failure;

        -- Do not wait for rising clock edge here to generate asynchronous reset.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert q = '0' and q_n = '1'
            report "d_flip_flop: should give q = '0' and q_n = '1' when reset_n = '0' (async)!"
            severity failure;

        report "d_flip_flop: all checks passed!"
        severity note;
        done <= true;
        wait;
    end process;
end architecture;
