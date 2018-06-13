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
		ready_out     : out std_logic
	);
end entity renderer_triangle;

architecture RTL of renderer_triangle is
	signal current_render_bounding_box, current_render_bounding_box_next : srect_t;

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

	signal cntx, cntx_next : s16;
	signal cnty, cnty_next : s16;

	signal put_pixel_out_next : std_logic := '0';
	signal ready_out_next     : std_logic := '0';

	signal triangle_latch, triangle_latch_next       : triangle2d_t;

	function cross_product_sign(
		x, y : s16; p2, p3 : point2d_t
	) return boolean is
	begin
		return ((x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (y - p3.y)) <= 0;
	end function;

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
			put_pixel_out               <= put_pixel_out_next;
			cntx                        <= cntx_next;
			cnty                        <= cnty_next;
			ready_out                   <= ready_out_next;
			current_render_bounding_box <= current_render_bounding_box_next;
			state                       <= state_next;
			triangle_latch              <= triangle_latch_next;
		end if;
	end process;

	process(state, cntx, cnty, current_render_bounding_box.x0, current_render_bounding_box.x1, current_render_bounding_box.y0, current_render_bounding_box.y1, put_pixel_out, ready_out, start_in, current_render_bounding_box, tile_rect_in, triangle_in, triangle_latch, triangle_latch(0), triangle_latch(1), triangle_latch(2)) is
	begin
		state_next                       <= state;
		put_pixel_out_next               <= put_pixel_out;
		cntx_next                        <= cntx;
		cnty_next                        <= cnty;
		ready_out_next                   <= ready_out;
		current_render_bounding_box_next <= current_render_bounding_box;
		triangle_latch_next              <= triangle_latch;

		case state is
			when st_start =>
				put_pixel_out_next <= '0';
				cntx_next          <= (others => '0');
				cnty_next          <= (others => '0');
				ready_out_next     <= '0';
				state_next         <= st_idle;

			when st_idle =>
				ready_out_next <= '0';
				if start_in = '1' then
					triangle_latch_next <= triangle_in;
					current_render_bounding_box_next <= get_current_rendering_bounding_box(triangle_in, tile_rect_in);
					state_next                       <= st_start_render;
				else
					state_next <= st_idle;
				end if;

			when st_start_render =>
				cntx_next <= current_render_bounding_box.x0;
				cnty_next <= current_render_bounding_box.y0;

				state_next <= st_render;

			when st_render =>
				if cntx = (current_render_bounding_box.x1) then
					cntx_next <= (others => '0');
					if cnty = (current_render_bounding_box.y1) then
						cnty_next  <= (others => '0');
						state_next <= st_finished;
					else
						cnty_next <= cnty + 1;
					end if;
				else
					cntx_next <= cntx + 1;
				end if;

				if 
					cross_product_sign(cntx, cnty, triangle_latch(0), triangle_latch(1)) and 
					cross_product_sign(cntx, cnty, triangle_latch(1), triangle_latch(2)) and 
					cross_product_sign(cntx, cnty, triangle_latch(2), triangle_latch(0)) 
				then
					put_pixel_out_next <= '1';
				else
					put_pixel_out_next <= '0';
				end if;

			when st_finished =>
				ready_out_next     <= '1';
				put_pixel_out_next <= '0';
				cntx_next          <= (others => '0');
				cnty_next          <= (others => '0');

				state_next <= st_idle;
		end case;
	end process;

end architecture RTL;
