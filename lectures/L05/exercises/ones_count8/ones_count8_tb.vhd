--------------------------------------------------------------------------------
-- Self-checking testbench for ones_count8 (population count of an 8-bit vector).
-- Sweeps all 256 input values and checks the count against one computed
-- independently here, so agreeing by accident is not possible.
--
-- Write your own ones_count8.vhd in THIS directory, then run:
--   ghdl -a --std=93 ones_count8.vhd ones_count8_tb.vhd
--   ghdl -e --std=93 ones_count8_tb
--   ghdl -r --std=93 ones_count8_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ones_count8_tb is
end entity;

architecture behaviour of ones_count8_tb is
constant WAIT_NS   : time    := 10 ns;
constant BIT_WIDTH : natural := 8;
constant INPUT_MAX : natural := 2 ** BIT_WIDTH - 1;

signal bits: std_logic_vector(BIT_WIDTH - 1 downto 0) := (others => '0');
signal ones: natural range 0 to BIT_WIDTH;
begin
    dut: entity work.ones_count8
        port map(bits, ones);

    SIM_PROCESS: process is
    -- The value of i as a vector, and the number of set bits in it, both derived from i
    -- rather than from the module under test. Restating the requirement independently is
    -- what turns this into a check: a testbench that asked the design what it thought the
    -- answer was would agree with it even when it is wrong.
    variable stimulus: std_logic_vector(BIT_WIDTH - 1 downto 0);
    variable expected: natural range 0 to BIT_WIDTH;
    variable rest    : natural;
    begin
        for i in 0 to INPUT_MAX loop
            rest     := i;
            expected := 0;
            for b in 0 to BIT_WIDTH - 1 loop
                if (rest mod 2 = 1) then
                    stimulus(b) := '1';
                    expected    := expected + 1;
                else
                    stimulus(b) := '0';
                end if;
                rest := rest / 2;
            end loop;

            bits <= stimulus;
            wait for WAIT_NS;

            assert ones = expected
                report "ones_count8: wrong count for input " & integer'image(i)
                     & " - expected " & integer'image(expected)
                     & ", got " & integer'image(ones) & "!"
                severity failure;
        end loop;

        report "ones_count8: all checks passed!" severity note;
        wait;
    end process;
end architecture;
