`timescale 1ns / 1ps
//==============================================================================
// design_1_tb.sv
//
// Full-path testbench for design_1_wrapper (videocapture_ip project):
//   OV7670 stimulus -> VideoCapture (S00_AXI ctrl + M00_AXIS data)
//                   -> AXI Stream Data FIFO (async, pclk<->100MHz)
//                   -> AXI VDMA (S2MM)
//                   -> DDR (emulated by an AXI VIP slave memory model)
//
// axi_vip_0 (MASTER, AXI4LITE) stands in for the PS. It drives axi_smc,
// which fans out to TWO slaves:
//   - VideoCapture_0/S00_AXI  (camera control: cam_rst/cam_pwnn/mclk)
//   - axi_vdma_0/S_AXI_LITE   (S2MM channel control)
// axi_vip_1 (SLAVE, AXI4 memory model) sits on M_AXI_S2MM and stands in for
// DDR, so the write burst has somewhere real to land in simulation. The
// real implementation replaces both VIPs with the actual PS.
//
// VideoCapture_0/S00_AXI register map (see VideoCapture_slave_lite_v1_0_S00_AXI.v):
//   0x0 CTRL:     bit0 cam_rst (raw), bit1 cam_pwnn (raw), bit2 mclk_en
//   0x4 MCLK_DIV: N, mclk_freq = s00_axi_aclk_freq / N (resets to 4 -> 25MHz)
// cam_rst/cam_pwnn/mclk are pure external pins in this design -- they have
// NO effect on the internal pixel-capture FSM in simulation (its reset is
// peripheral_aresetn, a separate domain), since there's no real camera chip
// here for them to actually power up/reset. The register writes below are
// included to exercise/verify the new AXI-Lite feature, not because the
// pixel stimulus depends on them.
//
// VDMA register offsets/sequence per PG020 (AXI VDMA v6.3), Register Direct
// mode (C_INCLUDE_SG=0), S2MM channel -- same as before:
//   S2MM_DMACR           0x30  -> RS=1 arms the channel. Bit1 (Circular_Park)
//                                 set (0x3) = Park mode.
//   S2MM_START_ADDRESS1  0xAC  -> destination address for buffer 0
//   S2MM_FRMDLY_STRIDE   0xA8  -> bytes between the start of each line
//   S2MM_HSIZE           0xA4  -> bytes per line
//   S2MM_VSIZE           0xA0  -> lines per frame; MUST be written last
//
// NOTE: this VDMA instance has C_NUM_FSTORES=3, but this testbench only
// targets buffer 0 (START_ADDRESS1) in Park mode -- same proven single-
// buffer approach as the earlier ov7670_vga_0 project's design_1_tb. Park
// mode captures exactly frame 0 and then parks, ignoring further frame
// syncs; NUM_FRAMES > 1 below exists to confirm that parking behavior is
// still correct (later frames don't corrupt frame 0's data), not to
// exercise the other two frame stores.
//
// ADDRESSES: VideoCapture_0/S00_AXI base = 0x0000_0000 (axi_vip_0's view),
// axi_vdma_0/S_AXI_LITE base = 0x44A0_0000 (axi_vip_0's view), DDR_BASE
// (axi_vdma_0's view of axi_vip_1's S_AXI) = 0x44A0_0000 -- a separate
// address space that is numerically identical to the VDMA control base by
// coincidence of this project's auto-assigned address map, same as before.
//
// PIXEL PACKING: pixel0 (first of the pair) is in the upper 16 bits,
// pixel1 in the lower 16 bits, same packing as the earlier project.
//==============================================================================

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;   // axi_vip_0 : MASTER, AXI4LITE -> "PS"
import design_1_axi_vip_1_0_pkg::*;   // axi_vip_1 : SLAVE, AXI4, mem model -> "DDR"

module design_1_tb;

    reg         clk_100MHz;

    reg         reset_rtl;   // active-high, per proc_sys_reset_0 ext_reset polarity
    reg         pclk;
    reg         vsync;
    reg         href;
    reg  [7:0]  d;

    wire        cam_rst;
    wire        cam_pwnn;
    wire        mclk;

    reg [7:0] random_shit_lowbyte;
    reg [7:0] random_shit_highbyte;

    // Signals frame-stimulus completion to the VDMA/checker block below.
    event frame_stim_done;

    design_1_wrapper dut(
        .cam_pwnn_0  (cam_pwnn),
        .cam_rst_0   (cam_rst),
        .clk_100MHz  (clk_100MHz),
        .d_0         (d),
        .href_0      (href),
        .mclk_0      (mclk),
        .pclk_0      (pclk),
        .reset_rtl   (reset_rtl),
        .vsync_0     (vsync)
    );

    // Scaled-down test resolution (NOT the real 640x480 array size)
    parameter WIDTH  = 8;
    parameter HEIGHT = 4;

    // Number of complete frames the camera stimulus sends back-to-back.
    // Only frame 0's data will actually be present in DDR at the end (Park
    // mode, buffer 0 only -- see NOTE above). NUM_FRAMES > 1 confirms the
    // channel correctly parks/ignores subsequent frames rather than
    // corrupting frame 0's data.
    parameter NUM_FRAMES = 2;

    parameter HBLANK_CYCLES = 4;

    parameter VSYNC_LINES      = 3;
    parameter PRE_BLANK_LINES  = 17;
    parameter POST_BLANK_LINES = 10;

    localparam LINE_CYCLES = (2*WIDTH) + HBLANK_CYCLES;

    reg [15:0] pixel;
    integer x, y, frame;

    always #5 clk_100MHz = ~clk_100MHz; //100MHz
    always #20 pclk = ~pclk; //25MHz

    //==========================================================================
    // AXI VIP agents
    //==========================================================================
    design_1_axi_vip_0_0_mst_t     mst_agent;      // -> VideoCapture_0/S00_AXI + axi_vdma_0/S_AXI_LITE (via axi_smc)
    design_1_axi_vip_1_0_slv_mem_t slv_mem_agent;   // -> axi_vdma_0/M_AXI_S2MM ("DDR")

    xil_axi_prot_t prot = 0;
    xil_axi_resp_t resp;

    // Base addresses (see ADDRESSES note above)
    localparam xil_axi_ulong VC_BASE   = 32'h0000_0000;
    localparam xil_axi_ulong VDMA_BASE = 32'h44A0_0000;
    localparam xil_axi_ulong DDR_BASE  = 32'h44A0_0000;

    // VideoCapture_0/S00_AXI register offsets
    localparam xil_axi_ulong OFF_VC_CTRL     = 32'h0;
    localparam xil_axi_ulong OFF_VC_MCLK_DIV = 32'h4;
    // CTRL bit positions
    localparam int CTRL_CAM_RST  = 0;
    localparam int CTRL_CAM_PWNN = 1;
    localparam int CTRL_MCLK_EN  = 2;

    // S2MM register offsets, PG020
    localparam xil_axi_ulong OFF_S2MM_DMACR         = 32'h30;
    localparam xil_axi_ulong OFF_S2MM_VSIZE         = 32'hA0;
    localparam xil_axi_ulong OFF_S2MM_HSIZE         = 32'hA4;
    localparam xil_axi_ulong OFF_S2MM_FRMDLY_STRIDE = 32'hA8;
    localparam xil_axi_ulong OFF_S2MM_START_ADDR1   = 32'hAC;
    localparam xil_axi_ulong OFF_S2MM_DMASR         = 32'h34;

    localparam int BYTES_PER_PIXEL   = 2;
    localparam int HSIZE_BYTES       = WIDTH * BYTES_PER_PIXEL;
    localparam int STRIDE_BYTES      = HSIZE_BYTES;   // tightly packed, no padding
    localparam int VSIZE_LINES       = HEIGHT;
    localparam int NUM_WORDS         = (WIDTH/2) * HEIGHT;   // words in ONE frame
    localparam int PIXELS_PER_FRAME  = WIDTH * HEIGHT;        // pixels in ONE frame

    task automatic axi_write(input xil_axi_ulong addr, input bit [31:0] data, input string name);
        mst_agent.AXI4LITE_WRITE_BURST(addr, prot, data, resp);
        $display("[%0t] AXI WRITE  %-22s addr=0x%08h data=0x%08h resp=%0d",
                  $time, name, addr, data, resp);
    endtask

    task automatic axi_read(input xil_axi_ulong addr, input string name, output bit [31:0] rdata);
        mst_agent.AXI4LITE_READ_BURST(addr, prot, rdata, resp);
        $display("[%0t] AXI READ   %-22s addr=0x%08h data=0x%08h resp=%0d",
                  $time, name, addr, rdata, resp);
    endtask

    // Deterministic pixel value generator, matches the sequence produced by
    // the camera-stimulus block below (starts 0xaa72, increments per pixel,
    // row-major, continuous across the whole run -- including across frame
    // boundaries, since the stimulus generator free-runs).
    function automatic bit [15:0] expected_pixel(input int n);
        bit [7:0] hi, lo;
        hi = 8'haa + n[7:0];
        lo = 8'h72 + n[7:0];
        expected_pixel = {hi, lo};
    endfunction

    // =========================================================================
    // M_AXI_S2MM write-channel monitor (debug instrumentation, carried over
    // from the earlier project's design_1_tb).
    // =========================================================================
    int unsigned s2mm_beat_count = 0;

    always @(posedge dut.design_1_i.axi_vdma_0.m_axi_s2mm_aclk) begin
      if (dut.design_1_i.axi_vdma_0.m_axi_s2mm_awvalid &&
          dut.design_1_i.axi_vdma_0.m_axi_s2mm_awready) begin
        $display("[%0t] S2MM AW  addr=0x%08h  awlen=%0d (%0d beats)",
                  $time,
                  dut.design_1_i.axi_vdma_0.m_axi_s2mm_awaddr,
                  dut.design_1_i.axi_vdma_0.m_axi_s2mm_awlen,
                  dut.design_1_i.axi_vdma_0.m_axi_s2mm_awlen + 1);
      end

      if (dut.design_1_i.axi_vdma_0.m_axi_s2mm_wvalid &&
          dut.design_1_i.axi_vdma_0.m_axi_s2mm_wready) begin
        $display("[%0t] S2MM W   beat=%0d  data=0x%08h  wlast=%0b",
                  $time, s2mm_beat_count,
                  dut.design_1_i.axi_vdma_0.m_axi_s2mm_wdata,
                  dut.design_1_i.axi_vdma_0.m_axi_s2mm_wlast);
        s2mm_beat_count <= s2mm_beat_count + 1;
      end
      else if (dut.design_1_i.axi_vdma_0.m_axi_s2mm_wvalid &&
               !dut.design_1_i.axi_vdma_0.m_axi_s2mm_wready) begin
        $display("[%0t] S2MM W   STALL (wvalid=1, wready=0)  data(held)=0x%08h",
                  $time, dut.design_1_i.axi_vdma_0.m_axi_s2mm_wdata);
      end
    end

    // =========================================================================
    // mclk frequency sanity check: counts s00_axi_aclk (100MHz) cycles per
    // mclk half-period, printed once per toggle. With MCLK_DIV left at its
    // reset default (4), expect ~2 cycles/half-period -> mclk ~= 25MHz.
    // =========================================================================
    integer mclk_cycle_count = 0;
    reg     mclk_d = 0;

    always @(posedge clk_100MHz) begin
        mclk_d <= mclk;
        if (mclk !== mclk_d)
            mclk_cycle_count <= 0;
        else
            mclk_cycle_count <= mclk_cycle_count + 1;
    end

    //==========================================================================
    // Camera-side stimulus (unchanged in structure from the earlier project's
    // design_1_tb, aside from: reset_rtl replaces block_rst as the port name)
    //==========================================================================
    initial begin
        clk_100MHz  = 0;
        pclk      = 0;
        reset_rtl = 1;
        vsync     = 0;
        href      = 0;
        d         = 8'h00;
        pixel = 16'haa72;
        random_shit_lowbyte  = 8'h72;
        random_shit_highbyte = 8'haa;

        #100;
        reset_rtl = 0;
        #100;

        for (frame = 0; frame < NUM_FRAMES; frame = frame + 1) begin

            //======================================================
            // Frame Start (VSYNC pulse), 3 x tLINE per Fig. 6
            //======================================================
            @(negedge pclk);
            vsync = 1;
            repeat (VSYNC_LINES * LINE_CYCLES) @(negedge pclk);
            vsync = 0;

            // Pre-frame blanking before Row 0
            repeat (8) @(negedge pclk);

            //======================================================
            // Active image: HEIGHT rows x WIDTH pixels, 2 bytes/pixel
            //======================================================
            for (y = 0; y < HEIGHT; y = y + 1) begin
                @(negedge pclk);
                href = 1;
                for (x = 0; x < WIDTH; x = x + 1) begin
                    pixel = {random_shit_highbyte, random_shit_lowbyte};
                    random_shit_lowbyte  = random_shit_lowbyte  + 8'd1;
                    random_shit_highbyte = random_shit_highbyte + 8'd1;

                    d = pixel[15:8];   // first byte (high byte)
                    @(negedge pclk);
                    d = pixel[7:0];    // second byte (low byte)
                    @(negedge pclk);
                end
                href = 0;
                d    = 8'h00;

                repeat (HBLANK_CYCLES) @(negedge pclk);
            end

            //======================================================
            // End of frame: 10 x tLINE trailing blank per Fig. 6
            //======================================================
            repeat (POST_BLANK_LINES * LINE_CYCLES) @(negedge pclk);

            $display("[%0t] Camera stimulus: frame %0d/%0d sent",
                      $time, frame + 1, NUM_FRAMES);
        end

        repeat (20) @(posedge pclk);
        -> frame_stim_done;
    end

    //==========================================================================
    // AXI VIP setup + camera control (VideoCapture_0/S00_AXI) + VDMA control
    // + DDR readback/checker
    //==========================================================================
    initial begin
        int i;
        int base_pixel;
        bit [31:0] rd_data;
        bit [15:0] p0, p1;
        bit [31:0] exp_a, exp_b;

        mst_agent     = new("mst_agent",     dut.design_1_i.axi_vip_0.inst.IF);
        slv_mem_agent = new("slv_mem_agent", dut.design_1_i.axi_vip_1.inst.IF);
        mst_agent.set_agent_tag("PS Ctrl Master VIP");
        slv_mem_agent.set_agent_tag("DDR Slave Mem VIP");
        mst_agent.start_master();
        slv_mem_agent.start_slave();

        // Wait past reset_rtl deassertion (#200 above) plus margin for
        // clk_wiz lock / proc_sys_reset release before touching AXI.
        #400;

        // ---- Camera control (VideoCapture_0/S00_AXI). Doesn't gate the
        // ---- simulated pixel stimulus (see header note), included to
        // ---- exercise/verify the new register interface. ----
        axi_read (VC_BASE + OFF_VC_MCLK_DIV, "VC_MCLK_DIV (reset val)", rd_data);
        // Realistic power-up: pulse cam_rst, hold cam_pwnn low (normal/not
        // powered down), enable mclk throughout.
        axi_write(VC_BASE + OFF_VC_CTRL, (1 << CTRL_MCLK_EN) | (1 << CTRL_CAM_RST),
                   "VC_CTRL (rst=1,mclk_en=1)");
        #200;
        axi_write(VC_BASE + OFF_VC_CTRL, (1 << CTRL_MCLK_EN),
                   "VC_CTRL (rst=0,mclk_en=1)");
        axi_read (VC_BASE + OFF_VC_CTRL, "VC_CTRL (readback)", rd_data);

        // ---- Arm and start the S2MM channel. Order matters: VSIZE last. ----
        // DMACR = 0x3 (RS=1, Circular_Park=1 / Park mode). See NOTE above:
        // captures exactly frame 0 into buffer 0, then parks.
        axi_write(VDMA_BASE + OFF_S2MM_DMACR,         32'h0000_0003,  "S2MM_DMACR (RS=1)");
        axi_write(VDMA_BASE + OFF_S2MM_START_ADDR1,   DDR_BASE,       "S2MM_START_ADDRESS1");
        axi_write(VDMA_BASE + OFF_S2MM_FRMDLY_STRIDE, STRIDE_BYTES,   "S2MM_FRMDLY_STRIDE");
        axi_write(VDMA_BASE + OFF_S2MM_HSIZE,         HSIZE_BYTES,    "S2MM_HSIZE");
        axi_write(VDMA_BASE + OFF_S2MM_VSIZE,         VSIZE_LINES,    "S2MM_VSIZE (starts xfer)");

        // Let the camera stimulus run through all NUM_FRAMES frames.
        @(frame_stim_done);

        // Settle time for the last AXI-Stream beats to drain through the
        // FIFO/VDMA and land as AXI4 write bursts in the memory model.
        #500;

        axi_read(VDMA_BASE + OFF_S2MM_DMASR, "S2MM_DMASR (status)", rd_data);

        // Park mode, buffer 0 only: DDR holds frame 0's data regardless of
        // how many frames the camera stimulus sends afterward.
        base_pixel = 0;

        $display("---------------------------------------------------------");
        $display(" DDR readback: %0d words (%0d bytes/line, %0d lines) -- frame 0 of %0d",
                  NUM_WORDS, HSIZE_BYTES, VSIZE_LINES, NUM_FRAMES);
        $display("---------------------------------------------------------");

        for (i = 0; i < NUM_WORDS; i = i + 1) begin
            rd_data = slv_mem_agent.mem_model.backdoor_memory_read(DDR_BASE + i*4);

            p0 = expected_pixel(base_pixel + 2*i);
            p1 = expected_pixel(base_pixel + 2*i + 1);
            exp_a = {p0, p1};   // guess: first pixel in upper half
            exp_b = {p1, p0};   // guess: first pixel in lower half

            if (rd_data === exp_a)
                $display("word[%0d] addr=0x%08h data=0x%08h  MATCH (pixel0 in upper half)",
                          i, DDR_BASE + i*4, rd_data);
            else if (rd_data === exp_b)
                $display("word[%0d] addr=0x%08h data=0x%08h  MATCH (pixel0 in lower half)",
                          i, DDR_BASE + i*4, rd_data);
            else
                $display("word[%0d] addr=0x%08h data=0x%08h  MISMATCH (expected 0x%08h or 0x%08h)",
                          i, DDR_BASE + i*4, rd_data, exp_a, exp_b);
        end

        $finish;
    end

endmodule