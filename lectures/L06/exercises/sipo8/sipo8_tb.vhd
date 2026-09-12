--------------------------------------------------------------------------------
-- Self-checking testbench for sipo8 (serial-in / parallel-out).
--
-- Write your own sipo8.vhd in THIS directory, then run:
--   ghdl -a --std=93 sipo8.vhd sipo8_tb.vhd
--   ghdl -e --std=93 sipo8_tb
--   ghdl -r --std=93 sipo8_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity sipo8_tb is
end entity;

architecture behaviour of sipo8_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

-- Shifted in most significant bit first, so after eight clocks the register holds it whole.
constant PATTERN: std_logic_vector(7 downto 0) := "11010010";

signal clock, reset_s2_n, serial_in: std_logic := '0';
signal parallel_out: std_logic_vector(7 downto 0);
signal done        : boolean := false;
begin
    dut: entity work.sipo8
        port map(clock, reset_s2_n, serial_in, parallel_out);

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
    variable expected: std_logic_vector(parallel_out'range);
    begin
        -- Case 1: reset_s2_n = '0' (system reset).
        -- Expect parallel_out = "00000000" (register cleared).
        reset_s2_n <= '0';
        serial_in  <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert parallel_out = "00000000"
            report "sipo8: reset should clear the register!"
            severity failure;

        -- Case 2: shift in all eight bits of PATTERN, most significant bit first (the newest
        -- bit lands in bit 0). Expect the register to take one bit per clock, so that the
        -- first bit shifted in has travelled all the way up to bit 7 by the eighth clock and
        -- the register holds the whole pattern. Shifting only half a byte would leave the top
        -- of the register untested, and a shift register with a broken bit 7 passing.
        reset_s2_n <= '1';
        expected   := (others => '0');
        for j in PATTERN'high downto PATTERN'low loop
            serial_in <= PATTERN(j);
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            expected := expected(expected'high - 1 downto 0) & PATTERN(j);
            assert parallel_out = expected
                report "sipo8: wrong contents after shifting in bit "
                     & integer'image(j) & " of the pattern!"
                severity failure;
        end loop;
        assert parallel_out = PATTERN
            report "sipo8: eight shifts should leave the whole pattern in the register!"
            severity failure;

        -- Case 3: one more bit. Expect the oldest bit to fall off the top of the register.
        serial_in <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert parallel_out = PATTERN(PATTERN'high - 1 downto PATTERN'low) & '1'
            report "sipo8: a ninth bit should push the first one out of the register!"
            severity failure;

        -- Case 4: reset_s2_n = '0' with data in the register.
        -- Expect it cleared, and cleared asynchronously: this check does not wait for a
        -- clock edge, so a synchronous reset fails it.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert parallel_out = (parallel_out'range => '0')
            report "sipo8: reset should clear the register without waiting for a clock edge!"
            severity failure;

        report "sipo8: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
