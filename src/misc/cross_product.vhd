library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;
use work.definitions.all;

entity cross_product is
	port(
		vec0, vec1, vec2 : in point2d_t;
		output : out int16_t
	);
end entity;

architecture arch of cross_product is	
begin
	output <= resize((vec2.x - vec0.x) * (vec1.y - vec0.y) - (vec2.y - vec0.y) * (vec1.x - vec0.x), 16);
end architecture;
