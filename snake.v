// =============================================================
// Snake Game - Top-Level Module
// Target Board : Terasic DE10-Standard (Cyclone V SoC 5CSXFC6D6F31C6)
// Original     : DE10-Lite by Jjateen Gundesha
//
// Controls (all push buttons are active-low on DE10-Standard):
//   KEY[0] = UP
//   KEY[1] = DOWN
//   KEY[2] = LEFT
//   KEY[3] = RIGHT / RESET (hold for reset)
//   SW[0]  = START game
// =============================================================

module snake (
    input        CLOCK_50,    // 50 MHz master clock
    input        SW0,         // START
    input        KEY0,        // UP    (active-low)
    input        KEY1,        // DOWN  (active-low)
    input        KEY2,        // LEFT  (active-low)
    input        KEY3,        // RIGHT / RESET (active-low)
    // VGA – ADV7123 DAC (8-bit channels)
    output [7:0] VGA_R,
    output [7:0] VGA_G,
    output [7:0] VGA_B,
    output       VGA_HS,
    output       VGA_VS,
    output       VGA_BLANK_N,
    output       VGA_SYNC_N,
    output       VGA_CLK,
    // 7-segment score display (active-low segments)
    output [6:0] HEX0,   // ones
    output [6:0] HEX1    // tens
);

    // ---------------------------------------------------------
    // Internal wires
    // ---------------------------------------------------------
    wire [9:0] xCount, yCount;
    wire       displayArea;
    wire       VGA_clk;
    wire       update;
    wire       snakeHead, snakeBody;
    wire       game_over;
    reg        border;
    wire       apple;
    wire       R_wire, G_wire, B_wire;

    // ---------------------------------------------------------
    // Clock divider: 50 MHz to 25 MHz VGA clock + slow update tick
    // ---------------------------------------------------------
    Clks_Generator CLKs (
        .master_clk (CLOCK_50),
        .update     (update),
        .VGA_clk    (VGA_clk)
    );

    assign VGA_CLK    = VGA_clk;
    assign VGA_SYNC_N = 1'b0;   // composite sync disabled on ADV7123

    // ---------------------------------------------------------
    // VGA Controller: 640x480 @ 60 Hz timing
    // ---------------------------------------------------------
    VGA_Controller VGA (
        .VGA_clk    (VGA_clk),
        .xCount     (xCount),
        .yCount     (yCount),
        .displayArea(displayArea),
        .VGA_hSync  (VGA_HS),
        .VGA_vSync  (VGA_VS),
        .blank_n    (VGA_BLANK_N)
    );

    // ---------------------------------------------------------
    // 30-pixel border around the play field
    // ---------------------------------------------------------
    always @(posedge VGA_clk) begin
        border <= ( ((xCount >= 0)   && (xCount < 31))  ||
                    ((xCount >= 610) && (xCount < 641)) ||
                    ((yCount >= 0)   && (yCount < 31))  ||
                    ((yCount >= 450) && (yCount < 481)) );
    end

    // ---------------------------------------------------------
    // Game logic: snake body, apple, collision detection, score
    // ---------------------------------------------------------
    collision col (
        .snakeBody (snakeBody),
        .snakeHead (snakeHead),
        .border    (border),
        .game_over (game_over),
        .VGA_clk   (VGA_clk),
        .update    (update),
        .start     (SW0),
        .xCount    (xCount),
        .yCount    (yCount),
        // Buttons are active-low; pass raw signals
        .x         (KEY0),   // UP
        .y         (KEY2),   // LEFT
        .z         (KEY1),   // DOWN
        .w         (KEY3),   // RIGHT / RESET
        .h         (1'b1),   // pause unused (inactive high = not pressed)
        .apple     (apple),
        .seg1      (HEX0),
        .seg2      (HEX1)
    );

    // ---------------------------------------------------------
    // Pixel colour logic
    //   Red   : apple, game-over screen, snake head
    //   Green : snake body/head/border (normal play only)
    //   Blue  : background (non-blanked, non-gameover)
    // ---------------------------------------------------------
    assign R_wire = displayArea && ( apple || game_over || snakeHead );
    assign G_wire = displayArea && ( (snakeBody || snakeHead || border) && ~game_over );
    // In snake.v, replace the B_wire line:
	 assign B_wire = VGA_BLANK_N && ( ~game_over || snakeHead );

    // Upper 4 bits drive the ADV7123; lower 4 bits = 0
    assign VGA_R = { {4{R_wire}}, 4'b0000 };
    assign VGA_G = { {4{G_wire}}, 4'b0000 };
    assign VGA_B = { {4{B_wire}}, 4'b0000 };

endmodule
