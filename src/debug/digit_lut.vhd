library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package digits is
	subtype digit_t is std_logic_vector(0 to 255);
	type digit_array_t is array (0 to 9) of digit_t;
	subtype num_t is unsigned(3 downto 0);
	type num_array_t is array (1 downto 0) of num_t;

	constant digit_lut : digit_array_t := (
		X"03E007F00E380C18180C180C180C180C180C180C180C180C0C180E3807F003E0",
		X"008007801F801D8001800180018001800180018001800180018001803FFC3FFC",
		X"03C00FF01C301818181800180038007000E001C0030006000C0018003FF83FF8",
		X"03E007F00E380C1800180018003001E001F00038001C000C000C181C1FF80FE0",
		X"007000F000F001B001B003300330063006300C3018301FFC1FFC003001FC01FC",
		X"1FF81FF81800180018001BE01FF01C18180C000C000C000C000C38183FF00FE0",
		X"00F803FC078C0E000C001C001BE01FF01E381C1C180C180C0C0C0E1C07F803E0",
		X"1FFC1FFC180C1818001800180030003000600060006000C000C001C001800180",
		X"03E00FF80C18180C180C180C0C1807F007F00C18180C180C180C0C180FF803E0",
		X"03C007F00C381818180C180C180C1C1C0E3C07FC03EC0018003818701FE00F80"
	);

end package;
