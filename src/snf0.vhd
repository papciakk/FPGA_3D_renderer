library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.all;
use work.fb_types.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;

entity snf0 is
	port(
		CLK_50       : in    std_logic;
		--		CLK_50_2       : in    std_logic;
		--		PS2_CLK        : inout std_logic;
		--		PS2_DATA       : inout std_logic;
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
	
	constant DELAY_IN_TICKS : integer := 2500000;
	
	type fsm_state_type is (
		st_idle,
		st_start,
		st_fb_init, st_fb_init_wait);
	signal state_init : fsm_state_type := st_start;

	type drawing_state_type is (
		st_start,
		st_delay,
		st_wait,
		st_screen_write,
		st_init_tilegen, st_tilegen_wait,
		st_disp_clear, st_disp_clear_wait,
		st_next_tile,
		st_screen_wait,
		st_end,
		st_tilegen_clear, st_tilegen_clear_wait
	);
	signal state_drawing : drawing_state_type := st_wait;

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

	signal fb_disp_clk        : std_logic;
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

	signal screen_tile_rect    : rect_t;
	signal fb_disp_window_rect : rect_t := FULLSCREEN_RECT;
	----------------------

	----------------------------------------

	signal fb_data_read : slv8_t;

	signal fb_init_start : std_logic := '0';
	signal fb_init_done  : std_logic;

	-----------------------------------------
	signal tilegen_posx_out      : uint16_t;
	signal tilegen_posy_out      : uint16_t;
	signal tilegen_color_out     : color_t;
	signal tilegen_put_pixel_out : std_logic;
	signal tilegen_ready         : std_logic;
	signal tilegen_start         : std_logic := '0';
	signal tilegen_tile_num_in   : integer   := 0;

	-----------------------------------------
	signal tilebuf_clear      : std_logic := '0';
	signal tilebuf_clear_done : std_logic;

	signal depth_in   : int16_t;
	signal depth_out  : int16_t;
	signal depth_wren : std_logic;

	signal clk150     : std_logic;
	signal pll_locked : std_logic;

	signal enable_drawing : std_logic := '0';

	signal measurment0_run   : std_logic := '0';
	signal measurment0_value : uint32_t;
	signal measurment0_done  : std_logic;
	signal delay_counter : integer;
	signal measurment_send : std_logic := '0';
	signal printf0_val : integer;

begin

	pll0 : entity work.pll
		port map(
			areset => not rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => fb_disp_clk,
			c2     => clk150,
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
			clk           => fb_disp_clk,
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

	tile_buffer0 : entity work.tile_buffer
		port map(
			screen_clk        => fb_disp_clk,
			screen_posx       => screen_posx,
			screen_posy       => screen_posy,
			color_out         => screen_pixel_color,
			----------
			tilegen_clk       => fb_disp_clk,
			tilegen_posx      => tilegen_posx_out,
			tilegen_posy      => tilegen_posy_out,
			tilegen_put_pixel => tilegen_put_pixel_out,
			color_in          => tilegen_color_out,
			----------
			rst               => not rst,
			clear             => tilebuf_clear,
			clear_done        => tilebuf_clear_done,
			----------
			depth_in          => depth_in,
			depth_out         => depth_out,
			clk50             => clk150,
			depth_wren        => depth_wren
		);

	tile_system0 : entity work.tile_system
		port map(
			clk           => fb_disp_clk,
			rst           => not rst,
			posx_out      => tilegen_posx_out,
			posy_out      => tilegen_posy_out,
			color_out     => tilegen_color_out,
			put_pixel_out => tilegen_put_pixel_out,
			tile_rect_out => screen_tile_rect,
			ready_out     => tilegen_ready,
			start_in      => tilegen_start,
			tile_num_in   => tilegen_tile_num_in,
			depth_in      => depth_in,
			depth_out     => depth_out,
			depth_wren    => depth_wren
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

	measurment0 : entity work.single_measurment
		port map(
			clk   => CLK_50,
			rst   => not rst,
			run   => measurment0_run,
			value => measurment0_value,
			done  => measurment0_done
		);

	pritf0 : entity work.printf
		port map(
			send => 	measurment_send,
			clk      => CLK_50,
			rst      => not rst,
			uart_txd => UART_TXD,
			val      => printf0_val
		);

	LED(0) <= rst;
	LED(2) <= xor_reduce(std_logic_vector(measurment0_value));

	rst <= BTN(0);

	fb_clk        <= fb_initializer_clk when fb_initializer_enabled = '1' else fb_disp_clk;
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
					enable_drawing         <= '0';

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
						enable_drawing         <= '1';
						state_init             <= st_idle;
					else
						state_init <= st_fb_init_wait;
					end if;

				when st_idle =>
					state_init <= st_idle;
			end case;
		end if;
	end process;

	process(fb_disp_clk, rst) is
	begin
		if not rst then
			state_drawing <= st_start;
		elsif rising_edge(fb_disp_clk) then
			case state_drawing is

				when st_start =>
					fb_disp_start_write <= '0';
					tilegen_start       <= '0';
					tilegen_tile_num_in <= 0;
					state_drawing       <= st_wait;
					measurment0_run     <= '0';
					delay_counter <= 0;

				when st_delay =>
					if delay_counter < DELAY_IN_TICKS then
						state_drawing <= st_delay;
					else
						state_drawing <= st_wait;
					end if;

				when st_wait =>
					if enable_drawing then
						state_drawing <= st_disp_clear;
					else
						state_drawing <= st_wait;
					end if;

				-- CLEAR SCREEN

				when st_disp_clear =>
					fb_disp_start_write <= '1';
					fb_disp_clear       <= '1';
					fb_disp_clear_color <= (r => X"00", g => X"00", b => X"FF");
					fb_disp_window_rect <= FULLSCREEN_RECT;
					state_drawing       <= st_disp_clear_wait;

				when st_disp_clear_wait =>
					fb_disp_start_write <= '0';
					fb_disp_clear       <= '0';

					if fb_disp_write_done then
						state_drawing <= st_tilegen_clear;
					else
						state_drawing <= st_disp_clear_wait;
					end if;

				-- GENERATE TILE

			when st_tilegen_clear =>
					measurment_send <= '0';
					measurment0_run <= '1';
					tilebuf_clear   <= '1';
					state_drawing   <= st_tilegen_clear_wait;

				when st_tilegen_clear_wait =>
					tilebuf_clear <= '0';
					if tilebuf_clear_done then
						state_drawing <= st_init_tilegen;
					else
						state_drawing <= st_tilegen_clear_wait;
					end if;

				when st_init_tilegen =>
					tilegen_start <= '1';
					state_drawing <= st_tilegen_wait;

				when st_tilegen_wait =>
					tilegen_start <= '0';
					if tilegen_ready then
						state_drawing <= st_screen_write;
					else
						state_drawing <= st_tilegen_wait;
					end if;

				-- DISPLAY IMAGE

				when st_screen_write =>
					fb_disp_clear       <= '0';
					fb_disp_start_write <= '1';
					state_drawing       <= st_screen_wait;
					fb_disp_window_rect <= screen_tile_rect;

				when st_screen_wait =>
					fb_disp_start_write <= '0';
					if fb_disp_write_done then
						state_drawing <= st_next_tile;
					else
						state_drawing <= st_screen_wait;
					end if;

				-- TILE GENERATION MANAGEMENT

				when st_next_tile =>
					if tilegen_tile_num_in <= TILES_CNT - 2 then
						tilegen_tile_num_in <= tilegen_tile_num_in + 1;
						state_drawing       <= st_tilegen_clear;
					else
						tilegen_tile_num_in <= 0;
						measurment0_run     <= '0';
						measurment_send <= '1';
						printf0_val <= to_integer(measurment0_value);
						
						state_drawing       <= st_tilegen_clear;
					end if;

				when st_end =>
					null;
			end case;
		end if;
	end process;

end architecture;
