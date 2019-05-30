library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.txt_util.all;

entity printf is
	port(
		clk      : in  std_logic;
		rst      : in  std_logic;
		uart_txd : out std_logic;
		done     : out std_logic;
		send     : in  std_logic;
		val      : in  integer
	);
end entity printf;

architecture RTL of printf is
	type state_type is (
		st_start, st_idle, st_print_integer, st_print_integer_2, st_send_char_start, st_send_char_wait, st_send_newline_char, st_send_newline_char_wait
	);
	signal state, state_next : state_type := st_start;

	signal uart_start_transmit, uart_start_transmit_next : std_logic := '0';
	signal uart_baudrate_tick                            : std_logic;

	signal val_d, val_d_next         : unsigned(31 downto 0);
	signal val_char, val_char_next   : unsigned(3 downto 0);
	signal uart_char, uart_char_next : unsigned(7 downto 0);

	type buf_arr_t is array (7 downto 0) of u8;
	signal buf_arr                               : buf_arr_t;
	signal buf_arr_pointer, buf_arr_pointer_next : s8;

	function hex_to_ascii(val : unsigned(3 downto 0)) return unsigned is
		variable v : integer;
	begin
		case val is
			when X"0"   => v := 48;
			when X"1"   => v := 49;
			when X"2"   => v := 50;
			when X"3"   => v := 51;
			when X"4"   => v := 52;
			when X"5"   => v := 53;
			when X"6"   => v := 54;
			when X"7"   => v := 55;
			when X"8"   => v := 56;
			when X"9"   => v := 57;
			when X"A"   => v := 65;
			when X"B"   => v := 66;
			when X"C"   => v := 67;
			when X"D"   => v := 68;
			when X"E"   => v := 69;
			when X"F"   => v := 70;
			when others => v := 0;
		end case;
		return to_unsigned(v, 8);
	end function;

begin

	uart_baudrate_generator0 : entity work.uart_baudrate_generator
		generic map(
			BAUDRATE     => 115200,
			MAIN_CLK_MHZ => 50
		)
		port map(
			clk  => clk,
			rst  => rst,
			tick => uart_baudrate_tick
		);

	uart_transmitter0 : entity work.uart_transmitter
		generic map(
			DATA_BITS => 8,
			STOP_BITS => 1.0
		)
		port map(
			clk         => clk,
			rst         => rst,
			start       => uart_start_transmit,
			baud_gen_in => uart_baudrate_tick,
			txd         => uart_txd,
			done        => done,
			data        => uart_char
		);

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			uart_start_transmit <= uart_start_transmit_next;
			state               <= state_next;
			val_d               <= val_d_next;
			val_char            <= val_char_next;
			buf_arr_pointer     <= buf_arr_pointer_next;
			uart_char           <= uart_char_next;
		end if;
	end process;

	process(uart_start_transmit, state, val_d, val_char, buf_arr_pointer, uart_char, send, val, done, buf_arr) is
	begin
		uart_start_transmit_next <= uart_start_transmit;
		state_next               <= state;
		val_d_next               <= val_d;
		val_char_next            <= val_char;
		buf_arr_pointer_next     <= buf_arr_pointer;
		uart_char_next           <= uart_char;

		case state is
			when st_start =>
				uart_start_transmit_next <= '0';
				state_next               <= st_idle;
			when st_idle =>
				uart_start_transmit_next <= '0';
				if send = '1' then
					state_next <= st_print_integer;
					buf_arr_pointer_next <= (others => '0');
					val_d_next <= to_unsigned(val, 32);
				else
					state_next <= st_idle;
				end if;
			when st_print_integer =>
				uart_start_transmit_next <= '0';

				val_char_next <= val_d(3 downto 0);
				val_d_next    <= val_d srl 4;

				state_next <= st_print_integer_2;

			when st_print_integer_2 =>
				buf_arr(to_integer(buf_arr_pointer)) <= hex_to_ascii(val_char);

				if val_d > 0 then
					buf_arr_pointer_next                 <= buf_arr_pointer + 1;
					state_next <= st_print_integer;
				else
					state_next <= st_send_char_start;
				end if;

			when st_send_char_start =>
				uart_start_transmit_next <= '1';
				uart_char_next           <= buf_arr(to_integer(buf_arr_pointer));
				buf_arr_pointer_next     <= buf_arr_pointer - 1;
				state_next               <= st_send_char_wait;

			when st_send_char_wait =>
				uart_start_transmit_next <= '0';
				if done = '1' then
					if buf_arr_pointer = -1 then
						state_next <= st_send_newline_char;
					else
						state_next <= st_send_char_start;
					end if;
				else
					state_next <= st_send_char_wait;
				end if;

			when st_send_newline_char =>
				uart_start_transmit_next <= '1';
				uart_char_next           <= to_unsigned(10, 8);
				state_next               <= st_send_newline_char_wait;

			when st_send_newline_char_wait =>
				uart_start_transmit_next <= '0';
				if done = '1' then
					state_next <= st_idle;
				else
					state_next <= st_send_newline_char_wait;
				end if;

		end case;
	end process;
end architecture RTL;

