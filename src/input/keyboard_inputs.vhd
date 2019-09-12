library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.keyboard_inc.all;

entity keyboard_inputs is
	port(
		clk      : in     std_logic;
		rst      : in     std_logic;
		ps2_clk  : in     std_logic;
		ps2_data : in     std_logic;
		keys     : out    keys_t;
		error    : out    std_logic;
		scancode : buffer uint8_t
	);
end entity keyboard_inputs;

architecture rtl of keyboard_inputs is
	signal break_code : std_logic := '0';
	signal code_ready : std_logic;
begin

	ps2_keyboard_0 : entity work.ps2_keyboard
		port map(
			clk          => clk,
			rst          => rst,
			ps2_clk_raw  => ps2_clk,
			ps2_data_raw => ps2_data,
			error        => error,
			code_ready   => code_ready,
			code         => scancode
		);

	process(code_ready, rst) is
	begin
		if rst then
			break_code <= '0';
			keys       <= (others => '0');
		elsif rising_edge(code_ready) then
			case scancode is
				when X"1D" =>
					keys(KEY_W) <= not break_code;
				when X"1B" =>
					keys(KEY_S) <= not break_code;
				when X"1C" =>
					keys(KEY_A) <= not break_code;
				when X"23" =>
					keys(KEY_D) <= not break_code;
				when X"15" =>
					keys(KEY_Q) <= not break_code;
				when X"24" =>
					keys(KEY_E) <= not break_code;
				when X"1A" =>
					keys(KEY_Z) <= not break_code;
				when X"22" =>
					keys(KEY_X) <= not break_code;
				when X"2C" =>
					keys(KEY_T) <= not break_code;
				when X"34" =>
					keys(KEY_G) <= not break_code;
				when X"2B" =>
					keys(KEY_F) <= not break_code;
				when X"33" =>
					keys(KEY_H) <= not break_code;
				when X"F0" =>
					break_code <= '1';
				when others =>
			end case;

			if scancode /= X"F0" then
				break_code <= '0';
			end if;
		end if;
	end process;

end architecture rtl;