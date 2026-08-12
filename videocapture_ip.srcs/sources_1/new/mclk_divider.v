`timescale 1 ns / 1 ps

// ===========================================================================
// mclk_divider
//
// Generates a free-running, 50%-duty-cycle output clock (intended for the
// OV7670's XCLK/MCLK input) by toggling once every (div_reg >> 1) cycles of
// the input reference clock `clk`.
//
// div_reg is the register-visible "N" value: mclk period = N cycles of clk,
// i.e. mclk_freq = clk_freq / N (exact for even N; odd N rounds down to the
// next even divide ratio, since N>>1 truncates).
//
// The >> 1 is a bit slice, not an arithmetic divider -- free in hardware.
//
// enable = 0 holds mclk_out low and holds the internal counter at 0, rather
// than free-running through an undefined state; this also means re-enabling
// always starts from a clean, known phase.
// ===========================================================================
module mclk_divider #
(
    parameter integer DIV_WIDTH = 32
)
(
    input  wire                   clk,      // reference clock (s00_axi_aclk)
    input  wire                   aresetn,  // active-low reset (s00_axi_aresetn)
    input  wire [DIV_WIDTH-1:0]   div_reg,  // "N": desired divide ratio
    input  wire                   enable,   // 0 = hold mclk_out low
    output reg                    mclk_out
);

    wire [DIV_WIDTH-2:0] half_period = div_reg[DIV_WIDTH-1:1]; // N >> 1, free
    reg  [DIV_WIDTH-2:0] count;

    always @(posedge clk) begin
        if (!aresetn || !enable) begin
            count    <= {(DIV_WIDTH-1){1'b0}};
            mclk_out <= 1'b0;
        end
        else begin
            if (count == half_period) begin
                count    <= {(DIV_WIDTH-1){1'b0}};
                mclk_out <= ~mclk_out;
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule