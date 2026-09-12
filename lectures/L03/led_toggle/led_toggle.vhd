--------------------------------------------------------------------------------
-- Toggles led(i) on each falling edge of button_n(i); all LEDs off on reset.
--
-- Inputs:
--     - clock   : 50 MHz system clock.
--     - reset_n : Active-low reset.
--     - button_n: Active-low push buttons.
-- Outputs:
--     - led: LED toggled by the matching button.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle is
    port(clock, reset_n: in std_logic;
         button_n      : in std_logic_vector(1 downto 0);
         led           : out std_logic_vector(1 downto 0));
end entity;

architecture behaviour of led_toggle is
-- Previous button values (for edge detection).
signal button_prev_n: std_logic_vector(1 downto 0);

-- Button pressdown indicators (falling edge).
signal button_edge: std_logic_vector(1 downto 0);

-- LED states (necessary for toggling, as output signals cannot be read).
signal led_s: std_logic_vector(1 downto 0);
begin
    -- Detect a falling edge of button_n.
    button_edge <= (not button_n) and button_prev_n;
    led <= led_s;

    -- Update button_prev_n on system reset or on rising edge of the system clock.
    BUTTON_PROCESS: process(clock, reset_n) is
    begin
        if (reset_n = '0') then
            button_prev_n <= "11";
        elsif (rising_edge(clock)) then
            button_prev_n <= button_n;
        end if;
    end process;

    -- Update led_s on system reset or on rising edge of the system clock.
    LED_PROCESS: process(clock, reset_n) is
    begin
        if (reset_n = '0') then
            led_s <= "00";
        elsif (rising_edge(clock)) then
            for i in 0 to 1 loop
                if (button_edge(i) = '1') then
                    led_s(i) <= not led_s(i);
                end if;
            end loop;
        end if;
    end process;
end architecture;
