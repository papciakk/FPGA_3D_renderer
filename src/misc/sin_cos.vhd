library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;

entity sin_cos is
	port(
		angle  : in  int16_t;
		sine   : out int16_t;
		cosine : out int16_t
	);
end entity sin_cos;

architecture rtl of sin_cos is
	type sin_lut_t is array (natural range <>) of int16_t;

	function gen_sin_lut return sin_lut_t is
		variable slut : sin_lut_t(359 downto 0);
	begin
		for i in 0 to 359 loop
			slut(i) := to_signed(integer(real(8192) * sin(real(i) * 0.0174533)), 16);
		end loop;

		return slut;
	end function;

	constant sin_lut : sin_lut_t(359 downto 0) := gen_sin_lut;

	signal cosine_angle : int16_t;
begin
	cosine_angle <= (90 - angle) when angle <= 90 else (90 - angle + 360);
	sine         <= sin_lut(to_integer(angle));
	cosine       <= sin_lut(to_integer(cosine_angle));
end architecture rtl;
