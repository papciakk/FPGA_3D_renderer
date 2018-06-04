library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use ieee.math_real.all;

entity tile_buffer is
	port(
		clk                    : in  std_logic;
		rst                    : in  std_logic;
		screen_posx            : in  unsigned(15 downto 0);
		screen_posy            : in  unsigned(15 downto 0);
		screen_pixel_color_out : out color_t
	);
end entity tile_buffer;

architecture RTL of tile_buffer is
	signal ram_addr_rd      : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0);
	signal ram_data_out_raw : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);

begin

	tile_ram0 : entity work.tile_ram
		port map(
			data      => (others => '0'),
			rdaddress => ram_addr_rd,
			rdclock   => clk,
			wraddress => (others => '0'),
			wrclock   => '0',
			wren      => '0',
			q         => ram_data_out_raw
		);

	ram_addr_rd            <= std_logic_vector(to_unsigned(
		to_integer(screen_posy * TILE_RES_X + screen_posx),
		TILE_ADDR_LEN
	));
	screen_pixel_color_out <= (
		b => ram_data_out_raw(7 downto 0),
		g => ram_data_out_raw(15 downto 8),
		r => ram_data_out_raw(23 downto 16)
	);
	--
	--	process(clk, rst) is
	--	begin
	--		if rst = '1' then
	--
	--		elsif rising_edge(clk) then
	--
	--		end if;
	--
	--	end process;

end architecture RTL;
