--------------------------------------------------------------------------------
-- Self-checking testbench for the uart_tx8 capstone.
--
-- Acts as the receiver: waits for the start bit on tx, then samples the line in
-- the middle of each bit period, so the checks tolerate a cycle or two of slack
-- in when your machine changes the line.
--
-- Checks the framing (start bit low, eight data bits most significant first,
-- stop bit high), the busy handshake, that a second byte can follow the first,
-- and that a send request asserted mid-frame is ignored rather than disturbing
-- the frame in flight.
--
-- BIT_TICK_COUNT is overridden with a tiny value so the simulation runs fast. One
-- timer period, and therefore one bit period, is BIT_TICK_COUNT + 1 clock cycles.
--
-- Run:  ghdl -a --std=93 reset_sync.vhd timer.vhd uart_tx8.vhd uart_tx8_tb.vhd
--       ghdl -e --std=93 uart_tx8_tb
--       ghdl -r --std=93 uart_tx8_tb --assert-level=error --stop-time=10ms
--
-- (Add your piso8.vhd to the list if you instantiated it rather than shifting
-- the byte out inline, which is the route the exercise recommends.)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity uart_tx8_tb is
end entity;

architecture behaviour of uart_tx8_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
-- One bit period is 20 clock cycles here, matching uart_rx8_tb. That slack is
-- what lets a transmitter that reaches its timer a cycle or two later than ours
-- still pass: with a bit period of only 8 cycles, sampling sits 4 cycles from
-- either neighbour and an otherwise correct design fails with "wrong byte on
-- the line", which says nothing about timing.
constant BIT_TICK_COUNT : natural := 19;
constant BIT_CYCLES     : natural := BIT_TICK_COUNT + 1;
constant HALF_BIT       : natural := BIT_CYCLES / 2;
constant IDLE_CYCLES    : natural := 4 * BIT_CYCLES;
constant BYTE1          : std_logic_vector(7 downto 0) := "10110010";
constant BYTE2          : std_logic_vector(7 downto 0) := "01001101";

signal clock, reset_n, tx, busy: std_logic := '0';
signal data_in                 : std_logic_vector(7 downto 0) := (others => '0');
signal done                    : boolean := false;

-- send is driven from two places: the stimulus process, and an interference
-- process that pulses it in the middle of a frame to check it is ignored. They
-- get a signal each so neither has to know about the other.
signal send, send_req, send_glitch: std_logic := '0';
signal glitch_armed               : boolean := false;

-- data_in is driven the same way and for the same reason: the stimulus sets the byte to send,
-- and the interference process below scribbles the complement over it part way through the
-- frame. A transmitter that latched the byte when the frame started does not notice. One that
-- indexes data_in directly puts the new bits on the wire from that point on.
signal data_req     : std_logic_vector(7 downto 0) := (others => '0');
signal data_scribble: boolean := false;
begin
    send    <= send_req or send_glitch;
    data_in <= (not data_req) when data_scribble else data_req;

    dut: entity work.uart_tx8
        generic map(BIT_TICK_COUNT)
        port map(clock, reset_n, data_in, send, tx, busy);

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

    -- Once armed, wait two bit periods into the frame and ask for another byte.
    -- A correct transmitter ignores this: it is already busy.
    GLITCH_PROCESS: process is
    begin
        wait until glitch_armed;
        for i in 1 to 2 * BIT_CYCLES loop
            wait until rising_edge(clock);
        end loop;
        send_glitch   <= '1';
        data_scribble <= true;          -- and change the byte under the transmitter's feet
        wait until rising_edge(clock);
        send_glitch <= '0';
        wait;
    end process;

    SIMULATION_PROCESS: process is

        -- Advance a whole number of clock cycles.
        procedure wait_cycles(constant n: in natural) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clock);
            end loop;
        end procedure;

        -- Ask for a byte to be sent: one-cycle send pulse alongside the data.
        procedure request(constant data: in std_logic_vector(7 downto 0)) is
        begin
            data_req <= data;
            send_req <= '1';
            wait until rising_edge(clock);
            send_req <= '0';
        end procedure;

        -- Receive one frame off tx, sampling in the middle of each bit period.
        -- tx may already be low by the time this is called, so check before
        -- waiting for the edge - waiting unconditionally would skip a whole bit.
        procedure receive(variable data: out std_logic_vector(7 downto 0)) is
        begin
            if (tx /= '0') then
                -- Bounded on purpose. An unbounded wait here would block forever on a
                -- transmitter that never pulls the line low, and GHDL exits 0 when
                -- --stop-time cuts a run short, so you would get neither a failure nor
                -- the pass line: silence that reads like success.
                wait until tx = '0' for 4 * BIT_CYCLES * CLOCK_PERIOD_NS;
                assert tx = '0'
                    report "uart_tx8: no start bit appeared within four bit periods of the "
                         & "send request - the line never left idle!"
                    severity failure;
            end if;
            wait until rising_edge(clock);
            wait_cycles(HALF_BIT);          -- now mid start bit
            wait for SYNC_UPDATE_NS;
            assert tx = '0'
                report "uart_tx8: start bit must be low for a full bit period!"
                severity failure;
            for i in 7 downto 0 loop        -- data bits, most significant first
                wait_cycles(BIT_CYCLES);
                wait for SYNC_UPDATE_NS;
                data(i) := tx;
            end loop;
            wait_cycles(BIT_CYCLES);        -- stop bit
            wait for SYNC_UPDATE_NS;
            assert tx = '1'
                report "uart_tx8: stop bit must be high!"
                severity failure;
        end procedure;

    variable got: std_logic_vector(7 downto 0);
    begin
        -- Case 1: reset with nothing requested.
        -- Expect an idle line (tx high) and busy low.
        reset_n <= '0';
        wait_cycles(4);
        wait for SYNC_UPDATE_NS;
        assert tx = '1'
            report "uart_tx8: the line must idle high, including during reset!"
            severity failure;
        assert busy = '0'
            report "uart_tx8: busy must be low while idle!"
            severity failure;
        reset_n <= '1';

        -- Case 2: still idle, several bit periods later.
        -- Expect nothing transmitted without a send request.
        for i in 1 to IDLE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert tx = '1'
                report "uart_tx8: transmitted something without a send request!"
                severity failure;
            assert busy = '0'
                report "uart_tx8: busy asserted without a send request!"
                severity failure;
        end loop;

        -- Case 3: send BYTE1 and read the frame back off the line.
        request(BYTE1);
        receive(got);
        assert got = BYTE1
            report "uart_tx8: wrong byte on the line for BYTE1!"
            severity failure;
        -- receive() returns in the middle of the stop bit, so the frame is not
        -- over yet. A transmitter that skips the stop bit looks identical on the
        -- line - it just goes idle, which is also high - and this is what tells
        -- the two apart.
        assert busy = '1'
            report "uart_tx8: busy must stay asserted for the whole stop bit!"
            severity failure;

        -- Case 4: once the frame is over, the line idles high and busy drops.
        -- The stop bit ends HALF_BIT cycles after receive() returns; allow a
        -- further bit period so a machine with a return-to-idle state of its own
        -- is not failed for taking a cycle or two to get there.
        wait_cycles(HALF_BIT + BIT_CYCLES);
        wait for SYNC_UPDATE_NS;
        assert tx = '1'
            report "uart_tx8: the line must return to idle after a frame!"
            severity failure;
        assert busy = '0'
            report "uart_tx8: busy must drop once the frame is complete!"
            severity failure;

        -- Case 5: send BYTE2, with two pieces of interference injected two bit periods into
        -- the frame: a second send request, and the complement of BYTE2 on data_in.
        --
        -- Expect the frame to arrive as BYTE2 regardless. The send request must be ignored,
        -- since reloading mid-frame would restart the byte and corrupt what is on the wire.
        -- The data_in change must be ignored too, for the reason the exercise gives: a
        -- producer is free to move on the moment busy goes high, so the byte has to be
        -- latched when the frame starts rather than read off data_in bit by bit. Those are
        -- two different mistakes and this case fails on either.
        glitch_armed <= true;
        request(BYTE2);
        wait for SYNC_UPDATE_NS;
        assert busy = '1'
            report "uart_tx8: busy must be asserted while a frame is in flight!"
            severity failure;
        receive(got);
        assert got = BYTE2
            report "uart_tx8: the frame was disturbed part way through - either the second "
                 & "send request was acted on, or data_in is being read bit by bit instead "
                 & "of latched when the frame starts!"
            severity failure;

        -- Case 6: nothing further is transmitted, so the ignored request really
        -- was ignored rather than queued.
        wait_cycles(HALF_BIT + BIT_CYCLES);
        for i in 1 to IDLE_CYCLES loop
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert tx = '1'
                report "uart_tx8: a send request during a frame was queued, not ignored!"
                severity failure;
            assert busy = '0'
                report "uart_tx8: busy must stay low once the line is idle again!"
                severity failure;
        end loop;

        report "uart_tx8: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
