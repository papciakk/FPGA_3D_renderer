library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.tiles.all;
use work.digits.all;

entity mesh_renderer is
	port(
		clk                     : in  std_logic;
		screen_clk              : in  std_logic;
		rst                     : in  std_logic;
		--------------------------------------------
		start_in                : in  std_logic;
		working_out             : out std_logic;
		--------------------------------------------
		rot_in                  : in  point3d_t;
		rot_light_in            : in  point2d_t;
		scale_in                : in  int16_t;
		bg_color_in             : in  color_t;
		--------------------------------------------
		screen_request_out      : out std_logic;
		screen_request_ready_in : in  std_logic;
		screen_ready_in         : in  std_logic;
		screen_posx_in          : in  uint16_t;
		screen_posy_in          : in  uint16_t;
		screen_pixel_color_out  : out color_t;
		--------------------------------------------
		get_rect                : out rect_t;
		task_request_out        : out std_logic;
		task_ready_in           : in  std_logic;
		task_tile_num_in        : in  integer;
		--------------------------------------------
		overlay_num             : in  num_array_t
	);
end entity mesh_renderer;

architecture rtl of mesh_renderer is

	type state_type is (
		st_start, st_idle, st_render_tile, st_render_tile_wait
	);
	signal state, state_next : state_type := st_start;

	type drawing_state_type is (
		st_start, st_wait_for_start, st_tilegen_clear, st_tilegen_clear_wait, st_start_generate_tile, st_generate_tile_wait, st_wait_for_screen_request, st_wait_for_copy_to_screen, st_get_tile_wait,
		st_show_overlay, st_show_overlay_loop
	);
	signal state_drawing : drawing_state_type := st_start;

	signal start_rendering_tile, start_rendering_tile_next : std_logic := '0';
	signal tile_rendered                                   : std_logic;

	signal untransposed_posx, untransposed_posy : uint16_t;

	signal current_tile_rect  : rect_t;
	signal tilegen_ready_next : std_logic;

	signal posx, posx_draw, posx_overlay, posx_overlay_cnt, posx_overlay_next, posx_overlay_cnt_next : uint16_t;
	signal posy, posy_draw, posy_overlay, posy_overlay_cnt, posy_overlay_next, posy_overlay_cnt_next : uint16_t;
	signal put_pixel, put_pixel_draw, put_pixel_overlay, put_pixel_overlay_next                      : std_logic;
	signal color, color_draw, color_overlay, color_overlay_next                                      : color_t;
	signal depth_in                                                                                  : int16_t;
	signal depth_out                                                                                 : int16_t;
	signal depth_wren                                                                                : std_logic;

	signal tilegen_start      : std_logic := '0';
	signal tilegen_ready      : std_logic;
	signal tilebuf_clear      : std_logic := '0';
	signal tilebuf_clear_done : std_logic;
	signal current_tile       : integer   := 0;
	signal clear_color        : color_t;

	signal current_tile_rect_attr : rect_attr_t;

	signal screen_request_out_next     : std_logic;
	signal task_request_out_next       : std_logic;
	signal state_drawing_next          : drawing_state_type;
	signal tilebuf_clear_next          : std_logic;
	signal clear_color_next            : color_t;
	signal tilegen_start_next          : std_logic;
	signal current_tile_rect_next      : rect_t;
	signal current_tile_next           : integer;
	signal current_tile_rect_attr_next : rect_attr_t;
	signal working_out_next            : std_logic;

	signal show_overlay                                              : std_logic := '0';
	signal overlay_show_second_digit, overlay_show_second_digit_next : std_logic := '0';
begin
	get_rect <= current_tile_rect;

	posx      <= posx_draw when show_overlay = '0' else posx_overlay;
	posy      <= posy_draw when show_overlay = '0' else posy_overlay;
	put_pixel <= put_pixel_draw when show_overlay = '0' else put_pixel_overlay;
	color     <= color_draw when show_overlay = '0' else color_overlay;

	tile_buffer0 : entity work.tile_buffer
		port map(
			rst               => rst,
			--------------------------------------------
			screen_clk        => screen_clk,
			screen_posx       => screen_posx_in,
			screen_posy       => screen_posy_in,
			color_out         => screen_pixel_color_out,
			--------------------------------------------
			tilegen_clk       => clk,
			tilegen_posx      => posx,
			tilegen_posy      => posy,
			tilegen_put_pixel => put_pixel,
			color_in          => color,
			--------------------------------------------
			clear             => tilebuf_clear,
			clear_done        => tilebuf_clear_done,
			clear_color       => clear_color,
			--------------------------------------------
			depth_in          => depth_in,
			depth_out         => depth_out,
			depth_wren        => depth_wren
		);

	tile_renderer0 : entity work.tile_renderer
		port map(
			clk                => clk,
			rst                => rst,
			--------------------------------------------
			posx_out           => untransposed_posx,
			posy_out           => untransposed_posy,
			put_pixel_out      => put_pixel_draw,
			pixel_color_out    => color_draw,
			--------------------------------------------
			start_in           => start_rendering_tile,
			ready_out          => tile_rendered,
			--------------------------------------------
			tile_rect_in       => current_tile_rect,
			--------------------------------------------
			depth_buf_read_out => depth_in,
			depth_buf_write_in => depth_out,
			depth_wren_out     => depth_wren,
			--------------------------------------------
			rot_in             => rot_in,
			rot_light_in       => rot_light_in,
			scale_in           => scale_in
		);

	posx_draw <= untransposed_posx - current_tile_rect.x0;
	posy_draw <= untransposed_posy - current_tile_rect.y0;

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

	show_overlay <= '1' when current_tile = 0 else '0';

	process(clk, rst) is
	begin
		if rst then
			state_drawing <= st_start;
		elsif rising_edge(clk) then
			screen_request_out     <= screen_request_out_next;
			task_request_out       <= task_request_out_next;
			state_drawing          <= state_drawing_next;
			tilebuf_clear          <= tilebuf_clear_next;
			clear_color            <= clear_color_next;
			tilegen_start          <= tilegen_start_next;
			current_tile_rect      <= current_tile_rect_next;
			current_tile           <= current_tile_next;
			current_tile_rect_attr <= current_tile_rect_attr_next;
			working_out            <= working_out_next;

			posx_overlay              <= posx_overlay_next;
			posy_overlay              <= posy_overlay_next;
			posx_overlay_cnt          <= posx_overlay_cnt_next;
			posy_overlay_cnt          <= posy_overlay_cnt_next;
			color_overlay             <= color_overlay_next;
			put_pixel_overlay         <= put_pixel_overlay_next;
			overlay_show_second_digit <= overlay_show_second_digit_next;
		end if;
	end process;

	process(all) is
	begin
		screen_request_out_next     <= screen_request_out;
		task_request_out_next       <= task_request_out;
		state_drawing_next          <= state_drawing;
		tilebuf_clear_next          <= tilebuf_clear;
		clear_color_next            <= clear_color;
		tilegen_start_next          <= tilegen_start;
		current_tile_rect_next      <= current_tile_rect;
		current_tile_next           <= current_tile;
		current_tile_rect_attr_next <= current_tile_rect_attr;
		working_out_next            <= working_out;

		posx_overlay_next              <= posx_overlay;
		posy_overlay_next              <= posy_overlay;
		posx_overlay_cnt_next          <= posx_overlay_cnt;
		posy_overlay_cnt_next          <= posy_overlay_cnt;
		color_overlay_next             <= color_overlay;
		put_pixel_overlay_next         <= put_pixel_overlay;
		overlay_show_second_digit_next <= overlay_show_second_digit;

		case state_drawing is

			when st_start =>
				screen_request_out_next <= '0';
				tilegen_start_next      <= '0';
				current_tile_rect_next  <= tile_rects(0).rect;
				task_request_out_next   <= '0';
				state_drawing_next      <= st_wait_for_start;
				working_out_next        <= '0';

			when st_wait_for_start =>
				if start_in then
					task_request_out_next <= '1';
					state_drawing_next    <= st_get_tile_wait;
				else
					state_drawing_next <= st_wait_for_start;
				end if;

			-- CLEAR ON-CHIP BUFFERS

			when st_tilegen_clear =>
				tilebuf_clear_next <= '1';
				--if (current_tile_rect_attr.y(0) = '0' and current_tile_rect_attr.x(0) = '0') or (current_tile_rect_attr.y(0) = '1' and current_tile_rect_attr.x(0) = '1') then
				--clear_color   <= COLOR_BLACK;
				--else
				--clear_color   <= COLOR_RED;
				clear_color_next   <= bg_color_in;
				--end if;
				state_drawing_next <= st_tilegen_clear_wait;

			when st_tilegen_clear_wait =>
				tilebuf_clear_next <= '0';
				if tilebuf_clear_done then
					state_drawing_next <= st_start_generate_tile;
				else
					state_drawing_next <= st_tilegen_clear_wait;
				end if;

			-- GENERATE TILE

			when st_start_generate_tile =>
				tilegen_start_next <= '1';
				state_drawing_next <= st_generate_tile_wait;

			when st_generate_tile_wait =>
				tilegen_start_next <= '0';
				if tilegen_ready then
					if show_overlay then
						state_drawing_next <= st_show_overlay;
					else
						screen_request_out_next <= '1';
						state_drawing_next      <= st_wait_for_screen_request;
					end if;
				else
					state_drawing_next <= st_generate_tile_wait;
				end if;

			when st_show_overlay =>
				posx_overlay_next      <= (others => '0');
				posy_overlay_next      <= (others => '0');
				posx_overlay_cnt_next  <= (others => '0');
				posy_overlay_cnt_next  <= (others => '0');
				color_overlay_next     <= (r => slv8(255), others => slv8(0));
				put_pixel_overlay_next <= '0';

				state_drawing_next <= st_show_overlay_loop;

			when st_show_overlay_loop =>
				put_pixel_overlay_next <= '0';

				if posy_overlay_cnt < 16 then
					if posx_overlay_cnt < 16 then
						if overlay_show_second_digit then
							posx_overlay_next <= posx_overlay_cnt + 8 + 16;
						else
							posx_overlay_next <= posx_overlay_cnt + 8;
						end if;
						posy_overlay_next     <= posy_overlay_cnt + 8;
						
						posx_overlay_cnt_next <= posx_overlay_cnt + 1;

						if overlay_show_second_digit then
							if digit_lut(to_integer(overlay_num(0)))(to_integer(posy_overlay_cnt * 16 + posx_overlay_cnt)) = '1' then
								put_pixel_overlay_next <= '1';
							end if;
						else
							if digit_lut(to_integer(overlay_num(1)))(to_integer(posy_overlay_cnt * 16 + posx_overlay_cnt)) = '1' then
								put_pixel_overlay_next <= '1';
							end if;
						end if;

						state_drawing_next <= st_show_overlay_loop;
					else
						posx_overlay_cnt_next <= (others => '0');
						posy_overlay_cnt_next <= posy_overlay_cnt + 1;

						state_drawing_next <= st_show_overlay_loop;
					end if;
				else
					screen_request_out_next <= '1';
					if overlay_show_second_digit = '0' then
						overlay_show_second_digit_next <= '1';
						state_drawing_next             <= st_show_overlay;
					else
						overlay_show_second_digit_next <= '0';
						state_drawing_next             <= st_wait_for_screen_request;
					end if;

				end if;

			when st_wait_for_screen_request =>
				if screen_request_ready_in then
					screen_request_out_next <= '0';
					state_drawing_next      <= st_wait_for_copy_to_screen;
				else
					state_drawing_next <= st_wait_for_screen_request;
				end if;

			when st_wait_for_copy_to_screen =>
				if screen_ready_in then
					working_out_next      <= '0';
					task_request_out_next <= '1';
					state_drawing_next    <= st_get_tile_wait;
				else
					state_drawing_next <= st_wait_for_copy_to_screen;
				end if;

			-- GET NEW TASK

			when st_get_tile_wait =>
				if task_ready_in then
					task_request_out_next       <= '0';
					current_tile_next           <= task_tile_num_in;
					current_tile_rect_attr_next <= tile_rects(task_tile_num_in);
					current_tile_rect_next      <= tile_rects(task_tile_num_in).rect;
					state_drawing_next          <= st_tilegen_clear;
					working_out_next            <= '1';
				else
					state_drawing_next <= st_get_tile_wait;
				end if;

		end case;
	end process;

end architecture rtl;

