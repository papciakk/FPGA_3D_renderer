library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.stdint.all;
use work.definitions.all;
use work.config.all;
use work.mesh.all;
use work.renderer_inc.all;
use work.tile_renderer_inc.all;

entity tile_renderer is
	port(
		clk                : in  std_logic;
		rst                : in  std_logic;
		----------------------------------
		posx_out           : out uint16_t;
		posy_out           : out uint16_t;
		put_pixel_out      : out std_logic;
		pixel_color_out    : out color_t;
		-----------------------------------
		start_in           : in  std_logic;
		ready_out          : out std_logic;
		-----------------------------------
		tile_rect_in       : in  rect_t;
		-----------------------------------
		depth_buf_read_out : out int16_t;
		depth_buf_write_in : in  int16_t;
		depth_wren_out     : out std_logic;
		-----------------------------------
		rot_in             : in  point3d_t;
		rot_light_in       : in  point3d_t;
		scale_in           : in  int16_t
	);
end entity;

architecture rtl of tile_renderer is

	constant light_dir_starting : point3d_t := point3d(0, 0, -512);

	signal triangle_id, triangle_id_next : integer := 0;

	signal start_rasterizer, start_rasterizer_next : std_logic := '0';
	signal rasterizer_ready                        : std_logic;
	signal ready_out_next                          : std_logic;

	signal attr0, attr0_next : vertex_attr_t;
	signal attr1, attr1_next : vertex_attr_t;
	signal attr2, attr2_next : vertex_attr_t;

	signal triangle, triangle_next       : triangle2d_t;
	signal area, area_next               : int16_t;
	signal colors, colors_next           : triangle_colors_t;
	signal depths, depths_next           : point3d_t;
	signal render_rect, render_rect_next : srect_t;

	---------------------------------------------------------------

	signal angle, angle_next : int16_t;
	signal sine, cosine : int16_t;

	signal rh_shift                                                   : int8_t;
	signal rh_in01, rh_in02, rh_in03, rh_in04                         : int16_t;
	signal rh_in11, rh_in12, rh_in13, rh_in14                         : int16_t;
	signal rh_in21, rh_in22, rh_in23, rh_in24                         : int16_t;
	signal rh_trig1, rh_trig2, rh_trig3, rh_trig4                     : int16_t;
	signal rh_out01, rh_out02                                         : int16_t;
	signal rh_out11, rh_out12                                         : int16_t;
	signal rh_out21, rh_out22                                         : int16_t;
	signal rh_shift_next                                              : int8_t;
	signal rh_in01_next, rh_in02_next, rh_in03_next, rh_in04_next     : int16_t;
	signal rh_in11_next, rh_in12_next, rh_in13_next, rh_in14_next     : int16_t;
	signal rh_in21_next, rh_in22_next, rh_in23_next, rh_in24_next     : int16_t;
	signal rh_trig1_next, rh_trig2_next, rh_trig3_next, rh_trig4_next : int16_t;

	---------------------------------------------------------------

	signal light_dir, light_dir_next : point3d_t;
	signal ambient_diffuse           : int16_t := int16(20);

	---------------------------------------------------------------

	type state_type is (
		st_start, st_idle, st_calc_area_prepare_parameters, st_next_triangle,
		st_prepare_triangle_verts,
		st_prepare_rot_x, st_get_rot_x_prepare_rot_y, st_get_rot_y_prepare_rot_z, st_get_rot_z, 
		st_calc_scale, st_rescale_attributes,
		st_calc_lighting, st_wait_for_rasterizer
	);
	signal state, state_next : state_type := st_start;

begin

	sin_cos_0 : entity work.sin_cos
		port map(
			angle  => angle,
			sine   => sine,
			cosine => cosine
		);

	rotation_helper0 : entity work.rotation_helper
		port map(
			clk   => clk,
			shift => rh_shift,
			in01  => rh_in01, in02 => rh_in02, in03 => rh_in03, in04 => rh_in04,
			in11  => rh_in11, in12 => rh_in12, in13 => rh_in13, in14 => rh_in14,
			in21  => rh_in21, in22 => rh_in22, in23 => rh_in23, in24 => rh_in24,
			trig1 => rh_trig1, trig2 => rh_trig2, trig3 => rh_trig3, trig4 => rh_trig4,
			out01 => rh_out01, out02 => rh_out02,
			out11 => rh_out11, out12 => rh_out12,
			out21 => rh_out21, out22 => rh_out22
		);

	triangle_rasterizer0 : entity work.triangle_rasterizer
		port map(
			clk           => clk,
			rst           => rst,
			render_rect   => render_rect,
			triangle_in   => triangle,
			put_pixel_out => put_pixel_out,
			posx_out      => posx_out,
			posy_out      => posy_out,
			start_in      => start_rasterizer,
			ready_out     => rasterizer_ready,
			area_in       => area,
			depths_in     => depths,
			colors_in     => colors,
			color_out     => pixel_color_out,
			depth_buf_in  => depth_buf_read_out,
			depth_buf_out => depth_buf_write_in,
			depth_wren    => depth_wren_out
		);

	process(clk, rst) is
	begin
		if rst then
			state <= st_start;
		elsif rising_edge(clk) then
			state            <= state_next;
			triangle_id      <= triangle_id_next;
			render_rect      <= render_rect_next;
			ready_out        <= ready_out_next;
			attr0            <= attr0_next;
			attr1            <= attr1_next;
			attr2            <= attr2_next;
			light_dir        <= light_dir_next;
			start_rasterizer <= start_rasterizer_next;
			triangle         <= triangle_next;
			area             <= area_next;
			colors           <= colors_next;
			depths           <= depths_next;
--			angle            <= angle_next;
			rh_shift         <= rh_shift_next;
			rh_in01          <= rh_in01_next;
			rh_in02          <= rh_in02_next;
			rh_in03          <= rh_in03_next;
			rh_in04          <= rh_in04_next;
			rh_in11          <= rh_in11_next;
			rh_in12          <= rh_in12_next;
			rh_in13          <= rh_in13_next;
			rh_in14          <= rh_in14_next;
			rh_in21          <= rh_in21_next;
			rh_in22          <= rh_in22_next;
			rh_in23          <= rh_in23_next;
			rh_in24          <= rh_in24_next;
			rh_trig1         <= rh_trig1_next;
			rh_trig2         <= rh_trig2_next;
			rh_trig3         <= rh_trig3_next;
			rh_trig4         <= rh_trig4_next;
		end if;
	end process;

	process(all) is
		variable triangle_v : triangle2d_t;
		variable area_v     : int16_t;
		variable attr0posx, attr0posy, attr0posz : int16_t;
		variable attr1posx, attr1posy, attr1posz : int16_t;
		variable attr2posx, attr2posy, attr2posz : int16_t;
	begin
		state_next            <= state;
		triangle_id_next      <= triangle_id;
		render_rect_next      <= render_rect;
		ready_out_next        <= ready_out;
		attr0_next            <= attr0;
		attr1_next            <= attr1;
		attr2_next            <= attr2;
		light_dir_next        <= light_dir;
		start_rasterizer_next <= start_rasterizer;
		triangle_next         <= triangle;
		area_next             <= area;
		colors_next           <= colors;
		depths_next           <= depths;
--		angle_next            <= angle;
		rh_shift_next         <= rh_shift;
		rh_in01_next          <= rh_in01;
		rh_in02_next          <= rh_in02;
		rh_in03_next          <= rh_in03;
		rh_in04_next          <= rh_in04;
		rh_in11_next          <= rh_in11;
		rh_in12_next          <= rh_in12;
		rh_in13_next          <= rh_in13;
		rh_in14_next          <= rh_in14;
		rh_in21_next          <= rh_in21;
		rh_in22_next          <= rh_in22;
		rh_in23_next          <= rh_in23;
		rh_in24_next          <= rh_in24;
		rh_trig1_next         <= rh_trig1;
		rh_trig2_next         <= rh_trig2;
		rh_trig3_next         <= rh_trig3;
		rh_trig4_next         <= rh_trig4;

		case state is

			when st_start =>
				triangle_id_next      <= 0;
				start_rasterizer_next <= '0';
				ready_out_next        <= '0';
				state_next            <= st_idle;

			when st_idle =>
				ready_out_next   <= '0';
				triangle_id_next <= 0;
				if start_in then
					state_next <= st_prepare_triangle_verts;
				else
					state_next <= st_idle;
				end if;

			when st_prepare_triangle_verts =>
				ready_out_next <= '0';
				light_dir_next <= light_dir_starting;
				attr0_next     <= vertices(to_integer(indices(triangle_id).a));
				attr1_next     <= vertices(to_integer(indices(triangle_id).b));
				attr2_next     <= vertices(to_integer(indices(triangle_id).c));

				state_next <= st_prepare_rot_x;

			when st_prepare_rot_x =>
				-- x' = x
				-- y' = y * cos(x) - z * sin(x)
				-- z' = y * sin(x) + z * cos(x)

				angle            <= rot_in.x;
				rh_shift_next         <= int8(13);
				rh_in01_next          <= attr0.pos.y;
				rh_in02_next          <= -attr0.pos.z;
				rh_in03_next          <= attr0.pos.y;
				rh_in04_next          <= attr0.pos.z;
				rh_in11_next          <= attr1.pos.y;
				rh_in12_next          <= -attr1.pos.z;
				rh_in13_next          <= attr1.pos.y;
				rh_in14_next          <= attr1.pos.z;
				rh_in21_next          <= attr2.pos.y;
				rh_in22_next          <= -attr2.pos.z;
				rh_in23_next          <= attr2.pos.y;
				rh_in24_next          <= attr2.pos.z;
				rh_trig1_next         <= cosine;
				rh_trig2_next         <= sine;
				rh_trig3_next         <= sine;
				rh_trig4_next         <= cosine;

				state_next <= st_get_rot_x_prepare_rot_y;

			when st_get_rot_x_prepare_rot_y =>
				attr0posz := rh_out02;
				attr1posz := rh_out12;
				attr2posz := rh_out22;
				
				attr0_next.pos.y <= rh_out01;
				attr0_next.pos.z <= attr0posz;
				attr1_next.pos.y <= rh_out11;
				attr1_next.pos.z <= attr1posz;
				attr2_next.pos.y <= rh_out21;
				attr2_next.pos.z <= attr2posz;
				
				-- x' = z * sin(y) + x * cos(y)
				-- y' = y
				-- z' = z * cos(y) - x * sin(y)

				angle            <= rot_in.y;
				rh_shift_next         <= int8(13);
				rh_in01_next          <= attr0posz;
				rh_in02_next          <= attr0.pos.x;
				rh_in03_next          <= attr0posz;
				rh_in04_next          <= -attr0.pos.x;
				rh_in11_next          <= attr1posz;
				rh_in12_next          <= attr1.pos.x;
				rh_in13_next          <= attr1posz;
				rh_in14_next          <= -attr1.pos.x;
				rh_in21_next          <= attr2posz;
				rh_in22_next          <= attr2.pos.x;
				rh_in23_next          <= attr2posz;
				rh_in24_next          <= -attr2.pos.x;
				rh_trig1_next         <= sine;
				rh_trig2_next         <= cosine;
				rh_trig3_next         <= cosine;
				rh_trig4_next         <= sine;

				state_next <= st_get_rot_y_prepare_rot_z;

			when st_get_rot_y_prepare_rot_z =>
				attr0posx := rh_out01;
				attr1posx := rh_out11;
				attr2posx := rh_out21;
				
				attr0_next.pos.x <= attr0posx;
				attr0_next.pos.z <= rh_out02;
				attr1_next.pos.x <= attr1posx;
				attr1_next.pos.z <= rh_out12;
				attr2_next.pos.x <= attr2posx;
				attr2_next.pos.z <= rh_out22;
				
				-- x' = x * cos(z) - y * sin(z)
				-- y' = x * sin(z) + y * cos(z)
				-- z' = z

				angle            <= rot_in.z;
				rh_shift_next         <= int8(13);
				rh_in01_next          <= attr0posx;
				rh_in02_next          <= -attr0.pos.y;
				rh_in03_next          <= attr0posx;
				rh_in04_next          <= attr0.pos.y;
				rh_in11_next          <= attr1posx;
				rh_in12_next          <= -attr1.pos.y;
				rh_in13_next          <= attr1posx;
				rh_in14_next          <= attr1.pos.y;
				rh_in21_next          <= attr2posx;
				rh_in22_next          <= -attr2.pos.y;
				rh_in23_next          <= attr2posx;
				rh_in24_next          <= attr2.pos.y;
				rh_trig1_next         <= cosine;
				rh_trig2_next         <= sine;
				rh_trig3_next         <= sine;
				rh_trig4_next         <= cosine;

				state_next <= st_get_rot_z;
				
			when st_get_rot_z =>
				attr0_next.pos.x <= rh_out01;
				attr0_next.pos.y <= rh_out02;
				attr1_next.pos.x <= rh_out11;
				attr1_next.pos.y <= rh_out12;
				attr2_next.pos.x <= rh_out21;
				attr2_next.pos.y <= rh_out22;
				
				-- prepare for calc of light rotation around x
				angle            <= rot_light_in.x;
				rh_shift_next         <= int8(13);
				rh_in01_next          <= light_dir.y;
				rh_in02_next          <= -light_dir.z;
				rh_in03_next          <= light_dir.y;
				rh_in04_next          <= light_dir.z;
				rh_trig1_next         <= cosine;
				rh_trig2_next         <= sine;
				rh_trig3_next         <= sine;
				rh_trig4_next         <= cosine;
				
				state_next <= st_calc_scale;

			when st_calc_scale =>
				light_dir_next.y <= rh_out01;
				light_dir_next.z <= rh_out02;
				
				-- x' = x * scale / 256
				-- y' = y * scale / 256
				-- z' = z

				attr0_next.pos <= calc_scale(scale_in, attr0.pos);
				attr1_next.pos <= calc_scale(scale_in, attr1.pos);
				attr2_next.pos <= calc_scale(scale_in, attr2.pos);

				state_next <= st_rescale_attributes;

			when st_rescale_attributes =>
				start_rasterizer_next <= '0';
				attr0_next.pos        <= rescale_vertices(attr0.pos);
				attr1_next.pos        <= rescale_vertices(attr1.pos);
				attr2_next.pos        <= rescale_vertices(attr2.pos);

				angle            <= rot_light_in.y;
				rh_shift_next         <= int8(13);
				rh_in01_next          <= light_dir.z;
				rh_in02_next          <= light_dir.x;
				rh_in03_next          <= light_dir.z;
				rh_in04_next          <= -light_dir.x;
				rh_trig1_next         <= sine;
				rh_trig2_next         <= cosine;
				rh_trig3_next         <= cosine;
				rh_trig4_next         <= sine;

				state_next <= st_calc_area_prepare_parameters;

			when st_calc_area_prepare_parameters =>
				light_dir_next.x <= rh_out01;
				light_dir_next.z <= rh_out02;
				
				ready_out_next        <= '0';
				start_rasterizer_next <= '0';

				area_v := cross_product(attr0.pos, attr1.pos, attr2.pos);
				if area_v <= 0 then     -- backface culling
					state_next <= st_next_triangle;
				else
					triangle_v       := (
						(x => attr0.pos.x, y => attr0.pos.y),
						(x => attr1.pos.x, y => attr1.pos.y),
						(x => attr2.pos.x, y => attr2.pos.y)
					);
					triangle_next    <= triangle_v;
					area_next        <= area_v;
					depths_next      <= point3d(attr0.pos.z, attr1.pos.z, attr2.pos.z);
					render_rect_next <= get_current_rendering_bounding_box(triangle_v, tile_rect_in);

					state_next <= st_calc_lighting;
				end if;

			when st_calc_lighting =>
				colors_next <= (
					calc_vertex_lighting(attr0, light_dir, ambient_diffuse),
					calc_vertex_lighting(attr1, light_dir, ambient_diffuse),
					calc_vertex_lighting(attr2, light_dir, ambient_diffuse)
				);

				start_rasterizer_next <= '1';

				state_next <= st_wait_for_rasterizer;

			when st_wait_for_rasterizer =>
				ready_out_next        <= '0';
				start_rasterizer_next <= '0';
				if rasterizer_ready then
					state_next <= st_next_triangle;
				else
					state_next <= st_wait_for_rasterizer;
				end if;

			when st_next_triangle =>
				start_rasterizer_next <= '0';
				if triangle_id < indices'length - 1 then
					triangle_id_next <= triangle_id + 1;
					state_next       <= st_prepare_triangle_verts;
				else
					triangle_id_next <= 0;
					ready_out_next   <= '1';
					state_next       <= st_idle;
				end if;

		end case;
	end process;

end architecture rtl;
