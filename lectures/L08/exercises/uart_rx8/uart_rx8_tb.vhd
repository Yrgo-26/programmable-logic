--------------------------------------------------------------------------------
-- Self-checking testbench for the uart_rx8 capstone.
--
-- Acts as the transmitter: idles the line high, then sends framed bytes as a
-- start bit (low), eight data bits most significant first, and a stop bit
-- (high), holding each bit for one full bit period.
--
-- Monitor processes watch byte_valid and frame_err independently of the
-- transmitter, so the checks do not depend on exactly when in the frame your
-- receiver reports either. They count the pulses and fail if one ever lasts
-- longer than a single clock cycle.
--
-- OVERSAMPLE_TICK_COUNT is overridden with a tiny value so the simulation runs fast.
-- One timer period is OVERSAMPLE_TICK_COUNT + 1 clock cycles (a sixteenth of a bit),
-- so one bit period is 16 * (OVERSAMPLE_TICK_COUNT + 1) clock cycles.
--
-- Run:  ghdl -a --std=93 sync.vhd reset_sync.vhd timer.vhd \
--                        uart_rx8.vhd uart_rx8_tb.vhd
--       ghdl -e --std=93 uart_rx8_tb
--       ghdl -r --std=93 uart_rx8_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity uart_rx8_tb is
end entity;

architecture behaviour of uart_rx8_tb is
constant CLOCK_PERIOD_NS: time := 10 ns;
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := CLOCK_PERIOD_NS / 10;
-- Small enough to keep the simulation quick, but not so small that the timing is tight. One
-- oversample tick is three clock cycles here, so a receiver that registers the start edge a
-- cycle or two later than ours is still well inside the tick it means to be in. Shrink this
-- to one and a design that is otherwise correct starts failing on rounding rather than on
-- anything it got wrong.
constant OVERSAMPLE_TICK_COUNT : natural := 2;
constant TICK_CYCLES           : natural := OVERSAMPLE_TICK_COUNT + 1;
constant BIT_CYCLES            : natural := 16 * TICK_CYCLES;
constant IDLE_CYCLES           : natural := 12 * BIT_CYCLES;
constant BREAK_CYCLES          : natural := 12 * BIT_CYCLES;
constant BYTE1                 : std_logic_vector(7 downto 0) := "10110010";
constant BYTE2                 : std_logic_vector(7 downto 0) := "01001101";

signal clock, reset_n, rx            : std_logic := '0';
signal byte_valid, frame_err         : std_logic;
signal data_out                      : std_logic_vector(7 downto 0) := (others => '0');
signal done                          : boolean := false;
signal valid_count, error_count      : natural := 0;
signal last_byte                     : std_logic_vector(7 downto 0) := (others => '0');
begin
    dut: entity work.uart_rx8
        generic map(OVERSAMPLE_TICK_COUNT)
        port map(clock, reset_n, rx, data_out, byte_valid, frame_err);

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

    -- Capture every byte the receiver hands over, and every framing error it reports, whenever
    -- they happen, and check that neither strobe is ever asserted for two cycles in a row.
    MONITOR_PROCESS: process is
    variable was_valid, was_error: boolean := false;
    begin
        wait until rising_edge(clock);
        wait for SYNC_UPDATE_NS;
        if (byte_valid = '1') then
            assert not was_valid
                report "uart_rx8: byte_valid must be a single-cycle pulse!"
                severity failure;
            valid_count <= valid_count + 1;
            last_byte   <= data_out;
            was_valid   := true;
        else
            was_valid := false;
        end if;
        if (frame_err = '1') then
            assert not was_error
                report "uart_rx8: frame_err must be a single-cycle pulse!"
                severity failure;
            error_count <= error_count + 1;
            was_error   := true;
        else
            was_error := false;
        end if;
    end process;

    SIMULATION_PROCESS: process is
        -- Hold the line at a given level for one full bit period.
        procedure send_bit(constant level: in std_logic) is
        begin
            rx <= level;
            for i in 1 to BIT_CYCLES loop
                wait until rising_edge(clock);
            end loop;
        end procedure;

        -- One bit period carrying the value being sent only in its middle, and the opposite
        -- level for the first three and the last two of the sixteen oversample ticks.
        --
        -- This is what a transmitter and receiver disagreeing about where a bit begins looks
        -- like from the receiver's side, in the extreme. Sampling near tick 8 reads the bit;
        -- sampling near a boundary reads the neighbouring bit, and the byte is wrong. The
        -- clean window is ticks 3 to 13, wide enough that a receiver whose sample lands a few
        -- ticks late - which every real one does, since noticing the edge, comparing the
        -- counter and restarting it each cost a tick - still reads settled line.
        procedure send_bit_noisy(constant level: in std_logic) is
        begin
            rx <= not level;
            for i in 1 to 3 * TICK_CYCLES loop
                wait until rising_edge(clock);
            end loop;
            rx <= level;
            for i in 1 to 11 * TICK_CYCLES loop
                wait until rising_edge(clock);
            end loop;
            rx <= not level;
            for i in 1 to 2 * TICK_CYCLES loop
                wait until rising_edge(clock);
            end loop;
        end procedure;

        -- Send one frame: start bit, eight data bits (MSB first), and a stop bit of the given
        -- level. A stop bit of '0' is a framing error and must not produce a byte.
        procedure send_frame(constant data : in std_logic_vector(7 downto 0);
                             constant stop : in std_logic;
                             constant dirty: in boolean) is
        begin
            send_bit('0');
            for i in 7 downto 0 loop
                if dirty then
                    send_bit_noisy(data(i));
                else
                    send_bit(data(i));
                end if;
            end loop;
            send_bit(stop);
        end procedure;

        -- Hold the line at a level for a while, checking no byte appears out of nowhere.
        procedure hold(constant level : in std_logic;
                       constant cycles: in natural;
                       constant expected: in natural) is
        begin
            rx <= level;
            for i in 1 to cycles loop
                wait until rising_edge(clock);
                wait for SYNC_UPDATE_NS;
                assert valid_count = expected
                    report "uart_rx8: a byte appeared where none should have. Bytes so far: "
                         & integer'image(valid_count) & ", expected "
                         & integer'image(expected) & "!"
                    severity failure;
            end loop;
        end procedure;

        -- Let the line settle high after a frame, then let the checks read the counts.
        procedure settle is
        begin
            rx <= '1';
            for i in 1 to BIT_CYCLES loop
                wait until rising_edge(clock);
            end loop;
            wait for SYNC_UPDATE_NS;
        end procedure;

    begin
        -- Case 1: reset_n = '0' with the line idle.
        -- Expect both strobes low (nothing received yet).
        rx      <= '1';
        reset_n <= '0';
        for i in 1 to 4 loop
            wait until rising_edge(clock);
        end loop;
        wait for SYNC_UPDATE_NS;
        assert byte_valid = '0' and frame_err = '0'
            report "uart_rx8: reset should leave byte_valid and frame_err low!"
            severity failure;
        reset_n <= '1';

        -- Case 2: line held idle high for several bit periods.
        -- Expect no byte (an idle line is not a frame).
        hold('1', IDLE_CYCLES, 0);

        -- Case 3: send BYTE1, then let the line settle.
        -- Expect exactly one byte handed over, it must be BYTE1, and no framing error.
        send_frame(BYTE1, '1', false);
        settle;
        assert valid_count = 1
            report "uart_rx8: expected exactly one byte after the first frame!"
            severity failure;
        assert last_byte = BYTE1
            report "uart_rx8: wrong byte received for BYTE1!"
            severity failure;
        assert error_count = 0
            report "uart_rx8: a well-framed byte must not raise frame_err!"
            severity failure;

        -- Case 4: line idle between frames.
        -- Expect no further bytes: the receiver must return cleanly to idle.
        hold('1', IDLE_CYCLES, 1);

        -- Case 5: send BYTE2.
        -- Expect a second byte: the machine must be reusable, not a one-shot.
        -- A receiver whose bit timing drifts between frames fails here.
        send_frame(BYTE2, '1', false);
        settle;
        assert valid_count = 2
            report "uart_rx8: expected exactly two bytes after the second frame!"
            severity failure;
        assert last_byte = BYTE2
            report "uart_rx8: wrong byte received for BYTE2!"
            severity failure;
        assert error_count = 0
            report "uart_rx8: a well-framed byte must not raise frame_err!"
            severity failure;

        hold('1', IDLE_CYCLES, 2);

        -- Case 6: a frame whose stop bit is low. The data bits may well be intact, but the
        -- frame is not, and a receiver that hands the byte over anyway is reporting a byte it
        -- has no reason to trust.
        -- Expect frame_err instead of byte_valid, and no byte.
        send_frame(BYTE1, '0', false);
        settle;
        assert error_count >= 1
            report "uart_rx8: a frame with a low stop bit must raise frame_err!"
            severity failure;
        assert valid_count = 2
            report "uart_rx8: a frame with a low stop bit must not produce a byte!"
            severity failure;

        -- Case 7: the line held low far longer than a frame, which is a break rather than
        -- data: what a transmitter losing power looks like.
        -- Expect no byte throughout, and none once the line returns to idle either.
        --
        -- This is the case that requires idle to leave on a falling *edge* rather than on a low
        -- level. A level test re-arms as soon as the previous frame is judged, so the receiver
        -- marches through back-to-back all-zero frames for the whole break. Those are rejected
        -- correctly, one low stop bit each. The one that is not is the frame still in flight
        -- when the break ends: its stop bit is sampled after the line has recovered, so it
        -- looks well-formed, and a byte assembled out of the break gets handed over as data.
        -- With an edge test there is no second falling edge until the line has gone high again,
        -- so no frame is ever in flight across the boundary.
        hold('0', BREAK_CYCLES, 2);
        hold('1', IDLE_CYCLES, 2);

        -- Case 8: a frame in which every data bit carries its value only in the middle of the
        -- bit period, and the opposite level either side. Sampling the middle is the entire
        -- reason the receiver oversamples, and this is the case that separates a receiver that
        -- does from one that reads the line wherever it happens to look.
        -- Expect the byte to arrive intact.
        send_frame(BYTE1, '1', true);
        settle;
        assert valid_count = 3
            report "uart_rx8: expected a third byte after the noisy frame - the middle of "
                 & "every bit carried the correct value!"
            severity failure;
        assert last_byte = BYTE1
            report "uart_rx8: wrong byte received for the noisy frame - sample near the "
                 & "middle of each bit, not near its edges!"
            severity failure;

        -- Case 9: idle again, to catch a machine that keeps firing.
        hold('1', IDLE_CYCLES, 3);

        report "uart_rx8: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
