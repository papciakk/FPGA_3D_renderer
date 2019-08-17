library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use work.all;
use work.fb_types.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
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

	type state_screen_type is (
		st_start, st_wait_for_framebuffer_init,
		st_screen_write, st_screen_wait,
		st_next_tile, st_hold_measurement_step
	);
	signal state_screen, state_screen_next : state_screen_type := st_start;

	signal main_clk           : std_logic;
	signal fb_initializer_clk : std_logic;
	signal display_clk        : std_logic;

	signal rst        : std_logic;
	signal pll_locked : std_logic;

	-----------------------------------------

	signal framebuffer_initialized                       : std_logic := '0';
	signal fb_disp_window_rect, fb_disp_window_rect_next : rect_t;
	signal fb_disp_start_write, fb_disp_start_write_next : std_logic;
	signal fb_disp_write_done                            : std_logic;
	signal tile_num, tile_num_next                       : integer   := 0;

	---------------------------------------------

	signal measurement_step, measurement_step_next : std_logic;
	signal measurement_value                       : integer;
	signal measurement_value_ready                 : std_logic;

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

	framebuffer_driver0 : entity work.fb_driver
		port map(
			display_clk     => display_clk,
			initializer_clk => fb_initializer_clk,
			rst             => rst,
			-------------------------------
			start_write     => fb_disp_start_write,
			write_done      => fb_disp_write_done,
			-------------------------------
			color_in        => COLOR_CYAN,
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

	LED(0) <= rst;
	rst    <= not BTN(0);
--
	process(display_clk, rst) is
	begin
		if rst then
			state_screen <= st_start;
		elsif rising_edge(display_clk) then
			tile_num            <= tile_num_next;
			fb_disp_start_write <= fb_disp_start_write_next;
			measurement_step    <= measurement_step_next;
			fb_disp_window_rect <= fb_disp_window_rect_next;
			state_screen        <= state_screen_next;
		end if;
	end process;

	process(all) is
	begin
		tile_num_next            <= tile_num;
		fb_disp_start_write_next <= fb_disp_start_write;
		measurement_step_next    <= measurement_step;
		fb_disp_window_rect_next <= fb_disp_window_rect;
		state_screen_next        <= state_screen;

		case state_screen is

			when st_start =>
				measurement_step_next <= '0';
				tile_num_next         <= 0;
				fb_disp_start_write_next <= '0';
				state_screen_next     <= st_wait_for_framebuffer_init;

			when st_wait_for_framebuffer_init =>
				measurement_step_next <= '0';
				if framebuffer_initialized then
					state_screen_next <= st_screen_write;
				else
					state_screen_next <= st_wait_for_framebuffer_init;
				end if;

			when st_screen_write =>
				fb_disp_start_write_next <= '1';
				fb_disp_window_rect_next <= tile_rects(tile_num).rect;
				state_screen_next        <= st_screen_wait;

			when st_screen_wait =>
				measurement_step_next    <= '0';
				fb_disp_start_write_next <= '0';
				if fb_disp_write_done then
					state_screen_next <= st_next_tile;
				else
					state_screen_next <= st_screen_wait;
				end if;

			when st_next_tile =>
				if tile_num < TILES_CNT then
					tile_num_next     <= tile_num + 1;
					state_screen_next <= st_screen_write;
				else
					tile_num_next     <= 0;
					state_screen_next <= st_hold_measurement_step;

					measurement_step_next <= '1';
				end if;
				
			when st_hold_measurement_step =>
				measurement_step_next <= '1';
				state_screen_next <= st_screen_write;

		end case;
	end process;

end architecture;
