library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library common;
use common.common.all;
library generated;
use generated.tile_ram;

entity tile_buffer is
	port(
		screen_clk             : in  std_logic;
		screen_posx            : in  unsigned(15 downto 0);
		screen_posy            : in  unsigned(15 downto 0);
		screen_pixel_color_out : out color_t;
		---------------------------------------------------
		tilegen_clk            : in  std_logic;
		tilegen_posx           : in  unsigned(15 downto 0);
		tilegen_posy           : in  unsigned(15 downto 0);
		tilegen_enable         : in  std_logic;
		tilegen_pixel_color    : in  color_t
	);
end entity tile_buffer;

architecture RTL of tile_buffer is
	signal ram_addr_rd      : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0);
	signal ram_data_out_raw : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);
	------
	signal tilegen_pixel_color_raw : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);
	signal ram_addr_wr : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0);

begin
	
	tilegen_pixel_color_raw(7 downto 0)   <= tilegen_pixel_color.b;
	tilegen_pixel_color_raw(15 downto 8)  <= tilegen_pixel_color.g;
	tilegen_pixel_color_raw(23 downto 16) <= tilegen_pixel_color.r;
	
	ram_addr_wr <= std_logic_vector(to_unsigned(to_integer(tilegen_posy * TILE_RES_X + tilegen_posx), TILE_ADDR_LEN));

	tile_ram0 : entity generated.tile_ram
		port map(
			data      => tilegen_pixel_color_raw,
			rdaddress => ram_addr_rd,
			rdclock   => screen_clk,
			wraddress => ram_addr_wr,
			wrclock   => tilegen_clk,
			wren      => tilegen_enable,
			q         => ram_data_out_raw
		);

	ram_addr_rd <= std_logic_vector(to_unsigned(to_integer(screen_posy * TILE_RES_X + screen_posx), TILE_ADDR_LEN));
	screen_pixel_color_out <= (
		b => ram_data_out_raw(7 downto 0),
		g => ram_data_out_raw(15 downto 8),
		r => ram_data_out_raw(23 downto 16)
	);
	--
	--	process(clk, rst) is
	--	begin
	--		if rst = '1' then
	--
	--		elsif rising_edge(clk) then
	--
	--		end if;
	--
	--	end process;

end architecture RTL;
