--------------------------------------------------------------------------------
-- Self-checking testbench for seq_detect_101_mealy.
--
-- A Mealy detector for the sequence "1, 0, 1", NON-OVERLAPPING (after a full
-- match it starts a fresh search). y is a combinational function of the state
-- AND din, asserted during the same cycle the final '1' arrives.
--
-- Copy in the reset synchronizer this design reuses, the reset_sync.vhd you
-- wrote in L04 exercise 8. Then write your own seq_detect_101_mealy.vhd here:
--   cp ../../../L04/exercises/reset_sync/reset_sync.vhd .
--   ghdl -a --std=93 reset_sync.vhd seq_detect_101_mealy.vhd seq_detect_101_mealy_tb.vhd
--   ghdl -e --std=93 seq_detect_101_mealy_tb
--   ghdl -r --std=93 seq_detect_101_mealy_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seq_detect_101_mealy_tb is
end entity;

architecture behaviour of seq_detect_101_mealy_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant DIN_SETTLE_NS  : time := CLOCK_PERIOD_NS / 5;
-- din bit stream and expected y. Between them the bits exercise every state on every input:
--   "1101"  a leading extra '1' (staying put on a second '1'), then a match.
--   "0101"  a second match, and non-overlap: the '1' ending a match is not reused.
--   "1001"  the one that is easy to miss. After "1,0" a second '0' must send the machine
--           back to the start. A machine that stays put instead reports a match on the
--           following '1', and nothing else in this stream would notice.
--   "101"   a final match, confirming the machine still works after that reset to the start.
constant D_SEQ: std_logic_vector(0 to 14) := "110101011001101";
constant Y_SEQ: std_logic_vector(0 to 14) := "000100010000001";

-- One complete match, used twice in case 3: driven while reset is held (y must stay
-- low throughout) and again after release (y must pulse on the final '1').
constant MATCH_D: std_logic_vector(0 to 2) := "101";
constant MATCH_Y: std_logic_vector(0 to 2) := "001";

signal clock, reset_n, din, y: std_logic := '0';
signal done                  : boolean := false;
begin
    dut: entity work.seq_detect_101_mealy
        port map(clock, reset_n, din, y);

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
    constant RESET_CYCLES : natural := 4;
    constant SETTLE_CYCLES: natural := 4;
    begin
        -- Case 1: reset_n = '0', din = '0' (system reset).
        -- Expect y = '0' (held low during reset).
        reset_n <= '0';
        din     <= '0';
        for i in 1 to RESET_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;
        assert y = '0'
            report "seq_detect_101_mealy: reset should hold y at '0'!"
            severity failure;

        reset_n <= '1';
        for i in 1 to SETTLE_CYCLES loop   -- let reset_s2_n release; state settles to idle
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Case 2: drive D_SEQ one bit per cycle, the stream described above.
        -- Expect Y_SEQ: y = '1' the cycle each non-overlapping "101" completes.
        for k in D_SEQ'range loop
            din <= D_SEQ(k);
            wait for DIN_SETTLE_NS;         -- din settles; the Mealy y responds combinationally
            assert y = Y_SEQ(k)
                report "seq_detect_101_mealy: wrong y at bit " & integer'image(k) & "!"
                severity failure;
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;        -- state advances on this edge
        end loop;

        -- Case 3: reset must override the input stream, not merely coexist with it.
        -- Case 1 asserts reset with din = '0', which is vacuous for a Mealy machine:
        -- y = '1' requires din = '1', so a design that ignores reset_n entirely passes
        -- it. Here two complete "1, 0, 1" sequences are driven while reset is held, and
        -- y must stay low through every one of them.
        reset_n <= '0';
        din     <= '0';
        for i in 1 to RESET_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        for repetition in 1 to 2 loop
            for k in MATCH_D'range loop
                din <= MATCH_D(k);
                wait for DIN_SETTLE_NS;
                assert y = '0'
                    report "seq_detect_101_mealy: y went high while reset_n was low!"
                    severity failure;
                wait until rising_edge(clock);
                wait for SYNC_UPDATE_NS;
                assert y = '0'
                    report "seq_detect_101_mealy: y went high while reset_n was low!"
                    severity failure;
            end loop;
        end loop;

        -- Case 4: release, and confirm the machine detects again from a clean start.
        -- Reset that jams the machine permanently would pass case 3 and fail here.
        reset_n <= '1';
        din     <= '0';
        for i in 1 to SETTLE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        for k in MATCH_D'range loop
            din <= MATCH_D(k);
            wait for DIN_SETTLE_NS;
            assert y = MATCH_Y(k)
                report "seq_detect_101_mealy: wrong y at bit " & integer'image(k)
                     & " of the match after reset!"
                severity failure;
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        report "seq_detect_101_mealy: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
