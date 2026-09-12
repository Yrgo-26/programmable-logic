--------------------------------------------------------------------------------
-- Self-checking testbench for min_of_two.
-- m = smaller of a, b (both 4-bit unsigned).
--
-- Write your own min_of_two.vhd in THIS directory, then run:
--   ghdl -a --std=93 min_of_two.vhd min_of_two_tb.vhd
--   ghdl -e --std=93 min_of_two_tb
--   ghdl -r --std=93 min_of_two_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity min_of_two_tb is
end entity;

architecture behaviour of min_of_two_tb is
constant WAIT_NS: time := 10 ns;

-- VHDL-93 has no image function for std_logic_vector, and a failure message that cannot show the
-- value it wanted is not worth much.
function bits(v: std_logic_vector) return string is
variable s: string(1 to v'length);
variable k: natural := 1;
begin
    for i in v'range loop
        case v(i) is
            when '1'    => s(k) := '1';
            when '0'    => s(k) := '0';
            when others => s(k) := 'X';   -- undriven or contended, not a plausible '0'
        end case;
        k := k + 1;
    end loop;
    return s;
end function;

-- Driven from '0' rather than left at 'U'. An unsigned comparison on 'U' is legal but makes
-- numeric_std print "metavalue detected" before the first test case has even run, and a warning
-- on line one of your first run reads like a fault in the module you just wrote.
signal a, b, m: std_logic_vector(3 downto 0) := (others => '0');
begin
    dut: entity work.min_of_two
        port map(a, b, m);

    SIM_PROCESS: process is
    variable expected: std_logic_vector(3 downto 0);
    begin
        for ai in 0 to 15 loop
            for bi in 0 to 15 loop
                a <= std_logic_vector(to_unsigned(ai, 4));
                b <= std_logic_vector(to_unsigned(bi, 4));
                wait for WAIT_NS;
                if unsigned(a) < unsigned(b) then
                    expected := a;
                else
                    expected := b;
                end if;
                assert m = expected
                    report "min_of_two: wrong output with a = " & integer'image(ai)
                         & ", b = " & integer'image(bi)
                         & ", expected " & bits(expected)
                         & " but got " & bits(m) & "!" severity failure;
            end loop;
        end loop;
        report "min_of_two: all checks passed!" severity note;
        wait;
    end process;
end architecture;
