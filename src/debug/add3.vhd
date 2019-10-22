library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add3 is
	port(
		i : in std_logic_vector(3 downto 0);
		o : out std_logic_vector(3 downto 0)
	);
end entity add3;

architecture RTL of add3 is
begin
	process(i) is begin
		case(i) is
			when "0000" => 
				o <= "0000";
			when "0001" => 
				o <= "0001";
			when "0010" => 
				o <= "0010";
			when "0011" => 
				o <= "0011";
			when "0100" => 
				o <= "0100";
			when "0101" => 
				o <= "1000";
			when "0110" => 
				o <= "1001";
			when "0111" => 
				o <= "1010";
			when "1000" => 
				o <= "1011";
			when "1001" => 
				o <= "1100";
			when others =>
				o <= "0000";
		end case;
	end process;
end architecture RTL;
