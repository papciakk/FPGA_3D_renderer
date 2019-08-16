library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;

entity rotation_helper is
	port(
		in01 : in int16_t;
		in02 : in int16_t;
		in03 : in int16_t;
		in04 : in int16_t;
		in11 : in int16_t;
		in12 : in int16_t;
		in13 : in int16_t;
		in14 : in int16_t;
		in21 : in int16_t;
		in22 : in int16_t;
		in23 : in int16_t;
		in24 : in int16_t;
		trig1 : in int16_t;
		trig2 : in int16_t;
		trig3 : in int16_t;
		trig4 : in int16_t;
		out01 : out int16_t;
		out02 : out int16_t;
		out11 : out int16_t;
		out12 : out int16_t;
		out21 : out int16_t;
		out22 : out int16_t
	);
end entity;

architecture rtl of rotation_helper is	
begin
	out01 <= resize(shift_right(in01 * trig1 + in02 * trig2, 13), 16);
	out02 <= resize(shift_right(in03 * trig3 + in04 * trig4, 13), 16);
	
	out11 <= resize(shift_right(in11 * trig1 + in12 * trig2, 13), 16);
	out12 <= resize(shift_right(in13 * trig3 + in14 * trig4, 13), 16);
	
	out21 <= resize(shift_right(in21 * trig1 + in22 * trig2, 13), 16);
	out22 <= resize(shift_right(in23 * trig3 + in24 * trig4, 13), 16);
end architecture;
