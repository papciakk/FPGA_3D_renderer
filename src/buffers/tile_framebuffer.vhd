library ieee;
use ieee.std_logic_1164.all;

entity tile_framebuffer is

	generic 
	(
		DATA_WIDTH : natural := 24;
		ADDR_WIDTH : natural := 14;
		WORDS : natural := 0
	);

	port 
	(
		rclk	: in std_logic;
		wclk	: in std_logic;
		raddr	: in natural range 0 to 2**ADDR_WIDTH - 1;
		waddr	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we		: in std_logic := '1';
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);

end tile_framebuffer;

architecture rtl of tile_framebuffer is

	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array((WORDS-1) downto 0) of word_t;
	signal ram : memory_t;

begin

	process(wclk)
	begin
	if(rising_edge(wclk)) then 
		if we then
			ram(waddr) <= data;
		end if;
	end if;
	end process;

	process(rclk)
	begin
	if(rising_edge(rclk)) then 
		q <= ram(raddr);
	end if;
	end process;

end rtl;
