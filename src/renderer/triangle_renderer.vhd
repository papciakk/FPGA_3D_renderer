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
		posx_out      : out unsigned(15 downto 0);
		posy_out      : out unsigned(15 downto 0);
		start_in      : in  std_logic;
		ready_out     : out std_logic;
		area_in       : in  s32;
		depths_in     : in  point3d_t;
		colors_in     : in  triangle_colors_t;
		color_out     : out color_t
	);
end entity renderer_triangle;

architecture RTL of renderer_triangle is

	-- BOUNDING BOX CALCULATION

	signal render_rect_latch, render_rect_latch_next : srect_t;

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
			x0 => maximum2(triangle_bb.x0, to_s16(tile_bb.x0)),
			y0 => maximum2(triangle_bb.y0, to_s16(tile_bb.y0)),
			x1 => minimum2(triangle_bb.x1, to_s16(tile_bb.x1)),
			y1 => minimum2(triangle_bb.y1, to_s16(tile_bb.y1))
		);
	end function;

	function get_current_rendering_bounding_box(triangle : triangle2d_t; tile_rect : rect_t) return srect_t is
	begin
		return get_triangle_and_tile_intersected_bounding_box(
			get_triangle_bounding_box(triangle),
			tile_rect
		);
	end function;

	-- TRIANGLE RENDERING

	signal cntx, cntx_next : s16 := (others => '0');
	signal cnty, cnty_next : s16 := (others => '0');

	signal put_pixel_out_next : std_logic := '0';
	signal ready_out_next     : std_logic := '0';

	signal triangle_latch, triangle_latch_next : triangle2d_t := (point2d(0, 0), point2d(0, 0), point2d(0, 0));

	function cross_product(x, y : s16; p2, p3 : point2d_t) return s32 is
	begin
		return ((x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (y - p3.y));
	end function;
	
	function interpolate_color_component(
		c0, c1, c2 : std_logic_vector(7 downto 0);
		e0, e1, e2 : s32;
		area : s32
	) return s32 is
	begin
		return resize(
				e0 * signed('0' & c0) + 
				e1 * signed('0' & c1) + 
				e2 * signed('0' & c2), 32
		) / area;
	end function;

	-- CONTROL

	type state_type is (
		st_start, st_idle, st_render, st_finished, st_start_render
	);
	signal state, state_next : state_type := st_start;

begin
	posx_out <= to_u16_with_cut(cntx);
	posy_out <= to_u16_with_cut(cnty);

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			put_pixel_out     <= put_pixel_out_next;
			cntx              <= cntx_next;
			cnty              <= cnty_next;
			ready_out         <= ready_out_next;
			render_rect_latch <= render_rect_latch_next;
			state             <= state_next;
			triangle_latch    <= triangle_latch_next;
		end if;
	end process;

	process(state, cntx, cnty, render_rect_latch.x0, render_rect_latch.x1, render_rect_latch.y0, render_rect_latch.y1, put_pixel_out, ready_out, start_in, render_rect_latch, tile_rect_in, triangle_in, triangle_latch, area_in, depths_in.x, depths_in.y, depths_in.z, colors_in(0).b, colors_in(0).g, colors_in(0).r, colors_in(1).r, colors_in(2).r) is
		variable e0, e1, e2 : s32;
--		variable depth      : signed(47 downto 0);
		variable r, g, b : s32;
	begin
		state_next             <= state;
		put_pixel_out_next     <= put_pixel_out;
		cntx_next              <= cntx;
		cnty_next              <= cnty;
		ready_out_next         <= ready_out;
		render_rect_latch_next <= render_rect_latch;
		triangle_latch_next    <= triangle_latch;

		case state is
			when st_start =>
				put_pixel_out_next  <= '0';
				cntx_next           <= (others => '0');
				cnty_next           <= (others => '0');
				ready_out_next      <= '0';
				triangle_latch_next <= (point2d(0, 0), point2d(0, 0), point2d(0, 0));
				state_next          <= st_idle;

			when st_idle =>
				put_pixel_out_next <= '0';
				ready_out_next     <= '0';
				if start_in = '1' then
					triangle_latch_next    <= triangle_in;
					render_rect_latch_next <= get_current_rendering_bounding_box(triangle_in, tile_rect_in);
					state_next             <= st_start_render;
				else
					state_next <= st_idle;
				end if;

			when st_start_render =>
				put_pixel_out_next <= '0';
				cntx_next          <= render_rect_latch.x0;
				cnty_next          <= render_rect_latch.y0;

				state_next <= st_render;

			when st_render =>
				put_pixel_out_next <= '0';

				if cnty <= render_rect_latch.y1 then
					if cntx < render_rect_latch.x1 then
						e0 := cross_product(cntx, cnty, triangle_latch(0), triangle_latch(1));
						e1 := cross_product(cntx, cnty, triangle_latch(1), triangle_latch(2));
						e2 := cross_product(cntx, cnty, triangle_latch(2), triangle_latch(0));

						if e0 <= 0 and e1 <= 0 and e2 <= 0 then

							r := interpolate_color_component(colors_in(2).r, colors_in(0).r, colors_in(1).r, e0, e1, e2, area_in);
							g := interpolate_color_component(colors_in(2).g, colors_in(0).g, colors_in(1).g, e0, e1, e2, area_in);
							b := interpolate_color_component(colors_in(2).b, colors_in(0).b, colors_in(1).b, e0, e1, e2, area_in);
							
							color_out <= (
								r => std_logic_vector(r(7 downto 0)),
								g => std_logic_vector(g(7 downto 0)),
								b => std_logic_vector(b(7 downto 0))
							);

							--							depth := (e0 * depths_in.z + e1 * depths_in.x + e2 * depths_in.y) / area_in;

							--							color_out <= (
							--								r => std_logic_vector(depth(7 downto 0)),
							--								g => std_logic_vector(depth(7 downto 0)),
							--								b => std_logic_vector(depth(7 downto 0))
							--							);

							put_pixel_out_next <= '1';
						end if;

						cntx_next <= cntx + 1;
					else
						cntx_next <= render_rect_latch.x0;
						cnty_next <= cnty + 1;
					end if;
				else
					ready_out_next     <= '1';
					put_pixel_out_next <= '0';
					state_next         <= st_idle;
				end if;

			when st_finished =>
				ready_out_next     <= '1';
				put_pixel_out_next <= '0';
				cntx_next          <= (others => '0');
				cnty_next          <= (others => '0');

				state_next <= st_start;
		end case;
	end process;

end architecture RTL;
