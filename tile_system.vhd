library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity tile_system is
	port(
		clk           : in  std_logic;
		rst           : in  std_logic;
		posx_out      : out u16;
		posy_out      : out u16;
		color_out     : out color_t;
		put_pixel_out : out std_logic;
		tile_rect_out : out rect_t;
		ready_out     : out std_logic;
		start_in      : in  std_logic;
		tile_num_in   : in  integer
	);
end entity tile_system;

architecture bahavioral of tile_system is

	type state_type is (
		st_start, st_idle, st_render_tile, st_render_tile_wait
	);
	signal state, state_next : state_type := st_start;

	signal start_rendering_tile, start_rendering_tile_next : std_logic := '0';
	signal tile_rendered                                   : std_logic;

	function get_tile_rect(x, y : integer) return rect_t is
	begin
		return (
			x0 => to_unsigned(x * TILE_RES_X, 16),
			x1 => to_unsigned((x + 1) * TILE_RES_X, 16),
			y0 => to_unsigned(y * TILE_RES_Y, 16),
			y1 => to_unsigned((y + 1) * TILE_RES_Y, 16)
		);
	end function;

	signal untransposed_posx, untransposed_posy : u16;
	--	signal current_tile_rect                    : rect_t := (
	--		x0 => to_unsigned(100, 16),
	--		y0 => to_unsigned(100, 16),
	--		x1 => to_unsigned(200, 16),
	--		y1 => to_unsigned(200, 16)
	--	);

	type rect_arr_t is array (natural range <>) of rect_t;
	function prepare_tile_rects return rect_arr_t is
		constant TILES_X_CNT : integer := integer(real(FULLSCREEN_RES_X) / real(TILE_RES_X));
		constant TILES_Y_CNT : integer := integer(real(FULLSCREEN_RES_Y) / real(TILE_RES_Y));
		variable r           : rect_arr_t(0 to (TILES_X_CNT * TILES_Y_CNT - 1));
	begin
		for yi in 0 to (TILES_Y_CNT - 1) loop
			for xi in 0 to (TILES_X_CNT - 1) loop
				r(yi * TILES_X_CNT + xi) := get_tile_rect(xi, yi);
			end loop;
		end loop;
		return r;
	end function;

	constant tile_rects : rect_arr_t := prepare_tile_rects;

	signal current_tile_rect : rect_t;
	signal ready_out_next    : std_logic;
begin

	tile_generator0 : entity work.tile_generator
		port map(
			clk                   => clk,
			rst                   => rst,
			trianglegen_posx_out  => untransposed_posx,
			trianglegen_posy_out  => untransposed_posy,
			trianglegen_put_pixel => put_pixel_out,
			color_out             => color_out,
			tile_rect_in          => current_tile_rect,
			start_in              => start_rendering_tile,
			ready_out             => tile_rendered
		);

	posx_out <= untransposed_posx - current_tile_rect.x0;
	posy_out <= untransposed_posy - current_tile_rect.y0;

	tile_rect_out <= current_tile_rect;

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			start_rendering_tile <= start_rendering_tile_next;
			ready_out            <= ready_out_next;
			state                <= state_next;
		end if;
	end process;

	process(state, start_rendering_tile, tile_rendered, ready_out, start_in, tile_num_in) is
	begin
		start_rendering_tile_next <= start_rendering_tile;
		ready_out_next            <= ready_out;
		state_next                <= state;

		case state is
			when st_start =>
				start_rendering_tile_next <= '0';
				ready_out_next            <= '0';
				state_next                <= st_idle;

			when st_idle =>
				start_rendering_tile_next <= '0';
				current_tile_rect         <= tile_rects(tile_num_in);

				if start_in = '1' then
					state_next <= st_render_tile;
				else
					state_next <= st_idle;
				end if;

			when st_render_tile =>
				ready_out_next            <= '0';
				start_rendering_tile_next <= '1';
				state_next                <= st_render_tile_wait;

			when st_render_tile_wait =>
				start_rendering_tile_next <= '0';
				if tile_rendered = '1' then
					ready_out_next <= '1';
					state_next     <= st_idle;
				else
					state_next <= st_render_tile_wait;
				end if;

		end case;
	end process;

end architecture bahavioral;

