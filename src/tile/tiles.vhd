library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;

package tiles is
	type rect_arr_t is array (natural range <>) of rect_t;

	function get_tile_rect(x, y : integer) return rect_t;
	function prepare_tile_rects return rect_arr_t;

	constant tile_rects : rect_arr_t;
end package;

package body tiles is

	function get_tile_rect(x, y : integer) return rect_t is
	begin
		return (
			x0 => to_unsigned(x * TILE_RES_X, 16),
			x1 => to_unsigned((x + 1) * TILE_RES_X, 16),
			y0 => to_unsigned(y * TILE_RES_Y, 16),
			y1 => to_unsigned((y + 1) * TILE_RES_Y, 16)
		);
	end function;

	function prepare_tile_rects return rect_arr_t is
		constant TILES_X_CNT : integer := integer(real(FULLSCREEN_RES_X) / real(TILE_RES_X));
		constant TILES_Y_CNT : integer := integer(real(FULLSCREEN_RES_Y) / real(TILE_RES_Y));
		variable r           : rect_arr_t(0 to (TILES_X_CNT * TILES_Y_CNT - 1));
	begin
		for yi in 0 to (TILES_Y_CNT - 1) loop
			for xi in 0 to (TILES_X_CNT - 1) loop
				r(yi * TILES_X_CNT + xi) := get_tile_rect(xi, yi);
			end loop;
		end loop;
		return r;
	end function;
	
	constant tile_rects : rect_arr_t := prepare_tile_rects;
	
end package body;
