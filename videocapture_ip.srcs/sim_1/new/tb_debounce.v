`timescale 1ns/1ps

module tb_debounce;

    // DUT signals
    reg clk;
    reg rst;
    reg btn_raw;     // active-low button: 1 = released, 0 = pressed
    wire btn_clean;

    // Instantiate DUT
    debounce #(
        .STABLE_COUNT(5)
    ) dut (
        .clk(clk),
        .rst(rst),
        .btn_raw(btn_raw),
        .btn_clean(btn_clean)
    );

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin

        // Reset: idle state for active-low button is released = 1
        rst = 1'b1;
        btn_raw = 1'b1;
        #30;
        rst = 1'b0;

        //------------------------------------------------------
        // Test 1: Clean press (go low and stay low)
        //------------------------------------------------------
        $display("\n=== Clean Press (active-low) ===");
        btn_raw = 1'b0;
        #100;

        //------------------------------------------------------
        // Test 2: Clean release (go high and stay high)
        //------------------------------------------------------
        $display("\n=== Clean Release (active-low) ===");
        btn_raw = 1'b1;
        #100;

        //------------------------------------------------------
        // Test 3: Bouncing press
        //------------------------------------------------------
        $display("\n=== Bouncing Press (active-low) ===");
        btn_raw = 1'b0; #10;
        btn_raw = 1'b1; #10;
        btn_raw = 1'b0; #10;
        btn_raw = 1'b1; #10;
        btn_raw = 1'b0;       // finally stays low
        #100;

        //------------------------------------------------------
        // Test 4: Bouncing release
        //------------------------------------------------------
        $display("\n=== Bouncing Release (active-low) ===");
        btn_raw = 1'b1; #10;
        btn_raw = 1'b0; #10;
        btn_raw = 1'b1; #10;
        btn_raw = 1'b0; #10;
        btn_raw = 1'b1;       // finally stays high
        #100;

        //------------------------------------------------------
        // Test 5: Short glitch low (should be ignored)
        //------------------------------------------------------
        $display("\n=== Short Low Glitch ===");
        btn_raw = 1'b0;
        #20;                  // too short to qualify
        btn_raw = 1'b1;
        #100;

        $display("\nSimulation Finished.");
        $finish;
    end

endmodule