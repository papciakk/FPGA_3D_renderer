library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.common.all;

entity tile_buffer is
	port(
		screen_clk             : in  std_logic;
		screen_posx            : in  unsigned(15 downto 0);
		screen_posy            : in  unsigned(15 downto 0);
		color_out              : out color_t;
		---------------------------------------------------
		tilegen_clk            : in  std_logic;
		tilegen_posx           : in  unsigned(15 downto 0);
		tilegen_posy           : in  unsigned(15 downto 0);
		tilegen_put_pixel      : in  std_logic;
		color_in               : in  color_t;
		---------------------------------------------------
		rst                    : in  std_logic;
		clear                  : in  std_logic;
		clear_done             : out std_logic;
		---------------------------------------------------
		depth_in               : in unsigned(15 downto 0);
		depth_out              : out unsigned(15 downto 0);
		clk50 : in std_logic;
		depth_wren : in std_logic
	);
end entity tile_buffer;

architecture RTL of tile_buffer is
	signal color_out_raw        : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);
	signal color_in_raw : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);
	
	signal ram_addr_wr             : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0);
	signal ram_addr_rd             : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0);

	signal clear_addr_wr, clear_addr_wr_next : std_logic_vector((TILE_ADDR_LEN - 1) DOWNTO 0) := (others => '0');
	signal clear_mode, clear_mode_next       : std_logic := '0';
	signal clear_done_next                   : std_logic := '0';
	
	signal wren : std_logic;
	signal depth_wren_raw : std_logic;

	type state_type is (
		st_start, st_idle, st_clear_wait
	);
	signal state, state_next : state_type := st_start;
	
	constant TILE_SIZE : integer := (TILE_RES_X) * (TILE_RES_Y+1);
	
	signal depth_in_raw : STD_LOGIC_VECTOR (15 DOWNTO 0);
	signal depth_out_raw : STD_LOGIC_VECTOR (15 DOWNTO 0);
	
	

begin

	color_in_raw(7 downto 0)   <= X"00" when clear_mode = '1' else color_in.b;
	color_in_raw(15 downto 8)  <= X"00" when clear_mode = '1' else color_in.g;
	color_in_raw(23 downto 16) <= X"00" when clear_mode = '1' else color_in.r;

	ram_addr_wr <= clear_addr_wr when clear_mode = '1' else std_logic_vector(to_unsigned(to_integer(tilegen_posy * TILE_RES_X + tilegen_posx), TILE_ADDR_LEN));
	
	wren <= '1' when clear_mode = '1' else tilegen_put_pixel;
	depth_wren_raw <= '1' when clear_mode = '1' else depth_wren;

	color_buffer : entity work.tile_ram
		port map(
			data      => color_in_raw,
			rdaddress => ram_addr_rd,
			rdclock   => screen_clk,
			wraddress => ram_addr_wr,
			wrclock   => tilegen_clk,
			wren      => wren,
			q         => color_out_raw
		);
		
	depth_buffer : entity work.depth_buf
		port map(
			clock     => clk50,
			data      => depth_in_raw,
			rdaddress => '0' & ram_addr_wr,
			wraddress => '0' & ram_addr_wr,
			wren      => depth_wren_raw,
			q         => depth_out_raw
		);
		
	depth_in_raw <= X"0000" when clear_mode = '1' else std_logic_vector(depth_in);
	depth_out <= unsigned(depth_out_raw);
		
--	depth_buffer : entity work.tile_depth_ram
--		port map(
--			data      => depth_in_raw,
--			rdaddress => ram_addr_wr,
--			rdclock   => tilegen_clk,
--			wraddress => ram_addr_wr,
--			wrclock   => tilegen_clk,
--			wren      => wren,
--			q         => depth_out
--		);
		
	ram_addr_rd            <= std_logic_vector(to_unsigned(to_integer(screen_posy * TILE_RES_X + screen_posx), TILE_ADDR_LEN));
	color_out <= (
		b => color_out_raw(7 downto 0),
		g => color_out_raw(15 downto 8),
		r => color_out_raw(23 downto 16)
	);

	-- CLEAR MEM ------------------------------

	process(tilegen_clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(tilegen_clk) then
			state         <= state_next;
			clear_mode    <= clear_mode_next;
			clear_addr_wr <= clear_addr_wr_next;
			clear_done    <= clear_done_next;
		end if;
	end process;

	process(state, clear_mode, clear, clear_addr_wr, clear_done) is
	begin
		state_next         <= state;
		clear_mode_next    <= clear_mode;
		clear_addr_wr_next <= clear_addr_wr;
		clear_done_next    <= clear_done;

		case state is
			when st_start =>
				clear_mode_next <= '0';
				clear_done_next <= '0';
				clear_addr_wr_next <= (others => '0');
				state_next      <= st_idle;

			when st_idle =>
					clear_done_next <= '0';
				if clear = '1' then
					clear_mode_next    <= '1';
					clear_addr_wr_next <= (others => '0');
					state_next         <= st_clear_wait;
				else
					clear_mode_next <= '0';
					state_next      <= st_idle;
				end if;

			when st_clear_wait =>
				clear_done_next <= '0';
				if unsigned(clear_addr_wr) < TILE_SIZE then
					clear_addr_wr_next  <= std_logic_vector(unsigned(clear_addr_wr) + 1);
					state_next <= st_clear_wait;
				else
					clear_mode_next <= '0';
					clear_done_next <= '1';
					state_next      <= st_idle;
				end if;
		end case;
	end process;

end architecture RTL;
