--------------------------------------------------------------------------------
-- Testbench for meta_prev. Run it against your own meta_prev.vhd. Two
-- instances are driven at once, one at the default width and one at WIDTH = 4,
-- so the generic is exercised rather than merely declared.
--
-- Run, from controller/:
--       ghdl -a --std=93 meta_prev.vhd meta_prev_tb.vhd
--       ghdl -e --std=93 meta_prev_tb
--       ghdl -r --std=93 meta_prev_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity meta_prev_tb is
end entity;

architecture behaviour of meta_prev_tb is
constant CLOCK_PERIOD_NS: time    := 20 ns; -- 50 MHz.
constant CLOCK_EVENT_NS : time    := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time    := 1 ns;
constant WIDE           : natural := 4;
constant SETTLE_CYCLES  : natural := 4;  -- Edges clocked through before the first check.
constant STEADY_CYCLES  : natural := 6;  -- Edges a steady input is held for in case 4.

signal clock    : std_logic                         := '0';
signal async_bit: std_logic_vector(0 downto 0)      := "0";
signal sync_bit : std_logic_vector(0 downto 0);
signal async_vec: std_logic_vector(WIDE-1 downto 0) := (others => '0');
signal sync_vec : std_logic_vector(WIDE-1 downto 0);
signal done     : boolean                           := false;

begin
    dut_bit: entity work.meta_prev
        port map(clock, async_bit, sync_bit);

    dut_vec: entity work.meta_prev
        generic map(WIDE)
        port map(clock, async_vec, sync_vec);

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
        -- meta_prev has no reset, so clock the initial '0' level through the
        -- chain first; the checks below start from a known output.
        for i in 1 to SETTLE_CYCLES loop
            wait until rising_edge(clock);
        end loop;

        -- Case 1: one bit, low to high.
        -- Expect the old level after one edge, the new level after two.
        async_bit <= "1";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_bit = "0"
            report "meta_prev: sync_out changed after only one clock edge!"
            severity error;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_bit = "1"
            report "meta_prev: sync_out did not follow async_in after two clock edges!"
            severity error;

        -- Case 2: the same bit, high to low.
        -- Expect the same two-edge latency; the chain is symmetric.
        async_bit <= "0";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_bit = "1"
            report "meta_prev: sync_out changed after only one clock edge (high to low)!"
            severity error;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_bit = "0"
            report "meta_prev: sync_out did not follow a high-to-low change!"
            severity error;

        -- Case 3: WIDTH = 4.
        -- Expect all four bits to arrive together, two edges after the change.
        async_vec <= "1011";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_vec = "0000"
            report "meta_prev: a WIDTH = 4 sync_out changed after only one clock edge!"
            severity error;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_vec = "1011"
            report "meta_prev: a WIDTH = 4 sync_out did not follow async_in after two edges!"
            severity error;

        -- Case 4: both inputs held steady.
        -- Expect both outputs to hold too, not to follow the first stage.
        for i in 1 to STEADY_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert sync_vec = "1011" and sync_bit = "0"
                report "meta_prev: sync_out moved while async_in was steady!"
                severity error;
        end loop;

        report "meta_prev: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
