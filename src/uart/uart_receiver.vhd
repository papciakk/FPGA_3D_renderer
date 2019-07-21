library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library common;
use common.stdint.all;

entity uart_rx is
	generic(
		DATA_BITS       : integer := 8;
		STOP_BITS_TICKS : integer := 16
	);
	port(
		clk          : in  std_logic;
		rst          : in  std_logic;
		rx           : in  std_logic;
		s_tick       : in  std_logic;
		rx_done_tick : out std_logic;
		dout         : out slv8_t
	);
end uart_rx;

architecture rtl of uart_rx is
	type state_type is (st_idle, st_start, st_data, st_stop);
	signal state, state_next : state_type;

	signal s, s_next : unsigned(3 downto 0);
	signal n, n_next : unsigned(2 downto 0);
	signal b, b_next : slv8_t;

begin
	process(clk, rst, state_next)
	begin
		if rst then
			state <= st_idle;
			s     <= (others => '0');
			n     <= (others => '0');
			b     <= slv8(0);
			state <= state_next;
		elsif rising_edge(clk) then
			state <= state_next;
			s     <= s_next;
			n     <= n_next;
			b     <= b_next;
		end if;
	end process;

	process(all)
	begin
		state_next   <= state;
		s_next       <= s;
		n_next       <= n;
		b_next       <= b;
		rx_done_tick <= '0';

		case state is
			when st_idle =>
				if not rx then
					s_next     <= (others => '0');
					state_next <= st_start;
				end if;

			when st_start =>
				if s_tick then
					if s = 7 then
						s_next     <= (others => '0');
						n_next     <= (others => '0');
						state_next <= st_data;
					else
						s_next <= s + 1;
					end if;
				end if;

			when st_data =>
				if s_tick then
					if s = 15 then
						s_next <= (others => '0');
						b_next <= rx & b(7 downto 1);

						if n = (DATA_BITS - 1) then
							state_next <= st_stop;
						else
							n_next <= n + 1;
						end if;
					else
						s_next <= s + 1;
					end if;
				end if;

			when st_stop =>
				if s_tick then
					if s = (STOP_BITS_TICKS - 1) then
						rx_done_tick <= '1';
						state_next   <= st_idle;
					else
						s_next <= s + 1;
					end if;
				end if;
		end case;
	end process;

	dout <= b;
end rtl;
