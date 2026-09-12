--------------------------------------------------------------------------------
-- Self-checking testbench for gate_network.
-- Sweeps all eight input combinations; x must equal (a and b) or c.
--
-- Run:  ghdl -a --std=93 gate_network.vhd gate_network_tb.vhd
--       ghdl -e --std=93 gate_network_tb
--       ghdl -r --std=93 gate_network_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gate_network_tb is
end entity;

architecture behaviour of gate_network_tb is
constant INPUT_WIDTH: natural := 3;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

signal a, b, c, x: std_logic;
begin
    dut: entity work.gate_network
        port map(a, b, c, x);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b, c) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = ((a and b) or c)
                report "gate_network: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & " c=" & std_logic'image(c)
                     & ", expected " & std_logic'image((a and b) or c)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "gate_network: all checks passed!" severity note;
        wait;
    end process;
end architecture;
