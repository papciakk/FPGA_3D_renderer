library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

	constant TILE_RES_X : integer := 200;
	constant TILE_RES_Y : integer := 136;
	
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
	
end package common;