--------------------------------------------------------------------------------
-- Self-checking testbench for xor3 (3-input XOR / odd parity).
-- Write your own xor3.vhd in THIS directory, then run:
--   ghdl -a --std=93 xor3.vhd xor3_tb.vhd
--   ghdl -e --std=93 xor3_tb
--   ghdl -r --std=93 xor3_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xor3_tb is
end entity;

architecture behaviour of xor3_tb is
constant INPUT_WIDTH: natural := 3;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;
signal a, b, c, x: std_logic;
begin
    dut: entity work.xor3
        port map(a, b, c, x);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b, c) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = (a xor b xor c)
                report "xor3: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & " c=" & std_logic'image(c)
                     & ", expected " & std_logic'image(a xor b xor c)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "xor3: all checks passed!" severity note;
        wait;
    end process;
end architecture;
