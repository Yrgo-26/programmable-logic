--------------------------------------------------------------------------------
-- Self-checking testbench for combo_logic (x = ab + c'd).
--
-- Write your own combo_logic.vhd in THIS directory, then run:
--   ghdl -a --std=93 combo_logic.vhd combo_logic_tb.vhd
--   ghdl -e --std=93 combo_logic_tb
--   ghdl -r --std=93 combo_logic_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity combo_logic_tb is
end entity;

architecture behaviour of combo_logic_tb is
constant INPUT_WIDTH: natural := 4;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

signal a, b, c, d, x: std_logic;
begin
    dut: entity work.combo_logic
        port map(a, b, c, d, x);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b, c, d) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = ((a and b) or ((not c) and d))
                report "combo_logic: wrong output with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b)
                     & " c=" & std_logic'image(c)
                     & " d=" & std_logic'image(d)
                     & ", expected " & std_logic'image((a and b) or ((not c) and d))
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "combo_logic: all checks passed!" severity note;
        wait;
    end process;
end architecture;
