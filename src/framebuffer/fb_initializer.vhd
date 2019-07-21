library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
library common;
use common.stdint.all;

entity fb_initializer is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		---------------------------------------
		start         : in  std_logic;
		done          : out std_logic;
		---------------------------------------
		fb_data_write : out slv8_t;
		fb_op_start   : out std_logic;
		fb_op         : out fb_lo_level_op_type;
		fb_op_done    : in  std_logic
	);
end entity fb_initializer;

architecture rtl of fb_initializer is
	type fsm_state_type is (
		st_idle,
		st_fb_init, st_fb_init_wait,
		st_fb_do_operation, st_fb_do_operation_wait
	);
	signal state : fsm_state_type := st_idle;

	----------------------------------------

	signal cnt : uint32_t := uint32(0);

	----------------------------------------	

	type operation_type is (
		op_wr_cmd,
		op_wr_dat,
		op_waitms
	);

	type operation_data_pair_type is record
		operation : operation_type;
		data      : slv8_t;
	end record;

	type operation_list_type is array (natural range <>) of operation_data_pair_type;

	constant operation_list : operation_list_type := (
		(op_wr_cmd, X"01"),             -- soft_reset
		(op_waitms, X"0A"),             -- wait for 10ms

		---------------------------------------------------------	

		(op_wr_cmd, X"E2"),             -- set_pll_mn
		(op_wr_dat, X"1D"),             -- M = 29
		(op_wr_dat, X"02"),             -- N = 2
		(op_wr_dat, X"54"),             -- main clock = 10MHz * (29+1)/(2+1) = 100MHz

		(op_wr_cmd, X"E0"),             -- set_pll
		(op_wr_dat, X"01"),             -- enable PLL

		(op_waitms, X"01"),             -- wait 1ms

		(op_wr_cmd, X"E0"),             -- set_pll
		(op_wr_dat, X"03"),             -- lock PLL

		(op_wr_cmd, X"01"),             -- soft_reset

		---------------------------------------------------------

		(op_wr_cmd, X"B0"),             -- set_lcd_mode
		(op_wr_dat, X"20"),             -- 24-bit output interface
		(op_wr_dat, X"00"),             -- TFT mode
		(op_wr_dat, X"02"),             -- panel width = 639 + 1
		(op_wr_dat, X"7F"),             -- 
		(op_wr_dat, X"01"),             -- panel height = 479 + 1
		(op_wr_dat, X"DF"),             -- 
		(op_wr_dat, X"00"),             -- even & odd line in RGB order

		(op_wr_cmd, X"F0"),             -- set_pixel_data_interface
		(op_wr_dat, X"05"),             -- 24 bit

		(op_wr_cmd, X"E6"),             -- set_lshift_freq
		(op_wr_dat, X"03"),             -- for main clock = 100MHz
		(op_wr_dat, X"FF"),             -- pixel clock = 100MHz * ((LCDC_FPR+1)/2^20) = 25.175MHz
		(op_wr_dat, X"FF"),             -- LCDC_FPR = 263978

		(op_wr_cmd, X"B4"),             -- set_hori_period
		(op_wr_dat, X"03"),             -- HT = 640 + 48 + 16 + 96 - 1 = 799
		(op_wr_dat, X"1F"),             -- HT
		(op_wr_dat, X"00"),             -- HPS = 48 + 96 = 144
		(op_wr_dat, X"90"),             -- HPS
		(op_wr_dat, X"5F"),             -- HPW = 96 - 1 = 95
		(op_wr_dat, X"00"),             -- LPS = 0
		(op_wr_dat, X"00"),             -- LPS
		(op_wr_dat, X"00"),             -- LPSPP = 0

		(op_wr_cmd, X"B6"),             -- set_vert_period
		(op_wr_dat, X"02"),             -- VT = 480 + 33 + 10 + 2 - 1 = 524
		(op_wr_dat, X"0C"),             -- VT
		(op_wr_dat, X"00"),             -- VPS = 33 + 2 = 35
		(op_wr_dat, X"23"),             -- VPS
		(op_wr_dat, X"01"),             -- VPW = 2 - 1 = 1
		(op_wr_dat, X"00"),             -- FPS = 0
		(op_wr_dat, X"00"),             -- FPS

		(op_wr_cmd, X"2A"),             -- set_column_address
		(op_wr_dat, X"00"),             -- SC = 0
		(op_wr_dat, X"00"),             -- SC
		(op_wr_dat, X"02"),             -- EC = 640 - 1 = 639
		(op_wr_dat, X"7F"),             -- EC

		(op_wr_cmd, X"2B"),             -- set_page_address
		(op_wr_dat, X"00"),             -- SP = 0
		(op_wr_dat, X"00"),             -- SP
		(op_wr_dat, X"01"),             -- EP = 480 - 1 = 479
		(op_wr_dat, X"DF"),             -- EP
		
		---------------------------------------------------------

		(op_wr_cmd, X"13"),             -- enter_normal_mode
		(op_wr_cmd, X"38"),             -- exit_idle_mode
		(op_wr_cmd, X"29"),             -- set_display_on

		---------------------------------------------------------

		--(op_wr_cmd, X"35"),             -- set_tear_on
		--(op_wr_dat, X"00"),             -- v-blanking only
		
		---------------------------------------------------------
		
		(op_wr_cmd, X"B8"),             
		(op_wr_dat, "00001111"),             
		(op_wr_dat, "00000001"),            
		
		(op_wr_cmd, X"BA"),             
		(op_wr_dat, "00000010"), 

		(op_wr_cmd, X"2C")              -- write_memory_start
	);

	signal current_operation : operation_data_pair_type;
begin

	current_operation <= operation_list(to_integer(cnt));

	process(clk, rst) is
	begin
		if not rst then
			done  <= '0';
			state <= st_idle;
		elsif rising_edge(clk) then
			case state is
			
				when st_idle =>
					fb_op_start   <= '0';
					fb_data_write <= (others => '0');

					if start then
						state <= st_fb_init;
						done  <= '0';
					else
						state <= st_idle;
					end if;

				when st_fb_init =>
					fb_op       <= fb_lo_op_init;
					fb_op_start <= '1';
					state       <= st_fb_init_wait;

				when st_fb_init_wait =>
					fb_op_start <= '0';
					if fb_op_done then
						state <= st_fb_do_operation;
					else
						state <= st_fb_init_wait;
					end if;

					cnt <= (others => '0');

				when st_fb_do_operation =>
					fb_data_write <= current_operation.data;

					if current_operation.operation = op_wr_cmd then
						fb_op <= fb_lo_op_write_command;
					elsif current_operation.operation = op_waitms then
						fb_op <= fb_lo_op_wait_ms;
					else
						fb_op <= fb_lo_op_write_data;
					end if;

					fb_op_start <= '1';

					cnt   <= cnt + 1;
					state <= st_fb_do_operation_wait;

				when st_fb_do_operation_wait =>
					fb_op_start <= '0';

					if fb_op_done then
						if cnt < operation_list'length then
							state <= st_fb_do_operation;
						else
							done  <= '1';
							state <= st_idle;
						end if;
					else
						state <= st_fb_do_operation_wait;
					end if;

			end case;
		end if;
	end process;

end architecture rtl;
