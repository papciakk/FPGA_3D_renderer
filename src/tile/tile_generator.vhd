library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.renderer_mesh.all;

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
	signal triangle, triangle_next                             : triangle2d_t;
	signal current_triangle_index, current_triangle_index_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal triangle_rendered                     : std_logic;

	signal rand : std_logic_vector(31 downto 0);

	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished, st_idle
	);
	signal state, state_next : state_type := st_start;

begin

	triangle_renderer0 : entity work.renderer_triangle
		port map(
			clk           => tilegen_clk,
			rst           => rst,
			tile_rect_in  => ZERO_TILE_RECT,
			triangle_in   => triangle,
			put_pixel_out => tilegen_enable,
			posx_out      => tilegen_posx_out,
			posy_out      => tilegen_posy_out,
			start_in      => start_rendering,
			ready_out     => triangle_rendered
		);

	random0 : entity work.random
		port map(
			clk  => tilegen_clk,
			rst  => rst,
			rand => rand,
			seed => (others => '0')
		);

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

	process(state, current_triangle_index, triangle_rendered, start_rendering, triangle, rand(15 downto 8), rand(23 downto 16), rand(7 downto 0)) is
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
				tilegen_color_out    <= (r => rand(7 downto 0), g => rand(15 downto 8), b=> rand(23 downto 16));
				state_next           <= st_render_task_wait;

			when st_render_task_wait =>
				start_rendering_next <= '0';

				if triangle_rendered = '1' then
					state_next <= st_finished;
				else
					state_next <= st_render_task_wait;
				end if;

			when st_finished =>
				if current_triangle_index = (indices'length - 1) then
					state_next <= st_idle;
				else
					current_triangle_index_next <= current_triangle_index + 1;
					start_rendering_next        <= '0';
					state_next                  <= st_render_task;

				end if;

			when st_idle =>
				state_next <= st_idle;
		end case;
	end process;

end architecture bahavioral;

