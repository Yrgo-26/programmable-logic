--------------------------------------------------------------------------------
-- Self-checking testbench for seq_detect_mealy (detects "11" on din, Mealy).
-- y is combinational: '1' the same cycle the second '1' of a "11" pattern
-- arrives. din is driven synchronously (it is not passed through a synchronizer).
--
-- Copy in the one module this one reuses, the reset_sync.vhd you wrote in L04
-- exercise 8, and then:
--
--   cp ../../L04/exercises/reset_sync/reset_sync.vhd .
--   ghdl -a --std=93 reset_sync.vhd seq_detect_mealy.vhd seq_detect_mealy_tb.vhd
--   ghdl -e --std=93 seq_detect_mealy_tb
--   ghdl -r --std=93 seq_detect_mealy_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seq_detect_mealy_tb is
end entity;

architecture behaviour of seq_detect_mealy_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
constant DIN_SETTLE_NS  : time := CLOCK_PERIOD_NS / 5;
-- din bit stream and the expected y (y = '1' iff the previous and current bits are both '1').
constant D_SEQ: std_logic_vector(0 to 6) := "0111010";
constant Y_SEQ: std_logic_vector(0 to 6) := "0011000";

signal clock, reset_n, din, y: std_logic := '0';
signal done                  : boolean := false;
begin
    dut: entity work.seq_detect_mealy
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
            report "seq_detect_mealy: reset should hold y at '0'!"
            severity failure;

        reset_n <= '1';
        for i in 1 to SETTLE_CYCLES loop   -- let reset_s2_n release; state settles to STATE_IDLE
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
        end loop;

        -- Case 2: reset released, then drive din = "0111010" one bit per cycle.
        -- Expect y = "0011000" (y = '1' whenever the current and previous bits are both '1').
        for k in D_SEQ'range loop
            din <= D_SEQ(k);
            wait for DIN_SETTLE_NS;         -- din settles; y responds combinationally
            assert y = Y_SEQ(k)
                report "seq_detect_mealy: wrong y at bit " & integer'image(k) & "!"
                severity failure;
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;        -- state advances on this edge
        end loop;

        report "seq_detect_mealy: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
