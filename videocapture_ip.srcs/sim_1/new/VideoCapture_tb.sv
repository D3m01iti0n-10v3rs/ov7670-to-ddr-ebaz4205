`timescale 1ns / 1ps

module VideoCapture_tb;

    // Camera interface
    reg        pclk;
    reg        vsync;
    reg        href;
    reg  [7:0] d;
    wire       cam_rst;
    wire       cam_pwnn;

    // AXI4-Stream (M00_AXIS)
    wire        m00_axis_aclk_dummy = 1'b0;   // unused by the FSM, tied off
    reg         m00_axis_aresetn;
    wire        m00_axis_tvalid;
    wire [31:0] m00_axis_tdata;
    wire [3:0]  m00_axis_tstrb;
    wire        m00_axis_tlast;
    wire        m00_axis_tuser;
    reg         m00_axis_tready;

    // AXI4-Lite (S00_AXI) -- tied idle, registers not implemented yet
    reg         s00_axi_aclk;
    reg         s00_axi_aresetn;
    reg  [3:0]  s00_axi_awaddr;
    reg  [2:0]  s00_axi_awprot;
    reg         s00_axi_awvalid;
    wire        s00_axi_awready;
    reg  [31:0] s00_axi_wdata;
    reg  [3:0]  s00_axi_wstrb;
    reg         s00_axi_wvalid;
    wire        s00_axi_wready;
    wire [1:0]  s00_axi_bresp;
    wire        s00_axi_bvalid;
    reg         s00_axi_bready;
    reg  [3:0]  s00_axi_araddr;
    reg  [2:0]  s00_axi_arprot;
    reg         s00_axi_arvalid;
    wire        s00_axi_arready;
    wire [31:0] s00_axi_rdata;
    wire [1:0]  s00_axi_rresp;
    wire        s00_axi_rvalid;
    reg         s00_axi_rready;

    VideoCapture dut (
        .d              (d),
        .pclk           (pclk),
        .vsync          (vsync),
        .href           (href),
        .cam_rst        (cam_rst),
        .cam_pwnn       (cam_pwnn),
        .m00_axis_tuser (m00_axis_tuser),

        .s00_axi_aclk    (s00_axi_aclk),
        .s00_axi_aresetn (s00_axi_aresetn),
        .s00_axi_awaddr  (s00_axi_awaddr),
        .s00_axi_awprot  (s00_axi_awprot),
        .s00_axi_awvalid (s00_axi_awvalid),
        .s00_axi_awready (s00_axi_awready),
        .s00_axi_wdata   (s00_axi_wdata),
        .s00_axi_wstrb   (s00_axi_wstrb),
        .s00_axi_wvalid  (s00_axi_wvalid),
        .s00_axi_wready  (s00_axi_wready),
        .s00_axi_bresp   (s00_axi_bresp),
        .s00_axi_bvalid  (s00_axi_bvalid),
        .s00_axi_bready  (s00_axi_bready),
        .s00_axi_araddr  (s00_axi_araddr),
        .s00_axi_arprot  (s00_axi_arprot),
        .s00_axi_arvalid (s00_axi_arvalid),
        .s00_axi_arready (s00_axi_arready),
        .s00_axi_rdata   (s00_axi_rdata),
        .s00_axi_rresp   (s00_axi_rresp),
        .s00_axi_rvalid  (s00_axi_rvalid),
        .s00_axi_rready  (s00_axi_rready),

        .m00_axis_aclk    (m00_axis_aclk_dummy),
        .m00_axis_aresetn (m00_axis_aresetn),
        .m00_axis_tvalid  (m00_axis_tvalid),
        .m00_axis_tdata   (m00_axis_tdata),
        .m00_axis_tstrb   (m00_axis_tstrb),
        .m00_axis_tlast   (m00_axis_tlast),
        .m00_axis_tready  (m00_axis_tready)
    );

    // ------------------------------------------------------------------
    // pclk = 25 MHz camera clock
    // ------------------------------------------------------------------
    always #20 pclk = ~pclk;

    // s00_axi_aclk unused by any logic right now, just needs to toggle so
    // the S00_AXI submodule's reset state machines settle into Idle.
    always #5 s00_axi_aclk = ~s00_axi_aclk;

    parameter WIDTH  = 8;
    parameter HEIGHT = 4;
    parameter HBLANK_CYCLES = 4;
    parameter VSYNC_LINES = 3;
    parameter NUM_FRAMES = 2;
    localparam LINE_CYCLES = (2*WIDTH) + HBLANK_CYCLES;
    localparam WORDS_PER_FRAME = (WIDTH/2) * HEIGHT;

    reg [15:0] pixel;
    reg [7:0]  lo, hi;
    integer x, y, frame;

    // ------------------------------------------------------------------
    // Expected word check, always consumes on tready=1 (test always ready)
    // ------------------------------------------------------------------
    integer word_idx;
    integer errors;

    function automatic [15:0] expected_pixel(input integer n);
        reg [7:0] h, l;
        begin
            h = 8'haa + n[7:0];
            l = 8'h72 + n[7:0];
            expected_pixel = {h, l};
        end
    endfunction

    task automatic check_word(input integer idx);
        reg [15:0] p0, p1;
        reg [31:0] exp;
        reg exp_tuser, exp_tlast;
        begin
            p0 = expected_pixel(2*idx);
            p1 = expected_pixel(2*idx + 1);
            exp = {p0, p1};
            exp_tuser = (idx % WORDS_PER_FRAME == 0);
            exp_tlast = (idx % (WIDTH/2) == (WIDTH/2 - 1));

            if (m00_axis_tdata !== exp) begin
                $display("[%0t] word[%0d] MISMATCH tdata=0x%08h expected=0x%08h",
                          $time, idx, m00_axis_tdata, exp);
                errors = errors + 1;
            end
            if (m00_axis_tuser !== exp_tuser) begin
                $display("[%0t] word[%0d] MISMATCH tuser=%0b expected=%0b",
                          $time, idx, m00_axis_tuser, exp_tuser);
                errors = errors + 1;
            end
            if (m00_axis_tlast !== exp_tlast) begin
                $display("[%0t] word[%0d] MISMATCH tlast=%0b expected=%0b",
                          $time, idx, m00_axis_tlast, exp_tlast);
                errors = errors + 1;
            end
            if (m00_axis_tdata === exp && m00_axis_tuser === exp_tuser && m00_axis_tlast === exp_tlast)
                $display("[%0t] word[%0d] MATCH tdata=0x%08h tuser=%0b tlast=%0b",
                          $time, idx, m00_axis_tdata, m00_axis_tuser, m00_axis_tlast);
        end
    endtask

    // Monitor: whenever tvalid&tready fire, check the word against
    // expected_pixel() using word_idx, then advance word_idx.
    always @(posedge pclk) begin
        if (m00_axis_tvalid && m00_axis_tready) begin
            check_word(word_idx);
            word_idx = word_idx + 1;
        end
    end

    initial begin
        pclk            = 0;
        s00_axi_aclk    = 0;
        s00_axi_aresetn = 1'b1;
        s00_axi_awaddr  = 0;
        s00_axi_awprot  = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 0;
        s00_axi_wvalid  = 0;
        s00_axi_bready  = 1;
        s00_axi_araddr  = 0;
        s00_axi_arprot  = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready  = 1;

        //block_rst = 1;
        m00_axis_aresetn = 1'b0;
        vsync     = 0;
        href      = 0;
        d         = 8'h00;
        m00_axis_tready = 1'b1;

        word_idx = 0;
        errors   = 0;

        #100;
        //block_rst = 0;
        m00_axis_aresetn = 1'b1;
        #100;

        hi = 8'haa;
        lo = 8'h72;

        for (frame = 0; frame < NUM_FRAMES; frame = frame + 1) begin

            //======================================================
            // VSYNC pulse
            //======================================================
            @(negedge pclk);
            vsync = 1;
            repeat (VSYNC_LINES * LINE_CYCLES) @(negedge pclk);
            vsync = 0;

            repeat (8) @(negedge pclk);

            //======================================================
            // Active image: HEIGHT rows x WIDTH pixels, 2 bytes/pixel
            //======================================================
            for (y = 0; y < HEIGHT; y = y + 1) begin
                @(negedge pclk);
                href = 1;
                for (x = 0; x < WIDTH; x = x + 1) begin
                    pixel = {hi, lo};
                    lo = lo + 8'd1;
                    hi = hi + 8'd1;

                    d = pixel[15:8];
                    @(negedge pclk);
                    d = pixel[7:0];
                    @(negedge pclk);
                end
                href = 0;
                d    = 8'h00;
                repeat (HBLANK_CYCLES) @(negedge pclk);
            end

            $display("[%0t] Camera stimulus: frame %0d/%0d sent",
                      $time, frame + 1, NUM_FRAMES);
        end

        repeat (20) @(negedge pclk);

        if (word_idx != WORDS_PER_FRAME * NUM_FRAMES) begin
            $display("[%0t] ERROR: only got %0d words, expected %0d",
                      $time, word_idx, WORDS_PER_FRAME * NUM_FRAMES);
            errors = errors + 1;
        end

        $display("---------------------------------------------------------");
        if (errors == 0)
            $display(" ALL CHECKS PASSED (%0d words)", word_idx);
        else
            $display(" %0d ERROR(S)", errors);

        $finish;
    end

endmodule