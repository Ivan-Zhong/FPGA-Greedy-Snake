`timescale 1ns / 1ps
module horizontal_counter(
    input clk_25MHz, // clock for VGA
    output reg enable_V_Counter = 0, // enable V counter
    output reg [15:0] H_Count_Value = 0
    );
    always@(posedge clk_25MHz)
    begin
        if(H_Count_Value < 799)
        begin
            H_Count_Value <= H_Count_Value + 1;
            enable_V_Counter <= 0;
        end
        else
        begin
            H_Count_Value <= 0;
            enable_V_Counter <= 1; // when H_Count_Value reaches the end of this line, enable V counter.
        end
    end
endmodule
