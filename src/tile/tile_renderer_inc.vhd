library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;

package tile_renderer_inc is

	function calc_scale(scale : int16_t; vertex : point3d_t) return point3d_t;
	function rescale_vertices(vertex : point3d_t) return point3d_t;
	function calc_vertex_lighting(vertex : vertex_attr_t; light_dir : point3d_t; ambient_diffuse : int16_t) return color_t;

end package;


package body tile_renderer_inc is

	function calc_scale(scale : int16_t; vertex : point3d_t)
	return point3d_t is
		variable scale_x : int32_t := vertex.x * scale;
		variable scale_y : int32_t := vertex.y * scale;
	begin
		return (
			x => int16(scale_x / 256),
			y => int16(scale_y / 256),
			z => vertex.z
		);
	end function;
	
	function rescale_vertices(vertex : point3d_t)
	return point3d_t is
	begin
		return (
			x => shift_right(vertex.x, 7) + HALF_FULLSCREEN_RES_X,
			y => shift_right(vertex.y, 7) + HALF_FULLSCREEN_RES_Y,
			z => vertex.z
		);
	end function;

	-------------------------------------------------------------------------------------------------------

	function calc_vertex_lighting(vertex : vertex_attr_t; light_dir : point3d_t; ambient_diffuse : int16_t)
	return color_t is
		variable diffuse_raw : int16_t;
		variable diffuse     : slv8_t;
	begin

		diffuse_raw := resize(
			shift_right(
				vertex.normal.x * light_dir.x + 
				vertex.normal.y * light_dir.y + 
				vertex.normal.z * light_dir.z,
				16),
			16);

		if diffuse_raw < 0 then
			diffuse := slv8(ambient_diffuse);
		elsif diffuse_raw + ambient_diffuse > 255 then
			diffuse := slv8(255);
		else
			diffuse := slv8(diffuse_raw + ambient_diffuse);
		end if;

		return color(diffuse, diffuse, diffuse);
	end function;
	
end package body;
