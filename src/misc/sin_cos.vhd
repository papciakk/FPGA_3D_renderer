library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;

entity sin_cos is
	port(
		clk     : in  std_logic;
		rst     : in  std_logic;
		angle   : in  int16_t;
		sin_out : out int16_t;
		cos_out : out int16_t
	);
end entity sin_cos;

architecture rtl of sin_cos is
	type sin_lut_t is array (natural range <>) of int16_t;

	function gen_sin_lut return sin_lut_t is
		variable slut : sin_lut_t(360 downto 0);
	begin
		for i in 0 to 360 loop
			slut(i) := to_signed(integer(real(8192) * sin(real(i) * 0.0174533)), 16);
		end loop;

		return slut;
	end function;
	
	function gen_cos_lut return sin_lut_t is
		variable clut : sin_lut_t(360 downto 0);
	begin
		for i in 0 to 360 loop
			clut(i) := to_signed(integer(real(8192) * cos(real(i) * 0.0174533)), 16);
		end loop;

		return clut;
	end function;

	constant sin_lut : sin_lut_t(360 downto 0) := gen_sin_lut;
	constant cos_lut : sin_lut_t(360 downto 0) := gen_cos_lut;
begin
	sin_out <= sin_lut(to_integer(angle));
	cos_out <= cos_lut(to_integer(angle));
	
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
