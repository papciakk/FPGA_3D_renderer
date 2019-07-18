library ieee;
use ieee.std_logic_1164.all;

entity tile_depthbuffer is

	generic 
	(
		DATA_WIDTH : natural := 16;
		ADDR_WIDTH : natural := 14;
		WORDS : natural := 0
	);

	port 
	(
		clk		: in std_logic;
		raddr	: in natural range 0 to 2**ADDR_WIDTH - 1;
		waddr	: in natural range 0 to 2**ADDR_WIDTH - 1;
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		we		: in std_logic := '1';
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);

end tile_depthbuffer;

architecture rtl of tile_depthbuffer is
	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array((WORDS-1) downto 0) of word_t;
	signal ram : memory_t;
begin

	process(clk)
	begin
	if(rising_edge(clk)) then 
		if(we = '1') then
			ram(waddr) <= data;
		end if;
 
		q <= ram(raddr);
	end if;
	end process;

end rtl;
