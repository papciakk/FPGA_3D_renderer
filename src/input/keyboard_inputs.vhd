library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.keyboard_inc.all;

entity keyboard_inputs is
	port(
		clk      : in     std_logic;
		rst      : in     std_logic;
		ps2_clk  : in     std_logic;
		ps2_data : in     std_logic;
		key      : out    key_t;
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
			key        <= KEY_NONE;
		elsif rising_edge(code_ready) then
			if not break_code then
				case scancode is
					when X"1D" =>
						key <= KEY_W;
					when X"1B" =>
						key <= KEY_S;
					when X"1C" =>
						key <= KEY_A;
					when X"23" =>
						key <= KEY_D;
					when X"15" =>
						key <= KEY_Q;
					when X"24" =>
						key <= KEY_E;
					when X"1A" =>
						key <= KEY_Z;
					when X"22" =>
						key <= KEY_X;
					when others =>
						null;
				end case;
			else
				key <= KEY_NONE;
			end if;

			if scancode = X"F0" then
				break_code <= '1';
			else
				break_code <= '0';
			end if;
		end if;
	end process;

end architecture rtl;
