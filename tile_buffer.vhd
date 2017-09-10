library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity tile_buffer is

	port(
		clk  : in  std_logic;
		x    : in  unsigned(7 downto 0);
		y    : in  unsigned(7 downto 0);
		data : in  color_t;
		we   : in  std_logic := '1';
		q    : out color_t
	);

end entity;

architecture rtl of tile_buffer is

	signal buf : color_buffer_t;

begin

	process(clk)
	begin
		if (rising_edge(clk)) then
			if (we = '1') then
				buf(to_integer(x), to_integer(y)) <= data;
			end if;

		end if;
	end process;

	q <= buf(to_integer(x), to_integer(y));

end rtl;
