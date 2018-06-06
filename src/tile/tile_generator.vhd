library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity tile_generator is
	port(
		tilegen_clk       : in  std_logic;
		rst               : in  std_logic;
		tilegen_posx_out  : out unsigned(15 downto 0);
		tilegen_posy_out  : out unsigned(15 downto 0);
		tilegen_color_out : out color_t;
		tilegen_enable    : out std_logic
	);
end entity tile_generator;

architecture bahavioral of tile_generator is

	type vertex_arr_t is array (natural range <>) of point2d_t;
	type indices_arr_t is array (natural range <>) of triangle_indices_t;

	constant vertices : vertex_arr_t(0 to 4) := (
		point2d(18, 83),
		point2d(130, 19),
		point2d(170, 120),
		point2d(40, 115),
		point2d(172, 26)
	);

	constant indices : indices_arr_t(0 to 2) := (
		idx(0, 1, 2),
		idx(3, 0, 2),
		idx(2, 1, 4)
	);

	signal triangle, triangle_next                             : triangle2d_t;
	signal current_triangle_index, current_triangle_index_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal triangle_rendered                     : std_logic;

	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished, st_maliny
	);
	signal state, state_next : state_type := st_start;

begin

	triangle_renderer0 : entity work.triangle_renderer
		port map(
			clk                  => tilegen_clk,
			rst                  => rst,
			current_tile_rect_in => ZERO_TILE_RECT,
			triangle_in          => triangle,
			pixel_out            => tilegen_enable,
			posx_out             => tilegen_posx_out,
			posy_out             => tilegen_posy_out,
			start_in             => start_rendering,
			ready_out            => triangle_rendered
		);

	tilegen_color_out <= COLOR_WHITE;

	process(tilegen_clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(tilegen_clk) then
			state                  <= state_next;
			current_triangle_index <= current_triangle_index_next;
			start_rendering        <= start_rendering_next;
			triangle               <= triangle_next;
		end if;
	end process;

	process(state, current_triangle_index, triangle_rendered, start_rendering, triangle) is
	begin
		state_next                  <= state;
		current_triangle_index_next <= current_triangle_index;
		start_rendering_next        <= start_rendering;
		triangle_next               <= triangle;

		case state is
			when st_start =>
				current_triangle_index_next <= 0;
				start_rendering_next        <= '0';
				state_next                  <= st_render_task;

			when st_render_task =>
				start_rendering_next <= '1';
				triangle_next        <= (
					vertices(to_integer(indices(current_triangle_index).a)),
					vertices(to_integer(indices(current_triangle_index).b)),
					vertices(to_integer(indices(current_triangle_index).c))
				);
				state_next           <= st_render_task_wait;

			when st_render_task_wait =>
				start_rendering_next <= '0';

				if triangle_rendered = '1' then
					state_next <= st_finished;
				else
					state_next <= st_render_task_wait;
				end if;

			when st_finished =>
				--				state_next <= st_maliny;
				if current_triangle_index = (indices'length-1) then
					--					current_triangle_index_next <= 0;
					state_next <= st_maliny;
				else
					current_triangle_index_next <= current_triangle_index + 1;
					start_rendering_next        <= '0';
					state_next                  <= st_render_task;

				end if;

			when st_maliny =>
				state_next <= st_maliny;
		end case;
	end process;

end architecture bahavioral;

