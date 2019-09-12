library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.keyboard_inc.all;

entity input_handler is
	generic(
		rot_init       : point3d_t := point3d(0, 0, 0);
		rot_light_init : point2d_t := point2d(0, 0);
		scale_init     : int16_t   := int16(1)
	);

	port(
		input_clk : in  std_logic;
		rst       : in  std_logic;
		keys      : in  keys_t;
		rot       : out point3d_t := rot_init;
		rot_light : out point2d_t := rot_light_init;
		scale     : out int16_t   := scale_init
	);
end entity input_handler;

architecture rtl of input_handler is
begin

	process(input_clk, rst) is
	begin
		if rst then
			rot   <= rot_init;
			scale <= scale_init;
		elsif rising_edge(input_clk) then
			if keys(KEY_A) = '1' then
				rot.x <= sel(rot.x < 360, rot.x + 1, int16(1));
			end if;
			if keys(KEY_D) = '1' then
				rot.x <= sel(rot.x > 0, rot.x - 1, int16(360));
			end if;
			if keys(KEY_W) = '1' then
				rot.y <= sel(rot.y < 360, rot.y + 1, int16(1));
			end if;
			if keys(KEY_S) = '1' then
				rot.y <= sel(rot.y > 0, rot.y - 1, int16(360));
			end if;
			if keys(KEY_Q) = '1' then
				rot.z <= sel(rot.z < 360, rot.z + 1, int16(1));
			end if;
			if keys(KEY_E) = '1' then
				rot.z <= sel(rot.z > 0, rot.z - 1, int16(360));
			end if;
			if keys(KEY_Z) = '1' then
				scale <= sel(scale <= 256, scale + 1, int16(256));
			end if;
			if keys(KEY_X) = '1' then
				scale <= sel(scale > 1, scale - 1, int16(1));
			end if;
			if keys(KEY_F) = '1' then
				rot_light.x <= sel(rot_light.x < 360, rot_light.x + 1, int16(1));
			end if;
			if keys(KEY_H) = '1' then
				rot_light.x <= sel(rot_light.x > 0, rot_light.x - 1, int16(360));
			end if;
			if keys(KEY_T) = '1' then
				rot_light.y <= sel(rot_light.y < 360, rot_light.y + 1, int16(1));
			end if;
			if keys(KEY_G) = '1' then
				rot_light.y <= sel(rot_light.y > 0, rot_light.y - 1, int16(360));
			end if;
		end if;
	end process;
end architecture rtl;
