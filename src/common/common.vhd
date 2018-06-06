library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package common is

	-- TYPEDEFS

	type color_t is record
		r : std_logic_vector(7 downto 0);
		g : std_logic_vector(7 downto 0);
		b : std_logic_vector(7 downto 0);
	end record;

	type rect_t is record
		x0 : unsigned(15 downto 0);
		x1 : unsigned(15 downto 0);
		y0 : unsigned(15 downto 0);
		y1 : unsigned(15 downto 0);
	end record;

	type point2d_t is record
		x : unsigned(15 downto 0);
		y : unsigned(15 downto 0);
	end record;

	type triangle2d_t is array (0 to 2) of point2d_t;

	-- CONSTANTS

	constant BITS_PER_PIXEL : integer := 24;

	constant TILE_RES_X : integer := 200;
	constant TILE_RES_Y : integer := 136;

	constant FULLSCREEN_RES_X : integer := 640;
	constant FULLSCREEN_RES_Y : integer := 480;

	constant FULLSCREEN_RECT : rect_t := (
		x0 => to_unsigned(0, 16),
		x1 => to_unsigned((FULLSCREEN_RES_X - 1), 16),
		y0 => to_unsigned(0, 16),
		y1 => to_unsigned((FULLSCREEN_RES_Y - 1), 16)
	);

	constant ZERO_TILE_RECT : rect_t := (
		x0 => to_unsigned(0, 16),
		x1 => to_unsigned((TILE_RES_X - 1), 16),
		y0 => to_unsigned(0, 16),
		y1 => to_unsigned((TILE_RES_Y - 1), 16)
	);

	constant TILE_ADDR_LEN : natural := integer(ceil(log2(real(TILE_RES_X * TILE_RES_Y))));

	constant COLOR_BLACK : color_t := (others => X"00");
	constant COLOR_WHITE : color_t := (others => X"FF");
	constant COLOR_RED   : color_t := (r => X"FF", others => X"00");
	constant COLOR_GREEN : color_t := (g => X"FF", others => X"00");
	constant COLOR_BLUE  : color_t := (b => X"FF", others => X"00");
	
	-- FUNCTIONS
	
	function point2d(x : integer; y : integer) return point2d_t;
		
	function maximum2(x, y : unsigned) return unsigned;
	function minimum2(x, y : unsigned) return unsigned;
	function maximum3(x, y, z : unsigned) return unsigned;
	function minimum3(x, y, z : unsigned) return unsigned;

end package common;

package body common is

	-- FUNCTIONS

	function point2d(x : integer; y : integer) return point2d_t is
	begin
		return (x => to_unsigned(x, 16), y => to_unsigned(y, 16));
	end function;
	
	function minimum3(x, y, z : unsigned) return unsigned is
	begin 
		if x < y then
			if x < z then return x; else return z; end if;
		else
			if y < z then return y; else return z; end if;
		end if;
	end function;
	
	function maximum3(x, y, z : unsigned) return unsigned is
	begin 
		if x > y then
			if x > z then return x; else return z; end if;
		else
			if y > z then return y; else return z; end if;
		end if;
	end function;
	
	function minimum2(x, y : unsigned) return unsigned is
	begin
		if x < y then return x; else return y; end if;
	end function;
	
	function maximum2(x, y : unsigned) return unsigned is
	begin
		if x > y then return x; else return y; end if;
	end function;

end package body;
