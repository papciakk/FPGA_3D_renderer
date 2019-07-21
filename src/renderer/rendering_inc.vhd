library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library common;
use common.stdint.all;
use common.definitions.all;

package rendering_inc is

	function get_triangle_bounding_box(triangle : triangle2d_t) return srect_t;
	function get_triangle_and_tile_intersected_bounding_box(triangle_bb : srect_t; tile_bb : rect_t) return srect_t;
	function get_current_rendering_bounding_box(triangle : triangle2d_t; tile_rect : rect_t) return srect_t;

	function edge_function(a, b, c : point2d_t) return int16_t;
	function edge_function(a, b, c : point3d_t) return int16_t;

end package rendering_inc;


package body rendering_inc is

	function get_triangle_bounding_box(triangle : triangle2d_t) return srect_t is
	begin
		return (
			x0 => minimum3(triangle(0).x, triangle(1).x, triangle(2).x),
			y0 => minimum3(triangle(0).y, triangle(1).y, triangle(2).y),
			x1 => maximum3(triangle(0).x, triangle(1).x, triangle(2).x),
			y1 => maximum3(triangle(0).y, triangle(1).y, triangle(2).y)
		);
	end function;

	function get_triangle_and_tile_intersected_bounding_box(triangle_bb : srect_t; tile_bb : rect_t) return srect_t is
	begin
		return (
			x0 => maximum2(triangle_bb.x0, int16(tile_bb.x0)),
			y0 => maximum2(triangle_bb.y0, int16(tile_bb.y0)),
			x1 => minimum2(triangle_bb.x1, int16(tile_bb.x1)),
			y1 => minimum2(triangle_bb.y1, int16(tile_bb.y1))
		);
	end function;

	function get_current_rendering_bounding_box(triangle : triangle2d_t; tile_rect : rect_t) return srect_t is
	begin
		return get_triangle_and_tile_intersected_bounding_box(
			get_triangle_bounding_box(triangle),
			tile_rect
		);
	end function;
	
	function edge_function(a, b, c : point2d_t) return int16_t is
	begin
		return resize((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x), 16);
	end function;
	
	function edge_function(a, b, c : point3d_t) return int16_t is
		variable aa, bb, cc : point2d_t;
	begin
		aa := (a.x, a.y);
		bb := (b.x, b.y);
		cc := (c.x, c.y);
		return edge_function(aa, bb, cc);
	end function;
	
end package body;
