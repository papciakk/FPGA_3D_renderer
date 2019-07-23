library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.renderer_mesh.all;
use work.rendering_inc.all;

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
		depth_wren            : out std_logic;
		rot                   : in  point3d_t;
		scale                 : in  int16_t
	);
end entity tile_generator;

architecture bahavioral of tile_generator is

	function calc_rotx(sinx, cosx : int16_t; vertex : point3d_t)
	return point3d_t is
	begin
		return (
			x => vertex.x,
			y => resize(shift_right(vertex.y * cosx - vertex.z * sinx, 13), 16),
			z => resize(shift_right(vertex.y * sinx + vertex.z * cosx, 13), 16)
		);
	end function;

	function calc_roty(siny, cosy : int16_t; vertex : point3d_t)
	return point3d_t is
	begin
		return (
			x => resize(shift_right(vertex.z * siny + vertex.x * cosy, 13), 16),
			y => vertex.y,
			z => resize(shift_right(vertex.z * cosy - vertex.x * siny, 13), 16)
		);
	end function;

	function calc_rotz(sinz, cosz : int16_t; vertex : point3d_t)
	return point3d_t is
	begin
		return (
			x => resize(shift_right(vertex.x * cosz - vertex.y * sinz, 13), 16),
			y => resize(shift_right(vertex.x * sinz + vertex.y * cosz, 13), 16),
			z => vertex.z
		);
	end function;

	function calc_scale(scale : int16_t; vertex : point3d_32_t)
	return point3d_32_t is
	begin
		return (
			x => vertex.x + shift_right(resize(vertex.x * scale, 32), 3),
			y => vertex.y + shift_right(resize(vertex.y * scale, 32), 3),
			z => vertex.z + shift_right(resize(vertex.z * scale, 32), 3)
		);
	end function;

	----------------------------------------------------------

	function calc_lighting_for_vertex(vertex : vertex_attr_t)
	return color_t is
		variable diffuse_raw : int16_t;
		variable diffuse     : slv8_t;

		constant light_dir : point3d_32_t := (
			x => int32(30),
			y => int32(100),
			z => int32(-512)
		);

		constant ambient_diffuse : integer := 20;
	begin

		diffuse_raw := resize(
			shift_right(
				vertex.normal.x * light_dir.x + vertex.normal.y * light_dir.y + vertex.normal.z * light_dir.z,
				16),
			16);

		if diffuse_raw < 0 then
			diffuse := slv8(ambient_diffuse);
		elsif diffuse_raw + ambient_diffuse > 255 then
			diffuse := slv8(255);
		else
			diffuse := slv8(diffuse_raw + ambient_diffuse);
		end if;

		return color(diffuse, diffuse, diffuse);
	end function;

	function rescale_vertices_cast_to_16bit(vertex : point3d_32_t)
	return point3d_t is
	begin
		return (
			x => resize(shift_right(vertex.x, 7), 16) + HALF_FULLSCREEN_RES_X,
			y => resize(shift_right(vertex.y, 7), 16) + HALF_FULLSCREEN_RES_Y,
			z => resize(vertex.z, 16)
		);
	end function;

	signal triangle, triangle_next       : triangle2d_t;
	signal triangle_id, triangle_id_next : integer := 0;

	signal render_rect, render_rect_next : srect_t;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal trianglegen_ready                     : std_logic;
	signal ready_out_next                        : std_logic;

	signal attr0, attr0_next : vertex_attr_t;
	signal attr1, attr1_next : vertex_attr_t;
	signal attr2, attr2_next : vertex_attr_t;

	signal depths, depths_next : point3d_t;
	signal colors, colors_next : triangle_colors_t;
	signal area, area_next     : int16_t;

	--------------------------------------------

	signal sin : int16_t;
	signal cos : int16_t;

	signal angle, angle_next : int16_t;

	signal sinx, sinx_next : int16_t;
	signal cosx, cosx_next : int16_t;
	signal siny, siny_next : int16_t;
	signal cosy, cosy_next : int16_t;
	signal sinz, sinz_next : int16_t;
	signal cosz, cosz_next : int16_t;

	signal v0_32, v0_32_next : point3d_32_t;
	signal v1_32, v1_32_next : point3d_32_t;
	signal v2_32, v2_32_next : point3d_32_t;

	--------------------------------------------

	type state_type is (
		st_start, st_idle,
		st_prepare_triangle_vertices_request_sincos_x,
		st_get_sincos_x, st_get_sincos_y_calc_rot_x,
		st_get_sincos_z_calc_rot_y, st_calc_rotz_cast_to_32bit,
		st_calc_scale,
		st_rescale_attributes,
		st_calc_lighting_for_triangle, st_rendering_misc,
		st_rendering_task_wait, st_increment_triangle_id
	);
	signal state, state_next : state_type := st_start;

begin
	sin_cos_0 : entity work.sin_cos
		port map(
			clk     => clk,
			rst     => rst,
			angle   => angle,
			sin_out => sin,
			cos_out => cos
		);

	triangle_renderer0 : entity work.renderer_triangle
		port map(
			clk           => clk,
			rst           => rst,
			render_rect   => render_rect,
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
			render_rect     <= render_rect_next;
			start_rendering <= start_rendering_next;
			triangle        <= triangle_next;
			ready_out       <= ready_out_next;
			area            <= area_next;
			depths          <= depths_next;
			colors          <= colors_next;
			attr0           <= attr0_next;
			attr1           <= attr1_next;
			attr2           <= attr2_next;

			angle <= angle_next;
			sinx  <= sinx_next;
			cosx  <= cosx_next;
			siny  <= siny_next;
			cosy  <= cosy_next;
			sinz  <= sinz_next;
			cosz  <= cosz_next;
			v0_32 <= v0_32_next;
			v1_32 <= v1_32_next;
			v2_32 <= v2_32_next;

		end if;
	end process;

	process(all) is
		variable area_v : int16_t;
		variable triangle_v : triangle2d_t;
	begin
		state_next           <= state;
		triangle_id_next     <= triangle_id;
		render_rect_next     <= render_rect;
		start_rendering_next <= start_rendering;
		triangle_next        <= triangle;
		ready_out_next       <= ready_out;
		area_next            <= area;
		depths_next          <= depths;
		colors_next          <= colors;
		attr0_next           <= attr0;
		attr1_next           <= attr1;
		attr2_next           <= attr2;

		angle_next <= angle;
		sinx_next  <= sinx;
		cosx_next  <= cosx;
		siny_next  <= siny;
		cosy_next  <= cosy;
		sinz_next  <= sinz;
		cosz_next  <= cosz;
		v0_32_next <= v0_32;
		v1_32_next <= v1_32;
		v2_32_next <= v2_32;

		case state is
			when st_start =>
				ready_out_next       <= '0';
				triangle_id_next     <= 0;
				start_rendering_next <= '0';
				state_next           <= st_idle;

			when st_idle =>
				ready_out_next <= '0';
				if start_in then
					triangle_id_next <= 0;
					state_next       <= st_prepare_triangle_vertices_request_sincos_x;
				else
					state_next <= st_idle;
				end if;

			when st_prepare_triangle_vertices_request_sincos_x =>
				attr0_next <= vertices(to_integer(indices(triangle_id).a));
				attr1_next <= vertices(to_integer(indices(triangle_id).b));
				attr2_next <= vertices(to_integer(indices(triangle_id).c));

				angle_next <= rot.x;

				state_next <= st_get_sincos_x;

			when st_get_sincos_x =>
				sinx_next  <= sin;
				cosx_next  <= cos;
				angle_next <= rot.y;

				state_next <= st_get_sincos_y_calc_rot_x;

			when st_get_sincos_y_calc_rot_x =>
				siny_next <= sin;
				cosy_next <= cos;

				attr0_next.pos <= calc_rotx(sinx, cosx, attr0.pos);
				attr1_next.pos <= calc_rotx(sinx, cosx, attr1.pos);
				attr2_next.pos <= calc_rotx(sinx, cosx, attr2.pos);

				state_next <= st_get_sincos_z_calc_rot_y;

			when st_get_sincos_z_calc_rot_y =>
				sinz_next <= sin;
				cosy_next <= cos;

				attr0_next.pos <= calc_roty(siny, cosy, attr0.pos);
				attr1_next.pos <= calc_roty(siny, cosy, attr1.pos);
				attr2_next.pos <= calc_roty(siny, cosy, attr2.pos);

				state_next <= st_calc_rotz_cast_to_32bit;

			when st_calc_rotz_cast_to_32bit =>
				v0_32_next <= point3d_32(calc_rotz(siny, cosy, attr0.pos));
				v1_32_next <= point3d_32(calc_rotz(siny, cosy, attr1.pos));
				v2_32_next <= point3d_32(calc_rotz(siny, cosy, attr2.pos));

				state_next <= st_calc_scale;

			when st_calc_scale =>
				v0_32_next <= calc_scale(scale, v0_32);
				v1_32_next <= calc_scale(scale, v1_32);
				v2_32_next <= calc_scale(scale, v2_32);

				state_next <= st_rescale_attributes;

			when st_rescale_attributes =>
				attr0_next.pos <= rescale_vertices_cast_to_16bit(v0_32);
				attr1_next.pos <= rescale_vertices_cast_to_16bit(v1_32);
				attr2_next.pos <= rescale_vertices_cast_to_16bit(v2_32);

				state_next <= st_calc_lighting_for_triangle;

			when st_calc_lighting_for_triangle =>
				
				-- project to screen space
				triangle_v := (
					(x => attr0.pos.x, y => attr0.pos.y),
					(x => attr1.pos.x, y => attr1.pos.y),
					(x => attr2.pos.x, y => attr2.pos.y)
				);
				triangle_next <= triangle_v;
				
				-- calculate rendering bounding box
				
				render_rect_next <= get_current_rendering_bounding_box(triangle_v, tile_rect_in);

				-- calc area
				area_v    := edge_function(attr0.pos, attr1.pos, attr2.pos);
				area_next <= area_v;

				if area_v < 0 then      -- backface culling
					state_next <= st_increment_triangle_id;
				else
					colors_next <= (
						calc_lighting_for_vertex(attr0),
						calc_lighting_for_vertex(attr1),
						calc_lighting_for_vertex(attr2)
					);
					state_next  <= st_rendering_misc;
				end if;

			when st_rendering_misc =>
				depths_next   <= point3d(attr0.pos.y, attr1.pos.y, attr2.pos.y);

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
					state_next           <= st_prepare_triangle_vertices_request_sincos_x;
				else
					ready_out_next <= '1';
					state_next     <= st_start;
				end if;

		end case;
	end process;

end architecture bahavioral;

