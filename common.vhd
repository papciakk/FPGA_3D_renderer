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


	-- CONSTANTS
	
	constant BITS_PER_PIXEL : integer := 24;

	constant TILE_RES_X : integer := 200;
	constant TILE_RES_Y : integer := 136;
	
	constant FULLSCREEN_RES_X : integer := 640;
	constant FULLSCREEN_RES_Y : integer := 480;
  	
  	constant FULLSCREEN_RECT : rect_t := (
		x0 => to_unsigned(0, 16), 
		x1 => to_unsigned((FULLSCREEN_RES_X-1), 16), 
		y0 => to_unsigned(0, 16), 
		y1 => to_unsigned((FULLSCREEN_RES_Y-1), 16)
	);
	
	constant ZERO_TILE_RECT : rect_t := (
		x0 => to_unsigned(0, 16), 
		x1 => to_unsigned((TILE_RES_X-1), 16), 
		y0 => to_unsigned(0, 16), 
		y1 => to_unsigned((TILE_RES_Y-1), 16)
	);
	
	constant TILE_ADDR_LEN : natural := integer(ceil(log2(real(TILE_RES_X*TILE_RES_Y)))); 
	
end package common;