--------------------------------------------------------------------------------
-- Self-checking testbench for mux4 (4:1 multiplexer).
-- Convention checked here: sel "00"->d0, "01"->d1, "10"->d2, "11"->d3.
--
-- Write your own mux4.vhd in THIS directory, then run:
--   ghdl -a --std=93 mux4.vhd mux4_tb.vhd
--   ghdl -e --std=93 mux4_tb
--   ghdl -r --std=93 mux4_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux4_tb is
end entity;

architecture behaviour of mux4_tb is
constant WAIT_NS: time := 10 ns;

signal d0, d1, d2, d3, x: std_logic;
signal sel: std_logic_vector(1 downto 0);
begin
    dut: entity work.mux4
        port map(d0, d1, d2, d3, sel, x);

    SIM_PROCESS: process is
    variable expected      : std_logic;
    variable undefined_high: std_logic;
    variable undefined_low : std_logic;
    begin
        for dv in 0 to 15 loop
            (d3, d2, d1, d0) <= std_logic_vector(to_unsigned(dv, 4));
            for s in 0 to 3 loop
                sel <= std_logic_vector(to_unsigned(s, 2));
                wait for WAIT_NS;
                case s is
                    when 0      => expected := d0;
                    when 1      => expected := d1;
                    when 2      => expected := d2;
                    when others => expected := d3;
                end case;
                assert x = expected
                    report "mux4: wrong output with dv = " & integer'image(dv)
                         & ", sel = " & integer'image(s)
                         & ", expected " & std_logic'image(expected)
                         & " but got " & std_logic'image(x) & "!" severity failure;
            end loop;
        end loop;

        -- The when others branch. Which safe value you picked for it is your choice, so what
        -- is checked here is the property that holds whichever you picked: the output must not
        -- depend on what was selected beforehand. A case ending in `when others => null;`
        -- analyzes, simulates, and quietly infers a latch that holds the last selected input,
        -- which is the bug L05 exercise 7 is about, and every check above passes with it.
        (d3, d2, d1, d0) <= std_logic_vector'("1111");
        sel <= "00";
        wait for WAIT_NS;
        sel <= "XX";
        wait for WAIT_NS;
        undefined_high := x;

        (d3, d2, d1, d0) <= std_logic_vector'("0000");
        sel <= "00";
        wait for WAIT_NS;
        sel <= "XX";
        wait for WAIT_NS;
        undefined_low := x;

        assert undefined_high = undefined_low
            report "mux4: an undefined sel must drive a safe value of its own, the same one "
                 & "either way, but it gave " & std_logic'image(undefined_high) & " after a "
                 & "selected '1' and " & std_logic'image(undefined_low) & " after a selected "
                 & "'0' - the when others branch is holding the last input instead of "
                 & "assigning!" severity failure;

        report "mux4: all checks passed!" severity note;
        wait;
    end process;
end architecture;
