library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.keyboard_inc.all;

entity input_handler is
	generic(
		rot_init   : point3d_t := point3d(0, 0, 0);
		scale_init : int16_t   := int16(1)
	);

	port(
		input_clk : in  std_logic;
		rst          : in  std_logic;
		key          : in  key_t;
		rot          : out point3d_t := rot_init;
		scale        : out int16_t   := scale_init
		--update_rot   : out std_logic := '1'
	);
end entity input_handler;

architecture arch of input_handler is
begin

	--	update_rot <= start or key(KEY_W) or key(KEY_S) or key(KEY_A) or key(KEY_D) or key(KEY_Q) or key(KEY_E);

	process(input_clk, rst) is
	begin
		if rst then
			rot   <= rot_init;
			scale <= scale_init;
		elsif rising_edge(input_clk) then
			case key is
				when KEY_A =>
					rot.x <= rot.x + 1;
				when KEY_D =>
					rot.x <= rot.x - 1;
				when KEY_W =>
					rot.y <= rot.y + 1;
				when KEY_S =>
					rot.y <= rot.y + 1;
				when KEY_Q =>
					rot.z <= rot.z + 1;
				when KEY_E =>
					rot.z <= rot.z - 1;
				when KEY_Z =>
					scale <= scale + 1;
				when KEY_X =>
					scale <= scale - 1;							
				when others => 
			end case;
		end if;
	end process;
end architecture arch;

