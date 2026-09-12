--------------------------------------------------------------------------------
-- System testbench for can_controller. Run it against your own
-- can_controller.vhd. Two nodes share one open-drain (wired-AND) bus, exactly
-- as they would on a real CAN bus.
--
-- Run, from controller/:
--       ghdl -a --std=93 can_def.vhd meta_prev.vhd bit_timer.vhd crc15.vhd \
--            tx_shift_reg.vhd rx_shift_reg.vhd can_controller.vhd \
--            can_controller_tb.vhd
--       ghdl -e --std=93 can_controller_tb
--       ghdl -r --std=93 can_controller_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.can_def.all;

entity can_controller_tb is
end entity;

architecture behaviour of can_controller_tb is
constant CLOCK_PERIOD_NS  : time := 20 ns;
constant CLOCK_EVENT_NS   : time := CLOCK_PERIOD_NS / 2;
constant RESP_TIMEOUT_US  : time := 300 us;
constant RESET_CYCLES     : natural := 5;
-- Clock cycles both nodes are left alone between cases. One CAN bit period is
-- TICKS_PER_BIT cycles, and STATE_IDLE needs eleven consecutive recessive ones before
-- either node will start a frame, so this has to be comfortably more than 11 * 50.
constant SETTLE_CYCLES    : natural := 1000;
constant RESET_SYNC_CYCLES: natural := 4;   -- Edges for meta_prev to pass reset_n through.

signal clock, reset_n, bus_line          : std_logic := '0';
signal a_tx_done_latched, b_rx_valid_latched: std_logic := '0';
signal b_tx_done_latched                    : std_logic := '0';
signal done                                 : boolean   := false;

-- Node A.
signal a_tx_req, a_tx_done : std_logic := '0';
signal a_rx_valid, a_error : std_logic := '0';
signal a_tx_id, a_rx_id    : id_t      := (others => '0');
signal a_tx_dlc, a_rx_dlc  : dlc_t     := (others => '0');
signal a_tx_data, a_rx_data: data_t    := (others => '0');
signal a_tx_bus, a_bus_en  : std_logic := '0';

-- Node B.
signal b_tx_req, b_tx_done : std_logic := '0';
signal b_rx_valid, b_error : std_logic := '0';
signal b_tx_id, b_rx_id    : id_t      := (others => '0');
signal b_tx_dlc, b_rx_dlc  : dlc_t     := (others => '0');
signal b_tx_data, b_rx_data: data_t    := (others => '0');
signal b_tx_bus, b_bus_en  : std_logic := '0';

begin
    -- Shared open-drain bus: any node pulling it low wins. Each node's effective
    -- output is its driven value when bus_en = '1', else released ('1').
    bus_line <= (a_tx_bus or not a_bus_en) and (b_tx_bus or not b_bus_en);

    -- Ports are bound positionally, in the order L11 settles: every input, then every output.
    node_a: entity work.can_controller
        port map(clock, reset_n, a_tx_req, a_tx_id, a_tx_dlc, a_tx_data,
            bus_line, a_tx_done, a_tx_bus, a_bus_en, a_rx_id, a_rx_dlc,
            a_rx_data, a_rx_valid, a_error);

    node_b: entity work.can_controller
        port map(clock, reset_n, b_tx_req, b_tx_id, b_tx_dlc, b_tx_data,
            bus_line, b_tx_done, b_tx_bus, b_bus_en, b_rx_id, b_rx_dlc,
            b_rx_data, b_rx_valid, b_error);

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

    -- Latch the single-cycle tx_done / rx_valid pulses: driven by independent
    -- state machines, they need not land on the same edge, and a plain
    -- "wait until (a = '1' or b = '1')" would resume on the first and could
    -- miss a still-pending second pulse entirely.
    LATCH_PROCESS: process(clock, reset_n) is
    begin
        if (reset_n = '0') then
            a_tx_done_latched  <= '0';
            b_rx_valid_latched <= '0';
            b_tx_done_latched  <= '0';
        elsif (rising_edge(clock)) then
            if (a_tx_done = '1') then
                a_tx_done_latched <= '1';
            end if;
            if (b_rx_valid = '1') then
                b_rx_valid_latched <= '1';
            end if;
            -- Node B only ever transmits in case 2, where it loses arbitration,
            -- so this latch is entirely about the abort path.
            if (b_tx_done = '1') then
                b_tx_done_latched <= '1';
            end if;
        end if;
    end process;

    SIMULATION_PROCESS: process is
    begin
        reset_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_n <= '1';

        -- can_controller takes reset_n *raw* and synchronizes it internally with
        -- meta_prev (L12), so the release needs two further clock edges to reach
        -- the state machine. Wait them out: tx_req below is a single-cycle pulse
        -- that is dropped, not queued, so a pulse landing while the node is still
        -- held in reset would simply be lost and no frame would ever start.
        for i in 1 to RESET_SYNC_CYCLES loop
            wait until rising_edge(clock);
        end loop;

        -- Case 1: node A sends a 5-byte frame (ID 0x123, data 11 22 F8 44 55)
        -- while node B receives. 0xF8 forces a stuff bit inside the data field,
        -- so the CRC must skip it on both sides. Expect A's tx_done and B's
        -- rx_valid to pulse, B's whole frame to match what A sent - every data
        -- byte at its fixed position, unused low bytes zero - and no errors.
        a_tx_id   <= "00100100011";       -- 0x123.
        a_tx_dlc  <= "0101";              -- 5 data bytes.
        a_tx_data <= x"1122F84455000000"; -- bytes 0..4 = 11 22 F8 44 55.
        a_tx_req  <= '1';
        wait until rising_edge(clock);
        a_tx_req  <= '0';

        wait until (a_tx_done_latched = '1' and b_rx_valid_latched = '1') for RESP_TIMEOUT_US;

        assert a_error = '0'
            report "can_controller: case 1: node A (transmitter) raised error!"
            severity error;
        assert b_error = '0'
            report "can_controller: case 1: node B (receiver) raised error!"
            severity error;
        assert a_tx_done_latched = '1'
            report "can_controller: case 1: node A's tx_done did not pulse!"
            severity error;
        assert b_rx_valid_latched = '1'
            report "can_controller: case 1: node B's rx_valid did not pulse!"
            severity error;
        assert b_rx_id = a_tx_id
            report "can_controller: case 1: node B received the wrong ID!"
            severity error;
        assert b_rx_dlc = a_tx_dlc
            report "can_controller: case 1: node B received the wrong DLC!"
            severity error;
        assert b_rx_data = a_tx_data
            report "can_controller: case 1: node B reconstructed the data bytes wrong "
                   & "(fixed-position placement or destuffing failed)!"
            severity error;

        -- Let both nodes settle back to idle before case 2.
        wait for CLOCK_PERIOD_NS * SETTLE_CYCLES;

        -- Case 2: node A (ID 0x000, all dominant, the highest priority a
        -- standard frame can have) and node B (ID 0x001, differing only in the
        -- last identifier bit) both request transmission on the same cycle.
        -- Expect node B to detect the arbitration loss on that last bit, raise
        -- error and stop driving, while node A completes normally, unaware a
        -- contest took place. B's error must still be readable afterwards.
        a_tx_id  <= "00000000000"; -- 0x000.
        a_tx_dlc <= "0000";
        b_tx_id  <= "00000000001"; -- 0x001.
        b_tx_dlc <= "0000";
        a_tx_req <= '1';
        b_tx_req <= '1';
        wait until rising_edge(clock);
        a_tx_req <= '0';
        b_tx_req <= '0';

        wait until (a_tx_done = '1') for RESP_TIMEOUT_US;
        assert a_tx_done = '1'
            report "can_controller: case 2: node A (winner) never completed!"
            severity error;
        assert a_error = '0'
            report "can_controller: case 2: node A (winner) must not see an error!"
            severity error;
        assert b_error = '1'
            report "can_controller: case 2: node B (loser) must detect arbitration loss, "
                   & "and must still be reporting it once the winner's frame ends!"
            severity error;

        -- The loser must also report that its transmit attempt is over. tx_done means
        -- "the port is yours again", not "the frame was sent"; error is what says which.
        -- Without this pulse a caller waiting for tx_done before re-requesting waits
        -- forever, and register_bank's TX-ready bit never returns, so one lost
        -- arbitration leaves the node unable to transmit until it is reset (L17).
        assert b_tx_done_latched = '1'
            report "can_controller: case 2: node B (loser) never pulsed tx_done, so nothing "
                   & "ever tells a caller the transmit attempt ended!"
            severity error;

        report "can_controller: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
