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

	--	process(clk, rst)
	--	begin
	--		if (rst = '1') then
	--			sin_out <= (others => '0');
	--			cos_out <= (others => '0');
	--		elsif rising_edge(clk) then
	--			if angle >= 270 then
	--				sin_out <= -sin_lut(to_integer(360 - angle));
	--				cos_out <= sin_lut(to_integer(angle - 270));
	--			elsif angle >= 180 then
	--				sin_out <= -sin_lut(to_integer(angle - 180));
	--				cos_out <= -sin_lut(to_integer(270 - angle));
	--			elsif angle >= 90 then
	--				sin_out <= sin_lut(to_integer(180 - angle));
	--				cos_out <= -sin_lut(to_integer(angle - 90));
	--			else
	--				sin_out <= sin_lut(to_integer(angle));
	--				cos_out <= sin_lut(to_integer(90 - angle));
	--			end if;
	--		end if;
	--	end process;

end architecture rtl;
