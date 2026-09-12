--------------------------------------------------------------------------------
-- Toggle an LED on each synchronized, edge-detected press of button_n.
-- The LED is cleared on reset.
--
-- Inputs:
--    - clock: 50 MHz system clock.
--    - reset_n: Active-low asynchronous reset.
--    - button_n: Active-low button.
-- Outputs:
--    - led: Toggled on the falling edge of button_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity led_toggle_sync is
    port(clock, reset_n, button_n: in std_logic;
         led                     : out std_logic);
end entity;

architecture behaviour of led_toggle_sync is
-- Stable reset signal synchronized using a two-flip-flop synchronizer.
signal reset_s2_n: std_logic;

-- Pulse indicating a falling edge on button_n, synchronized using a two-flip-flop synchronizer.
signal button_edge_s2: std_logic;

-- One-element vectors adapting the scalar button signals above to button_sync,
-- whose button ports are COUNT-bit vectors.
signal button_n_v, button_edge_s2_v: std_logic_vector(0 downto 0);

-- Internal LED state.
signal led_s: std_logic;

begin
    led <= led_s;

    -- Adapt the scalar button signals to button_sync's vector ports.
    button_n_v(0)     <= button_n;
    button_edge_s2 <= button_edge_s2_v(0);

    -- Synchronize the asynchronous reset.
    reset_sync1: entity work.reset_sync
        port map(clock, reset_n, reset_s2_n);

    -- Synchronize button_n and pulse on each press (a single button, so COUNT = 1).
    button_sync1: entity work.button_sync
        generic map(1)
        port map(clock, reset_s2_n, button_n_v, button_edge_s2_v);

    -- Toggle the LED on button press event.
    LED_PROCESS: process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            led_s <= '0';
        elsif (rising_edge(clock)) then
            if (button_edge_s2 = '1') then
                led_s <= not led_s;
            end if;
        end if;
    end process;
end architecture;
