library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;

entity fb_driver is
	port(
		display_clk     : in    std_logic;
		initializer_clk : in    std_logic;
		rst             : in    std_logic;
		---------------------------------------
		start_write     : in    std_logic;
		write_done      : out   std_logic;
		---------------------------------------
		posx_out        : out   uint16_t;
		posy_out        : out   uint16_t;
		color_in        : in    color_t;
		fb_window_in    : in    rect_t;
		---------------------------------------
		initialize      : in    std_logic;
		initialized     : out   std_logic;
		---------------------------------------
		VGA1_CS_n       : out   std_logic;
		VGA1_DC_n       : out   std_logic;
		VGA1_RD_n       : out   std_logic;
		VGA1_WR_n       : out   std_logic;
		VGA1_RESET_n    : out   std_logic;
		VGA1_R          : inout slv8_t;
		VGA1_G          : out   slv8_t;
		VGA1_B          : out   slv8_t
	);
end entity;

architecture rtl of fb_driver is
	signal initializer_enabled : std_logic := '1';
	signal initialize_start    : std_logic := '0';
	signal initialize_done     : std_logic;

	signal fbramebuffer_clk : std_logic;
	signal data_write       : slv8_t;
	signal operation_start  : std_logic;
	signal opeartion        : fb_lo_level_op_type;

	signal initializer_data_write      : slv8_t;
	signal initializer_operation_start : std_logic;
	signal initializer_operation       : fb_lo_level_op_type;

	signal display_data_write      : slv8_t;
	signal display_operation_start : std_logic;
	signal display_operation       : fb_lo_level_op_type;

	signal operation_done : std_logic;
	signal data_read      : slv8_t;

	signal display_clear       : std_logic := '0';
	signal display_clear_color : color_t   := (others => X"00");

	type state_init_type is (
		st_idle,
		st_start,
		st_init, st_init_wait
	);
	signal state_init : state_init_type := st_start;

begin

	fb_lo_level_driver0 : entity work.fb_lo_level_driver
		port map(
			clk          => fbramebuffer_clk,
			rst          => rst,
			op_start     => operation_start,
			op_done      => operation_done,
			op_op        => opeartion,
			data_in      => data_write,
			data_out     => data_read,
			VGA1_CS_n    => VGA1_CS_n,
			VGA1_DC_n    => VGA1_DC_n,
			VGA1_RD_n    => VGA1_RD_n,
			VGA1_WR_n    => VGA1_WR_n,
			VGA1_RESET_n => VGA1_RESET_n,
			VGA1_R       => VGA1_R
		);

	fb_initializer0 : entity work.fb_initializer
		port map(
			clk           => initializer_clk,
			rst           => rst,
			start         => initialize_start,
			done          => initialize_done,
			fb_data_write => initializer_data_write,
			fb_op_start   => initializer_operation_start,
			fb_op         => initializer_operation,
			fb_op_done    => operation_done
		);

	fb_display0 : entity work.fb_display
		port map(
			clk           => display_clk,
			rst           => rst,
			------------------------------------
			posx_out      => posx_out,
			posy_out      => posy_out,
			color_in      => color_in,
			------------------------------------
			fb_window     => fb_window_in,
			start_write   => start_write,
			write_done    => write_done,
			------------------------------------
			do_clear      => display_clear,
			clear_color   => display_clear_color,
			------------------------------------
			fb_data_write => display_data_write,
			fb_op_start   => display_operation_start,
			fb_op         => display_operation,
			fb_op_done    => operation_done,
			fb_color_g    => VGA1_G,
			fb_color_b    => VGA1_B
		);

	fbramebuffer_clk <= initializer_clk when initializer_enabled = '1' else display_clk;
	data_write       <= initializer_data_write when initializer_enabled = '1' else display_data_write;
	operation_start  <= initializer_operation_start when initializer_enabled = '1' else display_operation_start;
	opeartion        <= initializer_operation when initializer_enabled = '1' else display_operation;

	process(initializer_clk, rst) is
	begin
		if rst then
			state_init <= st_start;
		elsif rising_edge(initializer_clk) then
			case state_init is
				when st_start =>
					initializer_enabled <= '1';
					initialized         <= '0';

					if initialize then
						state_init <= st_init;
					else
						state_init <= st_start;
					end if;

				when st_init =>
					initialize_start <= '1';
					state_init       <= st_init_wait;

				when st_init_wait =>
					initialize_start <= '0';
					if initialize_done then
						initializer_enabled <= '0';
						initialized         <= '1';
						state_init          <= st_idle;
					else
						state_init <= st_init_wait;
					end if;

				when st_idle =>
					state_init <= st_idle;
			end case;
		end if;
	end process;

end architecture rtl;
