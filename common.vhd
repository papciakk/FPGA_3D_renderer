library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is

	constant TILE_RES_X : integer := 80;
	constant TILE_RES_Y : integer := 80;
	
	type color_t is record
		r : std_logic_vector(7 downto 0);
    	g : std_logic_vector(7 downto 0);
    	b : std_logic_vector(7 downto 0);
  	end record color_t;  
  	
  	type color_buffer_t is array (0 to TILE_RES_X, 0 to TILE_RES_Y) of color_t;
	
end package common;