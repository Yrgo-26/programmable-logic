--------------------------------------------------------------------------------
-- spi_def: the SPI transaction layer's own constants, and one testbench helper.
--
-- Provided, like the testbenches beside it. It holds only what belongs to the
-- *transport*: the command byte's write bit, and to_hex, so a bench can print a
-- bus value in a failure message.
--
-- The register indices are deliberately not here. They belong to the register
-- map in project/register_map.md, and naming them twice is how the two sides
-- drift apart; each consumer derives its own local constants from the index
-- column. See project/spi_register_protocol.md for the transaction format this
-- package's one constant belongs to.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package spi_def is
    -- Command byte, bit 7: '1' = write, '0' = read. Bits 3-0 carry the register
    -- index (offset / 4); bits 6-4 are reserved and must be zero.
    constant CMD_WRITE_BIT: integer := 7;

    -- Testbench helper: render a std_logic_vector as an uppercase hex string,
    -- zero-padded to whole nibbles (e.g. x"A5" -> "A5", a 12-bit bus -> three digits).
    function to_hex(slv: std_logic_vector) return string;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package body spi_def is
    function to_hex(slv: std_logic_vector) return string is
        constant DIGITS : string(1 to 16) := "0123456789ABCDEF";
        constant NIBBLES: natural := (slv'length + 3) / 4;
        variable v  : unsigned(NIBBLES * 4 - 1 downto 0) := (others => '0');
        variable res: string(1 to NIBBLES);
    begin
        v(slv'length - 1 downto 0) := unsigned(slv);
        for i in 0 to NIBBLES - 1 loop
            res(NIBBLES - i) := DIGITS(to_integer(v(i * 4 + 3 downto i * 4)) + 1);
        end loop;
        return res;
    end function;
end package body;
