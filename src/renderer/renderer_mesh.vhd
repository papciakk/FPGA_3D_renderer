use work.common.all;

package renderer_mesh is
	constant vertices : vertex_arr_t(0 to 3) := (
		point2d(10, 10), point2d(10, 100), point2d(100, 10), point2d(100, 100)
	);

	constant indices : indices_arr_t(0 to 1) := (
		idx(0, 1, 2), idx(3, 2, 1)
		
	);

end package renderer_mesh;
