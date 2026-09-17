--------------------------------------------------------------------------------
-- Constants and subtypes every CAN controller module shares.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package can_def is
-- Bit timing.
constant CLOCK_FREQ_HZ: natural := 50_000_000;                  -- System clock frequency: 50 MHz.
constant BIT_RATE_HZ  : natural := 1_000_000;                   -- CAN bit rate: 1 Mbit/s.
constant TICKS_PER_BIT: natural := CLOCK_FREQ_HZ / BIT_RATE_HZ; -- Clock ticks per CAN bit: 50.
constant SAMPLE_TICK  : natural := (TICKS_PER_BIT * 7) / 10;    -- Sample point: 35 (70%).

-- Frame field widths.
constant ID_WIDTH  : natural := 11;          -- Standard CAN identifier width in bits.
constant DLC_WIDTH : natural := 4;           -- Data Length Code field width in bits.
constant CRC_WIDTH : natural := 15;          -- CAN CRC-15 sequence width in bits.
constant DLC_MAX   : natural := 8;           -- Maximum payload length in bytes.
constant DATA_WIDTH: natural := DLC_MAX * 8; -- Maximum data-field width in bits.

-- Bit stuffing.
constant MAX_RUN: natural := 5; -- Maximum run of identical bits before a stuff bit is inserted.

-- Shared subtypes.
subtype byte_t is std_logic_vector(7 downto 0);            -- 8-bit byte.
subtype id_t   is std_logic_vector(ID_WIDTH-1 downto 0);   -- Standard CAN identifier.
subtype dlc_t  is std_logic_vector(DLC_WIDTH-1 downto 0);  -- Data Length Code field.
subtype crc_t  is std_logic_vector(CRC_WIDTH-1 downto 0);  -- CAN CRC-15 sequence.
subtype data_t is std_logic_vector(DATA_WIDTH-1 downto 0); -- CAN data field.

-- Checksum constants.
constant CRC_POLY: crc_t := "100010110011001"; -- The CRC-15 polynomial.
end package;
