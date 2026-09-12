--------------------------------------------------------------------------------
-- Self-checking testbench for register4.
--
-- Write your own register4.vhd in THIS directory, then run:
--   ghdl -a --std=93 register4.vhd register4_tb.vhd
--   ghdl -e --std=93 register4_tb
--   ghdl -r --std=93 register4_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity register4_tb is
end entity;

architecture behaviour of register4_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

signal clock, reset_n, enable: std_logic := '0';
signal d, q                  : std_logic_vector(3 downto 0) := (others => '0');
signal done                  : boolean := false;
begin
    dut: entity work.register4
        port map(clock, reset_n, enable, d, q);

    -- Free-running clock; stops once the stimulus process sets 'done'.
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
        reset_n <= '0';
        enable  <= '0';
        d       <= "0000";
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = "0000"
            report "register4: reset should clear q!" severity failure;

        reset_n <= '1';
        d       <= "1010";
        enable  <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = "1010"
            report "register4: should capture d when enable = '1'!" severity failure;

        -- Change d in the middle of a cycle, with enable still '1' and no clock edge in
        -- between. A register built from flip-flops cannot see this until the next edge.
        -- A level-sensitive latch follows it immediately, which is the whole difference
        -- between the two, and every other case in this file would pass either one.
        d <= "0011";
        wait for SYNC_UPDATE_NS * 2;
        assert q = "1010"
            report "register4: q changed with no clock edge - you have built a "
                 & "transparent latch, not an edge-triggered register!"
            severity failure;

        d      <= "0101";
        enable <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = "1010"
            report "register4: should hold q when enable = '0'!" severity failure;

        enable <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert q = "0101"
            report "register4: should capture new d!" severity failure;

        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert q = "0000"
            report "register4: async reset should clear q immediately!" severity failure;

        report "register4: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
