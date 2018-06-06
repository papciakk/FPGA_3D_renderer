library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity triangle_renderer is
	port(
		clk                  : in  std_logic;
		rst                  : in  std_logic;
		current_tile_rect_in : in  rect_t;
		triangle_in          : in  triangle2d_t;
		pixel_out            : out std_logic;
		posx_out             : out unsigned(15 downto 0);
		posy_out             : out unsigned(15 downto 0);
		start_in             : in  std_logic;
		ready_out            : out std_logic
	);
end entity triangle_renderer;

architecture RTL of triangle_renderer is
	signal triangle_bounding_box       : rect_t;
	signal current_render_bounding_box : rect_t;

	-- BOUNDING BOX CALCULATION

	function get_triangle_bounding_box(triangle : triangle2d_t) return rect_t is
		variable min_x, max_x : unsigned(15 downto 0);
		variable min_y, max_y : unsigned(15 downto 0);
	begin
		min_x := minimum3(triangle(0).x, triangle(1).x, triangle(2).x);
		min_y := minimum3(triangle(0).y, triangle(1).y, triangle(2).y);
		max_x := maximum3(triangle(0).x, triangle(1).x, triangle(2).x);
		max_y := maximum3(triangle(0).y, triangle(1).y, triangle(2).y);
		return (x0 => min_x, y0 => min_y, x1 => max_x, y1 => max_y);
	end function;

	function get_triangle_and_tile_intersected_bounding_box(triangle_bb : rect_t; tile_bb : rect_t) return rect_t is
	begin
		return (
			x0 => maximum2(triangle_bb.x0, tile_bb.x0),
			y0 => maximum2(triangle_bb.y0, tile_bb.y0),
			x1 => minimum2(triangle_bb.x1, tile_bb.x1),
			y1 => minimum2(triangle_bb.y1, tile_bb.y1)
		);
	end;

	-- TRIANGLE RENDERING

	signal cntx, cntx_next : unsigned(15 downto 0);
	signal cnty, cnty_next : unsigned(15 downto 0);

	signal e0, e1, e2 : std_logic;

	function cross_product_sign(
		x  : unsigned(15 downto 0); y : unsigned(15 downto 0);
		p2 : point2d_t; p3 : point2d_t
	) return std_logic is
		variable sign                                 : signed(31 downto 0);
		variable p2x_s, p2y_s, p3x_s, p3y_s, x_s, y_s : signed(15 downto 0);
	begin
		p2x_s := signed(std_logic_vector(p2.x));
		p2y_s := signed(std_logic_vector(p2.y));
		p3x_s := signed(std_logic_vector(p3.x));
		p3y_s := signed(std_logic_vector(p3.y));
		x_s   := signed(std_logic_vector(x));
		y_s   := signed(std_logic_vector(y));

		sign := (x_s - p3x_s) * (p2y_s - p3y_s) - (p2x_s - p3x_s) * (y_s - p3y_s);

		if sign > 0 then
			return '1';
		else
			return '0';
		end if;
	end function;

	type state_type is (
		st_start, st_idle, st_render, st_finished
	);
	signal state, state_next : state_type := st_start;

	signal pixel_out_next : std_logic := '0';
	signal ready_out_next : std_logic := '0';

begin

	triangle_bounding_box       <= get_triangle_bounding_box(triangle_in);
	current_render_bounding_box <= get_triangle_and_tile_intersected_bounding_box(triangle_bounding_box, current_tile_rect_in);

	e0 <= cross_product_sign(cntx, cnty, triangle_in(0), triangle_in(1));
	e1 <= cross_product_sign(cntx, cnty, triangle_in(1), triangle_in(2));
	e2 <= cross_product_sign(cntx, cnty, triangle_in(2), triangle_in(0));

	posx_out <= cntx;
	posy_out <= cnty;

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			pixel_out <= pixel_out_next;
			cntx      <= cntx_next;
			cnty      <= cnty_next;
			ready_out <= ready_out_next;
			state     <= state_next;
		end if;
	end process;

	process(state, cntx, cnty, current_render_bounding_box.x0, current_render_bounding_box.x1, current_render_bounding_box.y0, current_render_bounding_box.y1, e0, e1, e2, pixel_out, ready_out, start_in) is
	begin
		state_next     <= state;
		pixel_out_next <= pixel_out;
		cntx_next      <= cntx;
		cnty_next      <= cnty;
		ready_out_next <= ready_out;

		case state is
			when st_start =>
				pixel_out_next <= '0';
				cntx_next      <= (others => '0');
				cnty_next      <= (others => '0');
				ready_out_next <= '0';
				state_next     <= st_idle;

			when st_idle =>
				ready_out_next <= '0';
				if start_in = '1' then
					cntx_next      <= current_render_bounding_box.x0;
					cnty_next      <= current_render_bounding_box.y0;
					state_next     <= st_render;
				else
					state_next <= st_idle;
				end if;

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

				if e0 = '1' and e1 = '1' and e2 = '1' then
					pixel_out_next <= '1';
				else
					pixel_out_next <= '0';
				end if;

			when st_finished =>
				ready_out_next <= '1';
				pixel_out_next <= '0';
				cntx_next      <= (others => '0');
				cnty_next      <= (others => '0');

				state_next <= st_idle;
		end case;
	end process;

end architecture RTL;
