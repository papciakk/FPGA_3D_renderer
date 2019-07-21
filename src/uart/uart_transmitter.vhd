library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library common;
use common.stdint.all;

entity uart_transmitter is
	generic(
		DATA_BITS : integer := 8;
		STOP_BITS : real    := 1.0
	);

	port(
		clk         : in  std_logic;
		rst         : in  std_logic;
		start       : in  std_logic;
		baud_gen_in : in  std_logic;
		txd         : out std_logic;
		done        : out std_logic;
		data        : in  uint8_t
	);

end uart_transmitter;

architecture rtl of uart_transmitter is
	type transmitter_state is (st_idle, st_start, st_data, st_stop);
	signal state, state_next : transmitter_state := st_idle;

	signal n, n_next   : unsigned(2 downto 0) := (others => '0');
	signal s, s_next   : unsigned(3 downto 0) := (others => '0');
	signal b, b_next   : unsigned(7 downto 0) := (others => '0');
	signal tx, tx_next : std_logic            := '1';

	constant STOP_TICKS : integer := integer(real(16) * STOP_BITS);

begin
	process(clk, rst) is
	begin
		if rst then
			state <= st_idle;
			n     <= (others => '0');
			s     <= (others => '0');
			b     <= (others => '0');
			tx    <= '1';
		elsif rising_edge(clk) then
			state <= state_next;
			n     <= n_next;
			s     <= s_next;
			b     <= b_next;
			tx    <= tx_next;
		end if;
	end process;

	process(state, baud_gen_in, n, s, b, data, start, tx) is
	begin
		state_next <= state;
		n_next     <= n;
		s_next     <= s;
		b_next     <= b;
		tx_next    <= tx;

		done <= '0';

		case state is
			when st_idle =>
				tx_next <= '1';
				if start then
					s_next     <= (others => '0');
					b_next     <= data;
					state_next <= st_start;
				end if;

			when st_start =>
				tx_next <= '0';
				if baud_gen_in then
					if s = 15 then
						s_next     <= (others => '0');
						n_next     <= (others => '0');
						state_next <= st_data;
					else
						s_next <= s + 1;
					end if;
				end if;

			when st_data =>
				tx_next <= b(0);
				if baud_gen_in then
					if s = 15 then
						b_next <= '0' & b(7 downto 1);
						s_next <= (others => '0');
						if n = DATA_BITS - 1 then
							state_next <= st_stop;
						else
							n_next <= n + 1;
						end if;
					else
						s_next <= s + 1;
					end if;
				end if;

			when st_stop =>
				tx_next <= '1';
				if baud_gen_in then
					if s = STOP_TICKS - 1 then
						done       <= '1';
						state_next <= st_idle;
					else
						s_next <= s + 1;
					end if;
				end if;

		end case;
	end process;

	txd <= tx;

end rtl;
