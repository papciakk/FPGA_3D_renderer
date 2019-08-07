library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.tiles.all;

entity mesh_renderer is
	port(
		clk                : in  std_logic;
		rst                : in  std_logic;
		---------------------------------
		rot                : in  point3d_t;
		scale              : in  int16_t;
		---------------------------------
		screen_ready       : in  std_logic;
		screen_start_write : out std_logic;
		screen_write_done  : in  std_logic;
		screen_rect        : out rect_t;
		screen_posx        : in  uint16_t;
		screen_posy        : in  uint16_t;
		screen_pixel_color : out color_t;
		---------------------------------
		task_request       : out std_logic;
		task_ready         : in  std_logic;
		task_tile_num      : in  integer
	);
end entity mesh_renderer;

architecture rtl of mesh_renderer is

	type state_type is (
		st_start, st_idle, st_render_tile, st_render_tile_wait
	);
	signal state, state_next : state_type := st_start;

	type drawing_state_type is (
		st_start, st_wait_for_framebuffer_init,
		st_tilegen_clear, st_tilegen_clear_wait,
		st_tilegen_start_task, st_tilegen_task_wait,
		st_screen_write, st_screen_wait,
		st_wait_for_framebuffer_free, st_get_tile_wait
	);
	signal state_drawing : drawing_state_type := st_start;

	signal start_rendering_tile, start_rendering_tile_next : std_logic := '0';
	signal tile_rendered                                   : std_logic;

	signal untransposed_posx, untransposed_posy : uint16_t;

	signal current_tile_rect  : rect_t;
	signal tilegen_ready_next : std_logic;

	signal posx       : uint16_t;
	signal posy       : uint16_t;
	signal put_pixel  : std_logic;
	signal color      : color_t;
	signal depth_in   : int16_t;
	signal depth_out  : int16_t;
	signal depth_wren : std_logic;

	signal tilegen_start      : std_logic := '0';
	signal tilegen_ready      : std_logic;
	signal tilebuf_clear      : std_logic := '0';
	signal tilebuf_clear_done : std_logic;
	signal current_tile       : integer   := 0;
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

	tile_renderer0 : entity work.tile_renderer
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

	posx <= untransposed_posx - current_tile_rect.x0 +1;
	posy <= untransposed_posy - current_tile_rect.y0 + 1;

	current_tile_rect <= tile_rects(current_tile);

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			start_rendering_tile <= start_rendering_tile_next;
			tilegen_ready        <= tilegen_ready_next;
			state                <= state_next;
		end if;
	end process;

	process(all) is
	begin
		start_rendering_tile_next <= start_rendering_tile;
		tilegen_ready_next        <= tilegen_ready;
		state_next                <= state;

		case state is
			when st_start =>
				start_rendering_tile_next <= '0';
				tilegen_ready_next        <= '0';
				state_next                <= st_idle;

			when st_idle =>
				start_rendering_tile_next <= '0';

				if tilegen_start then
					state_next <= st_render_tile;
				else
					state_next <= st_idle;
				end if;

			when st_render_tile =>
				tilegen_ready_next        <= '0';
				start_rendering_tile_next <= '1';
				state_next                <= st_render_tile_wait;

			when st_render_tile_wait =>
				start_rendering_tile_next <= '0';
				if tile_rendered then
					tilegen_ready_next <= '1';
					state_next         <= st_start;
				else
					state_next <= st_render_tile_wait;
				end if;

		end case;
	end process;

	process(clk, rst) is
	begin
		if rst then
			state_drawing <= st_start;
		elsif rising_edge(clk) then
			case state_drawing is

				when st_start =>
					screen_start_write <= '0';
					tilegen_start      <= '0';
					state_drawing      <= st_wait_for_framebuffer_init;
					task_request       <= '0';

				when st_wait_for_framebuffer_init =>
					if screen_ready then
						task_request  <= '1';
						state_drawing <= st_get_tile_wait;
					else
						state_drawing <= st_wait_for_framebuffer_init;
					end if;

				-- CLEAR ON-CHIP BUFFERS

				when st_tilegen_clear =>
					tilebuf_clear <= '1';
					state_drawing <= st_tilegen_clear_wait;

				when st_tilegen_clear_wait =>
					tilebuf_clear <= '0';
					if tilebuf_clear_done then
						state_drawing <= st_tilegen_start_task;
					else
						state_drawing <= st_tilegen_clear_wait;
					end if;

				-- GENERATE TILE

				when st_tilegen_start_task =>
					tilegen_start <= '1';
					state_drawing <= st_tilegen_task_wait;

				when st_tilegen_task_wait =>
					tilegen_start <= '0';
					if tilegen_ready then
						state_drawing <= st_wait_for_framebuffer_free;
					else
						state_drawing <= st_tilegen_task_wait;
					end if;

				-- DISPLAY IMAGE

				when st_wait_for_framebuffer_free =>
					if screen_ready then
						state_drawing <= st_screen_write;
					else
						state_drawing <= st_wait_for_framebuffer_free;
					end if;

				when st_screen_write =>
					screen_start_write <= '1';
					screen_rect        <= tile_rects(current_tile);
					state_drawing      <= st_screen_wait;

				when st_screen_wait =>
					screen_start_write <= '0';
					if screen_write_done then
						task_request  <= '1';
						state_drawing <= st_get_tile_wait;
					else
						state_drawing <= st_screen_wait;
					end if;

				-- GET NEW TASK

				when st_get_tile_wait =>
					task_request <= '0';
					if task_ready then
						current_tile  <= task_tile_num;
						state_drawing <= st_tilegen_clear;
					else
						state_drawing <= st_get_tile_wait;
					end if;

			end case;
		end if;
	end process;

end architecture rtl;

