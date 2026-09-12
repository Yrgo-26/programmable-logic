--------------------------------------------------------------------------------
-- Self-checking testbench for button_sync.
--
-- Instantiates the module twice, once with COUNT = 1 and once with COUNT = 2, so
-- the generic is exercised at more than its default and the two-button case can
-- be checked for cross-talk: pressing one button must pulse its own bit and
-- nobody else's.
--
-- Checks that a press produces exactly one single-cycle pulse, two rising edges
-- after the button changes (two synchronizer flip-flops, plus a third the edge
-- detector compares against), that holding the button produces no further
-- pulses, that a release produces none at all, and that a button already held
-- down when reset is released does pulse, which is the case the all-ones reset
-- exists for.
--
-- Write your own button_sync.vhd in THIS directory, then run:
--   ghdl -a --std=93 button_sync.vhd button_sync_tb.vhd
--   ghdl -e --std=93 button_sync_tb
--   ghdl -r --std=93 button_sync_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity button_sync_tb is
end entity;

architecture behaviour of button_sync_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
-- Rising edges between a button changing and its pulse appearing.
constant SYNC_LATENCY: natural := 2;

signal clock, reset_s2_n: std_logic := '0';

-- COUNT = 1. Active low, so all-ones is "nothing pressed".
signal button1_n      : std_logic_vector(0 downto 0) := (others => '1');
signal button1_edge_s2: std_logic_vector(0 downto 0);

-- COUNT = 2.
signal button2_n      : std_logic_vector(1 downto 0) := (others => '1');
signal button2_edge_s2: std_logic_vector(1 downto 0);

signal done: boolean := false;
begin
    dut1: entity work.button_sync
        generic map(1)
        port map(clock, reset_s2_n, button1_n, button1_edge_s2);

    dut2: entity work.button_sync
        generic map(2)
        port map(clock, reset_s2_n, button2_n, button2_edge_s2);

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
        -- Step one clock and settle, so every check reads the value the flip-flops just took.
        procedure step is
        begin
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end procedure;
    begin
        -- Case 1: reset_s2_n = '0' (system reset).
        -- Expect no pulses on either instance: the synchronizer stages reset to "not
        -- pressed", so coming out of reset must not look like a press.
        reset_s2_n <= '0';
        for i in 1 to 4 loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: reset should leave button_edge_s2 low!"
                severity failure;
        end loop;
        reset_s2_n <= '1';
        for i in 1 to 4 loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: leaving reset should not look like a press!"
                severity failure;
        end loop;

        -- Case 2: a button already held down when reset is released.
        -- Expect no pulse while reset is held, then exactly one once it is released: the
        -- stages reset to "not pressed", so a button that is already down looks like a press
        -- arriving the moment the design leaves reset. This is the case that separates the
        -- required (others => '1') reset from an (others => '0') one, which would come out of
        -- reset already believing the button was down and would never pulse at all.
        reset_s2_n <= '0';
        button1_n  <= "0";
        button2_n  <= "10";
        for i in 1 to 4 loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: no pulse should escape while reset is held!"
                severity failure;
        end loop;
        reset_s2_n <= '1';
        for i in 1 to (SYNC_LATENCY - 1) loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: pulsed after only " & integer'image(i)
                     & " clock edge(s) out of reset!"
                severity failure;
        end loop;
        step;
        assert button1_edge_s2 = "1" and button2_edge_s2 = "01"
            report "button_sync: a button held through reset should pulse once reset is "
                 & "released; stages that reset to '0' instead of '1' never will!"
            severity failure;

        -- Release both again and settle, so the next case starts from idle.
        button1_n <= "1";
        button2_n <= "11";
        for i in 1 to 6 loop
            step;
        end loop;

        -- Case 3: press button 0 on both instances (falling edge, active low).
        -- Expect exactly one pulse, on the second rising edge after the change.
        button1_n <= "0";
        button2_n <= "10";
        for i in 1 to (SYNC_LATENCY - 1) loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: pulsed after only " & integer'image(i)
                     & " clock edge(s)!"
                severity failure;
        end loop;
        step;
        assert button1_edge_s2 = "1"
            report "button_sync: a press should pulse the one-button instance!"
            severity failure;
        -- The two-button instance must pulse bit 0 and leave bit 1 alone.
        assert button2_edge_s2 = "01"
            report "button_sync: pressing button 0 should pulse bit 0 only!"
            severity failure;

        -- Case 4: the button is still held.
        -- Expect the pulse to have lasted exactly one cycle, and no further pulses.
        for i in 1 to 6 loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: a held button should pulse only once!"
                severity failure;
        end loop;

        -- Case 5: release both buttons (rising edge).
        -- Expect no pulse: only a press is an event.
        button1_n <= "1";
        button2_n <= "11";
        for i in 1 to 6 loop
            step;
            assert button1_edge_s2 = "0" and button2_edge_s2 = "00"
                report "button_sync: releasing a button should not pulse!"
                severity failure;
        end loop;

        -- Case 6: press button 1 of the two-button instance only.
        -- Expect a pulse on bit 1 and nothing on bit 0, which is the check that the two
        -- buttons really are independent rather than sharing a synchronizer chain.
        button2_n <= "01";
        for i in 1 to (SYNC_LATENCY - 1) loop
            step;
            assert button2_edge_s2 = "00"
                report "button_sync: pulsed after only " & integer'image(i)
                     & " clock edge(s)!"
                severity failure;
        end loop;
        step;
        assert button2_edge_s2 = "10"
            report "button_sync: pressing button 1 should pulse bit 1 only!"
            severity failure;
        assert button1_edge_s2 = "0"
            report "button_sync: the one-button instance should be untouched!"
            severity failure;

        -- Case 7: both buttons pressed on the same edge.
        -- Expect both bits to pulse together.
        button2_n <= "11";
        for i in 1 to 6 loop
            step;
        end loop;
        button2_n <= "00";
        for i in 1 to (SYNC_LATENCY - 1) loop
            step;
        end loop;
        step;
        assert button2_edge_s2 = "11"
            report "button_sync: two buttons pressed together should both pulse!"
            severity failure;

        report "button_sync: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
