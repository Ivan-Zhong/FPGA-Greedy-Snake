`timescale 1ns / 1ps
module vertical_counter(
    input clk_25MHz, // clock for VGA
    input enable_V_Counter, // enable
    output reg [15:0] V_Count_Value = 0
    );
    always@(posedge clk_25MHz)
    begin
    // when enabled, count up 1
    if(enable_V_Counter == 1'b1)
        begin
            if(V_Count_Value < 524)
                V_Count_Value <= V_Count_Value + 1;
            else
                V_Count_Value <= 0;
        end
    end
endmodule
