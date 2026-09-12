--------------------------------------------------------------------------------
-- Byte-level SPI slave.
--
-- Inputs:
--    - clock     : 50 MHz system clock.
--    - reset_s2_n: Asynchronous active-low reset.
--    - sclk      : SPI clock.
--    - mosi      : Master Out Slave In.
--    - ss        : SPI Chip Select.
--    - tx_data   : Next byte to shift output.
-- Outputs:
--    - miso     : Master In Slave Out.
--    - rx_data  : Incoming byte.
--    - rx_valid : '1' if incoming byte is fresh.
--    - ss_active: '1' while selected (ss low).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity spi_slave is
    port(clock, reset_s2_n  : in std_logic;
         sclk, mosi, ss     : in std_logic;
         tx_data            : in std_logic_vector(7 downto 0);
         miso               : out std_logic;
         rx_data            : out std_logic_vector(7 downto 0);
         rx_valid, ss_active: out std_logic);
end entity;

architecture behaviour of spi_slave is

-- Two synchronizer stages, plus a third flop holding last cycle's s2 so an edge can be detected
-- by comparing the two. sclk and ss are used for their edges and need all three; mosi is only
-- ever read at an edge detected on sclk, so it needs the two synchronizer stages and no history.
type sync_t is record
    s1: std_logic; -- First synchronizer stage; may go metastable.
    s2: std_logic; -- Second synchronizer stage: the current, safe-to-use value.
    s3: std_logic; -- Previous cycle's s2, for edge detection.
end record;

-- Synchronized SPI signals.
signal sclk_s, ss_s     : sync_t;
signal mosi_s1, mosi_s2 : std_logic;

-- Bit counter.
signal bit_counter: natural range 0 to 7;

-- Shift registers.
signal rx_sh, tx_sh: std_logic_vector(7 downto 0);

begin
    ss_active <= not ss_s.s2;
    miso      <= tx_sh(7) when ss_s.s2 = '0' else '0';

    -- Synchronize SPI inputs.
    process(clock, reset_s2_n) is
    begin
        if (reset_s2_n = '0') then
            -- Each chain resets to the level its line idles at, so the module comes out of reset
            -- believing what is actually true of an idle bus. sclk idles low in SPI mode 0; ss
            -- is active low and idles HIGH, so resetting its chain to '0' would make ss_active
            -- read '1' out of reset and the bridge see a frame nobody started. This is the same
            -- rule L04's button_sync exercise exists to enforce.
            sclk_s  <= ('0', '0', '0');
            ss_s    <= ('1', '1', '1');
            mosi_s1 <= '0';
            mosi_s2 <= '0';
        elsif (rising_edge(clock)) then
            sclk_s.s1 <= sclk;
            sclk_s.s2 <= sclk_s.s1;
            sclk_s.s3 <= sclk_s.s2;
            ss_s.s1   <= ss;
            ss_s.s2   <= ss_s.s1;
            ss_s.s3   <= ss_s.s2;
            mosi_s1   <= mosi;
            mosi_s2   <= mosi_s1;
        end if;
    end process;

    -- Run SPI slave logic.
    process(clock, reset_s2_n) is
    variable sclk_rising, sclk_falling, ss_falling: std_logic := '0';
    begin
        if (reset_s2_n = '0') then
            bit_counter  <= 0;
            rx_sh        <= (others => '0');
            tx_sh        <= (others => '0');
            rx_data      <= (others => '0');
            rx_valid     <= '0';
        elsif (rising_edge(clock)) then
            rx_valid <= '0';

            -- Detect edges on sclk and ss.
            sclk_rising  := sclk_s.s2 and (not sclk_s.s3);
            sclk_falling := (not sclk_s.s2) and (sclk_s.s3);
            ss_falling   := (not ss_s.s2) and ss_s.s3;

            -- Deselected: hold the bit counter at zero and ignore the SPI lines entirely. SCK
            -- belongs to whichever slave the master is addressing, and a line that is merely
            -- ringing is not data. Without this gate the branches below would shift MOSI and
            -- pulse rx_valid on edges arriving while ss is high, and spi_reg_bridge would lose
            -- byte alignment for every transaction afterwards.
            if (ss_s.s2 = '1') then
                bit_counter <= 0;

            -- ss just fell: a transaction is starting. Load the first byte to send and start the
            -- frame at bit 0. This arm comes before the SCK arms rather than beside them, so a
            -- rising SCK edge landing on this same system-clock cycle cannot advance the counter
            -- past the start of the frame and misalign every byte in it.
            elsif (ss_falling = '1') then
                bit_counter <= 0;
                tx_sh       <= tx_data;

            else
                -- Sample MOSI, MSB first on rising SCLK edge.
                if (sclk_rising = '1') then
                    if (bit_counter = 7) then
                        rx_data     <= rx_sh(6 downto 0) & mosi_s2;
                        rx_valid    <= '1';
                        bit_counter <= 0;
                    else
                        rx_sh       <= rx_sh(6 downto 0) & mosi_s2;
                        bit_counter <= bit_counter + 1;
                    end if;
                end if;

                -- Present the next MISO bit on falling edge.
                if (sclk_falling = '1') then
                    if (bit_counter = 0) then
                        tx_sh <= tx_data;
                    else
                        tx_sh <= tx_sh(6 downto 0) & '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
