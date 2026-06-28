// =============================================================
// collision.v  —  Core game logic
//
// Snake mechanic:
//   - Snake starts at INIT_LENGTH segments
//   - Each apple eaten SHRINKS the snake by 1 segment
//   - When snake reaches size 1, win is asserted
//   - Wall or self collision asserts game_over (lose)
//
// No duplicate integer declarations: i and j are each
// declared exactly once at module scope.
// =============================================================

module collision (
    output reg    snakeBody,
    output reg    snakeHead,
    input         border,
    output reg    game_over,
    output reg    win,
    input         VGA_clk,
    input         update,
    input         start,
    input  [9:0]  xCount,
    input  [9:0]  yCount,
    input         x,        // UP    (active-low)
    input         y,        // LEFT  (active-low)
    input         z,        // DOWN  (active-low)
    input         w,        // RIGHT (active-low)
    input         h,        // RESET (active-low)
    output wire   apple,
    output [6:0]  seg1,     // HEX0 ones
    output [6:0]  seg2      // HEX1 tens
);

    // ----------------------------------------------------------
    // Parameters — adjust INIT_LENGTH to set starting size
    // ----------------------------------------------------------
    localparam SEG_SIZE   = 10;
    localparam MAX_SEGS   = 32;
    localparam INIT_X     = 300;
    localparam INIT_Y     = 240;
    localparam INIT_LENGTH = 10;   // ← change starting length here

    // ----------------------------------------------------------
    // Snake position arrays
    // ----------------------------------------------------------
    reg [9:0] snakeX [0:MAX_SEGS-1];
    reg [8:0] snakeY [0:MAX_SEGS-1];
    reg [4:0] snake_size;

    // ----------------------------------------------------------
    // Controller
    // ----------------------------------------------------------
    wire [2:0] direction;
    wire       ctrl_reset;

    Controller ctrl (
        .x         (x),
        .y         (y),
        .z         (z),
        .w         (w),
        .h         (h),
        .direction (direction),
        .reset     (ctrl_reset)
    );

    // ----------------------------------------------------------
    // Apple
    // ----------------------------------------------------------
    wire [9:0] appleX;
    wire [8:0] appleY;
    reg        reroll = 0;

    random_apple ra (
        .VGA_clk (VGA_clk),
        .reroll  (reroll),
        .rand_X  (appleX),
        .rand_Y  (appleY)
    );

    assign apple = ( (xCount >= appleX) && (xCount < appleX + SEG_SIZE) &&
                     (yCount >= appleY) && (yCount < appleY + SEG_SIZE) );

    // ----------------------------------------------------------
    // Score BCD (subtraction cascade — no hardware divider)
    // ----------------------------------------------------------
    reg [6:0] score;

    wire [3:0] score_ones;
    wire [3:0] score_tens;

    assign score_ones = (score >= 90) ? score - 90 :
                        (score >= 80) ? score - 80 :
                        (score >= 70) ? score - 70 :
                        (score >= 60) ? score - 60 :
                        (score >= 50) ? score - 50 :
                        (score >= 40) ? score - 40 :
                        (score >= 30) ? score - 30 :
                        (score >= 20) ? score - 20 :
                        (score >= 10) ? score - 10 : score;

    assign score_tens = (score >= 90) ? 4'd9 :
                        (score >= 80) ? 4'd8 :
                        (score >= 70) ? 4'd7 :
                        (score >= 60) ? 4'd6 :
                        (score >= 50) ? 4'd5 :
                        (score >= 40) ? 4'd4 :
                        (score >= 30) ? 4'd3 :
                        (score >= 20) ? 4'd2 :
                        (score >= 10) ? 4'd1 : 4'd0;

    seg7_decoder d0 (.digit(score_ones), .seg(seg1));
    seg7_decoder d1 (.digit(score_tens), .seg(seg2));

    // ----------------------------------------------------------
    // Update pulse (edge detect on toggle signal)
    // ----------------------------------------------------------
    reg  update_prev = 0;
    wire update_pulse = update ^ update_prev;

    always @(posedge VGA_clk)
        update_prev <= update;

    // ----------------------------------------------------------
    // Predicted next head position (combinational)
    // Used for collision detection so it fires the same tick
    // the head arrives, not one tick late.
    // ----------------------------------------------------------
    reg [9:0] next_x;
    reg [8:0] next_y;

    always @(*) begin
        next_x = snakeX[0];
        next_y = snakeY[0];
        case (direction)
            3'b001: next_y = snakeY[0] - SEG_SIZE; // UP
            3'b011: next_y = snakeY[0] + SEG_SIZE; // DOWN
            3'b010: next_x = snakeX[0] - SEG_SIZE; // LEFT
            3'b100: next_x = snakeX[0] + SEG_SIZE; // RIGHT
            default: next_x = snakeX[0] + SEG_SIZE;
        endcase
    end

    // Apple eaten when predicted head lands on apple square
    wire ate_apple = ( (next_x >= appleX) && (next_x < appleX + SEG_SIZE) &&
                       (next_y >= appleY) && (next_y < appleY + SEG_SIZE) );

    // ----------------------------------------------------------
    // Loop variables — declared ONCE here, used in both the
    // state machine and pixel membership blocks below.
    // ----------------------------------------------------------
    integer i;
    integer j;

    // ----------------------------------------------------------
    // Game state machine
    // ----------------------------------------------------------
    always @(posedge VGA_clk) begin

        reroll <= 0;   // de-assert every cycle by default

        // ---- Reset / waiting to start ----
        if (ctrl_reset || !start) begin
            game_over  <= 0;
            win        <= 0;
            score      <= 0;
            snake_size <= INIT_LENGTH;
            reroll     <= 0;
            for (i = 0; i < MAX_SEGS; i = i + 1) begin
                snakeX[i] <= INIT_X - i * SEG_SIZE;
                snakeY[i] <= INIT_Y;
            end

        // ---- Normal play ----
        end else if (!game_over && !win && update_pulse) begin

            // 1. Shift body tail-first
            for (i = MAX_SEGS-1; i > 0; i = i - 1) begin
                if (i < snake_size) begin
                    snakeX[i] <= snakeX[i-1];
                    snakeY[i] <= snakeY[i-1];
                end
            end

            // 2. Move head to predicted position
            snakeX[0] <= next_x;
            snakeY[0] <= next_y;

            // 3. Apple eaten -> shrink snake, increment score
            if (ate_apple) begin
                if (score < 99)
                    score <= score + 1;

                if (snake_size > 1) begin
                    snake_size <= snake_size - 1;  // shrink by 1
                    reroll     <= 1;               // move apple
                end else begin
                    win <= 1;   // snake reached size 1 — you win
                end
            end

            // 4. Wall collision
            if ( (next_x < 31) || (next_x > 599) ||
                 (next_y < 31) || (next_y > 439) )
                game_over <= 1;

            // 5. Self collision
            for (i = 2; i < MAX_SEGS; i = i + 1) begin
                if (i < snake_size) begin
                    if ( (next_x == snakeX[i]) &&
                         (next_y == snakeY[i]) )
                        game_over <= 1;
                end
            end
        end
    end

    // ----------------------------------------------------------
    // Pixel membership (combinational then registered 1 clock)
    // ----------------------------------------------------------
    reg head_comb;
    reg body_comb;

    always @(*) begin
        head_comb = ( (xCount >= snakeX[0]) &&
                      (xCount <  snakeX[0] + SEG_SIZE) &&
                      (yCount >= snakeY[0]) &&
                      (yCount <  snakeY[0] + SEG_SIZE) );

        body_comb = 0;
        for (j = 1; j < MAX_SEGS; j = j + 1) begin
            if (j < snake_size) begin
                if ( (xCount >= snakeX[j]) &&
                     (xCount <  snakeX[j] + SEG_SIZE) &&
                     (yCount >= snakeY[j]) &&
                     (yCount <  snakeY[j] + SEG_SIZE) )
                    body_comb = 1;
            end
        end
    end

    always @(posedge VGA_clk) begin
        snakeHead <= head_comb;
        snakeBody <= body_comb;
    end

endmodule