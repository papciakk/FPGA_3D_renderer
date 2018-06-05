library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity triangle_renderer is
	port(
		tilegen_clk       : in  std_logic;
		rst               : in  std_logic;
		tilegen_posx_out  : out unsigned(15 downto 0);
		tilegen_posy_out  : out unsigned(15 downto 0);
		tilegen_color_out : out color_t;
		tilegen_enable    : out std_logic
	);
end entity triangle_renderer;

architecture bahavioral of triangle_renderer is
	signal cntx : unsigned(15 downto 0);
	signal cnty : unsigned(15 downto 0);

	constant p : triangle2d_t := (
		point2d(18, 83),
		point2d(120, 18),
		point2d(170, 120)
	);

	--	type arr3_16_t is array (0 to 2) of unsigned(15 downto 0);
	--	type arr3_32_t is array (0 to 2) of unsigned(31 downto 0);
	--	
	--	constant startx, starty : unsigned(15 downto 0) := (others => '0');
	--	
	--	signal dx : arr3_16_t := (
	--		vertices(1).x - vertices(0).x, 
	--		vertices(2).x - vertices(1).x, 
	--		vertices(0).x - vertices(2).x
	--	);
	--	
	--	signal dy : arr3_16_t := (
	--		vertices(1).y - vertices(0).y, 
	--		vertices(2).y - vertices(1).y, 
	--		vertices(0).y - vertices(2).y
	--	);
	--	
	--	signal e : arr3_32_t := (
	--		(startx - vertices(0).x) * dy(0) - (startY - vertices(0).y) * dx(0),
	--        (startX - vertices(1).x) * dy(1) - (startY - vertices(1).y) * dx(1),
	--        (startX - vertices(2).x) * dy(2) - (startY - vertices(2).y) * dx(2)
	--	);
	--	
	--	signal e_tmp : arr3_32_t;

	signal e0, e1, e2 : signed(31 downto 0);
	signal s0, s1, s2 : std_logic;

begin

	e0 <= (signed(std_logic_vector((cntx - p(1).x) * (p(0).y - p(1).y))) - signed(std_logic_vector((p(0).x - p(1).x) * (cnty - p(1).y))));
	e1 <= (signed(std_logic_vector((cntx - p(2).x) * (p(1).y - p(2).y))) - signed(std_logic_vector((p(1).x - p(2).x) * (cnty - p(2).y))));
	e2 <= (signed(std_logic_vector((cntx - p(0).x) * (p(2).y - p(0).y))) - signed(std_logic_vector((p(2).x - p(0).x) * (cnty - p(0).y))));

	process(tilegen_clk, rst) is
	begin
		if rst = '1' then
			tilegen_color_out <= COLOR_BLACK;
			tilegen_posx_out  <= (others => '0');
			tilegen_posy_out  <= (others => '0');
			cntx              <= (others => '0');
			cnty              <= (others => '0');
		elsif rising_edge(tilegen_clk) then
			if cntx = (TILE_RES_X - 1) then
				cntx <= (others => '0');

				if cnty = (TILE_RES_Y - 1) then
					cnty <= (others => '0');
				else
					cnty <= cnty + 1;
				end if;
			else
				cntx <= cntx + 1;

				if (e0 < 0) and (e1 < 0) and (e2 < 0) then
					tilegen_enable <= '1';
				else
					tilegen_enable <= '0';
				end if;

			end if;

			tilegen_posx_out <= cntx;
			tilegen_posy_out <= cnty;
			tilegen_color_out <= COLOR_WHITE;
			
		end if;

	end process;

end architecture bahavioral;
