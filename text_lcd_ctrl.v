// ============================================================================
// text_lcd_ctrl.v
//  - HD44780 호환 16x2 Text LCD 드라이버 (8-bit 모드, 쓰기 전용)
//  - line1 / line2 에 들어온 16글자(ASCII)씩을 계속 반복해서 LCD에 써 준다.
//  - 문자열 규칙: 왼쪽 첫 글자가 [127:120] (Verilog 문자열 리터럴과 같은 순서)
//      예) line1 = "HELLO WORLD!    ";   // 정확히 16글자
//
//  동작 순서
//   1) 전원 인가 후 대기 (약 40ms)
//   2) 초기화 명령: 0x38 x3 (8bit, 2줄, 5x8) -> 0x0C (화면 ON, 커서 OFF)
//                   -> 0x06 (주소 자동 증가) -> 0x01 (화면 지우기)
//   3) 무한 반복: 0x80(1줄 시작) + 16글자 -> 0xC0(2줄 시작) + 16글자
//
//  CLK_FREQ 는 보드 클럭에 맞게 바꿔서 사용 (기본 50MHz)
// ============================================================================
module text_lcd_ctrl #(
    parameter integer CLK_FREQ = 50_000_000
)(
    input  wire         clk,
    input  wire         rst_n,        // active-low reset
    input  wire [127:0] line1,        // 1번째 줄 16글자
    input  wire [127:0] line2,        // 2번째 줄 16글자
    output reg          lcd_e,
    output reg          lcd_rs,       // 0: 명령, 1: 데이터(글자)
    output wire         lcd_rw,       // 항상 0 (쓰기만 함)
    output reg  [7:0]   lcd_data
);
    // ---------------- 타이밍 상수 ----------------
    localparam integer US        = (CLK_FREQ / 1_000_000 > 0) ? (CLK_FREQ / 1_000_000) : 1; // 1us 당 클럭 수
    localparam integer STEP_INIT = US * 5000;   // 초기화 단계: 한 스텝 5ms
    localparam integer STEP_RUN  = US * 200;    // 표시 단계: 한 스텝 200us
    localparam integer PWR_STEPS = 8;           // 전원 인가 대기 8 x 5ms = 40ms
    localparam integer N_INIT    = 6;           // 초기화 명령 개수

    assign lcd_rw = 1'b0;

    reg  [31:0] cnt;        // 스텝 안에서의 클럭 카운터
    reg  [4:0]  istep;      // 초기화 스텝 번호
    reg         init_done;  // 초기화 완료 여부
    reg  [5:0]  idx;        // 표시 단계 인덱스 0~33

    wire [31:0] step_len = init_done ? STEP_RUN : STEP_INIT;

    // ---------------- 초기화 명령 테이블 ----------------
    function [7:0] init_cmd;
        input [2:0] i;
        begin
            case (i)
                3'd0, 3'd1, 3'd2: init_cmd = 8'h38; // Function set
                3'd3:             init_cmd = 8'h0C; // Display ON, cursor OFF
                3'd4:             init_cmd = 8'h06; // Entry mode: increment
                default:          init_cmd = 8'h01; // Clear display
            endcase
        end
    endfunction

    // ---------------- 이번 스텝에 보낼 바이트 결정 ----------------
    reg       nx_valid;
    reg       nx_rs;
    reg [7:0] nx_data;

    always @(*) begin
        nx_valid = 1'b1;
        nx_rs    = 1'b0;
        nx_data  = 8'h00;
        if (!init_done) begin
            if (istep < PWR_STEPS) nx_valid = 1'b0;            // 전원 대기: E 펄스 없음
            else                   nx_data  = init_cmd(istep - PWR_STEPS);
        end else begin
            if (idx == 6'd0)       nx_data = 8'h80;            // DDRAM 0x00 (1줄)
            else if (idx <= 6'd16) begin
                nx_rs   = 1'b1;
                nx_data = line1[127 - 8*(idx-1) -: 8];
            end
            else if (idx == 6'd17) nx_data = 8'hC0;            // DDRAM 0x40 (2줄)
            else begin
                nx_rs   = 1'b1;
                nx_data = line2[127 - 8*(idx-18) -: 8];
            end
        end
    end

    // ---------------- 스텝 진행 + E 펄스 생성 ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 32'd0;
            istep     <= 5'd0;
            init_done <= 1'b0;
            idx       <= 6'd0;
            lcd_e     <= 1'b0;
            lcd_rs    <= 1'b0;
            lcd_data  <= 8'h00;
        end else begin
            // 스텝 시작에서 RS/DATA를 먼저 내보내고 (setup),
            // 1us ~ 3us 구간에만 E = 1 (펄스폭 2us), 나머지 시간은 대기
            if (cnt == 0) begin
                lcd_rs   <= nx_rs;
                lcd_data <= nx_data;
            end
            lcd_e <= nx_valid && (cnt >= US) && (cnt < 3*US);

            if (cnt == step_len - 1) begin
                cnt <= 32'd0;
                if (!init_done) begin
                    if (istep == PWR_STEPS + N_INIT - 1) begin
                        init_done <= 1'b1;
                        idx       <= 6'd0;
                    end else begin
                        istep <= istep + 1'b1;
                    end
                end else begin
                    idx <= (idx == 6'd33) ? 6'd0 : idx + 1'b1;
                end
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
