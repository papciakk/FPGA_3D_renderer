package fb_types is

	type fb_lo_level_op_type is (
		fb_lo_op_init, 
		fb_lo_op_read_data, 
		fb_lo_op_write_command, 
		fb_lo_op_write_data, 
		fb_lo_op_wait_ms
	);
	
end package fb_types;
