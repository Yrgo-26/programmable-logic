--------------------------------------------------------------------------------
-- Self-checking testbench for nand_gate.
--
-- Write your own nand_gate.vhd in THIS directory, then run:
--   ghdl -a --std=93 nand_gate.vhd nand_gate_tb.vhd
--   ghdl -e --std=93 nand_gate_tb
--   ghdl -r --std=93 nand_gate_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity nand_gate_tb is
end entity;

architecture behaviour of nand_gate_tb is
constant INPUT_WIDTH: natural := 2;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

signal a, b, x: std_logic;
begin
    dut: entity work.nand_gate
        port map(a, b, x);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = (a nand b)
                report "nand_gate: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & ", expected " & std_logic'image(a nand b)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "nand_gate: all checks passed!" severity note;
        wait;
    end process;
end architecture;
