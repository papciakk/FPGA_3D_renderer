library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;

entity fb_display is
	port(
		clk           : in     std_logic;
		rst           : in     std_logic;
		---------------------------------------
		start_write   : in     std_logic;
		write_done    : buffer std_logic;
		---------------------------------------
		fb_data_write : buffer slv8_t;
		fb_op_start   : buffer std_logic;
		fb_op         : buffer fb_lo_level_op_type;
		fb_op_done    : in     std_logic;
		---------------------------------------
		do_clear      : in     std_logic;
		clear_color   : in     color_t;
		---------------------------------------
		posx_out      : out    uint16_t;
		posy_out      : out    uint16_t;
		color_in      : in     color_t;
		---------------------------------------
		fb_color_g    : buffer slv8_t;
		fb_color_b    : buffer slv8_t;
		---------------------------------------
		fb_window     : in     rect_t
	);
end entity fb_display;

architecture rtl of fb_display is
	type state_type is (
		st_start, st_write_pixel_data, st_write_pixel_data_wait, st_write_pixel_data_wait_last, st_idle,
		st_init_window_0, st_init_window_0_wait, st_init_window_1, st_init_window_1_wait,
		st_init_window_2, st_init_window_2_wait, st_init_window_3, st_init_window_3_wait,
		st_init_window_4, st_init_window_4_wait, st_init_window_5, st_init_window_5_wait,
		st_init_window_6, st_init_window_6_wait, st_init_window_7, st_init_window_7_wait,
		st_init_window_8, st_init_window_8_wait, st_init_window_9, st_init_window_9_wait,
		st_init_window_10, st_init_window_10_wait
	);
	signal state, state_next : state_type := st_start;

	signal cnt, cnt_next           : uint32_t;
	signal cntx, cntx_next         : uint16_t;
	signal cnty, cnty_next         : uint16_t;
	signal cntx_cnt, cntx_cnt_next : uint16_t;
	signal cnty_cnt, cnty_cnt_next : uint16_t;

	signal clearing, clearing_next : std_logic;

	signal write_done_next    : std_logic;
	signal fb_data_write_next : slv8_t;
	signal fb_op_start_next   : std_logic;
	signal fb_op_next         : fb_lo_level_op_type;
	signal fb_color_g_next    : slv8_t;
	signal fb_color_b_next    : slv8_t;

	signal fb_window_x0 : std_logic_vector(15 downto 0);
	signal fb_window_y0 : std_logic_vector(15 downto 0);
	signal fb_window_x1 : std_logic_vector(15 downto 0);
	signal fb_window_y1 : std_logic_vector(15 downto 0);
	
	constant CNT_X_LIMIT : integer := sel(MODE_320_240, TILE_RES_X * 2, TILE_RES_X);
	constant CNT_Y_LIMIT : integer := sel(MODE_320_240, TILE_RES_Y * 2 , TILE_RES_Y);
	
begin
	posx_out <= sel(MODE_320_240, shift_right(cntx, 1), cntx);
	posy_out <= sel(MODE_320_240, shift_right(cnty, 1), cnty);

	fb_window_x0 <= std_logic_vector(sel(MODE_320_240, shift_left(fb_window.x0, 1), fb_window.x0));
	fb_window_y0 <= std_logic_vector(sel(MODE_320_240, shift_left(fb_window.y0, 1), fb_window.y0));
	fb_window_x1 <= std_logic_vector(sel(MODE_320_240, shift_left(fb_window.x1, 1) + 1, fb_window.x1));
	fb_window_y1 <= std_logic_vector(sel(MODE_320_240, shift_left(fb_window.y1, 1) + 1, fb_window.y1));

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			write_done    <= write_done_next;
			fb_data_write <= fb_data_write_next;
			fb_op_start   <= fb_op_start_next;
			fb_op         <= fb_op_next;
			fb_color_g    <= fb_color_g_next;
			fb_color_b    <= fb_color_b_next;
			state         <= state_next;
			cnt           <= cnt_next;
			cntx          <= cntx_next;
			cnty          <= cnty_next;
			cntx_cnt      <= cntx_cnt_next;
			cnty_cnt      <= cnty_cnt_next;
			clearing      <= clearing_next;
		end if;
	end process;

	process(all) is
	begin
		write_done_next    <= write_done;
		fb_data_write_next <= fb_data_write;
		fb_op_start_next   <= fb_op_start;
		fb_op_next         <= fb_op;
		fb_color_g_next    <= fb_color_g;
		fb_color_b_next    <= fb_color_b;
		state_next         <= state;
		cnt_next           <= cnt;
		cntx_next          <= cntx;
		cnty_next          <= cnty;
		cntx_cnt_next      <= cntx_cnt;
		cnty_cnt_next      <= cnty_cnt;
		clearing_next      <= clearing;

		case state is
			when st_start =>
				write_done_next    <= '0';
				fb_data_write_next <= (others => '0');
				fb_op_start_next   <= '0';
				state_next         <= st_idle;

			when st_idle =>
				if start_write then
					write_done_next <= '0';
					cntx_next       <= uint16(1);
					cnty_next       <= (others => '0');
					cntx_cnt_next   <= uint16(1);
					cnty_cnt_next   <= (others => '0');
					state_next      <= st_init_window_0;
					clearing_next   <= do_clear;
				else
					state_next <= st_idle;
				end if;

			when st_init_window_0 =>
				fb_data_write_next <= X"2A";
				fb_op_next         <= fb_lo_op_write_command;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_0_wait;

			when st_init_window_0_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_1;
				end if;

			when st_init_window_1 =>
				fb_data_write_next <= fb_window_x0(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_1_wait;

			when st_init_window_1_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_2;
				end if;

			when st_init_window_2 =>
				fb_data_write_next <= fb_window_x0(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_2_wait;

			when st_init_window_2_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_3;
				end if;

			when st_init_window_3 =>
				fb_data_write_next <= fb_window_x1(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_3_wait;

			when st_init_window_3_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_4;
				end if;

			when st_init_window_4 =>
				fb_data_write_next <= fb_window_x1(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_4_wait;

			when st_init_window_4_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_5;
				end if;

			when st_init_window_5 =>
				fb_data_write_next <= X"2B";
				fb_op_next         <= fb_lo_op_write_command;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_5_wait;

			when st_init_window_5_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_6;
				end if;

			when st_init_window_6 =>
				fb_data_write_next <= fb_window_y0(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_6_wait;

			when st_init_window_6_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_7;
				end if;

			when st_init_window_7 =>
				fb_data_write_next <= fb_window_y0(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_7_wait;

			when st_init_window_7_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_8;
				end if;

			when st_init_window_8 =>
				fb_data_write_next <= fb_window_y1(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_8_wait;

			when st_init_window_8_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_9;
				end if;

			when st_init_window_9 =>
				fb_data_write_next <= fb_window_y1(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_9_wait;

			when st_init_window_9_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_init_window_10;
				end if;

			when st_init_window_10 =>
				fb_data_write_next <= X"2C";
				fb_op_next         <= fb_lo_op_write_command;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_10_wait;

			when st_init_window_10_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					state_next <= st_write_pixel_data;
				end if;

			when st_write_pixel_data =>
				if cnty_cnt < CNT_Y_LIMIT then
					if cntx_cnt < CNT_X_LIMIT then
						cntx_next <= cntx_cnt;
						cnty_next <= cnty_cnt;

						if clearing then
							fb_data_write_next <= clear_color.r;
							fb_color_g_next    <= clear_color.g;
							fb_color_b_next    <= clear_color.b;
						else
							fb_data_write_next <= color_in.r;
							fb_color_g_next    <= color_in.g;
							fb_color_b_next    <= color_in.b;
						end if;

						fb_op_next       <= fb_lo_op_write_data;
						fb_op_start_next <= '1';
						state_next       <= st_write_pixel_data_wait;
					else
						cntx_cnt_next <= (others => '0');
						cnty_cnt_next <= cnty_cnt + 1;
					end if;
				else
					fb_op_next       <= fb_lo_op_write_data;
					fb_op_start_next <= '1';
					state_next      <= st_write_pixel_data_wait_last;
				end if;

			when st_write_pixel_data_wait =>
				fb_op_start_next <= '0';
				if fb_op_done then
					cntx_cnt_next <= cntx + 1;
					state_next    <= st_write_pixel_data;
				else
					state_next <= st_write_pixel_data_wait;
				end if;
				
			when st_write_pixel_data_wait_last =>
				fb_op_start_next <= '0';
				if fb_op_done then
					write_done_next <= '1';
					clearing_next   <= '0';
					cntx_cnt_next   <= (others => '0');
					cnty_cnt_next   <= (others => '0');
					state_next    <= st_start;
				else
					state_next <= st_write_pixel_data_wait_last;
				end if;

		end case;
	end process;

end architecture rtl;
