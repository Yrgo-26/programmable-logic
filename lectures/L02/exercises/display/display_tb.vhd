--------------------------------------------------------------------------------
-- Self-checking testbench for display (one hexadecimal 7-segment digit).
--
-- Sweeps all sixteen values of number and checks hex against the segment code
-- for that digit.
--
-- The codes are active-low, because the DE0-CV's displays are: a '0' lights a
-- segment. That is why 8, which lights every segment, is "0000000", and why a
-- blank display is "1111111".
--
-- Bit order is hex(6 downto 0) = g, f, e, d, c, b, a.
--
-- Write your own display.vhd in THIS directory, then run:
--   ghdl -a --std=93 display.vhd display_tb.vhd
--   ghdl -e --std=93 display_tb
--   ghdl -r --std=93 display_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_tb is
end entity;

architecture behaviour of display_tb is
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

-- The code the when others branch must drive: every segment off.
constant DISPLAY_OFF: std_logic_vector(6 downto 0) := "1111111";

constant WAIT_NS: time := 10 ns;

signal number: std_logic_vector(3 downto 0);
signal hex   : std_logic_vector(6 downto 0);
begin
    dut: entity work.display
        port map(number, hex);

    SIM_PROCESS: process is
    begin
        for i in EXPECTED'range loop
            number <= std_logic_vector(to_unsigned(i, 4));
            wait for WAIT_NS;
            assert hex = EXPECTED(i)
                report "display: wrong code for digit " & DIGITS(i + 1)
                     & ", expected " & bits(EXPECTED(i))
                     & " but got " & bits(hex) & "!" severity failure;
        end loop;

        -- The when others branch, which the exercise asks you to blank the display in. A case
        -- ending in `when others => null;` analyzes, simulates, and quietly infers a latch
        -- that holds the last digit, which is the bug L05 exercise 7 is about, and every check
        -- above passes with it.
        number <= "XXXX";
        wait for WAIT_NS;
        assert hex = DISPLAY_OFF
            report "display: an undefined number must blank the display, expected "
                 & bits(DISPLAY_OFF) & " but got " & bits(hex) & "!" severity failure;

        report "display: all checks passed!" severity note;
        wait;
    end process;
end architecture;
