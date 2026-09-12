--------------------------------------------------------------------------------
-- 8-bit serial receiver: a SIPO shift register paired with a bit counter, so it
-- reports a complete byte rather than shifting forever. Bits arrive most
-- significant first, one per enabled clock edge. See Appendix A.5.
--
-- Inputs:
--    - clock       : 50 MHz system clock.
--    - reset_s2_n  : Active-low, already-synchronized reset: drive it from a
--                    reset_sync (L04 A.5), never straight from a pin. Asynchronous
--                    here, so it clears the register and the bit count with no
--                    clock edge involved.
--    - shift_enable: High for one clock cycle per incoming bit; holds both the
--                    shift register and the bit count when low.
--    - serial_in   : Serial input bit, sampled on each enabled rising edge.
-- Outputs:
--    - data_out  : Received byte, valid while data_ready is high.
--    - data_ready: One-cycle pulse as the eighth bit lands.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity serial_rx8 is
    port(clock, reset_s2_n, shift_enable, serial_in: in std_logic;
         data_out                                  : out std_logic_vector(7 downto 0);
         data_ready                                : out std_logic);
end entity;

architecture behaviour of serial_rx8 is

-- Bit width.
constant BIT_WIDTH: natural := 8;

-- Most significant bit.
constant MSB: natural := BIT_WIDTH - 1;

-- Shift register.
signal shift_reg: std_logic_vector(MSB downto 0);

-- Bit counter.
signal bit_count: natural range 0 to MSB;

begin
    data_out <= shift_reg;

    process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            shift_reg  <= (others => '0');
            bit_count  <= 0;
            data_ready <= '0';
        elsif (rising_edge(clock)) then
            data_ready <= '0';
            if (shift_enable = '1') then
                shift_reg <= shift_reg(MSB - 1 downto 0) & serial_in;
                if (bit_count >= BIT_WIDTH - 1) then
                    data_ready <= '1';
                    bit_count  <= 0;
                else
                    bit_count <= bit_count + 1;
                end if;
            end if;
        end if;
    end process;
end architecture;
