library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity tile_renderer is
	port(
		clk : in std_logic;
		rst : in std_logic
	);
end entity tile_renderer;

architecture RTL of tile_renderer is
	type state_type is (st_start, st_clear, st_idle);
	signal state : state_type := st_start;

	signal tilebuf_x            : unsigned(7 downto 0);
	signal tilebuf_y            : unsigned(7 downto 0);
	signal tilebuf_data_in      : color_t;
	signal tilebuf_data_out     : color_t;
	signal tilebuf_write_enable : std_logic := '0';

begin

	tile_buffer_0 : entity work.tile_buffer
		port map(
			clk  => clk,
			x    => tilebuf_x,
			y    => tilebuf_y,
			data => tilebuf_data_in,
			we   => tilebuf_write_enable,
			q    => tilebuf_data_out
		);

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			case state is
				when st_start =>
					tilebuf_x            <= (others => '0');
					tilebuf_y            <= (others => '0');
					tilebuf_data_in      <= (others => X"00");
					tilebuf_write_enable <= '0';
					state                <= st_clear;
					
				when st_clear =>
					if tilebuf_y < TILE_RES_Y then
						tilebuf_y <= tilebuf_y + 1;
						
						if tilebuf_x < TILE_RES_X then
							tilebuf_x <= tilebuf_x + 1;
						else 
							tilebuf_x <= (others => '0');
						end if;
						
						tilebuf_data_in <= (r => X"8A", g => X"07", b => X"07");
						tilebuf_write_enable <= '1';
					
					else
						state <= st_idle;
					end if;

				when st_idle =>
					
					state <= st_idle;
			end case;
		end if;
	end process;

end architecture RTL;
