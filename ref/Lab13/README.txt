// Change log: 
+ Filename: cnn_accel.v
	+ Lines 644~645: Correct out_pixel
		out_pixel <= acc_o[31:0];
	Note: 
		acc_o[ 7:  0]: The output pixel for Channel 0 => Connected to bmp_writer_00
		acc_o[15: 8]: The output pixel for Channel 1  => Connected to bmp_writer_01
		acc_o[23:16]: The output pixel for Channel 2 => Connected to bmp_writer_02
		acc_o[31:24]: The output pixel for Channel 3 => Connected to bmp_writer_03
	
	+ Lines 652~701: Add code for file logging (Slide 51 on Lecture Note 13)
	Note: It may slow down the simulation when writing logging files. 	

+ Add the file ex2_cnn_accel_dma/img/butterfly_32bit_reorder.hex

// Comments for verification		
1. Lab1a: Access buffers for weights, biases, and scales
	+ Handle a read request (addr, en)
		weights
			L1: 0->1-> ... ->15         (with an enable signable = 1)  
			L2: 16->17-> ... ->159    (with an enable signable = 1)
			L3: 160->161-> ... ->303 (with an enable signable = 1)
		scales/biases
			L1: 0->1-> ... ->15         (with an enable signable = 1)  
			L2: 16->17-> ... ->31    (with an enable signable = 1)
			L3: 32->33-> ... ->47 (with an enable signable = 1)

	+ Handle a return data (dob)
		+ Valid signal for dob is en_d
		+ Copy the dob to the local registers with the data size
			win_buf: 		WI * Ti 		-> 128 bit
			bias/scale:	PARAM_BITS	-> 16 bit

2. Lab1b: Access buffers for feature maps
	+ Handle a read request (pix_idx, data_count, q_width)

	+ Handle a return data dob: Check the synchronized signals
		+ valid signal (ctrl_data_run_d)
		+ pix_idx_d
		+ is_first_row_d, ...

3. Lab2 : Access the (external) memory for the input buffer
	+ The memory is an BRAM instance in top_system_tb.v and the memory cells are initialized from the file ing/butterfly_32bit.hex
		0000002a
		00000045
		0000005b
		00000063
		0000006a
		0000006c
		0000006f
		0000006d
		.................
	Comment: The size of word in memory is 32 bits which is match with the data for bus (HRDATA, WDATA). 

	+ Handle a read request:
		+ DMA: 
			start_dma_ld: Start a DMA
			num_trans_ld: Number of transactions
			start_addr_ld: Starting address for a DMA load/read request
		+ Loading pixels for in_img: Load data line by line
			num_trans_ld = 128 or q_width => Getting 512 bytes
			start_addr_ld: 0 -> 512 -> 1024 -> ... 
			Use a line counter: 0 -> 1 -> 2 -> ... -> 127 --> 0

	+ Handle a return data 
		data_vld_o_ld: 	Valid signal
		data_o_ld: 	32-bit return data
		data_last_o_ld: 	Mark the last data for one DMA load/request, i.e., for transaction 128 in this case. 
		Given an incoming data (data_vld_o_ld==1)						
			+ Pixel counter or index (in_pixel_count) for in_img must be updated, i.e., increasing by 1
			+ in_img must be updated using the pixel index (in_pixel_count) and the return data (data_o_ld)	