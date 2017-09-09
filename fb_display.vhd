library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fb_types.all;

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
		fb_color_b    : out std_logic_vector(7 downto 0)
	);
end entity fb_display;

architecture RTL of fb_display is
	type state_type is (st_start, st_write_pixel_data, st_write_pixel_data_wait, st_idle);
	signal state : state_type := st_start;

	signal cnt : unsigned(19 downto 0);
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

				when st_write_pixel_data =>
					if cnt < 640*480 then
						cnt           <= cnt + 1;
						fb_data_write <= X"FF";
						fb_color_g    <= X"FF";
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

				when st_idle =>
					if start_write = '1' then
						write_done <= '0';
						cnt   <= (others => '0');
						state <= st_write_pixel_data;
					else
						state <= st_idle;
					end if;
			end case;
		end if;
	end process;

end architecture RTL;
