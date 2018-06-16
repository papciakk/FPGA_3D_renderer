use work.common.all;

package renderer_mesh is
	constant vertices : vertex_arr_t(0 to 90) := (
		point2d(459, 95), point2d(423, 95), point2d(423, 87), point2d(459, 87), point2d(429, 95), point2d(467, 95), point2d(335, 95), point2d(335, 87), point2d(335, 95), point2d(248, 95), point2d(248, 87), 
		point2d(242, 95), point2d(212, 95), point2d(212, 87), point2d(203, 95), point2d(451, 164), point2d(498, 164), point2d(460, 227), point2d(511, 227), point2d(335, 164), point2d(335, 227), 
		point2d(220, 164), point2d(210, 227), point2d(173, 164), point2d(159, 227), point2d(445, 273), point2d(489, 273), point2d(429, 293), point2d(467, 293), point2d(335, 273), point2d(335, 293), 
		point2d(226, 273), point2d(242, 293), point2d(181, 273), point2d(203, 293), point2d(335, 307), point2d(222, 302), point2d(416, 302), point2d(448, 302), point2d(335, 302), point2d(255, 302), 
		point2d(467, 108), point2d(472, 118), point2d(557, 122), point2d(566, 113), point2d(586, 148), point2d(600, 148), point2d(476, 128), point2d(548, 131), point2d(573, 148), point2d(567, 196), 
		point2d(576, 205), point2d(507, 241), point2d(503, 254), point2d(559, 188), point2d(186, 254), point2d(186, 217), point2d(112, 164), point2d(99, 179), point2d(71, 95), point2d(45, 95), 
		point2d(186, 181), point2d(125, 148), point2d(98, 95), point2d(60, 89), point2d(34, 88), point2d(71, 95), point2d(54, 95), point2d(87, 90), point2d(89, 95), point2d(335, 29), 
		point2d(364, 44), point2d(356, 44), point2d(348, 69), point2d(353, 69), point2d(335, 44), point2d(335, 69), point2d(315, 44), point2d(323, 69), point2d(307, 44), point2d(318, 69), 
		point2d(387, 82), point2d(408, 82), point2d(417, 95), point2d(450, 95), point2d(335, 82), point2d(335, 95), point2d(284, 82), point2d(254, 95), point2d(263, 82), point2d(221, 95)
		
	);

	constant indices : indices_arr_t(0 to 129) := (
		idx(0, 1, 2), idx(2, 3, 0), 
		idx(3, 2, 4), idx(4, 5, 3), idx(1, 6, 7), idx(7, 2, 1), idx(2, 7, 8), idx(8, 4, 2), idx(6, 9, 10), idx(10, 7, 6), idx(7, 10, 11), idx(11, 8, 7), 
		idx(9, 12, 13), idx(13, 10, 9), idx(10, 13, 14), idx(14, 11, 10), idx(5, 4, 15), idx(15, 16, 5), idx(16, 15, 17), idx(17, 18, 16), idx(4, 8, 19), idx(19, 15, 4), 
		idx(15, 19, 20), idx(20, 17, 15), idx(8, 11, 21), idx(21, 19, 8), idx(19, 21, 22), idx(22, 20, 19), idx(11, 14, 23), idx(23, 21, 11), idx(21, 23, 24), idx(24, 22, 21), 
		idx(18, 17, 25), idx(25, 26, 18), idx(26, 25, 27), idx(27, 28, 26), idx(17, 20, 29), idx(29, 25, 17), idx(25, 29, 30), idx(30, 27, 25), idx(20, 22, 31), idx(31, 29, 20), 
		idx(29, 31, 32), idx(32, 30, 29), idx(22, 24, 33), idx(33, 31, 22), idx(31, 33, 34), idx(34, 32, 31), idx(35, 35, 36), idx(28, 27, 37), idx(37, 38, 28), idx(38, 37, 35), 
		idx(35, 35, 38), idx(27, 30, 39), idx(39, 37, 27), idx(37, 39, 35), idx(35, 35, 37), idx(30, 32, 40), idx(40, 39, 30), idx(39, 40, 35), idx(35, 35, 39), idx(32, 34, 36), 
		idx(36, 40, 32), idx(40, 36, 35), idx(35, 35, 40), idx(41, 42, 43), idx(43, 44, 41), idx(44, 43, 45), idx(45, 46, 44), idx(42, 47, 48), idx(48, 43, 42), idx(43, 48, 49), 
		idx(49, 45, 43), idx(46, 45, 50), idx(50, 51, 46), idx(51, 50, 52), idx(52, 53, 51), idx(45, 49, 54), idx(54, 50, 45), idx(50, 54, 18), idx(18, 52, 50), idx(55, 56, 57), 
		idx(57, 58, 55), idx(58, 57, 59), idx(59, 60, 58), idx(56, 61, 62), idx(62, 57, 56), idx(57, 62, 63), idx(63, 59, 57), idx(60, 59, 64), idx(64, 65, 60), idx(65, 64, 66), 
		idx(66, 67, 65), idx(59, 63, 68), idx(68, 64, 59), idx(64, 68, 69), idx(69, 66, 64), idx(70, 70, 71), idx(70, 70, 72), idx(72, 71, 70), idx(71, 72, 73), idx(73, 74, 71), 
		idx(70, 70, 75), idx(75, 72, 70), idx(72, 75, 76), idx(76, 73, 72), idx(70, 70, 77), idx(77, 75, 70), idx(75, 77, 78), idx(78, 76, 75), idx(70, 70, 79), idx(79, 77, 70), 
		idx(77, 79, 80), idx(80, 78, 77), idx(74, 73, 81), idx(81, 82, 74), idx(82, 81, 83), idx(83, 84, 82), idx(73, 76, 85), idx(85, 81, 73), idx(81, 85, 86), idx(86, 83, 81), 
		idx(76, 78, 87), idx(87, 85, 76), idx(85, 87, 88), idx(88, 86, 85), idx(78, 80, 89), idx(89, 87, 78), idx(87, 89, 90), idx(90, 88, 87)
	);

end package renderer_mesh;
