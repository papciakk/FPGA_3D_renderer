library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.renderer_mesh.all;
use work.rendering_common.all;

entity tile_generator is
	port(
		clk                   : in  std_logic;
		rst                   : in  std_logic;
		trianglegen_posx_out  : out uint16_t;
		trianglegen_posy_out  : out uint16_t;
		trianglegen_put_pixel : out std_logic;
		color_out             : out color_t;
		tile_rect_in          : in  rect_t;
		start_in              : in  std_logic;
		ready_out             : out std_logic;
		depth_in              : out int16_t;
		depth_out             : in  int16_t;
		depth_wren            : out std_logic
	);
end entity tile_generator;

architecture bahavioral of tile_generator is
	signal triangle, triangle_next       : triangle2d_t;
	signal triangle_id, triangle_id_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal trianglegen_ready                     : std_logic;
	signal ready_out_next                        : std_logic;

	signal v1, v2, v3          : vertex_attr_t;
	signal depths, depths_next : point3d_t;
	signal colors, colors_next : triangle_colors_t;
	signal area, area_next     : int16_t;

	type state_type is (
		st_start, st_idle,
		st_rescale_attributes, st_calc_lighting_for_triangle, st_rendering_misc,
		st_rendering_task_wait, st_increment_triangle_id
	);
	signal state, state_next : state_type := st_start;

	function calc_lighting_for_vertex(vertex : vertex_attr_t)
	return color_t is
		variable diffuse_raw : int16_t;
		variable diffuse     : slv8_t;

		constant light_dir : point3d_32_t := (
			z => to_signed(180, 32),
			y => (others => '0'),
			x => to_signed(180, 32)
		);

		constant ambient_diffuse : integer := 10;
	begin

		diffuse_raw := resize(
			(vertex.normal.x * light_dir.x + vertex.normal.y * light_dir.y + vertex.normal.z * light_dir.z) / 255, 16
		);                              -- TODO: shift

		if diffuse_raw < 0 then
			diffuse := slv8(ambient_diffuse);
		elsif diffuse_raw + ambient_diffuse > 255 then
			diffuse := slv8(255);
		else
			diffuse := slv8(diffuse_raw + ambient_diffuse);
		end if;

		return color(diffuse, diffuse, diffuse);
	end function;

	function rescale_attributes(vertex : vertex_attr_t)
	return vertex_attr_t is
	begin
		return (
			pos    => (
				x => vertex.pos.x / 128 + HALF_FULLSCREEN_RES_X,
				y => vertex.pos.y / 128 + HALF_FULLSCREEN_RES_Y,
				z => vertex.pos.z
			),
			normal => (
				x => vertex.normal.x,
				y => vertex.normal.y,
				z => vertex.normal.z
			)
		);
	end function;

begin

	triangle_renderer0 : entity work.renderer_triangle
		port map(
			clk           => clk,
			rst           => rst,
			tile_rect_in  => tile_rect_in,
			triangle_in   => triangle,
			put_pixel_out => trianglegen_put_pixel,
			posx_out      => trianglegen_posx_out,
			posy_out      => trianglegen_posy_out,
			start_in      => start_rendering,
			ready_out     => trianglegen_ready,
			area_in       => area,
			depths_in     => depths,
			colors_in     => colors,
			color_out     => color_out,
			depth_buf_in  => depth_in,
			depth_buf_out => depth_out,
			depth_wren    => depth_wren
		);

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			state           <= state_next;
			triangle_id     <= triangle_id_next;
			start_rendering <= start_rendering_next;
			triangle        <= triangle_next;
			ready_out       <= ready_out_next;
			area            <= area_next;
			depths          <= depths_next;
			colors          <= colors_next;

		end if;
	end process;

	process(all) is
	begin
		state_next           <= state;
		triangle_id_next     <= triangle_id;
		start_rendering_next <= start_rendering;
		triangle_next        <= triangle;
		ready_out_next       <= ready_out;
		area_next            <= area;
		depths_next          <= depths;
		colors_next          <= colors;

		case state is
			when st_start =>
				ready_out_next       <= '0';
				triangle_id_next     <= 0;
				start_rendering_next <= '0';
				state_next           <= st_idle;

			when st_rescale_attributes =>
				v1 <= rescale_attributes(
					vertices(to_integer(indices(triangle_id).a))
				);
				v2 <= rescale_attributes(
					vertices(to_integer(indices(triangle_id).b))
				);
				v3 <= rescale_attributes(
					vertices(to_integer(indices(triangle_id).c))
				);

				state_next <= st_calc_lighting_for_triangle;

			when st_calc_lighting_for_triangle =>
				colors_next <= (
					calc_lighting_for_vertex(v1),
					calc_lighting_for_vertex(v2),
					calc_lighting_for_vertex(v3)
				);
				state_next  <= st_rendering_misc;

			when st_rendering_misc =>
				-- project to screen space
				triangle_next <= (
					(x => v1.pos.x, y => v1.pos.y),
					(x => v2.pos.x, y => v2.pos.y),
					(x => v3.pos.x, y => v3.pos.y)
				);
				depths_next   <= point3d(v1.pos.y, v2.pos.y, v3.pos.y);

				-- calc area
				area_next <= edge_function(v1.pos, v2.pos, v3.pos);

				ready_out_next       <= '0';
				start_rendering_next <= '1';
				state_next           <= st_rendering_task_wait;

			when st_rendering_task_wait =>
				ready_out_next       <= '0';
				start_rendering_next <= '0';

				if trianglegen_ready then
					state_next <= st_increment_triangle_id;
				else
					state_next <= st_rendering_task_wait;
				end if;

			when st_increment_triangle_id =>
				if triangle_id < indices'length then
					triangle_id_next     <= triangle_id + 1;
					start_rendering_next <= '0';
					state_next           <= st_rescale_attributes;
				else
					ready_out_next <= '1';
					state_next     <= st_start;
				end if;

			when st_idle =>
				ready_out_next <= '0';
				if start_in then
					ready_out_next   <= '0';
					triangle_id_next <= 0;
					state_next       <= st_rescale_attributes;
				else
					state_next <= st_idle;
				end if;
		end case;
	end process;

end architecture bahavioral;

