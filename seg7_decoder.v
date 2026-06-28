// =============================================================
// seg7_decoder
// Converts a 4-bit BCD digit (0-9) to active-low 7-segment
// encoding for the DE10-Standard common-cathode displays.
//
//  Segment map:
//       _
//      |_|
//      |_|
//
//  Bit:  6 5 4 3 2 1 0
//  Seg:  g f e d c b a
// =============================================================

module seg7_decoder (
    input      [3:0] digit,
    output reg [6:0] seg     // active-low
);

    always @(*) begin
        case (digit)
            4'd0:  seg = 7'b1000000;
            4'd1:  seg = 7'b1111001;
            4'd2:  seg = 7'b0100100;
            4'd3:  seg = 7'b0110000;
            4'd4:  seg = 7'b0011001;
            4'd5:  seg = 7'b0010010;
            4'd6:  seg = 7'b0000010;
            4'd7:  seg = 7'b1111000;
            4'd8:  seg = 7'b0000000;
            4'd9:  seg = 7'b0010000;
            default: seg = 7'b1111111; // blank
        endcase
    end

endmodule
