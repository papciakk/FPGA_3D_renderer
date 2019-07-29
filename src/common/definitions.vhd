library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.stdint.all;

package definitions is

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
	type triangle3d_32_t is array (0 to 2) of point3d_32_t;

	type vertex_attr_t is record
		pos    : point3d_t;
		normal : point3d_t;
	end record;

	type vertex_attr_32_t is record
		pos    : point3d_32_t;
		normal : point3d_t;
	end record;

	type triangle_colors_t is array (0 to 2) of color_t;

	type triangle_indices_t is record
		a, b, c : uint16_t;
	end record;

	type vertex_arr_2d_t is array (natural range <>) of point2d_t;
	type vertex_arr_3d_t is array (natural range <>) of point3d_t;
	type vertex_attr_arr_t is array (natural range <>) of vertex_attr_t;

	type indices_arr_t is array (natural range <>) of triangle_indices_t;

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

	function point3d_32(p : point3d_t) return point3d_32_t;
	function triangle3d(v1, v2, v3 : point3d_t) return triangle3d_t;

	----------------------------------------------------

	function sel(cond : boolean; opt1 : std_logic; opt2 : std_logic) return std_logic;
	function sel(cond : boolean; opt1 : std_logic_vector; opt2 : std_logic_vector) return std_logic_vector;
	function sel(cond : boolean; opt1 : unsigned; opt2 : unsigned) return unsigned;
	function sel(cond : boolean; opt1 : signed; opt2 : signed) return signed;
	function sel(cond : boolean; opt1 : integer; opt2 : integer) return integer;

end package definitions;

package body definitions is

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
		return (r => r, g => g, b => b);
	end function;

	function point2d(x : integer; y : integer) return point2d_t is
	begin
		return (x => to_signed(x, 16), y => to_signed(y, 16));
	end function;

	function point3d(x : integer; y : integer; z : integer) return point3d_t is
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
			pos    => point3d(vx, vy, vz),
			normal => point3d(nx, ny, nz)
		);
	end function;

	function idx(a : integer; b : integer; c : integer) return triangle_indices_t is
	begin
		return (a => to_unsigned(a, 16), b => to_unsigned(b, 16), c => to_unsigned(c, 16));
	end function;

	function minimum3(x, y, z : signed) return signed is
	begin
		if x < y then
			if x < z then
				return x;
			else
				return z;
			end if;
		else
			if y < z then
				return y;
			else
				return z;
			end if;
		end if;
	end function;

	function maximum3(x, y, z : signed) return signed is
	begin
		if x > y then
			if x > z then
				return x;
			else
				return z;
			end if;
		else
			if y > z then
				return y;
			else
				return z;
			end if;
		end if;
	end function;

	function minimum2(x, y : signed) return signed is
	begin
		if x < y then
			return x;
		else
			return y;
		end if;
	end function;

	function maximum2(x, y : signed) return signed is
	begin
		if x > y then
			return x;
		else
			return y;
		end if;
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

	function point3d_32(p : point3d_t) return point3d_32_t is
	begin
		return (x => int32(p.x), y => int32(p.y), z => int32(p.z));
	end function;

	function triangle3d(v1, v2, v3 : point3d_t) return triangle3d_t is
	begin
		return (v1, v2, v3);
	end function;

	----------------------------------------------------

	function sel(cond : boolean; opt1 : std_logic; opt2 : std_logic) return std_logic is
	begin
		if cond then
			return opt1;
		else
			return opt2;
		end if;
	end function;

	function sel(cond : boolean; opt1 : std_logic_vector; opt2 : std_logic_vector) return std_logic_vector is
	begin
		if cond then
			return opt1;
		else
			return opt2;
		end if;
	end function;

	function sel(cond : boolean; opt1 : unsigned; opt2 : unsigned) return unsigned is
	begin
		if cond then
			return opt1;
		else
			return opt2;
		end if;
	end function;

	function sel(cond : boolean; opt1 : signed; opt2 : signed) return signed is
	begin
		if cond then
			return opt1;
		else
			return opt2;
		end if;
	end function;

	function sel(cond : boolean; opt1 : integer; opt2 : integer) return integer is
	begin
		if cond then
			return opt1;
		else
			return opt2;
		end if;
	end function;

end package body;