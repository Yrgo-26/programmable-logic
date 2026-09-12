--------------------------------------------------------------------------------
-- Self-checking testbench for the serial_rx8 module.
-- Feeds two bytes in MSB-first, one bit per enabled clock edge, and checks that
-- data_ready pulses for exactly one cycle as the eighth bit lands.
--
-- reset_s2_n is driven directly here because a testbench's reset is already
-- synchronous to the clock it generates. In a real design it comes from a
-- reset_sync; see A.5 and the board wrapper in A.7.
--
-- Run:  ghdl -a --std=93 serial_rx8.vhd serial_rx8_tb.vhd
--       ghdl -e --std=93 serial_rx8_tb
--       ghdl -r --std=93 serial_rx8_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity serial_rx8_tb is
end entity;

architecture behaviour of serial_rx8_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant IDLE_CYCLES    : natural := 5;
constant BYTE1          : std_logic_vector(7 downto 0) := "10110010";
constant BYTE2          : std_logic_vector(7 downto 0) := "01001101";

signal clock, reset_s2_n, shift_enable, serial_in, data_ready: std_logic := '0';
signal data_out                                              : std_logic_vector(7 downto 0);
signal done                                                  : boolean := false;
begin
    dut: entity work.serial_rx8
        port map(clock, reset_s2_n, shift_enable, serial_in, data_out, data_ready);

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
    begin
        -- Case 1: reset_s2_n = '0' (system reset).
        -- Expect data_ready = '0' (cleared by reset).
        reset_s2_n   <= '0';
        shift_enable <= '0';
        serial_in    <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert data_ready = '0'
            report "serial_rx8: reset should clear data_ready!"
            severity failure;
        assert data_out = (data_out'range => '0')
            report "serial_rx8: reset should clear the shift register too, not just "
                 & "data_ready!"
            severity failure;

        -- Case 2: shift BYTE1 in, most significant bit first.
        -- Expect data_ready = '0' for the first seven bits, then '1' as the eighth lands,
        -- with the complete byte on data_out in that same cycle.
        reset_s2_n   <= '1';
        shift_enable <= '1';
        for i in 7 downto 0 loop
            serial_in <= BYTE1(i);
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if (i > 0) then
                assert data_ready = '0'
                    report "serial_rx8: data_ready fired before eight bits arrived!"
                    severity failure;
            else
                assert data_ready = '1'
                    report "serial_rx8: data_ready should pulse as the eighth bit lands!"
                    severity failure;
                assert data_out = BYTE1
                    report "serial_rx8: wrong byte on data_out for BYTE1!"
                    severity failure;
            end if;
        end loop;

        -- Case 3: shift_enable = '0' (no incoming bits).
        -- Expect data_ready = '0' (the pulse is a single cycle wide) and data_out held.
        shift_enable <= '0';
        for i in 1 to IDLE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert data_ready = '0'
                report "serial_rx8: data_ready must be a single-cycle pulse!"
                severity failure;
            assert data_out = BYTE1
                report "serial_rx8: data_out must hold its value while disabled!"
                severity failure;
        end loop;

        -- Case 4: shift BYTE2 in after the pause.
        -- Expect the bit counter to have resumed from zero, so data_ready pulses again on
        -- the eighth bit and not before.
        shift_enable <= '1';
        for i in 7 downto 0 loop
            serial_in <= BYTE2(i);
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if (i > 0) then
                assert data_ready = '0'
                    report "serial_rx8: data_ready fired early on the second byte!"
                    severity failure;
            else
                assert data_ready = '1'
                    report "serial_rx8: data_ready should pulse once per received byte!"
                    severity failure;
                assert data_out = BYTE2
                    report "serial_rx8: wrong byte on data_out for BYTE2!"
                    severity failure;
            end if;
        end loop;

        -- Case 5: reset_s2_n = '0' with a byte in the register.
        -- Expect it cleared, and cleared asynchronously: this check does not wait for a
        -- clock edge, so a synchronous reset fails it.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert data_out = (data_out'range => '0') and data_ready = '0'
            report "serial_rx8: reset should clear the register without waiting for a "
                 & "clock edge!"
            severity failure;

        report "serial_rx8: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
