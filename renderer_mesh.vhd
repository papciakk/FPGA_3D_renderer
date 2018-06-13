use work.common.all;

package renderer_mesh is
	constant vertices : vertex_arr_t(0 to 90) := (
		point2d(313, 75), point2d(291, 75), point2d(292, 69), point2d(313, 69), point2d(295, 75), point2d(319, 75), point2d(238, 75), point2d(238, 69), point2d(238, 75), point2d(184, 75), point2d(184, 69), 
		point2d(181, 75), point2d(163, 75), point2d(162, 69), point2d(157, 75), point2d(308, 117), point2d(337, 117), point2d(314, 155), point2d(346, 155), point2d(238, 117), point2d(238, 155), 
		point2d(167, 117), point2d(161, 155), point2d(139, 117), point2d(130, 155), point2d(305, 183), point2d(332, 183), point2d(295, 196), point2d(319, 196), point2d(238, 183), point2d(238, 196), 
		point2d(171, 183), point2d(181, 196), point2d(144, 183), point2d(157, 196), point2d(238, 204), point2d(169, 201), point2d(287, 201), point2d(307, 201), point2d(238, 201), point2d(189, 201), 
		point2d(319, 83), point2d(321, 89), point2d(374, 91), point2d(379, 86), point2d(391, 107), point2d(400, 107), point2d(324, 95), point2d(368, 96), point2d(383, 107), point2d(380, 136), 
		point2d(385, 142), point2d(343, 163), point2d(340, 172), point2d(375, 131), point2d(146, 172), point2d(146, 149), point2d(101, 117), point2d(93, 126), point2d(76, 75), point2d(60, 75), 
		point2d(146, 127), point2d(109, 107), point2d(93, 75), point2d(70, 71), point2d(53, 70), point2d(76, 75), point2d(66, 75), point2d(86, 72), point2d(87, 75), point2d(238, 34), 
		point2d(255, 43), point2d(250, 43), point2d(246, 58), point2d(249, 58), point2d(238, 43), point2d(238, 58), point2d(225, 43), point2d(230, 58), point2d(220, 43), point2d(227, 58), 
		point2d(269, 67), point2d(282, 67), point2d(288, 75), point2d(308, 75), point2d(238, 67), point2d(238, 75), point2d(206, 67), point2d(188, 75), point2d(194, 67), point2d(168, 75)
		
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
