--------------------------------------------------------------------------------
-- Testbench for rx_shift_reg. Run it against your own rx_shift_reg.vhd.
--
-- Run, from controller/:
--       ghdl -a --std=93 can_def.vhd rx_shift_reg.vhd rx_shift_reg_tb.vhd
--       ghdl -e --std=93 rx_shift_reg_tb
--       ghdl -r --std=93 rx_shift_reg_tb --assert-level=error
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.can_def.all;

entity rx_shift_reg_tb is
end entity;

architecture behaviour of rx_shift_reg_tb is
constant CLOCK_PERIOD_NS: time := 20 ns; -- 50 MHz.
constant CLOCK_EVENT_NS : time := CLOCK_PERIOD_NS / 2;
constant SYNC_UPDATE_NS : time := 1 ns;
constant RESET_CYCLES   : natural := 3;

type bit_array_t is array(natural range <>) of std_logic;

-- The wire sequence tx_shift_reg produces for "11111000": a stuff bit ('0')
-- inserted right after the fifth consecutive '1'.
constant WIRE_1 : bit_array_t(0 to 8) := ('1', '1', '1', '1', '1', '0', '0', '0', '0');

-- Six consecutive '1's: a stuffing violation (the 6th bit should have been
-- the inverted stuff bit). A 7th '1' follows: after the violation the module
-- must restart its run count and keep accumulating rather than overflow it.
constant WIRE_2 : bit_array_t(0 to MAX_RUN + 1) := (others => '1');

-- A 6-bit chunk (the control field's width), then a narrower 3-bit chunk, with
-- no reset in between: exactly what can_controller does when it changes
-- bit_count from one field to the next. Neither run ever reaches five, so no
-- stuff bit is involved and the two chunks are purely about chunk sizing.
constant WIRE_3 : bit_array_t(0 to 5) := ('0', '1', '0', '1', '0', '1');
constant WIRE_4 : bit_array_t(0 to 2) := ('0', '1', '1');

signal clock,      reset_s2_n     : std_logic                    := '0';
signal sample                   : std_logic                    := '0';
signal rx_bus                   : std_logic                    := '1';
signal bit_count                : std_logic_vector(3 downto 0) := "1000";
signal enable                   : std_logic                    := '0';
signal data                     : byte_t;
signal valid,    stuff_error    : std_logic;
signal real_bit, real_bit_valid : std_logic;
signal done                     : boolean := false;

begin
    dut: entity work.rx_shift_reg
        port map(clock, reset_s2_n, sample, rx_bus, bit_count, enable,
            data, valid, stuff_error, real_bit, real_bit_valid);

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
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';
        enable     <= '1';
        bit_count  <= "1000";

        -- Case 1: feed WIRE_1, one bit per "sample" pulse.
        -- Expect data to destuff back to "11111000" and valid to pulse on the
        -- 9th sample, having transparently discarded the stuff bit.
        for i in WIRE_1'range loop
            rx_bus <= WIRE_1(i);
            sample <= '1';
            wait until rising_edge(clock);
            sample <= '0';
            wait for SYNC_UPDATE_NS;
            assert stuff_error = '0'
                report "rx_shift_reg: test 1, sample " & natural'image(i + 1) & ": unexpected stuff_error!"
                severity error;

            if (i = 5) then
                assert real_bit_valid = '0'
                    report "rx_shift_reg: test 1, sample 6: the stuff bit must not raise real_bit_valid!"
                    severity error;
            else
                assert real_bit_valid = '1' and real_bit = WIRE_1(i)
                    report "rx_shift_reg: test 1, sample " & natural'image(i + 1)
                           & ": wrong real_bit/real_bit_valid!"
                    severity error;
            end if;

            if (i = WIRE_1'high) then
                assert valid = '1'
                    report "rx_shift_reg: test 1: valid did not pulse on the final sample!"
                    severity error;
                assert data = "11111000"
                    report "rx_shift_reg: test 1: data did not destuff back to 11111000!"
                    severity error;
            else
                assert valid = '0'
                    report "rx_shift_reg: test 1: valid pulsed early!"
                    severity error;
            end if;

            -- real_bit_valid is a one-cycle *pulse*, not a level held until the
            -- next sample: can_controller gates crc15's enable straight off it,
            -- so a level would feed the same bit in for a whole bit period.
            wait until rising_edge(clock);
            wait for SYNC_UPDATE_NS;
            assert real_bit_valid = '0'
                report "rx_shift_reg: test 1, sample " & natural'image(i + 1)
                       & ": real_bit_valid must drop the cycle after a sample "
                       & "(it is a one-cycle pulse, not a level)!"
                severity error;
        end loop;

        -- Reset before test 2: an isolated stuffing-violation scenario.
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';

        -- Case 2: feed six consecutive '1's, then a seventh.
        -- Expect stuff_error to pulse on the 6th sample - the bit expected to
        -- invert the run of five does not - and the 7th bit to be accepted
        -- normally: the module restarts its run count at the violating bit and
        -- carries on accumulating.
        for i in WIRE_2'range loop
            rx_bus <= WIRE_2(i);
            sample <= '1';
            wait until rising_edge(clock);
            sample <= '0';
            wait for SYNC_UPDATE_NS;

            if (i = MAX_RUN) then
                assert stuff_error = '1'
                    report "rx_shift_reg: test 2: stuff_error did not pulse on the 6th consecutive '1'!"
                    severity error;

                -- "Accept nothing" is the other half of the violation rule, and the
                -- half a stuff_error-only check misses: the violating bit is not a
                -- real bit, so it must not be shifted in and must not be handed to
                -- crc15. can_controller gates crc15's enable straight off
                -- real_bit_valid (L17), so a module that pulses stuff_error and then
                -- accepts the bit anyway corrupts the CRC of a frame it has already
                -- reported as broken.
                assert real_bit_valid = '0'
                    report "rx_shift_reg: test 2: the violating bit must not be accepted "
                           & "(real_bit_valid must stay '0')!"
                    severity error;
                assert valid = '0'
                    report "rx_shift_reg: test 2: valid must not pulse on a stuffing violation!"
                    severity error;
            else
                assert stuff_error = '0'
                    report "rx_shift_reg: test 2, sample " & natural'image(i + 1) & ": unexpected stuff_error!"
                    severity error;
            end if;

            if (i = MAX_RUN + 1) then
                assert real_bit_valid = '1'
                    report "rx_shift_reg: test 2: the bit after a violation must be accepted normally!"
                    severity error;
            end if;

            wait until rising_edge(clock);
        end loop;

        -- Reset before test 3: a clean run-length state for the chunk-sizing
        -- scenario, independent of test 2's deliberate violation.
        reset_s2_n <= '0';
        wait for CLOCK_PERIOD_NS * RESET_CYCLES;
        wait until rising_edge(clock);
        reset_s2_n <= '1';

        -- Case 3: a 6-bit chunk.
        -- Expect valid to pulse on the 6th sample, not the 8th, and the six
        -- bits to land right-aligned in data(5 downto 0) - the placement
        -- can_controller relies on when it slices a reconstructed field.
        bit_count <= "0110";
        for i in WIRE_3'range loop
            rx_bus <= WIRE_3(i);
            sample <= '1';
            wait until rising_edge(clock);
            sample <= '0';
            wait for SYNC_UPDATE_NS;

            if (i = WIRE_3'high) then
                assert valid = '1'
                    report "rx_shift_reg: test 3: valid did not pulse on the 6th sample of a 6-bit chunk!"
                    severity error;
                assert data(5 downto 0) = "010101"
                    report "rx_shift_reg: test 3: a 6-bit chunk did not land right-aligned in data(5 downto 0)!"
                    severity error;
            else
                assert valid = '0'
                    report "rx_shift_reg: test 3, sample " & natural'image(i + 1) & ": valid pulsed early!"
                    severity error;
            end if;

            wait until rising_edge(clock);
        end loop;

        -- Case 4: a 3-bit chunk immediately after, with no reset.
        -- Expect rx_shift_reg to pick up the new bit_count for the next chunk
        -- and pulse valid after 3 samples, with the bits right-aligned in
        -- data(2 downto 0). This is the chunk-to-chunk resizing can_controller
        -- performs between every field.
        bit_count <= "0011";
        for i in WIRE_4'range loop
            rx_bus <= WIRE_4(i);
            sample <= '1';
            wait until rising_edge(clock);
            sample <= '0';
            wait for SYNC_UPDATE_NS;

            assert stuff_error = '0'
                report "rx_shift_reg: test 4, sample " & natural'image(i + 1) & ": unexpected stuff_error!"
                severity error;

            if (i = WIRE_4'high) then
                assert valid = '1'
                    report "rx_shift_reg: test 4: valid did not pulse on the 3rd sample of a 3-bit chunk!"
                    severity error;
                assert data(2 downto 0) = "011"
                    report "rx_shift_reg: test 4: a 3-bit chunk did not land right-aligned in data(2 downto 0)!"
                    severity error;
            else
                assert valid = '0'
                    report "rx_shift_reg: test 4, sample " & natural'image(i + 1) & ": valid pulsed early!"
                    severity error;
            end if;

            wait until rising_edge(clock);
        end loop;

        report "rx_shift_reg: all checks passed!" severity note;
        done <= true;
        wait;
    end process;
end architecture;
