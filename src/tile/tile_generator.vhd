library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.renderer_mesh.all;

entity tile_generator is
	port(
		clk                   : in  std_logic;
		rst                   : in  std_logic;
		trianglegen_posx_out  : out unsigned(15 downto 0);
		trianglegen_posy_out  : out unsigned(15 downto 0);
		trianglegen_put_pixel : out std_logic;
		color_out             : out color_t;
		tile_rect_in          : in  rect_t;
		start_in              : in  std_logic;
		ready_out             : out std_logic
	);
end entity tile_generator;

architecture bahavioral of tile_generator is
	signal trianglegen_triangle, triangle_next                 : triangle2d_t;
	signal current_triangle_index, current_triangle_index_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal trianglegen_ready                     : std_logic;

	signal ready_out_next : std_logic;

	signal rand : std_logic_vector(31 downto 0);

	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished, st_idle
	);
	signal state, state_next : state_type := st_start;

begin

	triangle_renderer0 : entity work.renderer_triangle
		port map(
			clk           => clk,
			rst           => rst,
			tile_rect_in  => tile_rect_in,
			triangle_in   => trianglegen_triangle,
			put_pixel_out => trianglegen_put_pixel,
			posx_out      => trianglegen_posx_out,
			posy_out      => trianglegen_posy_out,
			start_in      => start_rendering,
			ready_out     => trianglegen_ready
		);

	random0 : entity work.random
		port map(
			clk  => clk,
			rst  => rst,
			rand => rand,
			seed => (others => '0')
		);

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			state                  <= state_next;
			current_triangle_index <= current_triangle_index_next;
			start_rendering        <= start_rendering_next;
			trianglegen_triangle   <= triangle_next;
			ready_out              <= ready_out_next;
		end if;
	end process;

	process(state, current_triangle_index, trianglegen_ready, start_rendering, trianglegen_triangle, rand(15 downto 8), rand(23 downto 16), rand(7 downto 0), start_in, ready_out) is
	begin
		state_next                  <= state;
		current_triangle_index_next <= current_triangle_index;
		start_rendering_next        <= start_rendering;
		triangle_next               <= trianglegen_triangle;
		ready_out_next              <= ready_out;

		case state is
			when st_start =>
				ready_out_next              <= '0';
				current_triangle_index_next <= 0;
				start_rendering_next        <= '0';
				state_next                  <= st_idle;

			when st_render_task =>
				ready_out_next       <= '0';
				start_rendering_next <= '1';
				triangle_next        <= (
					vertices(to_integer(indices(current_triangle_index).a)),
					vertices(to_integer(indices(current_triangle_index).b)),
					vertices(to_integer(indices(current_triangle_index).c))
				);

				color_out <= (r => rand(7 downto 0), g => rand(15 downto 8), b => rand(23 downto 16));

				state_next <= st_render_task_wait;

			when st_render_task_wait =>
				ready_out_next       <= '0';
				start_rendering_next <= '0';

				if trianglegen_ready = '1' then
					state_next <= st_finished;
				else
					state_next <= st_render_task_wait;
				end if;

			when st_finished =>
				if current_triangle_index < indices'length then
					current_triangle_index_next <= current_triangle_index + 1;
					start_rendering_next        <= '0';
					state_next                  <= st_render_task;
				else
					ready_out_next <= '1';
					state_next     <= st_start;
				end if;

			when st_idle =>
				ready_out_next <= '0';
				if start_in = '1' then
					ready_out_next              <= '0';
					current_triangle_index_next <= 0;
					state_next                  <= st_render_task;
				else
					state_next <= st_idle;
				end if;
		end case;
	end process;

end architecture bahavioral;

