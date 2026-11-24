// ============================================================================
// blink_gen.v
//  - 0.5초마다 반전되는 깜빡임 신호 (1Hz) 생성
//  - 설정 모드에서 시/분/초 칸을 깜빡이게 할 때 lcd_formatter 의 blink 에 연결
//  - 설정 기능 담당 팀원이 7-segment 깜빡임에도 같이 쓸 수 있음
// ============================================================================
module blink_gen #(
    parameter integer CLK_FREQ = 50_000_000
)(
    input  wire clk,
    input  wire rst_n,
    output reg  blink
);
    localparam integer HALF = CLK_FREQ / 2;
    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt   <= 32'd0;
            blink <= 1'b1;
        end else if (cnt == HALF - 1) begin
            cnt   <= 32'd0;
            blink <= ~blink;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
endmodule
