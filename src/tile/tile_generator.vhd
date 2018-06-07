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

	--	constant vertices : vertex_arr_t(0 to 4) := (
	--		point2d(18, 83),
	--		point2d(130, 19),
	--		point2d(170, 120),
	--		point2d(40, 115),
	--		point2d(172, 26)
	--	);
	--
	--	constant indices : indices_arr_t(0 to 2) := (
	--		idx(1, 0, 2),
	--		idx(3, 0, 2),
	--		idx(1, 2, 4)
	--	);

	--	constant vertices : vertex_arr_t(0 to 7)  := (
	--		point2d(66, 80),
	--		point2d(32, 81),
	--		point2d(80, 110),
	--		point2d(113, 93),
	--		point2d(74, 31),
	--		point2d(40, 32),
	--		point2d(19, 72),
	--		point2d(120, 69)
	--	);
	--	constant indices  : indices_arr_t := (
	--		idx(0, 5, 4),
	--		idx(1, 6, 5),
	--		idx(7, 3, 4),
	--		idx(1, 5, 0),
	--		idx(0, 4, 3),
	--		idx(0, 3, 2),
	--		idx(1, 0, 2)
	--	);

	constant vertices : vertex_arr_t(0 to 67) := (
	point2d(7, 3),
	point2d(7, 42),
	point2d(12, 42),
	point2d(12, 9),
	point2d(15, 3),
	point2d(24, 31),
	point2d(23, 42),
	point2d(26, 36),
	point2d(28, 42),
	point2d(39, 10),
	point2d(28, 30),
	point2d(37, 3),
	point2d(44, 3),
	point2d(44, 42),
	point2d(39, 42),
	point2d(66, 7),
	point2d(54, 42),
	point2d(58, 30),
	point2d(65, 8),
	point2d(65, 10),
	point2d(65, 11),
	point2d(64, 12),
	point2d(78, 42),
	point2d(84, 42),
	point2d(69, 3),
	point2d(74, 30),
	point2d(63, 3),
	point2d(48, 42),
	point2d(66, 8),
	point2d(66, 9),
	point2d(67, 10),
	point2d(67, 12),
	point2d(67, 13),
	point2d(64, 14),
	point2d(64, 13),
	point2d(63, 15),
	point2d(59, 26),
	point2d(72, 26),
	point2d(68, 15),
	point2d(68, 14),
	point2d(99, 22),
	point2d(84, 42),
	point2d(90, 42),
	point2d(100, 29),
	point2d(102, 26),
	point2d(105, 22),
	point2d(118, 3),
	point2d(113, 3),
	point2d(105, 14),
	point2d(105, 14),
	point2d(104, 15),
	point2d(104, 15),
	point2d(103, 16),
	point2d(103, 17),
	point2d(113, 42),
	point2d(120, 42),
	point2d(104, 28),
	point2d(92, 3),
	point2d(86, 3),
	point2d(99, 13),
	point2d(100, 14),
	point2d(100, 15),
	point2d(101, 16),
	point2d(101, 16),
	point2d(102, 17),
	point2d(103, 17),
	point2d(102, 17),
	point2d(102, 18)
);
constant indices : indices_arr_t(0 to 63) := (
	idx(0, 1, 2),
	idx(0, 2, 3),
	idx(4, 0, 3),
	idx(5, 4, 3),
	idx(5, 3, 6),
	idx(7, 5, 6),
	idx(7, 6, 8),
	idx(7, 8, 9),
	idx(10, 7, 9),
	idx(11, 10, 9),
	idx(12, 11, 9),
	idx(13, 12, 9),
	idx(13, 9, 14),
	idx(15, 16, 17),
	idx(18, 15, 17),
	idx(19, 18, 17),
	idx(20, 19, 17),
	idx(21, 20, 17),
	idx(22, 23, 24),
	idx(25, 22, 24),
	idx(26, 27, 16),
	idx(26, 16, 15),
	idx(24, 26, 15),
	idx(25, 24, 15),
	idx(25, 15, 28),
	idx(25, 28, 29),
	idx(25, 29, 30),
	idx(25, 30, 31),
	idx(25, 31, 32),
	idx(33, 34, 21),
	idx(35, 33, 21),
	idx(36, 35, 21),
	idx(36, 21, 17),
	idx(36, 17, 25),
	idx(37, 36, 25),
	idx(38, 37, 25),
	idx(38, 25, 32),
	idx(39, 38, 32),
	idx(40, 41, 42),
	idx(40, 42, 43),
	idx(40, 43, 44),
	idx(45, 46, 47),
	idx(45, 47, 48),
	idx(45, 48, 49),
	idx(45, 49, 50),
	idx(45, 50, 51),
	idx(45, 51, 52),
	idx(45, 52, 53),
	idx(54, 55, 45),
	idx(56, 54, 45),
	idx(44, 56, 45),
	idx(57, 58, 40),
	idx(59, 57, 40),
	idx(60, 59, 40),
	idx(61, 60, 40),
	idx(62, 61, 40),
	idx(63, 62, 40),
	idx(64, 63, 40),
	idx(45, 53, 65),
	idx(66, 64, 40),
	idx(67, 66, 40),
	idx(45, 65, 67),
	idx(40, 44, 45),
	idx(67, 40, 45)
);
	signal triangle, triangle_next                             : triangle2d_t;
	signal current_triangle_index, current_triangle_index_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal triangle_rendered                     : std_logic;

	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished, st_idle
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
				if current_triangle_index = (indices'length - 1) then
					--					current_triangle_index_next <= 0;
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

