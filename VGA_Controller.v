// =============================================================
// VGA_Controller
// Generates 640x480 @ 60 Hz VGA timing from a 25 MHz pixel clock.
//
// Standard 640x480 @ 60 Hz parameters:
//   Pixel clock : 25.175 MHz  (we use 25 MHz, close enough)
//   Horizontal  : 640 active + 16 front + 96 sync + 48 back = 800 total
//   Vertical    : 480 active + 10 front +  2 sync + 33 back = 525 total
//   H sync      : active-low
//   V sync      : active-low
// =============================================================

module VGA_Controller (
    input            VGA_clk,
    output reg [9:0] xCount,
    output reg [9:0] yCount,
    output           displayArea,
    output           VGA_hSync,
    output           VGA_vSync,
    output           blank_n
);

    // Horizontal timing (pixels)
    parameter H_ACTIVE  = 640;
    parameter H_FRONT   =  16;
    parameter H_SYNC    =  96;
    parameter H_BACK    =  48;
    parameter H_TOTAL   = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 800

    // Vertical timing (lines)
    parameter V_ACTIVE  = 480;
    parameter V_FRONT   =  10;
    parameter V_SYNC    =   2;
    parameter V_BACK    =  33;
    parameter V_TOTAL   = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 525

    // Horizontal counter
    always @(posedge VGA_clk) begin
        if (xCount == H_TOTAL - 1)
            xCount <= 0;
        else
            xCount <= xCount + 1;
    end

    // Vertical counter (increments once per line)
    always @(posedge VGA_clk) begin
        if (xCount == H_TOTAL - 1) begin
            if (yCount == V_TOTAL - 1)
                yCount <= 0;
            else
                yCount <= yCount + 1;
        end
    end

    // Sync pulses (active-low)
    wire h_sync_active = (xCount >= (H_ACTIVE + H_FRONT)) &&
                         (xCount <  (H_ACTIVE + H_FRONT + H_SYNC));
    wire v_sync_active = (yCount >= (V_ACTIVE + V_FRONT)) &&
                         (yCount <  (V_ACTIVE + V_FRONT + V_SYNC));

    assign VGA_hSync  = ~h_sync_active;
    assign VGA_vSync  = ~v_sync_active;

    // Active display area
    assign displayArea = (xCount < H_ACTIVE) && (yCount < V_ACTIVE);
    assign blank_n     = displayArea;

endmodule
