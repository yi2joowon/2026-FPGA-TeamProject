`ifndef CLOCK_CNT_V
`define CLOCK_CNT_V

// Modulo up/down counter for clock fields.
module clock_cnt #(
    parameter integer MAX = 59
)(
    output reg [5:0] o_cnt,
    input wire i_tick,
    input wire i_inc,
    input wire i_dec,
    input wire i_rstn,
    input wire i_clk
);
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn)
            o_cnt <= 6'd0;
        else if (i_inc) begin
            if (o_cnt >= MAX) o_cnt <= 6'd0;
            else o_cnt <= o_cnt + 1'b1;
        end else if (i_dec) begin
            if (o_cnt == 0) o_cnt <= MAX;
            else o_cnt <= o_cnt - 1'b1;
        end else if (i_tick) begin
            if (o_cnt >= MAX) o_cnt <= 6'd0;
            else o_cnt <= o_cnt + 1'b1;
        end
    end
endmodule

`endif
