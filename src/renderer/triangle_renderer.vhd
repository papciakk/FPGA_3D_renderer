library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.rendering_common.all;

entity renderer_triangle is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		tile_rect_in  : in  rect_t;
		triangle_in   : in  triangle2d_t;
		put_pixel_out : out std_logic;
		posx_out      : out uint16_t;
		posy_out      : out uint16_t;
		start_in      : in  std_logic;
		ready_out     : out std_logic;
		area_in       : in  int16_t;
		depths_in     : in  point3d_t;
		colors_in     : in  triangle_colors_t;
		color_out     : out color_t;
		depth_buf_in  : out int16_t;
		depth_buf_out : in  int16_t;
		depth_wren    : out std_logic
	);
end entity renderer_triangle;

architecture RTL of renderer_triangle is

	-- BOUNDING BOX CALCULATION

	signal render_rect, render_rect_next : srect_t;

	signal depth_out_latch : int16_t;

	-- TRIANGLE RENDERING

	signal cntx, cntx_next : int16_t := (others => '0');
	signal cnty, cnty_next : int16_t := (others => '0');

	signal put_pixel_out_next : std_logic := '0';
	signal ready_out_next     : std_logic := '0';

	signal triangle, triangle_latch_next : triangle2d_t := (point2d(0, 0), point2d(0, 0), point2d(0, 0));

	signal e0, e1, e2 : int16_t;
	signal depth      : int16_t;
	signal r, g, b    : slv8_t;

	signal color1, color2, color3 : uint8_t;
	signal current_point : point2d_t;

	function cross_product(x, y : int16_t; p2, p3 : point2d_t) return int16_t is
	begin
		return resize(((x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (y - p3.y)), 16);
	end function;

	function interpolate_color_component(
		c0, c1, c2 : slv8_t;
		e0, e1, e2 : int16_t;
		area       : int16_t
	) return slv8_t is
		variable p : signed(24 downto 0);
	begin
		p := e0 * signed('0' & c0) + e1 * signed('0' & c1) + e2 * signed('0' & c2);
		return slv8(p / area);
	end function;

	-- CONTROL

	type state_type is (
		st_start, st_idle, st_render, st_finished, st_start_render, st_wait_0,
		st_render_e0, st_render_e1, st_render_e2, st_render_1, st_render_2,
		st_interpolate_r, st_interpolate_g, st_interpolate_b
	);
	signal state, state_next : state_type := st_start;

begin
	posx_out <= uint16_with_cut(cntx);
	posy_out <= uint16_with_cut(cnty);
	
	current_point.x <= cntx;
	current_point.y <= cnty;

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			put_pixel_out  <= put_pixel_out_next;
			cntx           <= cntx_next;
			cnty           <= cnty_next;
			ready_out      <= ready_out_next;
			render_rect    <= render_rect_next;
			state          <= state_next;
			triangle <= triangle_latch_next;
		end if;
	end process;

	process(all) is
	begin
		state_next          <= state;
		put_pixel_out_next  <= put_pixel_out;
		cntx_next           <= cntx;
		cnty_next           <= cnty;
		ready_out_next      <= ready_out;
		render_rect_next    <= render_rect;
		triangle_latch_next <= triangle;

		case state is
			when st_start =>
				depth_wren          <= '0';
				put_pixel_out_next  <= '0';
				cntx_next           <= (others => '0');
				cnty_next           <= (others => '0');
				ready_out_next      <= '0';
				triangle_latch_next <= (point2d(0, 0), point2d(0, 0), point2d(0, 0));
				state_next          <= st_idle;

			when st_idle =>
				depth_wren         <= '0';
				put_pixel_out_next <= '0';
				ready_out_next     <= '0';
				if start_in = '1' then
					triangle_latch_next <= triangle_in;
					render_rect_next    <= get_current_rendering_bounding_box(triangle_in, tile_rect_in);
					state_next          <= st_start_render;
				else
					state_next <= st_idle;
				end if;

			when st_start_render =>
				put_pixel_out_next <= '0';
				depth_wren         <= '0';
				cntx_next          <= render_rect.x0;
				cnty_next          <= render_rect.y0;

				state_next <= st_render;

			when st_render =>
				put_pixel_out_next <= '0';
				depth_wren         <= '0';

				if cnty <= render_rect.y1 then
					if cntx < render_rect.x1 then
						--e0         <= cross_product(cntx, cnty, triangle_latch(0), triangle_latch(1));
						e0 <= edge_function(triangle(1), triangle(2), current_point);
						state_next <= st_render_e1;
					else
						cntx_next <= render_rect.x0;
						cnty_next <= cnty + 1;
					end if;
				else
					ready_out_next     <= '1';
					put_pixel_out_next <= '0';
					state_next         <= st_idle;
				end if;

			when st_render_e0 =>

				state_next <= st_render_e1;

			when st_render_e1 =>
				--e1         <= cross_product(cntx, cnty, triangle_latch(1), triangle_latch(2));
				e1 <= edge_function(triangle(2), triangle(0), current_point);
				state_next <= st_render_e2;

			when st_render_e2 =>
				--e2         <= cross_product(cntx, cnty, triangle_latch(2), triangle_latch(0));
				e2 <= edge_function(triangle(0), triangle(1), current_point);
				state_next <= st_render_1;

			when st_render_1 =>

				if e0 >= 0 and e1 >= 0 and e2 >= 0 then

					state_next <= st_interpolate_r;
				else
					cntx_next  <= cntx + 1;
					state_next <= st_render;
				end if;

			when st_interpolate_r =>
				r          <= interpolate_color_component(colors_in(0).r, colors_in(1).r, colors_in(2).r, e0, e1, e2, area_in);
				--				color_out.r <= std_logic_vector(resize(resize(
				--					unsigned(e0) * unsigned(colors_in(0).r) + unsigned(e1) * unsigned(colors_in(1).r) + unsigned(e2) * unsigned(colors_in(2).r), 32
				--				) / unsigned(area_in), 8));
				state_next <= st_interpolate_g;

			when st_interpolate_g =>
				g          <= interpolate_color_component(colors_in(0).g, colors_in(1).g, colors_in(2).g, e0, e1, e2, area_in);
				state_next <= st_interpolate_b;

			when st_interpolate_b =>
				b          <= interpolate_color_component(colors_in(0).b, colors_in(1).b, colors_in(2).b, e0, e1, e2, area_in);
				state_next <= st_render_2;

			when st_render_2 =>
				depth_out_latch <= depth_buf_out;
				--depth           <= resize(256 - (e0 * depths_in.z + e1 * depths_in.x + e2 * depths_in.y), 16) / area_in;
				depth <= resize((e0 * depths_in.x + e1 * depths_in.y + e2 * depths_in.z) / area_in, 16);
				state_next      <= st_wait_0;

			when st_wait_0 =>
				depth_wren <= '0';
				if depth < depth_out_latch then
				--if signed(std_logic_vector(depth + 127))(15 downto 0) > depth_out_latch then
					depth_wren   <= '1';
					--depth_buf_in <= signed(std_logic_vector(depth + 127))(15 downto 0);
					depth_buf_in <= depth;
					color_out    <= (r => r, g => g, b => b);
					--					color_out    <= (
					--						r => X"00",
					--						g => X"5F",
					--						b => X"FF"
					--					);

					put_pixel_out_next <= '1';
				else
					put_pixel_out_next <= '0';
				end if;
				cntx_next  <= cntx + 1;
				state_next <= st_render;

			when st_finished =>
				depth_wren         <= '0';
				ready_out_next     <= '1';
				put_pixel_out_next <= '0';
				cntx_next          <= (others => '0');
				cnty_next          <= (others => '0');

				state_next <= st_start;
		end case;
	end process;

end architecture RTL;
