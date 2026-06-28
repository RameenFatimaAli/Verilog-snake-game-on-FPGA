module Clks_Generator (
    input  master_clk,
    output reg update  = 0,
    output reg VGA_clk = 0
);

    always @(posedge master_clk) begin
        VGA_clk <= ~VGA_clk;
    end

    parameter UPDATE_MAX = 4_000_000;  // ← adjust this for speed

    reg [24:0] count = 0;              // ← must be wide enough for UPDATE_MAX

    always @(posedge master_clk) begin
        if (count >= UPDATE_MAX) begin
            count  <= 0;
            update <= ~update;
        end else begin
            count <= count + 1;
        end
    end

endmodule