// ============================================================================
// text_lcd_top.v
//  - Text LCD 파트 최상위 모듈. 팀 top.v 에서 이것 하나만 연결하면 됨.
//  - 모드 번호 기본값은 팀 ctrl.v 와 같음
//    (0 CLOCK_RUN, 1 CLOCK_SET, 2 ALARM_SET, 3 TIMER_SET, 4 TIMER_RUN)
// ============================================================================
module text_lcd_top #(
    parameter integer CLK_FREQ     = 50_000_000,
    parameter integer BCD          = 0,
    parameter [2:0]   MODE_NORMAL  = 3'd0,
    parameter [2:0]   MODE_CLK_SET = 3'd1,
    parameter [2:0]   MODE_ALM_SET = 3'd2,
    parameter [2:0]   MODE_TMR_SET = 3'd3,
    parameter [2:0]   MODE_TIMER   = 3'd4
)(
    input  wire       i_clk,
    input  wire       i_rstn,
    input  wire [2:0] i_mode,
    input  wire [7:0] i_hour,     i_min,     i_sec,       // 현재 시각
    input  wire [1:0] i_set_pos,                         // 0 없음, 1 시, 2 분, 3 초
    input  wire       i_blink,
    input  wire [7:0] i_alm_hour, i_alm_min, i_alm_sec,   // 알람 시각
    input  wire       i_alm_on,
    input  wire       i_alm_ringing,
    input  wire [7:0] i_tmr_hour, i_tmr_min, i_tmr_sec,   // 타이머 표시값
    input  wire       i_tmr_run,
    input  wire       i_tmr_pause,
    input  wire       i_psd_near,
    input  wire        i_dbg,         // 1이면 PSD 측정값 표시
    input  wire [11:0] i_adc_value,   // PSD 측정값
    output wire       o_lcd_e,
    output wire       o_lcd_rs,
    output wire       o_lcd_rw,
    output wire [7:0] o_lcd_data
);
    wire [127:0] line1, line2;

    lcd_formatter #(
        .CLK_FREQ(CLK_FREQ), .BCD(BCD),
        .MODE_NORMAL(MODE_NORMAL), .MODE_CLK_SET(MODE_CLK_SET),
        .MODE_ALM_SET(MODE_ALM_SET), .MODE_TMR_SET(MODE_TMR_SET),
        .MODE_TIMER(MODE_TIMER)
    ) u_fmt (
        .clk(i_clk), .rst_n(i_rstn),
        .mode(i_mode),
        .cur_h(i_hour), .cur_m(i_min), .cur_s(i_sec),
        .alm_h(i_alm_hour), .alm_m(i_alm_min), .alm_s(i_alm_sec),
        .alm_on(i_alm_on), .alm_ringing(i_alm_ringing),
        .tmr_h(i_tmr_hour), .tmr_m(i_tmr_min), .tmr_s(i_tmr_sec),
        .tmr_run(i_tmr_run), .tmr_pause(i_tmr_pause),
        .set_pos(i_set_pos), .blink(i_blink), .psd_near(i_psd_near),
        .dbg(i_dbg), .adc_value(i_adc_value),
        .line1(line1), .line2(line2)
    );

    text_lcd_ctrl #(.CLK_FREQ(CLK_FREQ)) u_ctrl (
        .clk(i_clk), .rst_n(i_rstn),
        .line1(line1), .line2(line2),
        .lcd_e(o_lcd_e), .lcd_rs(o_lcd_rs), .lcd_rw(o_lcd_rw), .lcd_data(o_lcd_data)
    );
endmodule
