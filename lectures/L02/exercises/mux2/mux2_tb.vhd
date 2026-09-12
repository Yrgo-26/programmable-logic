--------------------------------------------------------------------------------
-- Self-checking testbench for mux2 (2:1 multiplexer).
-- Convention checked here: sel = '0' routes d0, sel = '1' routes d1.
--
-- Write your own mux2.vhd in THIS directory, then run:
--   ghdl -a --std=93 mux2.vhd mux2_tb.vhd
--   ghdl -e --std=93 mux2_tb
--   ghdl -r --std=93 mux2_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2_tb is
end entity;

architecture behaviour of mux2_tb is
constant INPUT_WIDTH: natural := 3;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

signal d0, d1, sel, x: std_logic;
begin
    dut: entity work.mux2
        port map(d0, d1, sel, x);

    SIM_PROCESS: process is
    variable expected: std_logic;
    begin
        for i in 0 to INPUT_MAX loop
            (d0, d1, sel) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            if sel = '0' then
                expected := d0;
            else
                expected := d1;
            end if;
            assert x = expected
                report "mux2: wrong output with d0=" & std_logic'image(d0)
                     & " d1=" & std_logic'image(d1)
                     & " sel=" & std_logic'image(sel)
                     & ", expected " & std_logic'image(expected)
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
        end loop;
        report "mux2: all checks passed!" severity note;
        wait;
    end process;
end architecture;
