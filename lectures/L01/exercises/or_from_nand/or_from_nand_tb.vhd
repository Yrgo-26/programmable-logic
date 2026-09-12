--------------------------------------------------------------------------------
-- Self-checking testbench for or_from_nand (a 2-input OR gate built from NAND gates only).
-- Write your own or_from_nand.vhd in THIS directory, then run:
--   ghdl -a --std=93 or_from_nand.vhd or_from_nand_tb.vhd
--   ghdl -e --std=93 or_from_nand_tb
--   ghdl -r --std=93 or_from_nand_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity or_from_nand_tb is
end entity;

architecture behaviour of or_from_nand_tb is
constant INPUT_WIDTH: natural := 2;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;
signal a, b, x: std_logic;
begin
    dut: entity work.or_from_nand
        port map(a, b, x);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = (a or b)
                report "or_from_nand: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & ", expected " & std_logic'image(a or b)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "or_from_nand: all checks passed!" severity note;
        wait;
    end process;
end architecture;
