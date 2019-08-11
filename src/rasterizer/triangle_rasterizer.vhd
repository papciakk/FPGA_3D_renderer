library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.renderer_inc.all;

entity triangle_rasterizer is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		render_rect   : in  srect_t;
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
end entity;

architecture RTL of triangle_rasterizer is

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

	signal depth_out_latch : int16_t;

	signal x, x_next         : int16_t := int16(0);
	signal y, y_next         : int16_t := int16(0);
	signal x_cnt, x_cnt_next : int16_t := int16(0);
	signal y_cnt, y_cnt_next : int16_t := int16(0);

	signal put_pixel_out_next : std_logic := '0';
	
	signal ready_out_next     : std_logic := '0';

	signal e0, e1, e2 : int16_t;
	signal r, g, b    : slv8_t;
	signal depth      : int16_t;

	type state_type is (
		st_start, st_idle, 
		st_loop, st_init_loop, 
		st_calc_e0, st_calc_e1, st_calc_e2, st_test_pixel_inside_triangle,
		st_interpolate_r, st_interpolate_g, st_interpolate_b, 
		st_calc_depth,st_depth_test_put_pixel
		
	);
	signal state, state_next : state_type := st_start;

begin
	posx_out <= uint16_with_cut(x);
	posy_out <= uint16_with_cut(y);

	color_out <= (r, g, b);

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			put_pixel_out <= put_pixel_out_next;
			x             <= x_next;
			y             <= y_next;
			x_cnt         <= x_cnt_next;
			y_cnt         <= y_cnt_next;
			ready_out     <= ready_out_next;
			state         <= state_next;
		end if;
	end process;

	process(all) is
	begin
		state_next         <= state;
		put_pixel_out_next <= put_pixel_out;
		x_next             <= x;
		y_next             <= y;
		x_cnt_next         <= x_cnt;
		y_cnt_next         <= y_cnt;
		ready_out_next     <= ready_out;

		case state is
			when st_start =>
				depth_wren         <= '0';
				put_pixel_out_next <= '0';
				ready_out_next     <= '0';
				state_next         <= st_idle;

			when st_idle =>
				depth_wren         <= '0';
				put_pixel_out_next <= '0';
				ready_out_next     <= '0';
				if start_in then
					state_next <= st_init_loop;
				else
					state_next <= st_idle;
				end if;

			when st_init_loop =>
				x_next     <= render_rect.x0;
				y_next     <= render_rect.y0;
				x_cnt_next <= render_rect.x0;
				y_cnt_next <= render_rect.y0;

				state_next <= st_loop;

			when st_loop =>
				put_pixel_out_next <= '0';
				depth_wren         <= '0';

				if y_cnt < render_rect.y1 then
					if x_cnt < render_rect.x1 then
						x_next     <= x_cnt;
						y_next     <= y_cnt;
						state_next <= st_calc_e0;
					else
						x_cnt_next <= render_rect.x0;
						y_cnt_next <= y_cnt + 1;
					end if;
				else
					ready_out_next     <= '1';
					put_pixel_out_next <= '0';
					state_next         <= st_idle;
				end if;

			when st_calc_e0 =>
				e0         <= edge_function(triangle_in(1), triangle_in(2), (x, y));
				state_next <= st_calc_e1;

			when st_calc_e1 =>
				e1         <= edge_function(triangle_in(2), triangle_in(0), (x, y));
				state_next <= st_calc_e2;

			when st_calc_e2 =>
				e2         <= edge_function(triangle_in(0), triangle_in(1), (x, y));
				state_next <= st_test_pixel_inside_triangle;

			when st_test_pixel_inside_triangle =>
				if e0 >= 0 and e1 >= 0 and e2 >= 0 then
					state_next <= st_interpolate_r;
				else
					x_cnt_next <= x_cnt + 1;
					state_next <= st_loop;
				end if;

			when st_interpolate_r =>
				r          <= interpolate_color_component(colors_in(0).r, colors_in(1).r, colors_in(2).r, e0, e1, e2, area_in);
				state_next <= st_interpolate_g;

			when st_interpolate_g =>
				g          <= interpolate_color_component(colors_in(0).g, colors_in(1).g, colors_in(2).g, e0, e1, e2, area_in);
				state_next <= st_interpolate_b;

			when st_interpolate_b =>
				b          <= interpolate_color_component(colors_in(0).b, colors_in(1).b, colors_in(2).b, e0, e1, e2, area_in);
				state_next <= st_calc_depth;

			when st_calc_depth =>
				depth_out_latch <= depth_buf_out;
				depth           <= resize((e0 * depths_in.x + e1 * depths_in.y + e2 * depths_in.z) / area_in, 16);
				state_next      <= st_depth_test_put_pixel;

			when st_depth_test_put_pixel =>
				depth_wren         <= '0';
				put_pixel_out_next <= '0';

				if depth < depth_out_latch then
					depth_wren         <= '1';
					depth_buf_in       <= depth;
					put_pixel_out_next <= '1';
				end if;

				x_cnt_next <= x_cnt + 1;
				state_next <= st_loop;

		end case;
	end process;

end architecture RTL;
