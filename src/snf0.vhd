library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;

entity snf0 is
	port(
		CLK_50         : in    std_logic;
		CLK_50_2       : in    std_logic;
		PS2_CLK        : inout std_logic;
		PS2_DATA       : inout std_logic;
		UART_RXD       : in    std_logic;
		UART_TXD       : out   std_logic;
		SRAM_CLK       : out   std_logic;
		SRAM_ADDR      : out   std_logic_vector(18 downto 0);
		SRAM_DQ        : inout std_logic_vector(31 downto 0);
		SRAM_PAR       : inout std_logic_vector(3 downto 0);
		SRAM_MODE      : out   std_logic;
		SRAM_ADSC_n    : out   std_logic;
		SRAM_ADSP_n    : out   std_logic;
		SRAM_ADV_n     : out   std_logic;
		SRAM_BWE_n     : out   std_logic;
		SRAM_CE2_n     : out   std_logic;
		SRAM_CE_n      : out   std_logic;
		SRAM_OE_n      : out   std_logic;
		SRAM_ZZ        : out   std_logic;
		VGA1_PIXEL_CLK : in    std_logic;
		VGA1_CS_n      : out   std_logic;
		VGA1_DC_n      : out   std_logic;
		VGA1_RD_n      : out   std_logic;
		VGA1_WR_n      : out   std_logic;
		VGA1_RESET_n   : out   std_logic;
		VGA1_TE        : in    std_logic;
		VGA1_R         : inout std_logic_vector(7 downto 0);
		VGA1_G         : out   std_logic_vector(7 downto 0);
		VGA1_B         : out   std_logic_vector(7 downto 0);
		VGA2_R         : out   std_logic;
		VGA2_G         : out   std_logic;
		VGA2_B         : out   std_logic;
		VGA2_VSync     : out   std_logic;
		VGA2_HSync     : out   std_logic;
		BTN            : in    std_logic_vector(1 downto 0);
		LED            : out   std_logic_vector(2 downto 0);
		GPIO           : inout std_logic_vector(0 to 3);
		GPI            : in    std_logic_vector(0 to 7)
	);

end snf0;

architecture behavioral of snf0 is
	type fsm_state_type is (
		st_start,
		st_fb_init, st_fb_init_wait,
		st_disp_write,
		st_disp_wait,
		st_end
	);
	signal state : fsm_state_type := st_start;

	----------------------------------------

	signal rst : std_logic             := '1';
	signal cnt : unsigned(31 downto 0) := (others => '0');

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

	----------------------------------------

	signal fb_data_read : std_logic_vector(7 downto 0);

	signal fb_init_start : std_logic := '0';
	signal fb_init_done  : std_logic;

	signal fb_disp_start_write : std_logic := '0';
	signal fb_disp_write_done  : std_logic;

begin
	pll0 : entity work.pll
		port map(
			areset => not rst,
			inclk0 => CLK_50,
			c0     => fb_initializer_clk,
			c1     => fb_disp_clk
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
			fb_window     => (x0 => to_unsigned(0, 16), 
									x1 => to_unsigned(640, 16), 
									y0 => to_unsigned(0, 16), 
									y1 => to_unsigned(480, 16)),
			clk           => fb_disp_clk,
			rst           => rst,
			start_write   => fb_disp_start_write,
			write_done    => fb_disp_write_done,
			fb_data_write => fb_disp_data_write,
			fb_op_start   => fb_disp_op_start,
			fb_op         => fb_disp_op,
			fb_op_done    => fb_op_done,
			fb_color_g    => VGA1_G,
			fb_color_b    => VGA1_B
		);

	LED <= "111";

	fb_clk        <= fb_initializer_clk when fb_initializer_enabled = '1' else fb_disp_clk;
	fb_data_write <= fb_initializer_data_write when fb_initializer_enabled = '1' else fb_disp_data_write;
	fb_op_start   <= fb_initializer_op_start when fb_initializer_enabled = '1' else fb_disp_op_start;
	fb_op         <= fb_initializer_op when fb_initializer_enabled = '1' else fb_disp_op;

	process(fb_initializer_clk, rst) is
	begin
		if rst = '0' then
			rst   <= '1';
			state <= st_start;
		elsif rising_edge(fb_initializer_clk) then
			case state is
				when st_start =>
					rst                    <= '1';
					fb_initializer_enabled <= '1';
					fb_disp_start_write    <= '0';
					state                  <= st_fb_init;

				when st_fb_init =>
					fb_init_start <= '1';
					state         <= st_fb_init_wait;

				when st_fb_init_wait =>
					fb_init_start <= '0';
					if fb_init_done = '1' then
						fb_initializer_enabled <= '0';
						state                  <= st_disp_write;
					else
						state <= st_fb_init_wait;
					end if;

				when st_disp_write =>
					fb_disp_start_write <= '1';
					state               <= st_disp_wait;

				when st_disp_wait =>
					fb_disp_start_write <= '0';

					if fb_disp_write_done = '1' then
						state <= st_end;
					else
						state <= st_disp_wait;
					end if;

				when st_end =>
					state <= st_end;
			end case;
		end if;
	end process;

end architecture;
