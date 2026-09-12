--------------------------------------------------------------------------------
-- Self-checking testbench for sync (the plain double-flop synchronizer).
-- Instantiates it twice: one bit wide with PRESET = '1', and three bits wide
-- with PRESET = '0', so a design that ignores either generic is caught.
--
-- Write your own sync.vhd in THIS directory, then run:
--   ghdl -a --std=93 sync.vhd sync_tb.vhd
--   ghdl -e --std=93 sync_tb
--   ghdl -r --std=93 sync_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity sync_tb is
end entity;

architecture behaviour of sync_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

-- Two flip-flops between the pin and the design, so a change on async_in reaches sync_out
-- on the second rising edge after it, not the first.
constant SYNC_LATENCY: natural := 2;
constant WIDE        : natural := 3;

signal clock, reset_s2_n: std_logic := '0';
signal done             : boolean := false;

signal async_one, sync_one: std_logic_vector(0 downto 0) := (others => '1');
signal async_wide         : std_logic_vector(WIDE - 1 downto 0) := (others => '0');
signal sync_wide          : std_logic_vector(WIDE - 1 downto 0);
begin
    -- An idle-high input, the shape every active-low button and the UART's rx line have.
    one_bit: entity work.sync
        generic map(1, '1')
        port map(clock, reset_s2_n, async_one, sync_one);

    -- Wider than one bit, and preset the other way, so neither generic can be hard-coded.
    wide_bits: entity work.sync
        generic map(WIDE, '0')
        port map(clock, reset_s2_n, async_wide, sync_wide);

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
        -- Case 1: reset_s2_n = '0'.
        -- Expect each instance to hold its own PRESET, whatever is on its input. A design
        -- that resets to '0' regardless passes every later check in this file and then, on a
        -- line that idles high, spends two cycles after every reset claiming a start bit is
        -- in progress.
        reset_s2_n <= '0';
        async_one  <= "0";
        async_wide <= (others => '1');
        for i in 1 to 4 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert sync_one = "1"
            report "sync: reset must load PRESET, which is '1' for this instance!"
            severity failure;
        assert sync_wide = (sync_wide'range => '0')
            report "sync: reset must load PRESET, which is '0' for this instance!"
            severity failure;

        -- Case 2: reset released, input still at the value it had during reset.
        -- Expect sync_out to reach it after exactly SYNC_LATENCY rising edges, and not
        -- before. Checking the edge it arrives on, rather than that it arrives eventually,
        -- is what separates two flip-flops from one, or from a wire.
        reset_s2_n <= '1';
        for i in 1 to SYNC_LATENCY - 1 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert sync_one = "1"
                report "sync: sync_out changed after only " & integer'image(i)
                     & " edge(s) - an input must cross two flip-flops, not one!"
                severity failure;
        end loop;

        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert sync_one = "0"
            report "sync: sync_out should follow async_in after exactly "
                 & integer'image(SYNC_LATENCY) & " rising edges!"
            severity failure;

        -- Case 3: every bit of the wide instance carries its own value.
        -- Expect "101" through, unchanged. A design that synchronizes bit 0 and fans it out,
        -- or that collapses the vector to one flip-flop, fails here.
        async_wide <= "101";
        for i in 1 to SYNC_LATENCY loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert sync_wide = "101"
            report "sync: each bit is synchronized on its own; the vector is not one signal!"
            severity failure;

        -- Case 4: the input moves and moves back within one cycle.
        -- Expect sync_out to show the settled value. This is not a filter and is not being
        -- asked to be one; the check is only that the chain keeps shifting rather than
        -- latching the first thing it saw.
        async_wide <= "010";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        async_wide <= "111";
        for i in 1 to SYNC_LATENCY loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert sync_wide = "111"
            report "sync: the chain must keep shifting, not hold its first value!"
            severity failure;

        -- Case 5: reset asserted again, with no clock edge in between.
        -- Expect PRESET back immediately. This is the check a synchronous reset fails.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert sync_one = "1" and sync_wide = (sync_wide'range => '0')
            report "sync: reset must load PRESET with no clock edge - the reset branch "
                 & "belongs outside the rising_edge(clock) test!"
            severity failure;

        report "sync: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
