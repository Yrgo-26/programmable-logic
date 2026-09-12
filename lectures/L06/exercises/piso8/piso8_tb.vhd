--------------------------------------------------------------------------------
-- Self-checking testbench for piso8 (parallel-in / serial-out).
-- Convention checked here (Appendix A.4): serial_out is bit 7; a shift moves
-- every bit one position toward the MSB, feeding serial_in in at bit 0, so a
-- loaded byte leaves most-significant bit first.
--
-- Write your own piso8.vhd in THIS directory, then run:
--   ghdl -a --std=93 piso8.vhd piso8_tb.vhd
--   ghdl -e --std=93 piso8_tb
--   ghdl -r --std=93 piso8_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity piso8_tb is
end entity;

architecture behaviour of piso8_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;

-- A second byte, for the load-priority check in Case 6. Its top bit is '0', which is what
-- makes that check bite: by then the register holds all ones, so loading shows '0' on
-- serial_out and shifting shows '1'.
constant RELOAD_BYTE    : std_logic_vector(7 downto 0) := "01010101";

signal clock, reset_s2_n, load, shift, serial_in, serial_out: std_logic := '0';
signal parallel_in: std_logic_vector(7 downto 0) := "10110010";
signal done       : boolean := false;
begin
    dut: entity work.piso8
        port map(clock, reset_s2_n, load, shift, serial_in, parallel_in, serial_out);

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
        -- Expect serial_out = '0' (register cleared).
        reset_s2_n <= '0';
        load       <= '0';
        shift      <= '0';
        serial_in  <= '0';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        assert serial_out = '0'
            report "piso8: reset should clear the register!"
            severity failure;

        -- Case 2: load = '1' (load parallel_in).
        -- Expect serial_out = parallel_in(7), the MSB, after the load.
        reset_s2_n <= '1';
        load       <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        load <= '0';
        assert serial_out = parallel_in(parallel_in'high)
            report "piso8: serial_out should be bit 7 after load!"
            severity failure;

        -- Case 3: shift = '1' (serial_in = '0' fills in at bit 0).
        -- Expect serial_out to present parallel_in(7-k) at shift k, i.e. the
        -- loaded byte leaving most-significant bit first.
        shift <= '1';
        for k in 1 to parallel_in'high loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert serial_out = parallel_in(parallel_in'high - k)
                report "piso8: wrong serial_out at shift " & integer'image(k) & "!"
                severity failure;
        end loop;

        -- Case 4: load again, then shift = '0' (hold).
        -- Expect serial_out to stay on the freshly loaded bit 7, and a '1' on serial_in not
        -- to creep in while the register is holding. Reloading first is what makes this
        -- check bite: a register that shifts on every clock regardless of shift moves off
        -- bit 7 immediately, and is caught on the very next edge.
        shift <= '0';
        load  <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        load      <= '0';
        serial_in <= '1';
        for k in 1 to 2 loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert serial_out = parallel_in(parallel_in'high)
                report "piso8: serial_out should hold while shift is low!"
                severity failure;
        end loop;

        -- Case 5: shift the loaded byte back out, with serial_in held at '1' throughout.
        -- For the first seven shifts serial_out is still presenting the loaded byte. The
        -- eighth is the interesting one: serial_in enters at bit 0, so it takes exactly
        -- eight shifts for the first '1' to travel up to serial_out at bit 7. A register
        -- that ignores serial_in, or that fills with a hard-wired '0' instead, never gets
        -- there at all.
        shift <= '1';
        for k in 1 to (parallel_in'high + 1) loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            if k <= parallel_in'high then
                assert serial_out = parallel_in(parallel_in'high - k)
                    report "piso8: wrong serial_out at shift " & integer'image(k)
                         & " of the reloaded byte!"
                    severity failure;
            else
                assert serial_out = '1'
                    report "piso8: serial_in should reach bit 7 after eight shifts!"
                    severity failure;
            end if;
        end loop;

        -- Case 6: load = '1' and shift = '1' on the same edge.
        -- Expect the load to win, so serial_out becomes RELOAD_BYTE(7).
        --
        -- The exercise states that load takes priority. Writing the two tests the other way
        -- round, "if shift ... elsif load ...", is the natural mistake and is invisible until
        -- both arrive together, which in a real design is precisely when a producer is keeping
        -- the register fed. Case 5 left the register holding all ones, so a design that shifted
        -- instead of loading leaves serial_out at '1' and is caught here.
        parallel_in <= RELOAD_BYTE;
        load        <= '1';
        shift       <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        load  <= '0';
        shift <= '0';
        assert serial_out = RELOAD_BYTE(RELOAD_BYTE'high)
            report "piso8: load must take priority when load and shift are both high - "
                 & "test load first and shift in the elsif, not the other way round!"
            severity failure;

        -- One shift on, to confirm the whole byte arrived and not merely a correct top bit,
        -- and to put a '1' back on serial_out so the reset below has something to clear.
        shift <= '1';
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        shift <= '0';
        assert serial_out = RELOAD_BYTE(RELOAD_BYTE'high - 1)
            report "piso8: the priority load must load the whole of parallel_in!"
            severity failure;

        -- Case 7: reset_s2_n = '0' with serial_out currently high.
        -- Expect it cleared, and cleared asynchronously: this check does not wait for a
        -- clock edge, so a synchronous reset fails it.
        reset_s2_n <= '0';
        wait for SYNC_UPDATE_NS;
        assert serial_out = '0'
            report "piso8: reset should clear the register without waiting for a clock edge!"
            severity failure;

        report "piso8: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
