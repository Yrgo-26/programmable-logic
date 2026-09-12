--------------------------------------------------------------------------------
-- Self-checking testbench for walking_led.
-- Overrides LED_COUNT (4) and TICK_COUNT (3) so the walk is short and fast.
-- Checks: reset loads a single lit bit; no shift while disabled; once the
-- button enables shifting, the lit bit rotates one position toward the MSB per tick.
--
-- Copy in the three modules this one reuses: the reset_sync.vhd and
-- button_sync.vhd you wrote in L04, and the timer.vhd you wrote in exercise 4.
-- Then write your own walking_led.vhd here and:
--
--   ghdl -a --std=93 reset_sync.vhd button_sync.vhd timer.vhd \
--                    walking_led.vhd walking_led_tb.vhd
--   ghdl -e --std=93 walking_led_tb
--   ghdl -r --std=93 walking_led_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity walking_led_tb is
end entity;

architecture behaviour of walking_led_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant LED_COUNT      : natural := 4;
constant MSB            : natural := LED_COUNT - 1;
constant TICK_COUNT     : natural := 3;
constant SYNC_STAGES    : natural := 2;
constant RESET_PATTERN  : std_logic_vector(MSB downto 0) := (0 => '1', others => '0');

signal clock, reset_n: std_logic := '0';
-- Active low, so '1' is released. Starting it at '0' would mean starting with the button held
-- down, which is not the idle state the design is written for.
signal button_n      : std_logic := '1';
signal led                     : std_logic_vector(MSB downto 0) := (others => '0');
signal done                    : boolean := false;
begin
    dut: entity work.walking_led
        generic map(LED_COUNT, TICK_COUNT)
        port map(clock, reset_n, button_n, led);

    CLOCK_PROCESS: process is
    begin
        if done then
            wait;
        end if;
        clock <= '0';
        wait for CLOCK_EVENT_NS;
        clock <= '1';
        wait for CLOCK_EVENT_NS;
    end process;

    SIMULATION_PROCESS: process is
    constant PULSES         : natural := 10;
    -- The timer allows one shift every TICK_COUNT + 1 clock edges, so the observation
    -- window below holds this many of them.
    constant EXPECTED_SHIFTS: natural := (PULSES * 6) / (TICK_COUNT + 1);
    variable prev           : std_logic_vector(MSB downto 0);
    variable shifts         : natural;
    begin
        -- Case 1: reset_n = '0', button_n = '1' (system reset).
        -- Expect a single lit bit at position 0.
        reset_n  <= '0';
        button_n <= '1';
        for i in 0 to SYNC_STAGES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = RESET_PATTERN
            report "walking_led: reset should load a single lit bit at position 0!"
            severity failure;

        -- Case 2: reset_n = '1', button_n left high (shifting stays disabled).
        -- Expect the pattern not to move.
        reset_n <= '1';
        for i in 1 to (2 * PULSES) loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led = RESET_PATTERN
            report "walking_led: should not shift while disabled!"
            severity failure;

        -- Case 3: button_n = '0' (press enables shifting).
        -- Expect led to rotate one position toward the MSB per timer tick (>= 4 shifts).
        button_n <= '0';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Every change must be a one-position rotate toward the MSB, and there must be the
        -- right NUMBER of them. The count is what ties the walk to the timer: a design that
        -- ignores the timer and shifts on every clock edge still produces a valid
        -- one-position rotate every time, so a lower bound on its own passes it, and pacing
        -- is the whole point of this lecture. The +/- 1 covers where the window happens to
        -- fall relative to the timer's phase.
        prev   := led;
        shifts := 0;
        for i in 1 to PULSES * 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if led /= prev then
                assert led = (prev(MSB - 1 downto 0) & prev(MSB))
                    report "walking_led: a shift must be a one-position rotate toward the MSB!"
                    severity failure;
                prev   := led;
                shifts := shifts + 1;
            end if;
        end loop;
        assert shifts >= EXPECTED_SHIFTS - 1 and shifts <= EXPECTED_SHIFTS + 1
            report "walking_led: expected about " & integer'image(EXPECTED_SHIFTS)
                 & " shifts in this window but saw " & integer'image(shifts)
                 & " - the walk must be paced by the timer, not by the clock!"
            severity failure;

        -- Step on until the lit bit is somewhere other than its reset position, so the reset
        -- below has something visible to undo. The walk is still running, so this takes a tick
        -- or two at most.
        for i in 1 to (TICK_COUNT + 1) * LED_COUNT loop
            exit when led /= RESET_PATTERN;
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led /= RESET_PATTERN
            report "walking_led: the walk stopped on its own part way through!"
            severity failure;

        -- Case 4: reset_n = '0' with no clock edge in between.
        -- Expect the single lit bit back at position 0 immediately. This is the only check
        -- here that distinguishes an asynchronous reset from a synchronous one, and the raw
        -- reset_n has to cross your reset_sync before it gets here, so both halves of
        -- assert-async/release-sync are on the line.
        reset_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert led = RESET_PATTERN
            report "walking_led: reset must reload the single lit bit with no clock edge - "
                 & "the reset branch belongs outside the rising_edge(clock) test!"
            severity failure;

        -- Case 5: reset released, then two presses.
        -- Expect the first to start the walk and the second to stop it. Each press toggles,
        -- so a design that merely latches shifting on passes everything above and produces a
        -- walk that cannot be stopped, which is half of what the button is for. The reset
        -- above also cleared the enable, so this starts from a known state.
        reset_n  <= '1';
        button_n <= '1';
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        button_n <= '0';                    -- first press: start
        -- The first shift lands TICK_COUNT + 5 edges after the press: two through button_sync,
        -- one to register shift_enable, TICK_COUNT + 1 for the timer's first period, and one
        -- for the shift register to act on timeout. The window has to scale with TICK_COUNT,
        -- or raising it turns a correct design into a failure here.
        for i in 1 to (PULSES + TICK_COUNT) loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert led /= RESET_PATTERN
            report "walking_led: a press after reset must start the walk again!"
            severity failure;

        button_n <= '1';                    -- release, so the next press is a fresh edge
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        button_n <= '0';                    -- second press: stop
        for i in 1 to PULSES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        prev := led;
        for i in 1 to PULSES * 6 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert led = prev
                report "walking_led: a second press must stop the walk - toggle shifting on "
                     & "each button pulse rather than latching it on!"
                severity failure;
        end loop;

        report "walking_led: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
