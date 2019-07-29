library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;

entity ps2_keyboard is
	generic(
		MAIN_CLK_MHZ  : integer := 50;
		IDLE_CNT_SIZE : integer := 12
	);

	port(
		clk          : in     std_logic;
		rst          : in     std_logic;
		ps2_clk_raw  : in     std_logic;
		ps2_data_raw : in     std_logic;
		error        : buffer std_logic;
		code_ready   : out    std_logic;
		code         : out    uint8_t
	);
end entity ps2_keyboard;

architecture arch of ps2_keyboard is
	constant HALF_CLK_PERIOD : integer := integer(55.56 * real(MAIN_CLK_MHZ));

	signal ps2_clk      : std_logic;
	signal ps2_data     : std_logic;
	signal in_word      : unsigned(10 downto 0);
	signal counter_idle : unsigned(IDLE_CNT_SIZE - 1 downto 0);
	signal start_stop   : std_logic;
	signal parity       : std_logic;

begin
	ps2_synchronize : process(clk, rst) is
	begin
		if rst then
			ps2_clk  <= '0';
			ps2_data <= '0';
		elsif falling_edge(clk) then
			ps2_clk  <= ps2_clk_raw;
			ps2_data <= ps2_data_raw;
		end if;
	end process;

	ps2_shift_data : process(ps2_clk, rst) is
	begin
		if rst then
			in_word <= (others => '0');
		elsif falling_edge(ps2_clk) then
			in_word <= ps2_data & in_word(10 downto 1);
		end if;
	end process;

	process(clk, rst) is
	begin
		if rst then
			counter_idle <= (others => '0');
			code_ready   <= '0';
			code         <= (others => '0');
		elsif rising_edge(clk) then
			if not ps2_clk then
				counter_idle <= (others => '0');
			elsif counter_idle /= HALF_CLK_PERIOD then
				counter_idle <= counter_idle + 1;
			end if;

			if counter_idle = HALF_CLK_PERIOD and error = '0' then
				code_ready <= '1';
				code       <= in_word(8 downto 1);
			else
				code_ready <= '0';
			end if;
		end if;
	end process;

	parity <= in_word(9) xor in_word(8) xor in_word(7) xor in_word(6) xor in_word(5) xor in_word(4) xor in_word(3) xor in_word(2) xor in_word(1);
	start_stop <= not in_word(0) and in_word(10);
	error <= not (start_stop and parity);

end architecture arch;
