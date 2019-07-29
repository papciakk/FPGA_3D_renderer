library ieee;
use ieee.std_logic_1164.all;
use work.stdint.all;

entity uart_receiver_buffer is
	port(
		clk, rst             : in  std_logic;
		clear_flag, set_flag : in  std_logic;
		data_in              : in  slv8_t;
		data_out             : out slv8_t;
		flag                 : out std_logic
	);
end entity;

architecture arch of uart_receiver_buffer is
	signal buf_reg, buf_next   : slv8_t;
	signal flag_reg, flag_next : std_logic;
begin
	process(clk, rst)
	begin
		if rst then
			buf_reg  <= slv8(0);
			flag_reg <= '0';
		elsif rising_edge(clk) then
			buf_reg  <= buf_next;
			flag_reg <= flag_next;
		end if;
	end process;

	process(buf_reg, flag_reg, set_flag, clear_flag, data_in)
	begin
		buf_next  <= buf_reg;
		flag_next <= flag_reg;

		if set_flag then
			buf_next  <= data_in;
			flag_next <= '1';
		elsif clear_flag then
			flag_next <= '0';
		end if;
	end process;

	data_out <= buf_reg;
	flag     <= flag_reg;
end architecture;
