--------------------------------------------------------------------------------
-- Mealy FSM detecting two consecutive '1's on serial input din (overlapping
-- matches allowed, e.g. "111" reports two). y is combinational in (state, din),
-- so it asserts the same cycle the second '1' arrives - one cycle earlier than
-- the Moore equivalent. See Appendix A.5.
--
-- Inputs:
--    - clock: 50 MHz system clock.
--    - reset_n: Active-low asynchronous reset, from a push button.
--    - din: Synchronous serial data (already clocked by clock, so it is NOT run
--      through a synchronizer - doing so would shift the sequence being detected).
--
-- Outputs:
--    - y: Asserted during the cycle the second '1' of a "11" is seen on din.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seq_detect_mealy is
    port(clock, reset_n: in std_logic;
         din           : in std_logic;
         y             : out std_logic);
end entity;

architecture behaviour of seq_detect_mealy is
-- Enumeration of states. Only two are needed: this is the state count the
-- Mealy design saves relative to the three-state Moore equivalent.
type state_t is (STATE_IDLE, STATE_ONE);

-- Synchronized reset signal after two-flip-flop metastability protection.
signal reset_s2_n: std_logic;

-- Current state.
signal state: state_t;
begin
    -- Instantiate reset_sync (Appendix A.5 / L04) to synchronize reset_n. This
    -- example has no push button of its own, so the button synchronizer is
    -- simply not instantiated.
    reset_sync1: entity work.reset_sync
        port map(clock, reset_n, reset_s2_n);

    -- State-transition process:
    --    - On reset: reset the current state to STATE_IDLE.
    --    - On rising clock edge: move to STATE_ONE whenever din = '1', back to
    --      STATE_IDLE whenever din = '0'. Note this process only ever reads din
    --      to decide the *next* state; it never assigns y.
    STATE_PROCESS: process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            state <= STATE_IDLE;
        elsif (rising_edge(clock)) then
            case (state) is
                when STATE_IDLE =>
                    if (din = '1') then
                        state <= STATE_ONE;
                    else
                        state <= STATE_IDLE;
                    end if;
                when STATE_ONE =>
                    if (din = '1') then
                        state <= STATE_ONE;
                    else
                        state <= STATE_IDLE;
                    end if;
                when others =>
                    state <= STATE_IDLE;
            end case;
        end if;
    end process;

    -- Mealy output: a combinational (unregistered) function of the current
    -- state AND the current input, assigned outside any clocked process.
    -- Asserted the same cycle the second '1' arrives, one cycle earlier than
    -- a Moore machine could report the same event.
    y <= '1' when (state = STATE_ONE and din = '1') else '0';
end architecture;
