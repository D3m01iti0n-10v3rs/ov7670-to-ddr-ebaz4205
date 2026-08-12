`timescale 1 ns / 1 ps

	module VideoCapture_master_stream_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input  [7:0] d,
		input        pclk,
		input        vsync,
		input        href,
		input  [9:0] h_res_words,
		output reg   M_AXIS_TUSER,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output reg  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output reg [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output reg  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);

	assign M_AXIS_TSTRB = {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};

	// ===========================================================================
	// Original VideoCapture logic, dropped in unchanged. Runs entirely on the
	// camera's own pclk -- M_AXIS_ACLK/M_AXIS_ARESETN above are left
	// unused, exactly as in the original standalone module.
	//
	// cam_rst/cam_pwnn moved out of this file -- they're now raw register bits
	// driven directly from VideoCapture_slave_lite_v1_0_S00_AXI.
	// ===========================================================================

	parameter   IDLE = 2'b00,
	            NEW_FRAME = 2'b01,
	            NEW_LINE  = 2'b10,
	            UNDEFINED = 2'b11;
	//parameter H_RES = 4; // double to get actual horizontal pixel count (if 640 then H_RES = 320)
	wire [1:0] cur_state;
	reg [31:0] camera_data;
	reg pending_tlast;
	reg pending_tuser;
	reg word_avail;
	reg [1:0] byte_count;
	reg [9:0] pixel_x;
	reg first_pixel;

	// State checker
	assign cur_state =
	(!M_AXIS_ARESETN)      ? IDLE :
	(vsync && !href)       ? NEW_FRAME :
	(!vsync && href)       ? NEW_LINE :
	                         IDLE;

	// Store bytes from camera to buffer
	always @(posedge pclk) begin
	    if (!M_AXIS_ARESETN) begin
	        camera_data <= 32'd0;
	        pending_tlast <= 1'b0;
	        pending_tuser <= 1'b0;
	        word_avail <= 1'b0;
	        byte_count <= 2'b00;
	        pixel_x <= 10'd0;
	        first_pixel <= 1'b1;
	        M_AXIS_TVALID <= 1'b0;
	        M_AXIS_TLAST <= 1'b0;
	        M_AXIS_TUSER <= 1'b0;
	        M_AXIS_TDATA <= 32'd0;
	    end
	    else begin
	        case (cur_state)
	            IDLE: begin
	                byte_count <= 2'b00;
	            end
	            NEW_FRAME: begin
	                word_avail <= 1'b0;
	                byte_count <= 2'b00;
	                pixel_x <= 10'd0;
	                first_pixel <= 1'b1;
	            end
	            NEW_LINE: begin

	                case (byte_count)
	                    2'b00: camera_data[31:24] <= d[7:0];
	                    2'b01: camera_data[23:16] <= d[7:0];
	                    2'b10: camera_data[15:8] <= d[7:0];
	                    2'b11: begin
	                        camera_data[7:0] <= d[7:0];
	                        pending_tuser <= first_pixel;
	                        pending_tlast <= (pixel_x == h_res_sync1 - 1);
	                        word_avail <= 1'b1;
	                    end
	                endcase

	                byte_count <= byte_count + 2'b01;
	            end
	        endcase
	        if (word_avail) begin
	            M_AXIS_TDATA  <= camera_data;
	            M_AXIS_TVALID <= 1'b1;
	            M_AXIS_TUSER <= pending_tuser;
	            M_AXIS_TLAST <= pending_tlast;
	            if (M_AXIS_TREADY) begin
	                word_avail <= 1'b0;
	                if (first_pixel) first_pixel <= 1'b0;
	                if (pending_tlast) pixel_x <= 10'd0;
	                else pixel_x <= pixel_x + 1'b1;
	            end
	        end
	        else begin
	            M_AXIS_TVALID <= 1'b0;
	            M_AXIS_TUSER <= 1'b0;
	            M_AXIS_TLAST <= 1'b0;
	        end
	    end
	end

	// Add user logic here
    reg [9:0] h_res_sync0, h_res_sync1;
    always @(posedge pclk) begin
        h_res_sync0 <= h_res_words;
        h_res_sync1 <= h_res_sync0;
    end
	// User logic ends

	endmodule