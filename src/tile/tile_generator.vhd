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

	constant p : triangle2d_t := (
		point2d(18, 83),
		point2d(500, 18),
		point2d(170, 120)
	);

	signal triangle_rendered : std_logic;
	
	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished
	);
	signal state, state_next : state_type := st_start;

begin

	triangle_renderer0 : entity work.triangle_renderer
		port map(
			clk                  => tilegen_clk,
			rst                  => rst,
			current_tile_rect_in => ZERO_TILE_RECT,
			triangle_in          => p,
			pixel_out            => tilegen_enable,
			posx_out             => tilegen_posx_out,
			posy_out             => tilegen_posy_out,
			start_in             => '1',
			ready_out            => triangle_rendered
		);

	tilegen_color_out <= COLOR_WHITE;
	
	

end architecture bahavioral;
