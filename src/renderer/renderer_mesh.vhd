use work.common.all;

package renderer_mesh is
	constant vertices : vertex_arr_t(0 to 4) := (
		point2d(18, 83),
		point2d(130, 19),
		point2d(170, 120),
		point2d(40, 115),
		point2d(172, 26)
	);

	constant indices : indices_arr_t(0 to 2) := (
		idx(2, 0, 1),
		idx(2, 0, 3),
		idx(4, 2, 1)
	);

end package renderer_mesh;
