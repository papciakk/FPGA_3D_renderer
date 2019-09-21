library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.all;
use work.fb_types.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.keyboard_inc.all;
use work.tiles.all;

entity snf0 is
	port(
		CLK_50       : in    std_logic;
		--		CLK_50_2       : in    std_logic;
		PS2_CLK      : inout std_logic;
		PS2_DATA     : inout std_logic;
		--		UART_RXD     : in    std_logic;
		UART_TXD     : out   std_logic;
		--		SRAM_CLK       : out   std_logic;
		--		SRAM_ADDR      : out   std_logic_vector(18 downto 0);
		--		SRAM_DQ        : inout std_logic_vector(31 downto 0);
		--		SRAM_PAR       : inout std_logic_vector(3 downto 0);
		--		SRAM_MODE      : out   std_logic;
		--		SRAM_ADSC_n    : out   std_logic;
		--		SRAM_ADSP_n    : out   std_logic;
		--		SRAM_ADV_n     : out   std_logic;
		--		SRAM_BWE_n     : out   std_logic;
		--		SRAM_CE2_n     : out   std_logic;
		--		SRAM_CE_n      : out   std_logic;
		--		SRAM_OE_n      : out   std_logic;
		--		SRAM_ZZ        : out   std_logic;
		--		VGA1_PIXEL_CLK : in    std_logic;
		VGA1_CS_n    : out   std_logic;
		VGA1_DC_n    : out   std_logic;
		VGA1_RD_n    : out   std_logic;
		VGA1_WR_n    : out   std_logic;
		VGA1_RESET_n : out   std_logic;
		--		VGA1_TE        : in    std_logic;
		VGA1_R       : inout slv8_t;
		VGA1_G       : out   slv8_t;
		VGA1_B       : out   slv8_t;
		--		VGA2_R         : out   std_logic;
		--		VGA2_G         : out   std_logic;
		--		VGA2_B         : out   std_logic;
		--		VGA2_VSync     : out   std_logic;
		--		VGA2_HSync     : out   std_logic;
		BTN          : in    std_logic_vector(1 downto 0);
		LED          : out   std_logic_vector(2 downto 0)
		--		GPIO           : inout std_logic_vector(0 to 3);
		--		GPI            : in    std_logic_vector(0 to 7)
	);

end snf0;

architecture behavioral of snf0 is

	type state_tile_type is (
		st_start,
		st_idle, st_check_requests,
		st_next_tile,
		st_wait_for_workers
	);
	signal state_tile, state_tile_next : state_tile_type := st_start;

	type state_screen_type is (
		st_start, st_wait_for_framebuffer_init,
		st_idle, st_check_requests,
		st_screen_write, st_screen_wait
	);
	signal state_screen, state_screen_next : state_screen_type;

	signal main_clk           : std_logic;
	signal fb_initializer_clk : std_logic;
	signal display_clk        : std_logic;

	signal rst        : std_logic;
	signal pll_locked : std_logic;

	signal tile_num : integer := 0;

	-----------------------------------------

	signal framebuffer_initialized                       : std_logic := '0';
	signal fb_disp_window_rect, fb_disp_window_rect_next : rect_t;

	-----------------------------------------

	signal input_clk : std_logic := '0';
	signal key       : keys_t;
	signal rot       : point3d_t;
	signal rot_light : point2d_t;
	signal scale     : int16_t;

	signal tile_num_next : integer;

	signal led_blink : std_logic;

	signal fb_disp_start_write, fb_disp_start_write_next : std_logic;
	signal fb_disp_write_done                            : std_logic;
	signal posx_out, posy_out                            : uint16_t;
	signal color_in                                      : color_t;

	---------------------------------------------

	type color_arr_t is array (natural range <>) of color_t;
	type rect_arr_t is array (natural range <>) of rect_t;
	type int_arr_t is array (natural range <>) of integer;

	signal screen_request_p                                                    : std_logic_vector(num_processes - 1 downto 0);
	signal screen_request_ready_p, screen_request_ready_p_next                 : std_logic_vector(num_processes - 1 downto 0);
	signal color_in_p                                                          : color_arr_t(num_processes - 1 downto 0);
	signal tile_num_request_p                                                  : std_logic_vector(num_processes - 1 downto 0);
	signal tile_num_ready_p, tile_num_ready_p_next                             : std_logic_vector(num_processes - 1 downto 0) := (others => '0');
	signal screen_ready_p, screen_ready_p_next                                 : std_logic_vector(num_processes - 1 downto 0) := (others => '0');
	signal rects_p                                                             : rect_arr_t(num_processes - 1 downto 0);
	signal current_displaying_renderer_id, current_displaying_renderer_id_next : integer;
	signal tile_num_out_p, tile_num_out_p_next                                 : int_arr_t(num_processes - 1 downto 0);
	signal working_p                                                           : std_logic_vector(num_processes - 1 downto 0);

	signal tile_request_counter, tile_request_counter_next : integer             := 0;
	signal bg_colors_p                                     : color_arr_t(0 to 5) := (COLOR_BLUE, COLOR_GREEN, COLOR_RED, COLOR_YELLOW, COLOR_MAGENTA, COLOR_CYAN);

	signal start_mesh_renderer, start_mesh_renderer_next : std_logic := '0';

	signal request_counter, request_counter_next : integer;

	signal measurement_step        : std_logic;
	signal measurement_value       : integer;
	signal measurement_value_ready : std_logic;

begin

	pll0 : entity work.pll
		port map(
			areset => rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => main_clk,
			c2     => display_clk,
			locked => pll_locked
		);

	mesh_renderer_processes : for i in 0 to num_processes - 1 generate
	begin
		mesh_renderer : entity work.mesh_renderer
			port map(
				clk                     => main_clk,
				screen_clk              => display_clk,
				rst                     => rst,
				-------------------------------
				start_in                => start_mesh_renderer,
				get_rect                => rects_p(i),
				-------------------------------
				bg_color_in             => bg_colors_p(i),
				-------------------------------
				screen_request_out      => screen_request_p(i),
				screen_request_ready_in => screen_request_ready_p(i),
				screen_ready_in         => screen_ready_p(i),
				screen_posx_in          => posx_out,
				screen_posy_in          => posy_out,
				screen_pixel_color_out  => color_in_p(i),
				-------------------------------
				task_request_out        => tile_num_request_p(i),
				task_ready_in           => tile_num_ready_p(i),
				task_tile_num_in        => tile_num_out_p(i),
				working_out             => working_p(i),
				-------------------------------
				rot_in                  => rot,
				rot_light_in            => rot_light,
				scale_in                => scale
			);
	end generate;

	framebuffer_driver0 : entity work.fb_driver
		port map(
			display_clk     => display_clk,
			initializer_clk => fb_initializer_clk,
			rst             => rst,
			-------------------------------
			start_write     => fb_disp_start_write,
			write_done      => fb_disp_write_done,
			-------------------------------
			posx_out        => posx_out,
			posy_out        => posy_out,
			color_in        => color_in,
			fb_window_in    => fb_disp_window_rect,
			-------------------------------
			initialize      => pll_locked,
			initialized     => framebuffer_initialized,
			-------------------------------
			VGA1_CS_n       => VGA1_CS_n,
			VGA1_DC_n       => VGA1_DC_n,
			VGA1_RD_n       => VGA1_RD_n,
			VGA1_WR_n       => VGA1_WR_n,
			VGA1_RESET_n    => VGA1_RESET_n,
			VGA1_R          => VGA1_R,
			VGA1_G          => VGA1_G,
			VGA1_B          => VGA1_B
		);

	led_blinker0 : entity work.led_blinker
		generic map(
			frequency => 2.0            -- Hz
		)
		port map(
			clk50 => CLK_50,
			rst   => rst,
			led   => led_blink
		);

	measurement0 : entity work.continous_measurement
		port map(
			clk         => main_clk,
			rst         => rst,
			step        => measurement_step,
			value       => measurement_value,
			value_ready => measurement_value_ready
		);

	pritf0 : entity work.printf
		port map(
			clk      => CLK_50,
			rst      => rst,
			uart_txd => UART_TXD,
			send     => measurement_value_ready,
			val      => measurement_value
		);

	keyboard_inputs_0 : entity work.keyboard_inputs
		port map(
			clk      => CLK_50,
			rst      => rst,
			ps2_clk  => PS2_CLK,
			ps2_data => PS2_DATA,
			keys     => key
		);

	input_handler_0 : entity work.input_handler
		generic map(
			rot_init       => point3d(0, 0, 0),
			rot_light_init => point2d(0, 0),
			scale_init     => int16(256)
		)
		port map(
			input_clk => input_clk,
			rst       => rst,
			keys      => key,
			rot       => rot,
			rot_light => rot_light,
			scale     => scale
		);

	LED(0) <= rst;
	LED(1) <= led_blink;

	rst <= not BTN(0);

	color_in <= color_in_p(current_displaying_renderer_id);

	process(display_clk, rst) is
	begin
		if rst then
			state_screen <= st_start;
		elsif rising_edge(display_clk) then
			fb_disp_window_rect            <= fb_disp_window_rect_next;
			screen_ready_p                 <= screen_ready_p_next;
			screen_request_ready_p         <= screen_request_ready_p_next;
			fb_disp_start_write            <= fb_disp_start_write_next;
			state_screen                   <= state_screen_next;
			current_displaying_renderer_id <= current_displaying_renderer_id_next;
			start_mesh_renderer            <= start_mesh_renderer_next;
			request_counter                <= request_counter_next;
		end if;
	end process;

	process(all) is
	begin
		fb_disp_window_rect_next            <= fb_disp_window_rect;
		screen_ready_p_next                 <= screen_ready_p;
		screen_request_ready_p_next         <= screen_request_ready_p;
		fb_disp_start_write_next            <= fb_disp_start_write;
		state_screen_next                   <= state_screen;
		current_displaying_renderer_id_next <= current_displaying_renderer_id;
		start_mesh_renderer_next            <= start_mesh_renderer;
		request_counter_next                <= request_counter;

		case state_screen is

			when st_start =>
				screen_ready_p_next                 <= (others => '0');
				screen_request_ready_p_next         <= (others => '0');
				fb_disp_start_write_next            <= '0';
				state_screen_next                   <= st_wait_for_framebuffer_init;
				current_displaying_renderer_id_next <= 0;
				start_mesh_renderer_next            <= '0';
				request_counter_next                <= 0;

			when st_wait_for_framebuffer_init =>
				if framebuffer_initialized then
					start_mesh_renderer_next <= '1';
					state_screen_next        <= st_idle;
				else
					state_screen_next <= st_wait_for_framebuffer_init;
				end if;

			when st_idle =>
				request_counter_next <= 1;

				screen_ready_p_next         <= (others => '0');
				screen_request_ready_p_next <= (others => '0');

				if screen_request_p(0) then
					current_displaying_renderer_id_next <= 0;
					screen_request_ready_p_next(0)      <= '1';
					state_screen_next                   <= st_screen_write;
				else
					state_screen_next <= st_check_requests;
				end if;

			when st_check_requests =>
				if request_counter < num_processes then
					request_counter_next <= request_counter + 1;
					if screen_request_p(request_counter) then
						current_displaying_renderer_id_next          <= request_counter;
						screen_request_ready_p_next(request_counter) <= '1';
						state_screen_next                            <= st_screen_write;
					else
						state_screen_next <= st_check_requests;
					end if;
				else
					request_counter_next <= 0;
					state_screen_next    <= st_idle;
				end if;

			when st_screen_write =>
				fb_disp_start_write_next    <= '1';
				screen_ready_p_next         <= (others => '0');
				screen_request_ready_p_next <= (others => '0');
				fb_disp_window_rect_next    <= rects_p(current_displaying_renderer_id);
				state_screen_next           <= st_screen_wait;

			when st_screen_wait =>
				fb_disp_start_write_next <= '0';
				if fb_disp_write_done then
					screen_ready_p_next(current_displaying_renderer_id) <= '1';
					state_screen_next                                   <= st_idle;
				else
					state_screen_next <= st_screen_wait;
				end if;

		end case;

	end process;

	process(main_clk, rst) is
	begin
		if rst then
			state_tile <= st_start;
		elsif rising_edge(main_clk) then
			tile_num             <= tile_num_next;
			tile_num_ready_p     <= tile_num_ready_p_next;
			tile_num_out_p       <= tile_num_out_p_next;
			state_tile           <= state_tile_next;
			tile_request_counter <= tile_request_counter_next;
		end if;
	end process;

	process(all) is
	begin
		tile_num_next             <= tile_num;
		tile_num_ready_p_next     <= tile_num_ready_p;
		tile_num_out_p_next       <= tile_num_out_p;
		state_tile_next           <= state_tile;
		tile_request_counter_next <= tile_request_counter;
		case state_tile is

			when st_start =>
				measurement_step      <= '0';
				tile_num_next         <= 0;
				tile_num_ready_p_next <= (others => '0');
				tile_num_out_p_next   <= (others => 0);
				state_tile_next       <= st_idle;
				input_clk <= '0';

			when st_idle =>
				measurement_step          <= '0';
				tile_request_counter_next <= 1;

				if tile_num_request_p(0) then
					tile_num_out_p_next(0)   <= tile_num;
					tile_num_ready_p_next(0) <= '1';
					state_tile_next          <= st_next_tile;
				else
					state_tile_next <= st_check_requests;
				end if;

			when st_check_requests =>
				measurement_step <= '0';
				if tile_request_counter < num_processes then
					tile_request_counter_next <= tile_request_counter + 1;
					if tile_num_request_p(tile_request_counter) then
						tile_num_out_p_next(tile_request_counter)   <= tile_num;
						tile_num_ready_p_next(tile_request_counter) <= '1';
						state_tile_next                             <= st_next_tile;
					else
						state_tile_next <= st_check_requests;
					end if;
				else
					tile_request_counter_next <= 0;
					tile_num_ready_p_next     <= (others => '0');
					state_tile_next           <= st_idle;
				end if;

			when st_next_tile =>
				measurement_step      <= '0';
				tile_num_ready_p_next <= (others => '0');
				if tile_num < TILES_CNT then
					tile_num_next   <= tile_num + 1;
					state_tile_next <= st_idle;
				else
					if or_reduce(working_p) then
						state_tile_next <= st_wait_for_workers;
					else						
						tile_num_next   <= 0;
						state_tile_next <= st_idle;
						input_clk <= '1';
						measurement_step <= '1';
					end if;
				end if;

			when st_wait_for_workers =>
				input_clk <= '0';
				measurement_step <= '0';
				if or_reduce(working_p) then
					state_tile_next <= st_wait_for_workers;
				else
					state_tile_next <= st_next_tile;
				end if;

		end case;
	end process;

end architecture;
