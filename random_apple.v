module random_apple (
    input            VGA_clk,
    input            reroll,
    output reg [9:0] rand_X,
    output reg [8:0] rand_Y
);

    reg [15:0] lfsr_x = 16'hACE1;

    always @(posedge VGA_clk) begin
        lfsr_x <= { 1'b0, lfsr_x[15:1] } ^
                  (lfsr_x[0] ? 16'hB400 : 16'h0000);
    end

    reg [14:0] lfsr_y = 15'h3412;

    always @(posedge VGA_clk) begin
        lfsr_y <= { 1'b0, lfsr_y[14:1] } ^
                  (lfsr_y[0] ? 15'h6000 : 15'h0000);
    end

    reg [5:0] rx_latch;   // 6 bits: 0..63
    reg [5:0] ry_latch;   // 6 bits: 0..63

    always @(posedge VGA_clk) begin
        if (reroll) begin
            rx_latch = lfsr_x[7:2];        // ← was [8:2] (7-bit, caused overflow)
            if (rx_latch >= 54)
                rx_latch = rx_latch - 54;  // 54..63 → 0..9, always lands in 0..53

            ry_latch = lfsr_y[7:2];        // 0..63
            if (ry_latch >= 40)
                ry_latch = ry_latch - 40;  // 40..63 → 0..23, always lands in 0..39

            rand_X <= rx_latch * 10 + 40;  // 40..570 (inside left/right borders)
            rand_Y <= ry_latch * 10 + 40;  // 40..430 (inside top/bottom borders)
        end
    end

    initial begin
        rand_X = 200;
        rand_Y = 150;
    end

endmodule