library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity single_measurment is
	port(
		clk   : in  std_logic;
		rst   : in  std_logic;
		run   : in  std_logic;
		value : out u32;
		done  : out std_logic
	);
end entity single_measurment;

architecture RTL of single_measurment is
	type state_type is (st_init, st_idle, st_run, st_done);
	signal state : state_type := st_init;

	signal counter : integer := 0;
begin
	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_init;
		elsif rising_edge(clk) then
			case state is
				when st_init =>
					counter <= 0;
					done    <= '0';
					state   <= st_idle;
				when st_idle =>
					if run = '1' then
						state <= st_run;
					else
						state <= st_idle;
					end if;
				when st_run =>
					if run = '1' then
						counter <= counter + 1;
						state   <= st_run;
					else
						state <= st_done;
					end if;
				when st_done =>
					done  <= '1';
					value <= to_unsigned(counter, 32);
					state <= st_done;
			end case;
		end if;
	end process;

end architecture RTL;
