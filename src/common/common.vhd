library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package common is

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

	type color_t is record
		r : slv8_t;
		g : slv8_t;
		b : slv8_t;
	end record;

	type rect_t is record
		x0, x1, y0, y1 : uint16_t;
	end record;

	type srect_t is record
		x0, x1, y0, y1 : int16_t;
	end record;

	type point2d_t is record
		x, y : int16_t;
	end record;
	
	type point2d_32_t is record
		x, y : int32_t;
	end record;

	type point3d_t is record
		x, y, z : int16_t;
	end record;
	
	type point3d_32_t is record
		x, y, z : int32_t;
	end record;
	
	type triangle2d_t is array (0 to 2) of point2d_t;
	type triangle3d_t is array (0 to 2) of point3d_t;
	
	type vertex_attr_t is record
		pos : point3d_t;
		normal : point3d_t;
	end record;
	
	type vertex_attr_32_t is record
		pos : point3d_32_t;
		normal : point3d_t;
	end record;

	--type triangle_t is array (0 to 2) of vertex_attr_t;
	
	type triangle_colors_t is array (0 to 2) of color_t;

	type triangle_indices_t is record
		a, b, c : uint16_t;
	end record;

	type vertex_arr_2d_t is array (natural range <>) of point2d_t;
	type vertex_arr_3d_t is array (natural range <>) of point3d_t;
	type vertex_attr_arr_t is array (natural range <>) of vertex_attr_t;

	type indices_arr_t is array (natural range <>) of triangle_indices_t;

	-- CONSTANTS

	constant BITS_PER_PIXEL : integer := 24;
	
	constant TILE_RES_X : integer := 128;
	constant TILE_RES_Y : integer := 120;

	constant FULLSCREEN_RES_X : integer := 640;
	constant FULLSCREEN_RES_Y : integer := 480;
	
	constant HALF_FULLSCREEN_RES_X : integer := FULLSCREEN_RES_X / 2;
	constant HALF_FULLSCREEN_RES_Y : integer := FULLSCREEN_RES_Y / 2;

	constant FULLSCREEN_RECT : rect_t := (
		x0 => to_unsigned(0, 16),
		x1 => to_unsigned((FULLSCREEN_RES_X - 1), 16),
		y0 => to_unsigned(0, 16),
		y1 => to_unsigned((FULLSCREEN_RES_Y - 1), 16)
	);

	constant TILE_ADDR_LEN : natural := integer(ceil(log2(real(TILE_RES_X * TILE_RES_Y))));

	constant COLOR_BLACK : color_t := (others => X"00");
	constant COLOR_WHITE : color_t := (others => X"FF");
	constant COLOR_RED   : color_t := (r => X"FF", others => X"00");
	constant COLOR_GREEN : color_t := (g => X"FF", others => X"00");
	constant COLOR_BLUE  : color_t := (b => X"FF", others => X"00");
	
	-- FUNCTIONS

	function color(r, g, b : signed) return color_t;
	function color(r, g, b : std_logic_vector) return color_t;

	----------------------------------------------------

	function point2d(x : integer; y : integer) return point2d_t;
	function point3d(x : integer; y : integer; z : integer) return point3d_t;
	function point3d(x, y, z : signed) return point3d_t;
		
	----------------------------------------------------
		
	function va(vx, vy, vz, nx, ny, nz : integer) return vertex_attr_t;
	function idx(a : integer; b : integer; c : integer) return triangle_indices_t;

	----------------------------------------------------

	function maximum2(x, y : signed) return signed;
	function minimum2(x, y : signed) return signed;
	function maximum3(x, y, z : signed) return signed;
	function minimum3(x, y, z : signed) return signed;
		
	----------------------------------------------------

	function uint16_with_cut(s : int16_t) return uint16_t;
	
	----------------------------------------------------
		
	function int32(i : signed) return int32_t;
	function int16(i : signed) return int16_t;
	function int8(i : signed) return int8_t;
		
	function uint32(i : unsigned) return uint32_t;
	function uint16(i : unsigned) return uint16_t;
	function uint8(i : unsigned) return uint8_t;
		
	----------------------------------------------------
	
	function uint32(i : int32_t) return uint32_t;
	function uint16(i : int16_t) return uint16_t;
	function uint8(i : int8_t) return uint8_t;
		
	function int32(i : uint32_t) return int32_t;
	function int16(i : uint16_t) return int16_t;
	function int8(i : uint8_t) return int8_t;
		
	----------------------------------------------------
	
	function int32(slv : slv8_t) return int32_t;

end package common;

package body common is

	-- FUNCTIONS

	function color(r, g, b : signed) return color_t is
	begin
		return (
			r => std_logic_vector(r(7 downto 0)), 
			g => std_logic_vector(g(7 downto 0)), 
			b => std_logic_vector(b(7 downto 0))
		);
	end function;
	
	function color(r, g, b : std_logic_vector) return color_t is
	begin
		return (
			r => r, 
			g => g, 
			b => b
		);
	end function;

	function point2d(x : integer; y : integer) return point2d_t is
	begin
		return (x => to_signed(x, 16), y => to_signed(y, 16));
	end function;
	
	function point3d(x : integer; y : integer; z: integer) return point3d_t is
	begin
		return (x => to_signed(x, 16), y => to_signed(y, 16), z => to_signed(z, 16));
	end function;
	
	function point3d(x, y, z : signed) return point3d_t is
	begin
		return (x => x, y => y, z => z);
	end function;
	
	function va(vx, vy, vz, nx, ny, nz : integer) return vertex_attr_t is
	begin
		return (
			pos => point3d(vx, vy, vz),
			normal => point3d(nx, ny, nz)
		);
	end function;
	
	function idx(a : integer; b : integer; c: integer) return triangle_indices_t is
	begin
		return (a => to_unsigned(a, 16), b => to_unsigned(b, 16), c => to_unsigned(c, 16));
	end function;
	
	function minimum3(x, y, z : signed) return signed is
	begin 
		if x < y then
			if x < z then return x; else return z; end if;
		else
			if y < z then return y; else return z; end if;
		end if;
	end function;
	
	function maximum3(x, y, z : signed) return signed is
	begin 
		if x > y then
			if x > z then return x; else return z; end if;
		else
			if y > z then return y; else return z; end if;
		end if;
	end function;
	
	function minimum2(x, y : signed) return signed is
	begin
		if x < y then return x; else return y; end if;
	end function;
	
	function maximum2(x, y : signed) return signed is
	begin
		if x > y then return x; else return y; end if;
	end function;
	
	----------------------------------------------------
	
	function uint16_with_cut(s : int16_t) return uint16_t is
	begin
		if s < 0 then
			return (others => '0');
		else
			return uint16(s);
		end if; 		
	end function;
	
	----------------------------------------------------
	
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
	

end package body;
