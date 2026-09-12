--------------------------------------------------------------------------------
-- Moore FSM cycling an LED through OFF / BLINK / ON via two push buttons.
-- (Moore: the LED depends only on the state, never directly on the buttons;
-- contrast seq_detect_mealy. See Appendix A.5.)
--
-- Generics:
--    - TIMER_TICK_COUNT: The timer's tick count, so the interval between LED
--      toggles in STATE_BLINK (default = 5 000 000, i.e. about 100 ms at
--      50 MHz; override to shorten it in a testbench).
--
-- Inputs:
--    - clock: 50 MHz system clock.
--    - reset_n: Active-low asynchronous reset.
--    - button_n: Active-low buttons; (0) = next state, (1) = previous.
--
-- Outputs:
--    - led: The controlled LED.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity fsm_led is
    generic(TIMER_TICK_COUNT: natural := 5_000_000);
    port(clock, reset_n: in std_logic;
         button_n      : in std_logic_vector(1 downto 0);
         led           : out std_logic);
end entity;

architecture behaviour of fsm_led is
-- Enumeration of states.
type state_t is (STATE_OFF, STATE_BLINK, STATE_ON);

-- Synchronized input signals after two-flip-flop metastability protection.
signal reset_s2_n       : std_logic;
signal button_edge_s2: std_logic_vector(1 downto 0);

-- Timer signals.
signal timer_enable, timer_timeout: std_logic;

-- Internal LED state.
signal led_s: std_logic;

-- Current state.
signal state: state_t;

-- Signals indicating whether to change state.
signal to_prev_state, to_next_state: std_logic;
begin
    -- Assign the internal LED state to the output port.
    led <= led_s;

    -- Enable the timer in STATE_BLINK only.
    timer_enable <= '1' when STATE_BLINK = state else '0';

    -- Indicate a change to the previous state on a falling edge of button_n(1).
    -- Each direction also requires the other button's edge to be '0', so two
    -- presses landing on the same clock cycle move the machine nowhere.
    to_prev_state <= '1' when button_edge_s2(1) = '1' and button_edge_s2(0) = '0' else '0';

    -- Indicate a change to the next state on a falling edge of button_n(0).
    to_next_state <= '1' when button_edge_s2(0) = '1' and button_edge_s2(1) = '0' else '0';

    -- Synchronize the asynchronous reset (Appendix A.4, reusing L04's reset_sync).
    reset_sync1: entity work.reset_sync
        port map(clock, reset_n, reset_s2_n);

    -- Synchronize both buttons and pulse on each press (Appendix A.4, reusing
    -- L04's button_sync at COUNT = 2: the same file, a wider vector).
    button_sync1: entity work.button_sync
        generic map(2)
        port map(clock, reset_s2_n, button_n, button_edge_s2);

    -- Instantiate the 100 ms timer (Appendix A.4, reusing L07's timer unchanged).
    timer1: entity work.timer
        generic map(TIMER_TICK_COUNT)
        port map(clock, reset_s2_n, timer_enable, timer_timeout);

    -- State-transition process:
    --    - On reset: reset the current state to STATE_OFF.
    --    - On rising clock edge: update the current state when a synchronized,
    --      edge-detected button press is seen.
    STATE_PROCESS: process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            state <= STATE_OFF;
        elsif (rising_edge(clock)) then
            case (state) is
                when STATE_OFF =>
                    if (to_next_state = '1') then
                        state <= STATE_BLINK;
                    elsif (to_prev_state = '1') then
                        state <= STATE_ON;
                    end if;
                when STATE_BLINK =>
                    if (to_next_state = '1') then
                        state <= STATE_ON;
                    elsif (to_prev_state = '1') then
                        state <= STATE_OFF;
                    end if;
                when STATE_ON =>
                    if (to_next_state = '1') then
                        state <= STATE_OFF;
                    elsif (to_prev_state = '1') then
                        state <= STATE_BLINK;
                    end if;
                when others =>
                    state <= STATE_OFF;
            end case;
        end if;
    end process;

    -- LED (Moore output) process, depending only on the current state:
    --    - On reset: disable the LED.
    --    - On rising clock edge, based on the current state:
    --        - STATE_OFF  : disable the LED.
    --        - STATE_BLINK: toggle the LED on every timer timeout.
    --        - STATE_ON   : enable the LED.
    LED_PROCESS: process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            led_s <= '0';
        elsif (rising_edge(clock)) then
            case (state) is
                when STATE_OFF =>
                    led_s <= '0';
                when STATE_BLINK =>
                    if (timer_timeout = '1') then
                        led_s <= not led_s;
                    end if;
                when STATE_ON =>
                    led_s <= '1';
                when others =>
                    led_s <= '0';
            end case;
        end if;
    end process;
end architecture;
