library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library common;
use common.stdint.all;
use common.definitions.all;
use common.config.all;

entity tile_buffer is
	port(
		screen_clk        : in  std_logic;
		screen_posx       : in  uint16_t;
		screen_posy       : in  uint16_t;
		color_out         : out color_t;
		---------------------------------------------------
		tilegen_clk       : in  std_logic;
		tilegen_posx      : in  uint16_t;
		tilegen_posy      : in  uint16_t;
		tilegen_put_pixel : in  std_logic;
		color_in          : in  color_t;
		---------------------------------------------------
		rst               : in  std_logic;
		clear             : in  std_logic;
		clear_done        : out std_logic;
		---------------------------------------------------
		depth_in          : in  int16_t;
		depth_out         : out int16_t;
		clk50             : in  std_logic;
		depth_wren        : in  std_logic
	);
end entity tile_buffer;

architecture RTL of tile_buffer is

	constant TILE_SIZE : integer := (TILE_RES_X) * (TILE_RES_Y + 1);

	signal color_out_raw : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);
	signal color_in_raw  : std_logic_vector((BITS_PER_PIXEL - 1) DOWNTO 0);

	signal ram_addr_wr : integer;
	signal ram_addr_rd : integer;

	signal clear_addr_wr, clear_addr_wr_next : integer   := 0;
	signal clear_mode, clear_mode_next       : std_logic := '0';
	signal clear_done_next                   : std_logic := '0';

	signal wren           : std_logic;
	signal depth_wren_raw : std_logic;

	signal depth_in_raw  : slv16_t;
	signal depth_out_raw : slv16_t;

	type state_type is (
		st_start, st_idle, st_clear_wait
	);
	signal state, state_next : state_type := st_start;

begin

	color_in_raw(7 downto 0)   <= X"00" when clear_mode else color_in.b;
	color_in_raw(15 downto 8)  <= X"00" when clear_mode else color_in.g;
	color_in_raw(23 downto 16) <= X"00" when clear_mode else color_in.r;

	ram_addr_wr <= clear_addr_wr when clear_mode else to_integer(tilegen_posy * TILE_RES_X + tilegen_posx);

	wren           <= '1' when clear_mode else tilegen_put_pixel;
	depth_wren_raw <= '1' when clear_mode else depth_wren;

	tile_framebuffer_0 : entity work.tile_framebuffer
		generic map(
			DATA_WIDTH => BITS_PER_PIXEL,
			ADDR_WIDTH => TILE_ADDR_LEN,
			WORDS      => TILE_RES_X * TILE_RES_Y
		)
		port map(
			rclk  => screen_clk,
			wclk  => tilegen_clk,
			raddr => ram_addr_rd,
			waddr => ram_addr_wr,
			data  => color_in_raw,
			we    => wren,
			q     => color_out_raw
		);

	tile_depthbuffer_0 : entity work.tile_depthbuffer
		generic map(
			DATA_WIDTH => DEPTH_BITS,
			ADDR_WIDTH => TILE_ADDR_LEN,
			WORDS      => TILE_RES_X * TILE_RES_Y
		)
		port map(
			clk   => clk50,
			raddr => ram_addr_wr,
			waddr => ram_addr_wr,
			data  => depth_in_raw,
			we    => depth_wren_raw,
			q     => depth_out_raw
		);

	depth_in_raw <= INT16_MAX when clear_mode else std_logic_vector(depth_in);
	depth_out    <= signed(depth_out_raw);

	ram_addr_rd <= to_integer(screen_posy * TILE_RES_X + screen_posx);
	color_out   <= (
		b => color_out_raw(7 downto 0),
		g => color_out_raw(15 downto 8),
		r => color_out_raw(23 downto 16)
	);

	-- CLEAR MEM ------------------------------

	process(tilegen_clk, rst) is
	begin
		if rst then
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
				clear_mode_next    <= '0';
				clear_done_next    <= '0';
				clear_addr_wr_next <= 0;
				state_next         <= st_idle;

			when st_idle =>
				clear_done_next <= '0';
				if clear then
					clear_mode_next    <= '1';
					clear_addr_wr_next <= 0;
					state_next         <= st_clear_wait;
				else
					clear_mode_next <= '0';
					state_next      <= st_idle;
				end if;

			when st_clear_wait =>
				clear_done_next <= '0';
				if clear_addr_wr < TILE_SIZE then
					clear_addr_wr_next <= clear_addr_wr + 1;
					state_next         <= st_clear_wait;
				else
					clear_mode_next <= '0';
					clear_done_next <= '1';
					state_next      <= st_idle;
				end if;
		end case;
	end process;

end architecture RTL;
