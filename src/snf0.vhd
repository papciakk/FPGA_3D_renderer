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
		st_idle,
		st_next_tile
	);
	signal state_tile : state_tile_type := st_start;

	signal main_clk   : std_logic;
	signal rst        : std_logic;
	signal pll_locked : std_logic;

	signal tile_num : integer := 0;

	-----------------------------------------

	signal framebuffer_ready   : std_logic := '0';
	signal fb_disp_window_rect : rect_t;

	signal measurment0_run   : std_logic := '0';
	signal measurment0_value : uint32_t;
	signal measurment0_done  : std_logic;
	signal measurment_send   : std_logic := '0';
	signal printf0_val       : integer;

	-----------------------------------------

	signal input_clk            : std_logic := '0';
	signal key                  : keys_t;
	signal rot                  : point3d_t;
	signal scale                : int16_t;
	signal start_screen_display : std_logic := '0';
	signal tile_num_request     : std_logic;
	signal tile_num_ready       : std_logic;

	signal tile_num_out        : integer;
	signal state_tile_next     : state_tile_type;
	signal tile_num_next       : integer;
	signal tile_num_ready_next : std_logic;
	signal tile_num_out_next   : integer;
	signal xxx                 : std_logic;

	signal fb_disp_start_write : std_logic;
	signal fb_disp_write_done  : std_logic;
	signal fb_initializer_clk  : std_logic;
	signal posx_out, posy_out  : uint16_t;
	signal color_in            : color_t;
	signal rot_cnt : integer;
	signal rot_cnt_next : integer;
	signal rot_next : point3d_t;

begin

	pll0 : entity work.pll
		port map(
			areset => rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => main_clk,
			locked => pll_locked
		);

	mesh_renderer0 : entity work.mesh_renderer
		port map(
			clk                => main_clk,
			rst                => rst,
			-------------------------------
			screen_ready       => framebuffer_ready and start_screen_display,
			screen_start_write => fb_disp_start_write,
			screen_write_done  => fb_disp_write_done,
			screen_rect        => fb_disp_window_rect,
			screen_posx        => posx_out,
			screen_posy        => posy_out,
			screen_pixel_color => color_in,
			-------------------------------
			task_request       => tile_num_request,
			task_ready         => tile_num_ready,
			task_tile_num      => tile_num_out,
			-------------------------------
			rot                => rot,
			scale              => scale
		);

	framebuffer_driver0 : entity work.fb_driver
		port map(
			display_clk     => main_clk,
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
			initialized     => framebuffer_ready,
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
			frequency => 50.0           -- Hz
		)
		port map(
			clk50 => CLK_50,
			rst   => rst,
			led   => xxx
		);

	--	measurment0 : entity work.single_measurment
	--		port map(
	--			clk   => CLK_50,
	--			rst   => rst,
	--			run   => measurment0_run,
	--			value => measurment0_value,
	--			done  => measurment0_done
	--		);
	--
	--	pritf0 : entity work.printf
	--		port map(
	--			send     => measurment_send,
	--			clk      => CLK_50,
	--			rst      => rst,
	--			uart_txd => UART_TXD,
	--			val      => printf0_val
	--		);
	--
	--	keyboard_inputs_0 : entity work.keyboard_inputs
	--		port map(
	--			clk      => CLK_50,
	--			rst      => rst,
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
	--			rst       => rst,
	--			keys       => key,
	--			rot       => rot,
	--			scale     => scale
	--		);

	LED(0) <= rst;
	LED(1) <= xxx;

	start_screen_display <= '1';

	rst <= not BTN(0);

	process(xxx) is
	begin
		if rising_edge(xxx) then
			--			rot.x <= sel(rot.x > 360, int16(1), rot.x + 1);
		end if;
	end process;

	process(main_clk, rst) is
	begin
		if rst then
			state_tile <= st_start;
		elsif rising_edge(main_clk) then
			tile_num       <= tile_num_next;
			tile_num_ready <= tile_num_ready_next;
			tile_num_out   <= tile_num_out_next;
			state_tile     <= state_tile_next;
			rot_cnt <= rot_cnt_next;
			rot <= rot_next;
		end if;
	end process;

	process(all) is
	begin
		tile_num_next       <= tile_num;
		tile_num_ready_next <= tile_num_ready;
		tile_num_out_next   <= tile_num_out;
		state_tile_next     <= state_tile;
		rot_next <= rot;
		rot_cnt_next <= rot_cnt;
		case state_tile is

			when st_start =>
				tile_num_next       <= 0;
				tile_num_ready_next <= '0';
				tile_num_out_next   <= 0;
				rot_cnt_next <= 0;
				rot_next <= (others => int16(0));
				state_tile_next     <= st_idle;

			when st_idle =>
				if tile_num_request then
					tile_num_out_next   <= tile_num;
					tile_num_ready_next <= '1';
					state_tile_next     <= st_next_tile;
				else
					tile_num_ready_next <= '0';
					state_tile_next     <= st_idle;
				end if;

			when st_next_tile =>
				tile_num_ready_next <= '0';
				if tile_num < TILES_CNT then
					tile_num_next <= tile_num + 1;
				else
					--if rot_cnt >= 20 then
						rot_next.x <= sel(rot.x > 359, int16(0), rot.x + 1);
					--	rot_cnt_next <= 0;
					--else
						--rot_cnt_next <= rot_cnt + 1;
					--end if;
					tile_num_next <= 0;
				end if;

				state_tile_next <= st_idle;

		end case;
	end process;

end architecture;
