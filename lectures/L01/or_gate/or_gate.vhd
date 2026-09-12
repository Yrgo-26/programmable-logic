---------------------------------------------------------------------------
-- Two-input OR gate: x = a or b.
--
-- Inputs:
--     - a, b: OR inputs.
--
-- Outputs:
--     - x: OR output.
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity or_gate is
    port(a, b: in std_logic;
         x   : out std_logic);
end entity;

architecture behaviour of or_gate is
begin
    x <= a or b;
end architecture;
