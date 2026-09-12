--------------------------------------------------------------------------------
-- Self-checking testbench for hex_display (two hexadecimal 7-segment digits).
--
-- Sweeps all 256 values of input and checks that the top four bits reach hex1
-- and the bottom four reach hex0, each decoded to the right segment code. A
-- design that wires the two halves the wrong way round passes every check on
-- input values whose halves happen to be equal, so both halves are swept
-- independently rather than together.
--
-- The segment codes are the same ones display was checked against, and are
-- active-low: a '0' lights a segment. Bit order is hex(6 downto 0) = g f e d c b a.
--
-- Write your own hex_display.vhd in THIS directory and copy in the display.vhd
-- you wrote for the previous exercise, then run:
--   ghdl -a --std=93 display.vhd hex_display.vhd hex_display_tb.vhd
--   ghdl -e --std=93 hex_display_tb
--   ghdl -r --std=93 hex_display_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hex_display_tb is
end entity;

architecture behaviour of hex_display_tb is
type code_array is array (0 to 15) of std_logic_vector(6 downto 0);

-- One segment code per hexadecimal digit, 0 through F.
constant EXPECTED: code_array := (
    "1000000",   -- 0
    "1111001",   -- 1
    "0100100",   -- 2
    "0110000",   -- 3
    "0011001",   -- 4
    "0010010",   -- 5
    "0000010",   -- 6
    "1111000",   -- 7
    "0000000",   -- 8
    "0010000",   -- 9
    "0001000",   -- A
    "0000011",   -- b
    "1000110",   -- C
    "0100001",   -- d
    "0000110",   -- E
    "0001110");  -- F

-- The digit each index prints, so a failure can name it.
constant DIGITS: string(1 to 16) := "0123456789AbCdEF";

-- VHDL-93 has no image function for std_logic_vector, and a failure message that
-- cannot show the code it wanted is not worth much.
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

constant WAIT_NS: time := 10 ns;

signal input     : std_logic_vector(7 downto 0);
signal hex1, hex0: std_logic_vector(6 downto 0);
begin
    dut: entity work.hex_display
        port map(input, hex1, hex0);

    SIM_PROCESS: process is
    begin
        for hi in 0 to 15 loop
            for lo in 0 to 15 loop
                input <= std_logic_vector(to_unsigned(hi, 4))
                       & std_logic_vector(to_unsigned(lo, 4));
                wait for WAIT_NS;
                assert hex1 = EXPECTED(hi)
                    report "hex_display: wrong code on hex1 for input(7 downto 4) = "
                         & DIGITS(hi + 1) & ", expected " & bits(EXPECTED(hi))
                         & " but got " & bits(hex1) & "!" severity failure;
                assert hex0 = EXPECTED(lo)
                    report "hex_display: wrong code on hex0 for input(3 downto 0) = "
                         & DIGITS(lo + 1) & ", expected " & bits(EXPECTED(lo))
                         & " but got " & bits(hex0) & "!" severity failure;
            end loop;
        end loop;
        report "hex_display: all checks passed!" severity note;
        wait;
    end process;
end architecture;
