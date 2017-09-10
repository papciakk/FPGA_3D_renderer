library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;
use work.common.all;

entity fb_display is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		---------------------------------------
		start_write   : in  std_logic;
		write_done    : out std_logic;
		---------------------------------------
		fb_data_write : out std_logic_vector(7 downto 0);
		fb_op_start   : out std_logic;
		fb_op         : out fb_lo_level_op_type;
		fb_op_done    : in  std_logic;
		---------------------------------------
		fb_color_g    : out std_logic_vector(7 downto 0);
		fb_color_b    : out std_logic_vector(7 downto 0);
		---------------------------------------
		fb_window     : in rect_t 
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
	signal state : state_type := st_start;

	signal cnt : unsigned(31 downto 0);
begin
	process(clk, rst) is
	begin
		if rst = '0' then
			state <= st_start;
		elsif rising_edge(clk) then
			case state is
				when st_start =>
					write_done <= '0';
					fb_data_write <= (others => '0');
					fb_op_start <= '0';
					state <= st_idle;
					
				when st_idle =>
					if start_write = '1' then
						write_done <= '0';
						cnt   <= (others => '0');
						state <= st_init_window_0;
					else
						state <= st_idle;
					end if;
					
				when st_init_window_0 =>
					fb_data_write <= X"2A";
					fb_op <= fb_lo_op_write_command;
					fb_op_start <= '1';
					state <= st_init_window_0_wait;
				
				when st_init_window_0_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_1;
					end if;
				
				when st_init_window_1 =>
					fb_data_write <= std_logic_vector(fb_window.x0)(15 downto 8);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_1_wait;
				
				when st_init_window_1_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_2;
					end if;
					
				when st_init_window_2 =>
					fb_data_write <= std_logic_vector(fb_window.x0)(7 downto 0);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_2_wait;
				
				when st_init_window_2_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_3;
					end if;
					
				when st_init_window_3 =>
					fb_data_write <= std_logic_vector(fb_window.x1)(15 downto 8);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_3_wait;
				
				when st_init_window_3_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_4;
					end if;
					
				when st_init_window_4 =>
					fb_data_write <= std_logic_vector(fb_window.x1)(7 downto 0);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_4_wait;
				
				when st_init_window_4_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_5;
					end if;
					
				when st_init_window_5 =>
					fb_data_write <= X"2B";
					fb_op <= fb_lo_op_write_command;
					fb_op_start <= '1';
					state <= st_init_window_5_wait;
				
				when st_init_window_5_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_6;
					end if;
					
				when st_init_window_6 =>
					fb_data_write <= std_logic_vector(fb_window.y0)(15 downto 8);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_6_wait;
				
				when st_init_window_6_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_7;
					end if;
					
				when st_init_window_7 =>
					fb_data_write <= std_logic_vector(fb_window.y0)(7 downto 0);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_7_wait;
				
				when st_init_window_7_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_8;
					end if;
					
				when st_init_window_8 =>
					fb_data_write <= std_logic_vector(fb_window.y1)(15 downto 8);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_8_wait;
				
				when st_init_window_8_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_9;
					end if;
					
				when st_init_window_9 =>
					fb_data_write <= std_logic_vector(fb_window.y1)(7 downto 0);
					fb_op <= fb_lo_op_write_data;
					fb_op_start <= '1';
					state <= st_init_window_9_wait;
				
				when st_init_window_9_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_init_window_10;
					end if;
					
				when st_init_window_10 =>
					fb_data_write <= X"2C";
					fb_op <= fb_lo_op_write_command;
					fb_op_start <= '1';
					state <= st_init_window_10_wait;
				
				when st_init_window_10_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_write_pixel_data;
					end if;

				when st_write_pixel_data =>
					if cnt < 641*481 then
						cnt           <= cnt + 1;
						fb_data_write <= X"FF";
						fb_color_g    <= X"00";
						fb_color_b    <= X"00";
						fb_op         <= fb_lo_op_write_data;
						fb_op_start   <= '1';
						state         <= st_write_pixel_data_wait;
					else
						write_done <= '1';
						state <= st_idle;
					end if;

				when st_write_pixel_data_wait =>
					fb_op_start <= '0';
					if fb_op_done = '1' then
						state <= st_write_pixel_data;
					else
						state <= st_write_pixel_data_wait;
					end if;
					
			end case;
		end if;
	end process;

end architecture RTL;
