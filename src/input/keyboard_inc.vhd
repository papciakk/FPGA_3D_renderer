library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;

package keyboard_inc is

	subtype keys_t is std_logic_vector(11 downto 0);

	constant KEY_W : integer := 0;
	constant KEY_S : integer := 1;
	constant KEY_A : integer := 2;
	constant KEY_D : integer := 3;
	constant KEY_Q : integer := 4;
	constant KEY_E : integer := 5;
	constant KEY_Z : integer := 6;
	constant KEY_X : integer := 7;
	constant KEY_T : integer := 8;
	constant KEY_G : integer := 9;
	constant KEY_F : integer := 10;
	constant KEY_H : integer := 11;

end package keyboard_inc;

package body keyboard_inc is
end package body;