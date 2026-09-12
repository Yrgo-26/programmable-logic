--------------------------------------------------------------------------------
-- 8-to-1 multiplexer: routes one of inputs(7:0) to x, selected by sel.
--
-- Inputs:
--     - inputs: Data inputs; sel "000" routes inputs(7), "111" routes inputs(0).
--     - sel   : Selector.
-- Outputs:
--     - x: Selected input.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity mux_8to1 is
    port(inputs: in std_logic_vector(7 downto 0);
         sel   : in std_logic_vector(2 downto 0);
         x     : out std_logic);
end entity;

architecture behaviour of mux_8to1 is
begin
    MUX_PROCESS: process (inputs, sel) is
    begin
        -- Check the selector combination, update the output accordingly.
        -- Safety default: drive output low if an invalid selector occurs.
        case (sel) is
            when "000" =>
                x <= inputs(7);
            when "001" =>
                x <= inputs(6);
            when "010" =>
                x <= inputs(5);
            when "011" =>
                x <= inputs(4);
            when "100" =>
                x <= inputs(3);
            when "101" =>
                x <= inputs(2);
            when "110" =>
                x <= inputs(1);
            when "111" =>
                x <= inputs(0);
            when others =>
                x <= '0';
        end case;
    end process;
end architecture;
