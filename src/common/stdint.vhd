library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package stdint is

	-- TYPEDEFS

	subtype uint16_t is unsigned(15 downto 0);
	subtype int16_t is signed(15 downto 0);
	subtype uint32_t is unsigned(31 downto 0);
	subtype int32_t is signed(31 downto 0);
	subtype uint8_t is unsigned(7 downto 0);
	subtype int8_t is signed(7 downto 0);
	subtype uint4_t is unsigned(3 downto 0);
	subtype int4_t is signed(3 downto 0);
	subtype slv8_t is std_logic_vector(7 downto 0);
	subtype slv16_t is std_logic_vector(15 downto 0);
	subtype slv32_t is std_logic_vector(31 downto 0);

	constant INT16_MIN : std_logic_vector := X"8000";
	constant INT16_MAX : std_logic_vector := X"7FFF";

	-- FUNCTIONS

	function int32(i : signed) return int32_t;
	function int16(i : signed) return int16_t;
	function int8(i : signed) return int8_t;

	function uint32(i : unsigned) return uint32_t;
	function uint16(i : unsigned) return uint16_t;
	function uint8(i : unsigned) return uint8_t;

	function uint32(i : integer) return uint32_t;
	function uint16(i : integer) return uint16_t;
	function uint8(i : integer) return uint8_t;

	----------------------------------------------------

	function uint32(i : int32_t) return uint32_t;
	function uint16(i : int16_t) return uint16_t;
	function uint8(i : int8_t) return uint8_t;

	function int32(i : uint32_t) return int32_t;
	function int16(i : uint16_t) return int16_t;
	function int8(i : uint8_t) return int8_t;
		
	function int32(i : integer) return int32_t;
	function int16(i : integer) return int16_t;
	function int8(i : integer) return int8_t;

	----------------------------------------------------

	function int32(slv : slv8_t) return int32_t;
	function slv8(s : signed) return slv8_t;
	function slv8(i : integer) return slv8_t;

end package stdint;

package body stdint is

	-- FUNCTIONS

	function int32(i : signed) return int32_t is
	begin
		return resize(i, 32);
	end function;

	function int16(i : signed) return int16_t is
	begin
		return resize(i, 16);
	end function;

	function int8(i : signed) return int8_t is
	begin
		return resize(i, 8);
	end function;
	
	function int32(i : integer) return int32_t is
	begin
		return to_signed(i, 32);
	end function;
	
	function int16(i : integer) return int16_t is
	begin
		return to_signed(i, 16);
	end function;
	
	function int8(i : integer) return int8_t is
	begin
		return to_signed(i, 8);
	end function;

	----------------------------------------------------

	function uint32(i : unsigned) return uint32_t is
	begin
		return resize(i, 32);
	end function;

	function uint16(i : unsigned) return uint16_t is
	begin
		return resize(i, 16);
	end function;

	function uint8(i : unsigned) return uint8_t is
	begin
		return resize(i, 8);
	end function;
	
	function uint32(i : integer) return uint32_t is
	begin
		return to_unsigned(i, 32);
	end function;
	
	function uint16(i : integer) return uint16_t is
	begin
		return to_unsigned(i, 16);
	end function;
	
	function uint8(i : integer) return uint8_t is
	begin
		return to_unsigned(i, 8);
	end function;

	----------------------------------------------------

	function uint32(i : int32_t) return uint32_t is
	begin
		return uint32(unsigned(std_logic_vector(i)));
	end function;

	function uint16(i : int16_t) return uint16_t is
	begin
		return uint16(unsigned(std_logic_vector(i)));
	end function;

	function uint8(i : int8_t) return uint8_t is
	begin
		return uint8(unsigned(std_logic_vector(i)));
	end function;

	----------------------------------------------------

	function int32(i : uint32_t) return int32_t is
	begin
		return int32(signed(std_logic_vector(i)));
	end function;

	function int16(i : uint16_t) return int16_t is
	begin
		return int16(signed(std_logic_vector(i)));
	end function;

	function int8(i : uint8_t) return int8_t is
	begin
		return int8(signed(std_logic_vector(i)));
	end function;

	----------------------------------------------------

	function int32(slv : slv8_t) return int32_t is
	begin
		return resize(signed(slv), 32);
	end function;

	function slv8(s : signed) return slv8_t is
		variable slv : std_logic_vector(s'length - 1 downto 0);
	begin
		slv := std_logic_vector(s);
		return slv(7 downto 0);
	end function;

	function slv8(i : integer) return slv8_t is
	begin
		return std_logic_vector(to_unsigned(i, 8));
	end function;

end package body;
