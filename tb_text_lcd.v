// ============================================================================
// tb_text_lcd.v
//  - 가상 LCD 모델을 붙여서, LCD에 실제로 써진 글자를 터미널에 그려 준다.
//  - 시뮬레이션 속도를 위해 CLK_FREQ = 1MHz (1클럭 = 1us)
//
//  실행 (팀 폴더에서):
//   iverilog -o sim tb_text_lcd.v text_lcd_top.v lcd_formatter.v text_lcd_ctrl.v
//   vvp sim
// ============================================================================
`timescale 1ns/1ns
module tb_text_lcd;
    reg clk = 0;
    always #500 clk = ~clk;        // 1MHz

    reg        rstn = 0;
    reg  [2:0] mode = 0;
    reg  [7:0] hour = 23, min = 7, sec = 12;
    reg  [7:0] alm_hour = 7, alm_min = 30, alm_sec = 0;
    reg        alm_on = 1, alm_ringing = 0;
    reg  [7:0] tmr_hour = 0, tmr_min = 3, tmr_sec = 0;
    reg        tmr_run = 0, tmr_pause = 0;
    reg  [1:0] set_pos = 0;
    reg        blink = 1, psd_near = 0;

    wire lcd_e, lcd_rs, lcd_rw;
    wire [7:0] lcd_data;

    text_lcd_top #(.CLK_FREQ(1_000_000)) dut (
        .i_clk(clk), .i_rstn(rstn),
        .i_mode(mode), .i_hour(hour), .i_min(min), .i_sec(sec),
        .i_set_pos(set_pos), .i_blink(blink),
        .i_alm_hour(alm_hour), .i_alm_min(alm_min), .i_alm_sec(alm_sec),
        .i_alm_on(alm_on), .i_alm_ringing(alm_ringing),
        .i_tmr_hour(tmr_hour), .i_tmr_min(tmr_min), .i_tmr_sec(tmr_sec),
        .i_tmr_run(tmr_run), .i_tmr_pause(tmr_pause),
        .i_psd_near(psd_near), .i_dbg(1'b0), .i_adc_value(12'd0),
        .o_lcd_e(lcd_e), .o_lcd_rs(lcd_rs), .o_lcd_rw(lcd_rw), .o_lcd_data(lcd_data)
    );

    // ---------------- 가상 LCD (HD44780 흉내) ----------------
    reg [7:0] ddram [0:127];
    reg [6:0] addr = 0;
    integer i;
    initial for (i = 0; i < 128; i = i + 1) ddram[i] = 8'h20;

    always @(negedge lcd_e) begin
        if (!lcd_rs) begin
            if (lcd_data[7]) addr = lcd_data[6:0];
            else if (lcd_data == 8'h01) begin
                for (i = 0; i < 128; i = i + 1) ddram[i] = 8'h20;
                addr = 0;
            end
        end else begin
            ddram[addr] = lcd_data;
            addr = addr + 1;
        end
    end

    task show(input [8*32-1:0] title);
        reg [127:0] l1, l2;
        integer k;
        begin
            for (k = 0; k < 16; k = k + 1) begin
                l1[127 - 8*k -: 8] = ddram[k];
                l2[127 - 8*k -: 8] = ddram[64 + k];
            end
            $display("\n[%0t ms] %0s", $time / 1_000_000, title);
            $display("+----------------+");
            $display("|%s|", l1);
            $display("|%s|", l2);
            $display("+----------------+");
        end
    endtask

    localparam WAIT = 30_000_000;   // 30ms (화면 한 바퀴 갱신 약 7ms)

    initial begin
        #2000 rstn = 1;
        #100_000_000;                                   show("01 NORMAL");

        psd_near = 1;                     #WAIT;        show("02 hand near -> next alarm");
        psd_near = 0;                     #1_000_000_000; show("03 hand away 1s (still shown)");
        #1_250_000_000; #1_250_000_000;                                 show("04 after 3s -> NORMAL");

        mode = 1; set_pos = 2; blink = 0; #WAIT;        show("05 CLK SET, min blink off");
        mode = 2; set_pos = 1; blink = 0; #WAIT;        show("06 ALM SET, hour blink off");
        mode = 0; set_pos = 0; blink = 1;

        alm_ringing = 1;                  #WAIT;        show("07 alarm ringing");
        psd_near = 1;                     #WAIT;
        alm_ringing = 0;                  #WAIT;        show("08 hand -> alarm stopped");
        #1_250_000_000; #1_250_000_000;                                 show("09 hand still near (no popup)");
        psd_near = 0;                     #WAIT;        show("10 hand away -> NORMAL");

        alm_on = 0; psd_near = 1;         #WAIT;        show("11 alarm OFF + hand");
        psd_near = 0; alm_on = 1;

        mode = 4; tmr_min = 2; tmr_sec = 59; tmr_run = 1;
                                          #1_750_000_000; #1_750_000_000; show("12 TIMER RUN");
        tmr_run = 0; tmr_pause = 1; psd_near = 1;
                                          #WAIT;        show("13 TIMER PAUSE by hand");
        $finish;
    end
endmodule
