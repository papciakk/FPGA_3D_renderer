library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all; 

entity single_measurment is
	port(
		clk   : in  std_logic;
		rst   : in  std_logic;
		run   : in  std_logic;
		value : out uint32_t;
		done  : out std_logic
	);
end entity single_measurment;

architecture rtl of single_measurment is
	type state_type is (st_init, st_idle, st_run, st_done);
	signal state : state_type := st_init;

	signal counter : integer := 0;
begin
	process(clk, rst) is
	begin
		if rst then
			state <= st_init;
		elsif rising_edge(clk) then
			case state is
				when st_init =>
					counter <= 0;
					done    <= '0';
					state   <= st_idle;
				when st_idle =>
					if run then
						state <= st_run;
					else
						state <= st_idle;
					end if;
				when st_run =>
					if run  then
						counter <= counter + 1;
						state   <= st_run;
					else
						state <= st_done;
					end if;
				when st_done =>
					done  <= '1';
					value <= uint32(counter);
					state <= st_done;
			end case;
		end if;
	end process;

end architecture rtl;
