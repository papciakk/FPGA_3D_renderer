library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.tiles.all;

entity tile_system is
	port(
		clk                : in  std_logic;
		rst                : in  std_logic;
		ready_out          : out std_logic;
		start_in           : in  std_logic;
		tile_num_in        : in  integer;
		rot                : in  point3d_t;
		scale              : in  int16_t;
		screen_posx        : in  uint16_t;
		screen_posy        : in  uint16_t;
		screen_pixel_color : out color_t;
		tilebuf_clear      : in  std_logic;
		tilebuf_clear_done : out std_logic
	);
end entity tile_system;

architecture rtl of tile_system is

	signal start_rendering_tile, start_rendering_tile_next : std_logic := '0';
	signal tile_rendered                                   : std_logic;

	signal untransposed_posx, untransposed_posy : uint16_t;

	signal current_tile_rect : rect_t;
	signal ready_out_next    : std_logic;

	type state_type is (
		st_start, st_idle, st_render_tile, st_render_tile_wait
	);
	signal state, state_next : state_type := st_start;
	signal posx              : uint16_t;
	signal posy              : uint16_t;
	signal put_pixel         : std_logic;
	signal color             : color_t;
	signal depth_in          : int16_t;
	signal depth_out         : int16_t;
	signal depth_wren        : std_logic;
begin

	tile_buffer0 : entity work.tile_buffer
		port map(
			screen_clk        => clk,
			screen_posx       => screen_posx,
			screen_posy       => screen_posy,
			color_out         => screen_pixel_color,
			----------
			tilegen_clk       => clk,
			tilegen_posx      => posx,
			tilegen_posy      => posy,
			tilegen_put_pixel => put_pixel,
			color_in          => color,
			----------
			rst               => rst,
			clear             => tilebuf_clear,
			clear_done        => tilebuf_clear_done,
			----------
			depth_in          => depth_in,
			depth_out         => depth_out,
			depth_wren        => depth_wren
		);

	tile_generator0 : entity work.tile_generator
		port map(
			clk                   => clk,
			rst                   => rst,
			trianglegen_posx_out  => untransposed_posx,
			trianglegen_posy_out  => untransposed_posy,
			trianglegen_put_pixel => put_pixel,
			color_out             => color,
			tile_rect_in          => current_tile_rect,
			start_in              => start_rendering_tile,
			ready_out             => tile_rendered,
			depth_in              => depth_in,
			depth_out             => depth_out,
			depth_wren            => depth_wren,
			rot                   => rot,
			scale                 => scale
		);

	posx <= untransposed_posx - current_tile_rect.x0;
	posy <= untransposed_posy - current_tile_rect.y0;

	current_tile_rect <= tile_rects(tile_num_in);

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			start_rendering_tile <= start_rendering_tile_next;
			ready_out            <= ready_out_next;
			state                <= state_next;
		end if;
	end process;

	process(all) is
	begin
		start_rendering_tile_next <= start_rendering_tile;
		ready_out_next            <= ready_out;
		state_next                <= state;

		case state is
			when st_start =>
				start_rendering_tile_next <= '0';
				ready_out_next            <= '0';
				state_next                <= st_idle;

			when st_idle =>
				start_rendering_tile_next <= '0';

				if start_in then
					state_next <= st_render_tile;
				else
					state_next <= st_idle;
				end if;

			when st_render_tile =>
				ready_out_next            <= '0';
				start_rendering_tile_next <= '1';
				state_next                <= st_render_tile_wait;

			when st_render_tile_wait =>
				start_rendering_tile_next <= '0';
				if tile_rendered then
					ready_out_next <= '1';
					state_next     <= st_start;
				else
					state_next <= st_render_tile_wait;
				end if;

		end case;
	end process;

end architecture rtl;

