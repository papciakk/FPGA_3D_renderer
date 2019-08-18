library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;

entity continous_measurement is
	port(
		clk         : in  std_logic;
		rst         : in  std_logic;
		step        : in  std_logic;
		value       : out integer;
		value_ready : out std_logic
	);
end entity;

architecture rtl of continous_measurement is
	type state_type is (st_init, st_run);
	signal state, state_next : state_type := st_init;

	signal value_next            : integer;
	signal value_ready_next      : std_logic := '0';
	signal counter, counter_next : integer   := 0;
begin
	process(clk, rst) is
	begin
		if rst then
			state <= st_init;
		elsif rising_edge(clk) then
			counter     <= counter_next;
			value_ready <= value_ready_next;
			value       <= value_next;
			state       <= state_next;
		end if;
	end process;

	process(all) is
	begin
		counter_next     <= counter;
		value_ready_next <= value_ready;
		value_next       <= value;
		state_next       <= state;

		case state is
			when st_init =>
				counter_next     <= 0;
				value_ready_next <= '0';
				state_next       <= st_run;
			when st_run =>
				if step then
					counter_next     <= 0;
					value_next       <= counter;
					value_ready_next <= '1';
				else
					counter_next <= counter + 1;
				end if;

				state_next <= st_run;
		end case;
	end process;

end architecture rtl;
