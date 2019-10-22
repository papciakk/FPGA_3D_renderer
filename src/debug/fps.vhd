library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.digits.all;

entity fps is
	port(
		val   : in  integer;
		nums  : out num_array_t
	);
end entity fps;

architecture RTL of fps is
	signal ones, tens        : std_logic_vector(3 downto 0);

	signal c1, c2, c3, c4, c5, c6, c7 : std_logic_vector(3 downto 0);
	signal d1, d2, d3, d4, d5, d6, d7 : std_logic_vector(3 downto 0);
	
	signal fps : std_logic_vector(7 downto 0);
begin
	
	fps <= std_logic_vector(to_unsigned(MAIN_CLK_HZ / val, 8));
	
	d1 <= '0' & fps(7) & fps(6) & fps(5);
	d2 <= c1(2 downto 0) & fps(4);
	d3 <= c2(2 downto 0) & fps(3);
	d4 <= c3(2 downto 0) & fps(2);
	d5 <= c4(2 downto 0) & fps(1);
	d6 <= "0" & c1(3) & c2(3) & c3(3);
	d7 <= c6(2 downto 0) & c4(3);

	add1 : entity work.add3
		port map(d1, c1);
	add2 : entity work.add3
		port map(d2, c2);
	add3 : entity work.add3
		port map(d3, c3);
	add4 : entity work.add3
		port map(d4, c4);
	add5 : entity work.add3
		port map(d5, c5);
	add6 : entity work.add3
		port map(d6, c6);
	add7 : entity work.add3
		port map(d7, c7);

	ones <= c5(2 downto 0) & fps(0);
	tens <= c7(2 downto 0) & c5(3);

	nums <= (unsigned(tens), unsigned(ones));

end architecture RTL;
