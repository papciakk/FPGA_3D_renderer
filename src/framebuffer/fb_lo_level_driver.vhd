library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
library common;
use common.stdint.all;

entity fb_lo_level_driver is
	port(
		clk          : in    std_logic;
		rst          : in    std_logic;
		------------------------------------------
		op_start     : in    std_logic;
		op_done      : out   std_logic;
		op_op        : in    fb_lo_level_op_type;
		------------------------------------------
		data_in      : in    slv8_t;
		data_out     : out   slv8_t;
		------------------------------------------
		VGA1_CS_n    : out   std_logic;
		VGA1_DC_n    : out   std_logic;
		VGA1_RD_n    : out   std_logic;
		VGA1_WR_n    : out   std_logic;
		VGA1_RESET_n : out   std_logic;
		VGA1_R       : inout slv8_t
	);
end entity fb_lo_level_driver;

architecture rtl of fb_lo_level_driver is
	type state_type is (st_idle,
	                    st_init_0, st_init_1,
	                    st_read_data_0, st_read_data_1,
	                    st_write_0, st_write_1,
	                    st_wait_ms, st_wait_one_ms
	                   );
	signal state : state_type := st_idle;
	signal cnt   : uint16_t;

	signal cnt_ms            : uint32_t;
	constant ONE_MS_COUNT_TO : integer := 1000;
begin

	process(clk, rst) is
		constant RESET_WAIT_TICKS                            : integer   := 20000;
		constant MODE_DATA, WR_STOP, RD_STOP, RST_STOP       : std_logic := '1';
		constant MODE_COMMAND, WR_START, RD_START, RST_START : std_logic := '0';
	begin
		if rst then
			state <= st_idle;
		elsif rising_edge(clk) then
			case state is
				when st_idle =>
					op_done      <= '0';
					VGA1_CS_n    <= '0';
					VGA1_WR_n    <= WR_STOP;
					VGA1_RD_n    <= RD_STOP;
					VGA1_RESET_n <= RST_STOP;
					VGA1_R       <= (others => 'Z');
					cnt          <= (others => '0');

					if op_start then
						case op_op is
							when fb_lo_op_init =>
								state <= st_init_0;
							when fb_lo_op_read_data =>
								state <= st_read_data_0;
							when fb_lo_op_write_command =>
								VGA1_DC_n <= MODE_COMMAND;
								state     <= st_write_0;
							when fb_lo_op_write_data =>
								VGA1_DC_n <= MODE_DATA;
								state     <= st_write_0;
							when fb_lo_op_wait_ms =>
								cnt   <= (others => '0');
								state <= st_wait_ms;
						end case;
					else
						state <= st_idle;
					end if;

				when st_init_0 =>
					op_done      <= '0';
					VGA1_RESET_n <= RST_START;
					cnt          <= (others => '0');
					state        <= st_init_1;

				when st_init_1 =>
					if cnt < RESET_WAIT_TICKS then
						op_done <= '0';
						cnt     <= cnt + 1;
						state   <= st_init_1;
					else
						state   <= st_idle;
						op_done <= '1';
					end if;

				when st_write_0 =>
					op_done   <= '0';
					VGA1_WR_n <= WR_START;
					VGA1_R    <= data_in;
					state     <= st_write_1;

				when st_write_1 =>
					op_done   <= '1';
					VGA1_WR_n <= WR_STOP;
					state     <= st_idle;

				when st_read_data_0 =>
					op_done   <= '0';
					VGA1_R    <= (others => 'Z');
					VGA1_DC_n <= MODE_DATA;
					VGA1_RD_n <= RD_START;
					state     <= st_read_data_1;

				when st_read_data_1 =>
					op_done   <= '1';
					data_out  <= VGA1_R;
					VGA1_RD_n <= RD_STOP;
					state     <= st_idle;

				when st_wait_ms =>
					if cnt < unsigned(data_in) then
						op_done <= '0';
						cnt_ms  <= (others => '0');
						cnt     <= cnt + 1;
						state   <= st_wait_one_ms;
					else
						op_done <= '1';
						state   <= st_idle;
					end if;

				when st_wait_one_ms =>
					if cnt_ms < ONE_MS_COUNT_TO then
						cnt_ms <= cnt_ms + 1;
						state  <= st_wait_one_ms;
					else
						state <= st_wait_ms;
					end if;

			end case;
		end if;
	end process;

end architecture rtl;
