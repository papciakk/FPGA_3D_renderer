library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;
use work.renderer_mesh.all;

entity tile_generator is
	port(
		clk                   : in  std_logic;
		rst                   : in  std_logic;
		trianglegen_posx_out  : out unsigned(15 downto 0);
		trianglegen_posy_out  : out unsigned(15 downto 0);
		trianglegen_put_pixel : out std_logic;
		color_out             : out color_t;
		tile_rect_in          : in  rect_t;
		start_in              : in  std_logic;
		ready_out             : out std_logic;
		depth_in : out unsigned(15 downto 0);
		depth_out : in unsigned(15 downto 0);
		depth_wren : out std_logic
	);
end entity tile_generator;

architecture bahavioral of tile_generator is
	signal triangle, triangle_next                             : triangle2d_t;
	signal current_triangle_index, current_triangle_index_next : integer := 0;

	signal start_rendering, start_rendering_next : std_logic := '0';
	signal trianglegen_ready                     : std_logic;

	signal ready_out_next : std_logic;

	signal rand : std_logic_vector(31 downto 0);

	type state_type is (
		st_start, st_render_task, st_render_task_wait, st_finished, st_idle
	);
	signal state, state_next : state_type := st_start;

	signal area, area_next     : s32;
	signal depths, depths_next : point3d_t;
	signal colors, colors_next : triangle_colors_t;

	function calc_lighting_for_vertex(vertex : vertex_attr_t) return color_t is
		variable diffuse_raw : signed(47 downto 0);
		variable diffuse     : std_logic_vector(7 downto 0);
		variable diffuse_1 : unsigned(47 downto 0);
		
		constant light_dir : point3d_32t := (
			z => to_signed(180, 32),
			y => (others => '0'),
			x => to_signed(180, 32)
		);
	begin

		diffuse_raw := (vertex.normal.x * light_dir.x + vertex.normal.y * light_dir.y + vertex.normal.z * light_dir.z) / 255;

		if diffuse_raw > 0 then
			if diffuse_raw > 255 then
				diffuse := std_logic_vector(to_unsigned(255, 8));
			else
				diffuse_1 := to_unsigned(to_integer(abs(diffuse_raw)), 48);
				diffuse := std_logic_vector(diffuse_1(7 downto 0));
			end if;
		else
			diffuse := (others => '0');
		end if;

		return color(diffuse, diffuse, diffuse);
	end function;

	function rescale_attributes(vertex : vertex_attr_t) return vertex_attr_t is
	begin

		return (
			pos    => (
				x => vertex.pos.x / 128 + 320,
				y => vertex.pos.y / 128,
				z => vertex.pos.z / 128 + 240
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
			depth_buf_in => depth_in,
			depth_buf_out => depth_out,
			depth_wren => depth_wren
		);

	random0 : entity work.random
		port map(
			clk  => clk,
			rst  => rst,
			rand => rand,
			seed => (others => '0')
		);

	process(clk, rst) is
	begin
		if rst = '1' then
			state <= st_start;
		elsif rising_edge(clk) then
			state                  <= state_next;
			current_triangle_index <= current_triangle_index_next;
			start_rendering        <= start_rendering_next;
			triangle               <= triangle_next;
			ready_out              <= ready_out_next;
			area                   <= area_next;
			depths                 <= depths_next;
			colors                 <= colors_next;

		end if;
	end process;

	process(state, current_triangle_index, trianglegen_ready, start_rendering, triangle, start_in, ready_out, area, depths, colors) is
		variable v1, v2, v3 : vertex_attr_t;
		variable area_v     : s32;

		variable color1, color2, color3 : color_t;

	begin
		state_next                  <= state;
		current_triangle_index_next <= current_triangle_index;
		start_rendering_next        <= start_rendering;
		triangle_next               <= triangle;
		ready_out_next              <= ready_out;
		area_next                   <= area;
		depths_next                 <= depths;
		colors_next                 <= colors;

		case state is
			when st_start =>
				ready_out_next              <= '0';
				current_triangle_index_next <= 0;
				start_rendering_next        <= '0';
				state_next                  <= st_idle;

			when st_render_task =>
				v1 := rescale_attributes(vertices(to_integer(indices(current_triangle_index).a)));
				v2 := rescale_attributes(vertices(to_integer(indices(current_triangle_index).b)));
				v3 := rescale_attributes(vertices(to_integer(indices(current_triangle_index).c)));

				color1 := calc_lighting_for_vertex(v1);
				color2 := calc_lighting_for_vertex(v2);
				color3 := calc_lighting_for_vertex(v3);

				area_v := (v1.pos.x - v2.pos.x) * (v3.pos.z - v2.pos.z) - (v1.pos.z - v2.pos.z) * (v3.pos.x - v2.pos.x);

				--				if area_v > 0 then      -- backface culling - ccw mode
				triangle_next <= (
					(x => v1.pos.x, y => v1.pos.z),
					(x => v2.pos.x, y => v2.pos.z),
					(x => v3.pos.x, y => v3.pos.z)
				);

				area_next   <= area_v;
				depths_next <= point3d(v1.pos.y, v2.pos.y, v3.pos.y);
									colors_next <= (
										color(v1.normal.x, v1.normal.y, v1.normal.z),
										color(v2.normal.x, v2.normal.y, v2.normal.z),
										color(v3.normal.x, v3.normal.y, v3.normal.z)
										
									);

--				colors_next <= (
--					color1,
--					color2,
--					color3
--				);

				--									color_out <= (
				--										r => std_logic_vector(v2.normal.x(7 downto 0)),
				--										g => std_logic_vector(v2.normal.y(7 downto 0)),
				--										b => std_logic_vector(v2.normal.z(7 downto 0))
				--									);

				ready_out_next       <= '0';
				start_rendering_next <= '1';
				state_next           <= st_render_task_wait;
			--				else
			--					state_next <= st_finished;
			--				end if;

			when st_render_task_wait =>
				ready_out_next       <= '0';
				start_rendering_next <= '0';

				if trianglegen_ready = '1' then
					state_next <= st_finished;
				else
					state_next <= st_render_task_wait;
				end if;

			when st_finished =>
				if current_triangle_index < indices'length then
					current_triangle_index_next <= current_triangle_index + 1;
					start_rendering_next        <= '0';
					state_next                  <= st_render_task;
				else
					ready_out_next <= '1';
					state_next     <= st_start;
				end if;

			when st_idle =>
				ready_out_next <= '0';
				if start_in = '1' then
					ready_out_next              <= '0';
					current_triangle_index_next <= 0;
					state_next                  <= st_render_task;
				else
					state_next <= st_idle;
				end if;
		end case;
	end process;

end architecture bahavioral;

