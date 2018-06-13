library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity renderer_triangle is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		tile_rect_in  : in  rect_t;
		triangle_in   : in  triangle2d_t;
		put_pixel_out : out std_logic;
		posx_out      : out s16;
		posy_out      : out s16;
		start_in      : in  std_logic;
		ready_out     : out std_logic
	);
end entity renderer_triangle;

architecture RTL of renderer_triangle is
	-- BOUNDING BOX CALCULATION

	function get_triangle_bounding_box(triangle : triangle2d_t) return srect_t is
		variable min_x, max_x : s16;
		variable min_y, max_y : s16;
	begin
		min_x := minimum3(triangle(0).x, triangle(1).x, triangle(2).x);
		min_y := minimum3(triangle(0).y, triangle(1).y, triangle(2).y);
		max_x := maximum3(triangle(0).x, triangle(1).x, triangle(2).x);
		max_y := maximum3(triangle(0).y, triangle(1).y, triangle(2).y);
		return (x0 => min_x, y0 => min_y, x1 => max_x, y1 => max_y);
	end function;

	function get_triangle_and_tile_intersected_bounding_box(triangle_bb : srect_t; tile_bb : rect_t) return srect_t is
	begin
		return (
			x0 => maximum2(triangle_bb.x0, to_s16(tile_bb.x0)),
			y0 => maximum2(triangle_bb.y0, to_s16(tile_bb.y0)),
			x1 => minimum2(triangle_bb.x1, to_s16(tile_bb.x1)),
			y1 => minimum2(triangle_bb.y1, to_s16(tile_bb.y1))
		);
	end;

	function get_current_rendering_bounding_box(triangle : triangle2d_t; tile_rect : rect_t) return srect_t is
	begin
		return get_triangle_and_tile_intersected_bounding_box(
			get_triangle_bounding_box(triangle),
			tile_rect
		);
	end function;

	-- TRIANGLE RENDERING

	function cross_product_sign(x : s16; y : s16; p2 : point2d_t; p3 : point2d_t) return boolean is
	begin
		return (x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (y - p3.y) < 0;
	end function;

	-- SIGNALS

	signal cntx, cntx_next : s16;
	signal cnty, cnty_next : s16;

	signal put_pixel_out_next : std_logic;
	signal ready_out_next     : std_logic;

	signal triangle_latch, triangle_latch_next       : triangle2d_t;
	signal render_rect_latch, render_rect_latch_next : srect_t;

	type state_type is (
		st_start, st_idle, st_render_start, st_render_loop
	);
	signal state, state_next : state_type := st_start;

begin

	posx_out <= cntx;
	posy_out <= cnty;

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			state             <= state_next;
			put_pixel_out     <= put_pixel_out_next;
			cntx              <= cntx_next;
			cnty              <= cnty_next;
			ready_out         <= ready_out_next;
			triangle_latch    <= triangle_latch_next;
			render_rect_latch <= render_rect_latch_next;
		end if;
	end process;

	process(state, cntx, cnty, put_pixel_out, ready_out, render_rect_latch, start_in, tile_rect_in, triangle_in, triangle_latch) is
	begin
		state_next             <= state;
		put_pixel_out_next     <= put_pixel_out;
		cntx_next              <= cntx;
		cnty_next              <= cnty;
		ready_out_next         <= ready_out;
		triangle_latch_next    <= triangle_latch;
		render_rect_latch_next <= render_rect_latch;

		case state is
			when st_start =>
				put_pixel_out_next <= '0';
				cntx_next          <= (others => '0');
				cnty_next          <= (others => '0');
				ready_out_next     <= '0';

				state_next <= st_idle;

			when st_idle =>
				put_pixel_out_next <= '0';

				if start_in = '1' then
					triangle_latch_next    <= triangle_in;
					render_rect_latch_next <= get_current_rendering_bounding_box(triangle_in, tile_rect_in);
					ready_out_next         <= '0';
					state_next             <= st_render_start;
				else
					state_next <= st_idle;
				end if;

			when st_render_start =>
				cntx_next <= render_rect_latch.x0;
				cnty_next <= render_rect_latch.y0;

				state_next <= st_render_loop;

			when st_render_loop =>
				if cnty <= render_rect_latch.y1 then
					if cntx <= render_rect_latch.x1 then
						if 
							cross_product_sign(cntx, cnty, triangle_latch(0), triangle_latch(1)) and 
							cross_product_sign(cntx, cnty, triangle_latch(1), triangle_latch(2)) and 
							cross_product_sign(cntx, cnty, triangle_latch(2), triangle_latch(0)) 
						then
							put_pixel_out_next <= '1';
						else
							put_pixel_out_next <= '0';
						end if;
						cntx_next <= cntx + 1;
					else
						cntx_next <= (others => '0');
						cnty_next <= cnty + 1;
					end if;
				else
					ready_out_next     <= '1';
					put_pixel_out_next <= '0';
					state_next         <= st_idle;
				end if;

		end case;
	end process;

end architecture RTL;
