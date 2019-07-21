use work.definitions.all;

package renderer_mesh is
	constant vertices : vertex_attr_arr_t(0 to 25) := (
		va(0, 0, 24574, 127, 127, 254), va(0, 17373, 17373, 127, 222, 211), va(-12287, 12287, 17373, 59, 194, 211), va(-17373, 0, 17373, 31, 127, 211), va(-12287, -12287, 17373, 59, 59, 211), va(0, -17373, 17373, 127, 31, 211), va(12287, -12287, 17373, 194, 59, 211), va(17373, 0, 17373, 222, 127, 211), va(12287, 12287, 17373, 194, 194, 211), va(0, 24574, 0, 127, 254, 127), va(-17373, 17373, 0, 37, 216, 127), 
		va(-24574, 0, 0, 0, 127, 127), va(-17373, -17373, 0, 37, 37, 127), va(0, -24574, 0, 127, 0, 127), va(17373, -17373, 0, 216, 37, 127), va(24574, 0, 0, 254, 127, 127), va(17373, 17373, 0, 216, 216, 127), va(0, 17373, -17373, 127, 222, 42), va(-12287, 12287, -17373, 59, 194, 42), va(-17373, 0, -17373, 31, 127, 42), va(-12287, -12287, -17373, 59, 59, 42), 
		va(0, -17373, -17373, 127, 31, 42), va(12287, -12287, -17373, 194, 59, 42), va(17373, 0, -17373, 222, 127, 42), va(12287, 12287, -17373, 194, 194, 42), va(0, 0, -24574, 127, 127, 0)
	);

	constant indices : indices_arr_t(0 to 47) := (
		idx(0, 1, 2), idx(0, 2, 3), 
		idx(0, 3, 4), idx(0, 4, 5), idx(0, 5, 6), idx(0, 6, 7), idx(0, 7, 8), idx(0, 8, 1), idx(1, 9, 10), idx(1, 10, 2), idx(2, 10, 11), idx(2, 11, 3), 
		idx(3, 11, 12), idx(3, 12, 4), idx(4, 12, 13), idx(4, 13, 5), idx(5, 13, 14), idx(5, 14, 6), idx(6, 14, 15), idx(6, 15, 7), idx(7, 15, 16), idx(7, 16, 8), 
		idx(8, 16, 9), idx(8, 9, 1), idx(9, 17, 18), idx(9, 18, 10), idx(10, 18, 19), idx(10, 19, 11), idx(11, 19, 20), idx(11, 20, 12), idx(12, 20, 21), idx(12, 21, 13), 
		idx(13, 21, 22), idx(13, 22, 14), idx(14, 22, 23), idx(14, 23, 15), idx(15, 23, 24), idx(15, 24, 16), idx(16, 24, 17), idx(16, 17, 9), idx(25, 18, 17), idx(25, 19, 18), 
		idx(25, 20, 19), idx(25, 21, 20), idx(25, 22, 21), idx(25, 23, 22), idx(25, 24, 23), idx(25, 17, 24)
	);

end package renderer_mesh;
