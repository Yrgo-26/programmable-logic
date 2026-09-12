--------------------------------------------------------------------------------
-- Minimized gate network for the Appendix A Karnaugh example: x = ab + c.
--
-- Inputs:
--     - a, b, c: The three function inputs.
-- Outputs:
--     - x: Network output.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity gate_network is
    port(a, b, c: in std_logic;
         x      : out std_logic);
end entity;

architecture behaviour of gate_network is
begin
    x <= (a and b) or c;
end architecture;
