module Controller (
    input        x,   // UP    (active-low)
    input        y,   // LEFT  (active-low)
    input        z,   // DOWN  (active-low)
    input        w,   // RIGHT (active-low)
    input        h,   // RESET (active-low)
    output reg [2:0] direction,
    output reg       reset
);

    initial begin
        direction = 3'b100;
        reset     = 0;
    end

    always @(x, y, z, w, h) begin
        if (~h) begin
            reset     = 1;
            direction = 3'b111;
        end else begin
            reset = 0;
            if      (~x) direction = 3'b001;   // UP
            else if (~y) direction = 3'b100;   // LEFT key → moves RIGHT
            else if (~z) direction = 3'b011;   // DOWN
            else if (~w) direction = 3'b010;   // RIGHT key → moves LEFT
        end
    end

endmodule