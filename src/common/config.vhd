library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.definitions.all;

package config is

	constant num_processes : integer := 1;

	constant MODE_320_240 : boolean := false;

	constant TILE_RES_X : integer := 160;
	constant TILE_RES_Y : integer := 60;
	
	----------------------------------------------------------------
	
	constant FULLSCREEN_RES_X : integer := sel(MODE_320_240, 320, 640);
	constant FULLSCREEN_RES_Y : integer := sel(MODE_320_240, 240, 480);
	
	constant MAIN_CLK_MHZ : integer := 50;

	constant BITS_PER_PIXEL : integer := 24;
	constant DEPTH_BITS     : integer := 16;
	
	constant ENABLE_LIGHTING : boolean := true;
	
	----------------------------------------------------------------

	constant HALF_FULLSCREEN_RES_X : integer := FULLSCREEN_RES_X / 2;
	constant HALF_FULLSCREEN_RES_Y : integer := FULLSCREEN_RES_Y / 2;

	constant TILES_X_CNT : integer := FULLSCREEN_RES_X / TILE_RES_X;
	constant TILES_Y_CNT : integer := FULLSCREEN_RES_Y / TILE_RES_Y;
	constant TILES_CNT   : integer := TILES_X_CNT * TILES_Y_CNT;

	constant FULLSCREEN_RECT : rect_t := (
		x0 => to_unsigned(0, 16),
		x1 => to_unsigned((FULLSCREEN_RES_X - 1), 16),
		y0 => to_unsigned(0, 16),
		y1 => to_unsigned((FULLSCREEN_RES_Y - 1), 16)
	);

	constant TILE_ADDR_LEN : natural := integer(ceil(log2(real(TILE_RES_X * TILE_RES_Y))));

	constant COLOR_BLACK : color_t := (others => X"00");
	constant COLOR_WHITE : color_t := (others => X"FF");
	constant COLOR_RED   : color_t := (r => X"FF", others => X"00");
	constant COLOR_GREEN : color_t := (g => X"FF", others => X"00");
	constant COLOR_BLUE  : color_t := (b => X"FF", others => X"00");
	constant COLOR_YELLOW  : color_t := (r => X"FF", g => X"FF", b => X"00");
	constant COLOR_MAGENTA  : color_t := (r => X"FF", g => X"00", b => X"FF");
	constant COLOR_CYAN  : color_t := (r => X"00", g => X"FF", b => X"FF");

end package config;
