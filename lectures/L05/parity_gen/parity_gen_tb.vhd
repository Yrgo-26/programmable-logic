--------------------------------------------------------------------------------
-- Self-checking testbench for parity_gen.
-- Sweeps every 8-bit input value; parity must equal the XOR of all bits.
--
-- Run:  ghdl -a --std=93 parity_gen.vhd parity_gen_tb.vhd
--       ghdl -e --std=93 parity_gen_tb
--       ghdl -r --std=93 parity_gen_tb --assert-level=error --stop-time=10ms
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity parity_gen_tb is
end entity;

architecture behaviour of parity_gen_tb is
constant BIT_WIDTH: natural := 8;
constant BIT_MAX  : natural := 2**BIT_WIDTH - 1;
constant WAIT_NS  : time := 10 ns;

signal bits  : std_logic_vector(BIT_WIDTH - 1 downto 0);
signal parity: std_logic;
begin
    dut: entity work.parity_gen
        port map(bits, parity);

    SIM_PROCESS: process is
    variable expected: std_logic;
    begin
        for i in 0 to BIT_MAX loop
            bits <= std_logic_vector(to_unsigned(i, BIT_WIDTH));
            wait for WAIT_NS;
            expected := '0';
            for j in bits'range loop
                expected := expected xor bits(j);
            end loop;
            assert parity = expected
                report "parity_gen: wrong parity for bits = " & integer'image(i)
                     & " (decimal), expected " & std_logic'image(expected)
                     & " but got " & std_logic'image(parity) & "!"
                severity failure;
        end loop;
        report "parity_gen: all checks passed!" severity note;
        wait;
    end process;
end architecture;
