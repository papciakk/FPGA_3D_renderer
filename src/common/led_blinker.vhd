library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.common.all;

entity led_blinker is
	generic(
		frequency : real := 1.0
	);

	port(
		clk50 : in  std_logic;
		rst   : in  std_logic;
		led   : out std_logic
	);
end entity led_blinker;

architecture RTL of led_blinker is

	constant COUNTER_MAX_VAL : natural := integer(50000.0 * (1000.0 / real(frequency)));
	constant COUNTER_BITS    : natural := integer(ceil(log2(real(COUNTER_MAX_VAL))));

	signal counter : unsigned((COUNTER_BITS - 1) downto 0) := (others => '0');
	signal led_reg : std_logic                             := '0';

begin

	process(clk50, rst) is
	begin
		if rst = '1' then
			counter <= (others => '0');
			led_reg <= '0';
		elsif rising_edge(clk50) then
			if counter = (COUNTER_MAX_VAL - 1) then
				counter <= (others => '0');

				if led_reg = '1' then
					led_reg <= '0';
				else
					led_reg <= '1';
				end if;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;

	led <= led_reg;

end architecture RTL;
