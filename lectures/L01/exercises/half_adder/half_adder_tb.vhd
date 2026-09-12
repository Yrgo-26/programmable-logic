--------------------------------------------------------------------------------
-- Self-checking testbench for half_adder (one-bit addition, sum and carry).
--
-- Write your own half_adder.vhd in THIS directory, then run:
--   ghdl -a --std=93 half_adder.vhd half_adder_tb.vhd
--   ghdl -e --std=93 half_adder_tb
--   ghdl -r --std=93 half_adder_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity half_adder_tb is
end entity;

architecture behaviour of half_adder_tb is
constant INPUT_WIDTH: natural := 2;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

-- The two outputs, transcribed from the addition rather than from either gate. Written as
-- an expression they would be exactly the xor and the and the module is supposed to
-- contain, so a design that reached for the wrong operator would be checked against its own
-- mistake. Indexed by (a, b) read as a 2-bit number:
--
--   0 + 0 = 0 carry 0    0 + 1 = 1 carry 0
--   1 + 0 = 1 carry 0    1 + 1 = 0 carry 1
constant EXPECTED_SUM  : std_logic_vector(0 to INPUT_MAX) := "0110";
constant EXPECTED_CARRY: std_logic_vector(0 to INPUT_MAX) := "0001";

signal a, b, sum, carry: std_logic;
begin
    dut: entity work.half_adder
        port map(a, b, sum, carry);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            -- Checked separately, and this is the point of the exercise: a design that swaps
            -- the two outputs, or drives carry with an or instead of an and, is right about
            -- one of them and wrong about the other. One combined assertion would report
            -- "wrong at i = 3" and leave you to work out which half failed.
            assert sum = EXPECTED_SUM(i)
                report "half_adder: wrong sum with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & ", expected " & std_logic'image(EXPECTED_SUM(i))
                     & " but got " & std_logic'image(sum)
                     & " - sum is 1 when exactly one input is 1!"
                severity failure;
            assert carry = EXPECTED_CARRY(i)
                report "half_adder: wrong carry with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & ", expected " & std_logic'image(EXPECTED_CARRY(i))
                     & " but got " & std_logic'image(carry)
                     & " - carry is 1 only when both inputs are 1!"
                severity failure;
        end loop;
        report "half_adder: all checks passed!" severity note;
        wait;
    end process;
end architecture;
