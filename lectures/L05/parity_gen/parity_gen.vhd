-------------------------------------------------------------------------------
-- 8-bit XOR-parity generator.
--
-- Inputs:
--     - bits: The eight bits to compute parity over.
-- Outputs:
--     - parity: '1' if 'bits' holds an odd number of set bits, '0' otherwise.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity parity_gen is
    port(bits  : in std_logic_vector(7 downto 0);
         parity: out std_logic);
end entity;

architecture behaviour of parity_gen is
-- Internal representation of 'parity'.
signal parity_s: std_logic;
begin
    parity <= parity_s;

    PARITY_PROCESS: process(bits) is
        variable acc: std_logic;
    begin
        acc := '0';
        for i in bits'range loop
            acc := acc xor bits(i);
        end loop;
        parity_s <= acc;
    end process;
end architecture;
