--------------------------------------------------------------------------------
-- Self-checking testbench for mux_8to1.
-- For each 8-bit input, checks every selector value routes the matching bit to x.
--
-- Run:  ghdl -a --std=93 mux_8to1.vhd mux_8to1_tb.vhd
--       ghdl -e --std=93 mux_8to1_tb
--       ghdl -r --std=93 mux_8to1_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_8to1_tb is
end entity;

architecture behaviour of mux_8to1_tb is
constant SEL_WIDTH  : natural := 3;
constant SEL_MAX    : natural := 2**SEL_WIDTH - 1;
constant INPUT_WIDTH: natural := 2**SEL_WIDTH;
constant INPUT_MAX  : natural := 2**INPUT_WIDTH - 1;
constant WAIT_NS    : time := 10 ns;

-- VHDL-93 has no image function for std_logic_vector, and "inputs = 178" makes a reader convert
-- to binary by hand before the message says anything about which input was selected.
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

signal inputs: std_logic_vector(INPUT_WIDTH - 1 downto 0);
signal sel   : std_logic_vector(SEL_WIDTH - 1 downto 0);
signal x     : std_logic;
begin
    dut: entity work.mux_8to1
        port map(inputs, sel, x);

    SIM_PROCESS: process is
    constant INPUT_IDX_MAX: natural:= INPUT_WIDTH - 1;
    variable expected: std_logic;
    begin
        for i in 0 to INPUT_MAX loop
            inputs <= std_logic_vector(to_unsigned(i, INPUT_WIDTH));
            for s in 0 to SEL_MAX loop
                sel <= std_logic_vector(to_unsigned(s, SEL_WIDTH));
                wait for WAIT_NS;
                expected := inputs(INPUT_IDX_MAX - s);
                assert x = expected
                    report "mux_8to1: wrong output with sel = " & integer'image(s)
                         & ", inputs = " & bits(inputs)
                         & ", expected " & std_logic'image(expected)
                         & " but got " & std_logic'image(x) & "!"
                    severity failure;
            end loop;
        end loop;
        report "mux_8to1: all checks passed!" severity note;
        wait;
    end process;
end architecture;
