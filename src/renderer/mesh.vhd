use work.definitions.all;

package mesh is
	constant vertices : vertex_attr_arr_t(0 to 41) := (
		va(0, 0, 30720, 0, 0, 32767), va(0, 18056, 24853, 0, 20487, 25573), va(-10613, 14608, 24853, -12042, 16574, 25573), 
		va(-17173, 5579, 24853, -19484, 6331, 25573), va(-17173, -5579, 24853, -19484, -6331, 25573), va(-10613, -14608, 24853, -12042, -16574, 25573), 
		va(0, -18056, 24852, 0, -20487, 25573), va(10613, -14608, 24853, 12042, -16574, 25573), va(17173, -5579, 24853, 19484, -6331, 25573), 
		va(17172, 5579, 24853, 19484, 6331, 25573), va(10613, 14608, 24853, 12042, 16574, 25573), va(0, 29216, 9493, 0, 31334, 9584), 
		va(-17173, 23636, 9493, -18418, 25350, 9584), va(-27786, 9028, 9493, -29801, 9683, 9584), va(-27786, -9028, 9492, -29801, -9683, 9584), 
		va(-17173, -23636, 9492, -18418, -25350, 9584), va(0, -29216, 9492, 0, -31334, 9584), va(17173, -23636, 9492, 18418, -25350, 9584), 
		va(27786, -9028, 9492, 29801, -9683, 9584), va(27786, 9028, 9493, 29801, 9683, 9584), va(17172, 23636, 9493, 18418, 25350, 9584), 
		va(0, 29216, -9492, 0, 31334, -9584), va(-17172, 23636, -9492, -18418, 25350, -9584), va(-27786, 9028, -9493, -29801, 9683, -9584), 
		va(-27786, -9028, -9493, -29801, -9683, -9584), va(-17173, -23636, -9493, -18418, -25350, -9584), va(0, -29216, -9493, 0, -31334, -9584), 
		va(17173, -23636, -9493, 18418, -25350, -9584), va(27786, -9028, -9493, 29801, -9683, -9584), va(27786, 9028, -9493, 29801, 9683, -9584), 
		va(17172, 23636, -9492, 18418, 25350, -9584), va(0, 18056, -24853, 0, 20487, -25573), va(-10613, 14608, -24853, -12042, 16574, -25573), 
		va(-17172, 5579, -24853, -19484, 6331, -25573), va(-17173, -5579, -24853, -19484, -6331, -25573), va(-10613, -14608, -24853, -12042, -16574, -25573), 
		va(0, -18056, -24853, 0, -20487, -25573), va(10613, -14608, -24853, 12042, -16574, -25573), va(17173, -5579, -24853, 19484, -6331, -25573), 
		va(17172, 5579, -24853, 19484, 6331, -25573), va(10613, 14608, -24853, 12042, 16574, -25573), va(0, 0, -30720, 0, 0, -32767)
		
	);

	constant indices : indices_arr_t(0 to 79) := (
		idx(0, 1, 2), idx(0, 2, 3), idx(0, 3, 4), idx(0, 4, 5), idx(0, 5, 6), 
		idx(0, 6, 7), idx(0, 7, 8), idx(0, 8, 9), idx(0, 9, 10), idx(0, 10, 1), 
		idx(1, 11, 12), idx(1, 12, 2), idx(2, 12, 13), idx(2, 13, 3), idx(3, 13, 14), 
		idx(3, 14, 4), idx(4, 14, 15), idx(4, 15, 5), idx(5, 15, 16), idx(5, 16, 6), 
		idx(6, 16, 17), idx(6, 17, 7), idx(7, 17, 18), idx(7, 18, 8), idx(8, 18, 19), 
		idx(8, 19, 9), idx(9, 19, 20), idx(9, 20, 10), idx(10, 20, 11), idx(10, 11, 1), 
		idx(11, 21, 22), idx(11, 22, 12), idx(12, 22, 23), idx(12, 23, 13), idx(13, 23, 24), 
		idx(13, 24, 14), idx(14, 24, 25), idx(14, 25, 15), idx(15, 25, 26), idx(15, 26, 16), 
		idx(16, 26, 27), idx(16, 27, 17), idx(17, 27, 28), idx(17, 28, 18), idx(18, 28, 29), 
		idx(18, 29, 19), idx(19, 29, 30), idx(19, 30, 20), idx(20, 30, 21), idx(20, 21, 11), 
		idx(21, 31, 32), idx(21, 32, 22), idx(22, 32, 33), idx(22, 33, 23), idx(23, 33, 34), 
		idx(23, 34, 24), idx(24, 34, 35), idx(24, 35, 25), idx(25, 35, 36), idx(25, 36, 26), 
		idx(26, 36, 37), idx(26, 37, 27), idx(27, 37, 38), idx(27, 38, 28), idx(28, 38, 39), 
		idx(28, 39, 29), idx(29, 39, 40), idx(29, 40, 30), idx(30, 40, 31), idx(30, 31, 21), 
		idx(41, 32, 31), idx(41, 33, 32), idx(41, 34, 33), idx(41, 35, 34), idx(41, 36, 35), 
		idx(41, 37, 36), idx(41, 38, 37), idx(41, 39, 38), idx(41, 40, 39), idx(41, 31, 40)
		
	);

end package;
