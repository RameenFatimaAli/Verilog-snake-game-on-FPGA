# Snake Game – DE10-Standard Port

A complete Verilog remake of the Snake & Apple game originally written for the
Terasic **DE10-Lite** (MAX 10), ported to the **Terasic DE10-Standard**
(Cyclone V SoC – 5CSXFC6D6F31C6).

---

## What Changed from the DE10-Lite Version

| Aspect | DE10-Lite | DE10-Standard |
|---|---|---|
| FPGA | MAX 10 (10M50DAF484C7G) | Cyclone V SoC (5CSXFC6D6F31C6) |
| 50 MHz clock | PIN_P11 | PIN_AF14 |
| Push buttons | KEY[1:0] + resistors | KEY[3:0] on-board (active-low) |
| VGA DAC | 4-bit resistor network | 8-bit ADV7123, VGA_SYNC_N added |
| VGA_CLK | Derived from DAC_CLK | Dedicated VGA_CLK pin |
| Code improvements | Counter-based random apple | LFSR-based pseudo-random apple |
| Score display | 7-seg (2 digits) | 7-seg HEX0/HEX1 (ones/tens) |

---

## Hardware Setup

| Signal | DE10-Standard Pin / Connector |
|---|---|
| 50 MHz clock | CLOCK_50 – PIN_AF14 |
| START | SW[0] – PIN_AB30 (slide up = start) |
| UP | KEY[0] – PIN_AJ4 |
| DOWN | KEY[1] – PIN_AK4 |
| LEFT | KEY[2] – PIN_AA14 |
| RIGHT | KEY[3] – PIN_AA15 |
| VGA output | VGA D-SUB connector on board |
| Score (ones) | HEX0 |
| Score (tens) | HEX1 |

**No external components required.** All inputs use the on-board push-buttons
and slide switch. Connect a VGA monitor directly to the D-SUB port.

> ⚠️ **Pin Assignment Notice**: The VGA pin assignments in `snake.qsf` are
> based on the DE10-Standard User Manual Table 3-18. If Quartus reports
> pin conflicts, cross-reference with the DE10-Standard System Builder tool
> or Section 3.6.7 of the User Manual.

---

## File Structure

```
snake.v            – Top-level module
collision.v        – Game logic: snake body, collision, score
VGA_Controller.v   – 640×480 @ 60 Hz VGA timing
Clks_Generator.v   – 50 MHz → 25 MHz VGA clock + game-tick
Controller.v       – Button → direction decoder
random_apple.v     – LFSR pseudo-random apple position
seg7_decoder.v     – BCD digit → 7-segment (active-low)
snake.qpf          – Quartus project file
snake.qsf          – Pin assignments & device settings
README.md          – This file
```

---

## Compilation & Programming

1. Open Quartus Prime (tested with 20.1 Lite Edition).
2. Open project: **File → Open Project → `snake.qpf`**.
3. Compile: **Processing → Start Compilation**.
4. Program: **Tools → Programmer** → select `output_files/snake.sof` → Start.

---

## How to Play

1. Slide **SW[0]** UP to start.
2. Use **KEY[0/1/2/3]** (UP/DOWN/LEFT/RIGHT) to steer the snake.
3. Eat red apples to grow and score points (shown on HEX1–HEX0).
4. Avoid the green border and the snake's own body.
5. Game-over: entire screen turns red. Press **KEY[3]** (hold) to reset,
   then toggle SW[0] to restart.

---

## Colour Scheme

| Colour | Meaning |
|---|---|
| Green | Snake body, border |
| Red head | Snake head (both red & green) |
| Red | Apple; game-over state |
| Blue | Background |

---

## Game-Speed Tuning

Edit `Clks_Generator.v`, parameter `UPDATE_MAX`:

```verilog
parameter UPDATE_MAX = 1_666_667;  // ≈15 Hz  (default)
// parameter UPDATE_MAX = 2_500_000; // ≈10 Hz  (slower)
// parameter UPDATE_MAX =   833_333; // ≈30 Hz  (faster)
```

---

## References

- Terasic DE10-Standard User Manual:
  https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1081
- Original DE10-Lite project by Jjateen Gundesha:
  https://github.com/Jjateen/Snake-Game-Verilog
