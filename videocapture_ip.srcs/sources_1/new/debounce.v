// Button debouncer: requires input stable for STABLE_COUNT cycles
module debounce #(parameter STABLE_COUNT = 2_000_000) (
    input  wire clk,
    input  wire rst,
    input  wire btn_raw,    // raw button input (may bounce)
    output reg  btn_clean   // debounced stable output
);
    reg [20:0] cnt;         // up to 2M, needs 21 bits
    reg        last_raw;    // previous raw sample

    always @(posedge clk) begin
        if (rst) begin
            cnt       <= 21'd0;
            btn_clean <= 1'b1;
            last_raw  <= 1'b1;
        end else begin
            if (btn_raw != last_raw) begin
                cnt <= 21'd0;          // input changed - restart timer
            end else if (cnt < STABLE_COUNT - 1) begin
                cnt <= cnt + 1;        // still counting stability
            end else begin
                btn_clean <= btn_raw;  // stable for long enough - accept
            end
            last_raw <= btn_raw;
        end
    end

    // Rising-edge detector on btn_clean
    reg btn_clean_r;
    always @(posedge clk) btn_clean_r <= btn_clean;
endmodule