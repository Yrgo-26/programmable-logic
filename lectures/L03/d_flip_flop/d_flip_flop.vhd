--------------------------------------------------------------------------------
-- Rising-edge D flip-flop with asynchronous reset and enable.
--
-- Inputs:
--     - clock  : 50 MHz system clock.
--     - reset_n: Active-low asynchronous reset.
--     - d      : Data input.
--     - enable : Capture enable ('1' = load d on the edge, '0' = hold).
-- Outputs:
--     - q  : Flip-flop output.
--     - q_n: Inverse of q.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop is
    port(clock, reset_n, d, enable: in std_logic;
         q, q_n                   : out std_logic);
end entity;

architecture behaviour of d_flip_flop is
-- Internal representation of q.
signal q_s: std_logic;
begin
    q   <= q_s;
    q_n <= not q_s;

    -- Implement D flip flop logic.
    process (clock, reset_n) is
    begin
        if (reset_n = '0') then
            q_s <= '0';
        elsif (rising_edge(clock)) then
            if (enable = '1') then
                q_s <= d;
            end if;
        end if;
    end process;
end architecture;
