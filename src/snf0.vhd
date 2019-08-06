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

	type fsm_state_type is (
		st_idle,
		st_start,
		st_fb_init, st_fb_init_wait);
	signal state_init : fsm_state_type := st_start;

	type drawing_state_type is (
		st_start,
		st_wait_for_framebuffer,
		st_screen_write,
		st_tilegen_start_task, st_tilegen_task_wait,
		st_display_clear, st_display_clear_wait,
		st_screen_wait,
		st_tilegen_clear, st_tilegen_clear_wait,
		st_wait, st_get_tile_wait
	);
	signal state_drawing : drawing_state_type := st_start;
	
	type state_tile_type is (
		st_start,
		st_idle,
		st_next_tile
	);
	signal state_tile : state_tile_type := st_start;

	----------------------------------------

	signal rst : std_logic;

	----------------------------------------

	signal fb_initializer_enabled : std_logic := '1';

	signal fb_clk        : std_logic;
	signal fb_data_write : slv8_t;
	signal fb_op_start   : std_logic;
	signal fb_op         : fb_lo_level_op_type;
	signal fb_op_done    : std_logic;

	signal fb_initializer_clk        : std_logic;
	signal fb_initializer_data_write : slv8_t;
	signal fb_initializer_op_start   : std_logic;
	signal fb_initializer_op         : fb_lo_level_op_type;

	signal main_clk           : std_logic;
	signal fb_disp_data_write : slv8_t;
	signal fb_disp_op_start   : std_logic;
	signal fb_disp_op         : fb_lo_level_op_type;

	-- framebuffer display clear signals
	signal fb_disp_clear       : std_logic := '0';
	signal fb_disp_clear_color : color_t   := (others => X"00");

	-- framebuffer display write control
	signal fb_disp_start_write : std_logic := '0';
	signal fb_disp_write_done  : std_logic;

	-- framebuffer display out position, color input and window
	signal screen_posx        : uint16_t;
	signal screen_posy        : uint16_t;
	signal screen_pixel_color : color_t;

	signal fb_disp_window_rect : rect_t := FULLSCREEN_RECT;
	----------------------

	----------------------------------------

	signal fb_data_read : slv8_t;

	signal fb_init_start : std_logic := '0';
	signal fb_init_done  : std_logic;

	-----------------------------------------
	signal tilegen_ready       : std_logic;
	signal tilegen_start       : std_logic := '0';
	signal tile_num : integer   := 0;

	-----------------------------------------
	signal tilebuf_clear      : std_logic := '0';
	signal tilebuf_clear_done : std_logic;

	signal pll_locked : std_logic;

	signal framebuffer_ready : std_logic := '0';

	signal measurment0_run   : std_logic := '0';
	signal measurment0_value : uint32_t;
	signal measurment0_done  : std_logic;
	signal delay_counter     : integer;
	signal measurment_send   : std_logic := '0';
	signal printf0_val       : integer;

	-----------------------------------------

	signal input_clk : std_logic := '0';
	signal key       : keys_t;
	signal rot       : point3d_t;
	signal scale     : int16_t;
	signal start_screen_display : std_logic := '0';
	signal current_tile : integer;
	signal tile_num_request : std_logic;
	signal tile_num_ready : std_logic;

begin

	pll0 : entity work.pll
		port map(
			areset => not rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => main_clk,
			--			c2     => ,
			locked => pll_locked
		);

	fb_lo_level_driver0 : entity work.fb_lo_level_driver
		port map(
			clk          => fb_clk,
			rst          => not rst,
			op_start     => fb_op_start,
			op_done      => fb_op_done,
			op_op        => fb_op,
			data_in      => fb_data_write,
			data_out     => fb_data_read,
			VGA1_CS_n    => VGA1_CS_n,
			VGA1_DC_n    => VGA1_DC_n,
			VGA1_RD_n    => VGA1_RD_n,
			VGA1_WR_n    => VGA1_WR_n,
			VGA1_RESET_n => VGA1_RESET_n,
			VGA1_R       => VGA1_R
		);

	fb_initializer0 : entity work.fb_initializer
		port map(
			clk           => fb_initializer_clk,
			rst           => rst,
			start         => fb_init_start,
			done          => fb_init_done,
			fb_data_write => fb_initializer_data_write,
			fb_op_start   => fb_initializer_op_start,
			fb_op         => fb_initializer_op,
			fb_op_done    => fb_op_done
		);

	fb_display0 : entity work.fb_display
		port map(
			posx_out      => screen_posx,
			posy_out      => screen_posy,
			color_in      => screen_pixel_color,
			------------------------------------
			fb_window     => fb_disp_window_rect,
			clk           => main_clk,
			rst           => rst,
			start_write   => fb_disp_start_write,
			write_done    => fb_disp_write_done,
			do_clear      => fb_disp_clear,
			clear_color   => fb_disp_clear_color,
			fb_data_write => fb_disp_data_write,
			fb_op_start   => fb_disp_op_start,
			fb_op         => fb_disp_op,
			fb_op_done    => fb_op_done,
			fb_color_g    => VGA1_G,
			fb_color_b    => VGA1_B
		);

	mesh_renderer0 : entity work.mesh_renderer
		port map(
			clk                => main_clk,
			rst                => not rst,
			ready_out          => tilegen_ready,
			start_in           => tilegen_start,
			tile_num_in        => tile_num,
			rot                => rot,
			scale              => scale,
			screen_posx        => screen_posx,
			screen_posy        => screen_posy,
			screen_pixel_color => screen_pixel_color,
			tilebuf_clear      => tilebuf_clear,
			tilebuf_clear_done => tilebuf_clear_done
		);

	led_blinker0 : entity work.led_blinker
		generic map(
			frequency => 1.0            -- Hz
		)
		port map(
			clk50 => CLK_50,
			rst   => not rst,
			led   => LED(1)
		);

	--	measurment0 : entity work.single_measurment
	--		port map(
	--			clk   => CLK_50,
	--			rst   => not rst,
	--			run   => measurment0_run,
	--			value => measurment0_value,
	--			done  => measurment0_done
	--		);
	--
	--	pritf0 : entity work.printf
	--		port map(
	--			send     => measurment_send,
	--			clk      => CLK_50,
	--			rst      => not rst,
	--			uart_txd => UART_TXD,
	--			val      => printf0_val
	--		);
	--
	--	keyboard_inputs_0 : entity work.keyboard_inputs
	--		port map(
	--			clk      => CLK_50,
	--			rst      => not rst,
	--			ps2_clk  => PS2_CLK,
	--			ps2_data => PS2_DATA,
	--			keys      => key
	--		);
	--
	--	input_handler_0 : entity work.input_handler
	--		generic map(
	--			rot_init   => point3d(0, 0, 0),
	--			scale_init => int16(1)
	--		)
	--		port map(
	--			input_clk => input_clk,
	--			rst       => not rst,
	--			keys       => key,
	--			rot       => rot,
	--			scale     => scale
	--		);

	LED(0) <= rst;
	
	start_screen_display <= LED(1); 

	rst <= BTN(0);

	fb_clk        <= fb_initializer_clk when fb_initializer_enabled = '1' else main_clk;
	fb_data_write <= fb_initializer_data_write when fb_initializer_enabled = '1' else fb_disp_data_write;
	fb_op_start   <= fb_initializer_op_start when fb_initializer_enabled = '1' else fb_disp_op_start;
	fb_op         <= fb_initializer_op when fb_initializer_enabled = '1' else fb_disp_op;

	process(fb_initializer_clk, rst) is
	begin
		if not rst then
			state_init <= st_start;
		elsif rising_edge(fb_initializer_clk) then
			case state_init is
				when st_start =>
					fb_initializer_enabled <= '1';
					framebuffer_ready      <= '0';

					if pll_locked then
						state_init <= st_fb_init;
					else
						state_init <= st_start;
					end if;

				-- INIT FRAMEBUFFER

				when st_fb_init =>
					fb_init_start <= '1';
					state_init    <= st_fb_init_wait;

				when st_fb_init_wait =>
					fb_init_start <= '0';
					if fb_init_done then
						fb_initializer_enabled <= '0';
						framebuffer_ready      <= '1';
						state_init             <= st_idle;
					else
						state_init <= st_fb_init_wait;
					end if;

				when st_idle =>
					state_init <= st_idle;
			end case;
		end if;
	end process;

	process(main_clk, rst) is
	begin
		if not rst then
			state_drawing <= st_start;
		elsif rising_edge(main_clk) then
			case state_drawing is

				when st_start =>
					fb_disp_start_write <= '0';
					tilegen_start       <= '0';
					state_drawing       <= st_wait_for_framebuffer;
					tile_num_request <= '0';

				when st_wait_for_framebuffer =>
					if framebuffer_ready then
						state_drawing <= st_display_clear;
					else
						state_drawing <= st_wait_for_framebuffer;
					end if;

				-- CLEAR SCREEN

				when st_display_clear =>
					fb_disp_start_write <= '1';
					fb_disp_clear       <= '1';
					fb_disp_clear_color <= (r => X"00", g => X"00", b => X"FF");
					fb_disp_window_rect <= FULLSCREEN_RECT;
					state_drawing       <= st_display_clear_wait;

				when st_display_clear_wait =>
					fb_disp_start_write <= '0';
					fb_disp_clear       <= '0';

					if fb_disp_write_done then
						state_drawing <= st_tilegen_clear;
					else
						state_drawing <= st_display_clear_wait;
					end if;

				-- GENERATE TILE

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

				when st_tilegen_start_task =>
					tilegen_start <= '1';
					state_drawing <= st_tilegen_task_wait;

				when st_tilegen_task_wait =>
					tilegen_start <= '0';
					if tilegen_ready then
						state_drawing <= st_wait;
					else
						state_drawing <= st_tilegen_task_wait;
					end if;

				-- DISPLAY IMAGE
				
				when st_wait =>
					if start_screen_display then
						state_drawing <= st_screen_write;
					else
						state_drawing <= st_wait;
					end if;				

				when st_screen_write =>
					fb_disp_clear       <= '0';
					fb_disp_start_write <= '1';
					fb_disp_window_rect <= tile_rects(current_tile);
					state_drawing       <= st_screen_wait;

				when st_screen_wait =>
					fb_disp_start_write <= '0';
					if fb_disp_write_done then
						tile_num_request <= '1';
						state_drawing <= st_get_tile_wait;
					else
						state_drawing <= st_screen_wait;
					end if;
					
				when st_get_tile_wait =>
					tile_num_request <= '0';
					if tile_num_ready then
						current_tile <= tile_num;
						state_drawing <= st_tilegen_clear;
					else
						state_drawing <= st_get_tile_wait;
					end if;

			end case;
		end if;
	end process;
	
	process(main_clk, rst) is
	begin
		if not rst then
			state_tile <= st_start;
		elsif rising_edge(main_clk) then
			case state_tile is
				
				when st_start =>
					tile_num <= 0;
					tile_num_ready <= '0';
					state_tile       <= st_idle;

				when st_idle =>
					tile_num_ready <= '0';
					if tile_num_request then
						state_tile <= st_next_tile;
					else
						state_tile <= st_idle;
					end if;
					
				when st_next_tile =>
					if tile_num <= TILES_CNT - 2 then
						tile_num <= tile_num + 1;
					else
						tile_num <= 0;
					end if;
					
					tile_num_ready <= '1';

					rot.x <= sel(rot.x > 360, int16(1), rot.x + 1);

					state_tile <= st_idle;

			end case;
		end if;
	end process;

end architecture;
