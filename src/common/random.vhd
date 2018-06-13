library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity random is
	port(
		clk  : in     std_logic;
		rst  : in     std_logic;
		rand : buffer std_logic_vector(31 downto 0);
		seed : in     std_logic_vector(31 downto 0)
	);
end entity random;

architecture RTL of random is

begin
	process(clk)
		function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
		begin
			return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
		end function;
	begin
		if rising_edge(clk) then
			if rst = '1' then
				rand <= seed;
			else
				rand <= std_logic_vector(lfsr32(rand));
			end if;
		end if;
	end process;

end architecture RTL;
