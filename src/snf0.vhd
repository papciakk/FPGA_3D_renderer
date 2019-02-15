library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
use work.common.all;
use work.pll;

entity snf0 is
	port(
		CLK_50       : in    std_logic;
		--		CLK_50_2       : in    std_logic;
		--		PS2_CLK        : inout std_logic;
		--		PS2_DATA       : inout std_logic;
		--		UART_RXD       : in    std_logic;
		--		UART_TXD       : out   std_logic;
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
		VGA1_R       : inout std_logic_vector(7 downto 0);
		VGA1_G       : out   std_logic_vector(7 downto 0);
		VGA1_B       : out   std_logic_vector(7 downto 0);
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
		st_start,
		st_fb_init, st_fb_init_wait,
		st_screen_write,
		st_init_tilegen, st_tilegen_wait,
		st_disp_clear, st_disp_clear_wait,
		st_next_tile,
		st_screen_wait,
		st_end,
		st_tilegen_clear, st_tilegen_clear_wait);
	signal state : fsm_state_type := st_start;

	----------------------------------------

	signal rst : std_logic;

	----------------------------------------

	signal fb_initializer_enabled : std_logic := '1';

	signal fb_clk        : std_logic;
	signal fb_data_write : std_logic_vector(7 downto 0);
	signal fb_op_start   : std_logic;
	signal fb_op         : fb_lo_level_op_type;
	signal fb_op_done    : std_logic;

	signal fb_initializer_clk        : std_logic;
	signal fb_initializer_data_write : std_logic_vector(7 downto 0);
	signal fb_initializer_op_start   : std_logic;
	signal fb_initializer_op         : fb_lo_level_op_type;

	signal fb_disp_clk        : std_logic;
	signal fb_disp_data_write : std_logic_vector(7 downto 0);
	signal fb_disp_op_start   : std_logic;
	signal fb_disp_op         : fb_lo_level_op_type;

	-- framebuffer display clear signals
	signal fb_disp_clear       : std_logic := '0';
	signal fb_disp_clear_color : color_t   := (others => X"00");

	-- framebuffer display write control
	signal fb_disp_start_write : std_logic := '0';
	signal fb_disp_write_done  : std_logic;

	-- framebuffer display out position, color input and window
	signal screen_posx        : unsigned(15 downto 0);
	signal screen_posy        : unsigned(15 downto 0);
	signal screen_pixel_color : color_t;

	signal screen_tile_rect    : rect_t;
	signal fb_disp_window_rect : rect_t := FULLSCREEN_RECT;
	----------------------

	----------------------------------------

	signal fb_data_read : std_logic_vector(7 downto 0);

	signal fb_init_start : std_logic := '0';
	signal fb_init_done  : std_logic;

	-----------------------------------------
	signal tilegen_posx_out      : unsigned(15 downto 0);
	signal tilegen_posy_out      : unsigned(15 downto 0);
	signal tilegen_color_out     : color_t;
	signal tilegen_put_pixel_out : std_logic;
	signal tilegen_ready         : std_logic;
	signal tilegen_start         : std_logic := '0';
	signal tilegen_tile_num_in   : integer := 0;

	-----------------------------------------
	signal tilebuf_clear      : std_logic := '0';
	signal tilebuf_clear_done : std_logic;
	
	signal depth_in : unsigned(15 downto 0);
	signal depth_out : unsigned(15 downto 0);
	signal depth_wren : std_logic;

	signal clk150 : std_logic;

begin

	pll0 : entity work.pll
		port map(
			areset => not rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => fb_disp_clk,
			c2 => clk150
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
			screen_clk        => fb_clk,
			screen_posx       => screen_posx,
			screen_posy       => screen_posy,
			color_out         => screen_pixel_color,
			----------
			tilegen_clk       => fb_initializer_clk,
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
			clk50 => clk150,
			depth_wren => depth_wren
		);

	tile_system0 : entity work.tile_system
		port map(
			clk           => fb_initializer_clk,
			rst           => not rst,
			posx_out      => tilegen_posx_out,
			posy_out      => tilegen_posy_out,
			color_out     => tilegen_color_out,
			put_pixel_out => tilegen_put_pixel_out,
			tile_rect_out => screen_tile_rect,
			ready_out     => tilegen_ready,
			start_in      => tilegen_start,
			tile_num_in   => tilegen_tile_num_in,
			depth_in => depth_in,
			depth_out => depth_out,
			depth_wren => depth_wren
		);

	led_blinker0 : entity work.led_blinker
		generic map(
			frequency => 1.0            -- Hz
		)
		port map(
			clk50 => fb_initializer_clk,
			rst   => not rst,
			led   => LED(1)
		);

	LED(0) <= rst;

	rst <= BTN(0);

	fb_clk        <= fb_initializer_clk when fb_initializer_enabled = '1' else fb_disp_clk;
	fb_data_write <= fb_initializer_data_write when fb_initializer_enabled = '1' else fb_disp_data_write;
	fb_op_start   <= fb_initializer_op_start when fb_initializer_enabled = '1' else fb_disp_op_start;
	fb_op         <= fb_initializer_op when fb_initializer_enabled = '1' else fb_disp_op;

	process(fb_clk, rst) is
	begin
		if rst = '0' then
			state <= st_start;
		elsif rising_edge(fb_clk) then
			case state is
				when st_start =>
					LED(2)                 <= '0';
					fb_initializer_enabled <= '1';
					fb_disp_start_write    <= '0';
					tilegen_start          <= '0';
					tilegen_tile_num_in    <= 0;
					state                  <= st_fb_init;

				-- INIT FRAMEBUFFER

				when st_fb_init =>
					fb_init_start <= '1';
					state         <= st_fb_init_wait;

				when st_fb_init_wait =>
					fb_init_start <= '0';
					if fb_init_done = '1' then
						fb_initializer_enabled <= '0';
						state                  <= st_disp_clear;
					else
						state <= st_fb_init_wait;
					end if;

				-- CLEAR SCREEN

				when st_disp_clear =>
					fb_disp_start_write <= '1';
					fb_disp_clear       <= '1';
					fb_disp_clear_color <= (r => X"00", g => X"00", b => X"FF");
					fb_disp_window_rect <= FULLSCREEN_RECT;
					state               <= st_disp_clear_wait;

				when st_disp_clear_wait =>
					fb_disp_start_write <= '0';
					fb_disp_clear       <= '0';

					if fb_disp_write_done = '1' then
						state <= st_tilegen_clear;
					else
						state <= st_disp_clear_wait;
					end if;

				-- GENERATE TILE

				when st_tilegen_clear =>
					tilebuf_clear <= '1';
					state         <= st_tilegen_clear_wait;

				when st_tilegen_clear_wait =>
					tilebuf_clear <= '0';
					if tilebuf_clear_done = '1' then
						state <= st_init_tilegen;
					else
						state <= st_tilegen_clear_wait;
					end if;

				when st_init_tilegen =>
					tilegen_start <= '1';
					state         <= st_tilegen_wait;

				when st_tilegen_wait =>
					tilegen_start <= '0';
					if tilegen_ready = '1' then
						state <= st_screen_write;
					else
						state <= st_tilegen_wait;
					end if;

				-- DISPLAY IMAGE

				when st_screen_write =>
					fb_disp_clear       <= '0';
					fb_disp_start_write <= '1';
					state               <= st_screen_wait;
					fb_disp_window_rect <= screen_tile_rect;

				when st_screen_wait =>
					fb_disp_start_write <= '0';
					if fb_disp_write_done = '1' then
						state <= st_next_tile;
					else
						state <= st_screen_wait;
					end if;

				-- TILE GENERATION MANAGEMENT

				when st_next_tile =>
					if tilegen_tile_num_in <= 20 - 2 then
						tilegen_tile_num_in <= tilegen_tile_num_in + 1;
						state               <= st_tilegen_clear;
					else
						tilegen_tile_num_in <= 0;
						state               <= st_tilegen_clear;
						--						state <= st_disp_clear;
					end if;

				when st_end =>
					null;
			end case;
		end if;
	end process;

end architecture;
