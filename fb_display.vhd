library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
use work.common.all;

entity fb_display is
	port(
		clk           : in     std_logic;
		rst           : in     std_logic;
		---------------------------------------
		start_write   : in     std_logic;
		write_done    : buffer std_logic;
		---------------------------------------
		fb_data_write : buffer std_logic_vector(7 downto 0);
		fb_op_start   : buffer std_logic;
		fb_op         : buffer fb_lo_level_op_type;
		fb_op_done    : in     std_logic;
		---------------------------------------
		do_clear      : in     std_logic;
		clear_color   : in     color_t;
		---------------------------------------
		fb_color_g    : buffer std_logic_vector(7 downto 0);
		fb_color_b    : buffer std_logic_vector(7 downto 0);
		---------------------------------------
		fb_window     : in     rect_t
	);
end entity fb_display;

architecture RTL of fb_display is
	type state_type is (
		st_start, st_write_pixel_data, st_write_pixel_data_wait, st_idle,
		st_init_window_0, st_init_window_0_wait, st_init_window_1, st_init_window_1_wait,
		st_init_window_2, st_init_window_2_wait, st_init_window_3, st_init_window_3_wait,
		st_init_window_4, st_init_window_4_wait, st_init_window_5, st_init_window_5_wait,
		st_init_window_6, st_init_window_6_wait, st_init_window_7, st_init_window_7_wait,
		st_init_window_8, st_init_window_8_wait, st_init_window_9, st_init_window_9_wait,
		st_init_window_10, st_init_window_10_wait
	);
	signal state, state_next : state_type := st_start;

	signal cnt, cnt_next   : unsigned(32 downto 0);
	signal cntx, cntx_next : unsigned(15 downto 0);
	signal cnty, cnty_next : unsigned(15 downto 0);
	
	signal clearing, clearing_next : std_logic;

	signal write_done_next    : std_logic;
	signal fb_data_write_next : std_logic_vector(7 downto 0);
	signal fb_op_start_next   : std_logic;
	signal fb_op_next         : fb_lo_level_op_type;
	signal fb_color_g_next    : std_logic_vector(7 downto 0);
	signal fb_color_b_next    : std_logic_vector(7 downto 0);

	signal grad, grad1  : integer;
	signal xx           : std_logic_vector(7 downto 0);
	signal buf_out      : color_t;
	signal buf_out_raw  : std_logic_vector(23 downto 0);
	signal tilebuf_addr : std_logic_vector(14 downto 0);

begin

	tilebuf_addr <= std_logic_vector(to_unsigned(to_integer(cnty * TILE_RES_X + cntx), 15));
	buf_out      <= (b => buf_out_raw(7 downto 0), g => buf_out_raw(15 downto 8), r => buf_out_raw(23 downto 16));

	--	tile_buffer_0 : entity work.tile_buffer
	--		port map(
	--			addr => tilebuf_addr,
	--			clk  => clk,
	--			q    => buf_out
	--		);

	img_rom0 : entity work.img_rom
		port map(
			address => tilebuf_addr,
			clock   => clk,
			q       => buf_out_raw
		);

	xx <= X"7F" when cntx > 200 and cntx < 400 else X"80";

	process(clk, rst) is
	begin
		if rst = '0' then
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
			clearing <= clearing_next;
		end if;
	end process;

	grad  <= (to_integer(cntx) / 2) when cntx < 512 else 0;
	grad1 <= grad when grad < 110 or grad > 150 else 125;

	process(state, cnt, fb_color_b, fb_color_g, fb_data_write, fb_op, fb_op_done, fb_op_start, fb_window.x0, fb_window.x1, fb_window.y0, fb_window.y1, start_write, write_done, cntx, cnty, grad1, buf_out.b, buf_out.g, buf_out.r) is
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
		clearing_next	   <= clearing;

		case state is
			when st_start =>
				write_done_next    <= '0';
				fb_data_write_next <= (others => '0');
				fb_op_start_next   <= '0';
				state_next         <= st_idle;

			when st_idle =>
				if start_write = '1' then
					write_done_next <= '0';
					cntx_next       <= (others => '0');
					cnty_next       <= (others => '0');
					state_next      <= st_init_window_0;
					clearing_next 	<= do_clear;
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
				if fb_op_done = '1' then
					state_next <= st_init_window_1;
				end if;

			when st_init_window_1 =>
				fb_data_write_next <= std_logic_vector(fb_window.x0)(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_1_wait;

			when st_init_window_1_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_2;
				end if;

			when st_init_window_2 =>
				fb_data_write_next <= std_logic_vector(fb_window.x0)(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_2_wait;

			when st_init_window_2_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_3;
				end if;

			when st_init_window_3 =>
				fb_data_write_next <= std_logic_vector(fb_window.x1)(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_3_wait;

			when st_init_window_3_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_4;
				end if;

			when st_init_window_4 =>
				fb_data_write_next <= std_logic_vector(fb_window.x1)(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_4_wait;

			when st_init_window_4_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_5;
				end if;

			when st_init_window_5 =>
				fb_data_write_next <= X"2B";
				fb_op_next         <= fb_lo_op_write_command;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_5_wait;

			when st_init_window_5_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_6;
				end if;

			when st_init_window_6 =>
				fb_data_write_next <= std_logic_vector(fb_window.y0)(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_6_wait;

			when st_init_window_6_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_7;
				end if;

			when st_init_window_7 =>
				fb_data_write_next <= std_logic_vector(fb_window.y0)(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_7_wait;

			when st_init_window_7_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_8;
				end if;

			when st_init_window_8 =>
				fb_data_write_next <= std_logic_vector(fb_window.y1)(15 downto 8);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_8_wait;

			when st_init_window_8_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_9;
				end if;

			when st_init_window_9 =>
				fb_data_write_next <= std_logic_vector(fb_window.y1)(7 downto 0);
				fb_op_next         <= fb_lo_op_write_data;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_9_wait;

			when st_init_window_9_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_init_window_10;
				end if;

			when st_init_window_10 =>
				fb_data_write_next <= X"2C";
				fb_op_next         <= fb_lo_op_write_command;
				fb_op_start_next   <= '1';
				state_next         <= st_init_window_10_wait;

			when st_init_window_10_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_write_pixel_data;
				end if;

			when st_write_pixel_data =>
				if cnty < (fb_window.y1 - fb_window.y0 + 1) then
					if cntx < (fb_window.x1 - fb_window.x0 + 1) then
						if clearing = '1' then
							fb_data_write_next <= clear_color.r;
							fb_color_g_next    <= clear_color.g;
							fb_color_b_next    <= clear_color.b;
						else
							fb_data_write_next <= buf_out.r;
							fb_color_g_next    <= buf_out.g;
							fb_color_b_next    <= buf_out.b;
						end if;
						--						fb_data_write_next <= std_logic_vector(to_unsigned(grad, 8));
						--						fb_color_g_next    <= std_logic_vector(to_unsigned(grad, 8));
						--						fb_color_b_next    <= std_logic_vector(to_unsigned(grad, 8));
						--fb_data_write_next <= X"FF";
						--fb_color_g_next    <= X"00";
						--fb_color_b_next    <= X"00";
						fb_op_next         <= fb_lo_op_write_data;
						fb_op_start_next   <= '1';
						state_next         <= st_write_pixel_data_wait;
						cntx_next          <= cntx + 1;
					else
						cntx_next <= (others => '0');
						cnty_next <= cnty + 1;
					end if;
				else
					write_done_next <= '1';
					clearing_next <= '0';
					state_next      <= st_idle;
				end if;

			when st_write_pixel_data_wait =>
				fb_op_start_next <= '0';
				if fb_op_done = '1' then
					state_next <= st_write_pixel_data;
				else
					state_next <= st_write_pixel_data_wait;
				end if;

		end case;
	end process;

end architecture RTL;
