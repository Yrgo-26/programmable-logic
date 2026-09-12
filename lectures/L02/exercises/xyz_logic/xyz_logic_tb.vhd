--------------------------------------------------------------------------------
-- Self-checking testbench for xyz_logic (4-input / 3-output gate network).
-- Write your own xyz_logic.vhd in THIS directory, then run:
--   ghdl -a --std=93 xyz_logic.vhd xyz_logic_tb.vhd
--   ghdl -e --std=93 xyz_logic_tb
--   ghdl -r --std=93 xyz_logic_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xyz_logic_tb is
end entity;

architecture behaviour of xyz_logic_tb is
constant INPUT_WIDTH : natural := 4;
constant INPUT_MAX   : natural := 2**INPUT_WIDTH - 1;
constant OUTPUT_WIDTH: natural := 3;
constant WAIT_NS     : time := 10 ns;

type output_vec_t is array(0 to INPUT_MAX) of std_logic_vector(OUTPUT_WIDTH - 1 downto 0);
constant EXPECTED: output_vec_t := ("001", "010", "001", "011",
                                    "100", "110", "100", "111",
                                    "101", "110", "101", "111",
                                    "000", "010", "000", "011");
signal a, b, c, d: std_logic;
signal x, y, z   : std_logic;
begin
    dut: entity work.xyz_logic
        port map(a, b, c, d, x, y, z);

    SIM_PROCESS: process is
    begin
        for i in 0 to INPUT_MAX loop
            (a, b, c, d) <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            wait for WAIT_NS;
            assert x = EXPECTED(i)(2)
                report "xyz_logic: wrong X with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b) & " c=" & std_logic'image(c)
                     & " d=" & std_logic'image(d)
                     & ", expected " & std_logic'image(EXPECTED(i)(2))
                     & " but got " & std_logic'image(x) & "!"
                severity failure;
            assert y = EXPECTED(i)(1)
                report "xyz_logic: wrong Y with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b) & " c=" & std_logic'image(c)
                     & " d=" & std_logic'image(d)
                     & ", expected " & std_logic'image(EXPECTED(i)(1))
                     & " but got " & std_logic'image(y) & "!"
                severity failure;
            assert z = EXPECTED(i)(0)
                report "xyz_logic: wrong Z with a=" & std_logic'image(a)
                     & " b=" & std_logic'image(b) & " c=" & std_logic'image(c)
                     & " d=" & std_logic'image(d)
                     & ", expected " & std_logic'image(EXPECTED(i)(0))
                     & " but got " & std_logic'image(z) & "!"
                severity failure;
        end loop;
        report "xyz_logic: all checks passed!" severity note;
        wait;
    end process;
end architecture;
