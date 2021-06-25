`timescale 1ns / 1ps
`define ZERO 7'b1000000
`define ONE 7'b1111001
`define TWO 7'b0100100
`define THREE 7'b0110000
`define FOUR 7'b0011001
`define FIVE 7'b0010010
`define SIX 7'b0000010
`define SEVEN 7'b1111000
`define EIGHT 7'b0000000
`define NINE 7'b0010000
module sevenseg_clock_length(
    input clk,
    input [15:0] seconds,
    input [12:0] length,
    output reg [7:0] oControl,
    output [6:0] oData
    );
reg [5:0] count = 0;
wire [5:0] minute_upper;
wire [5:0] minute_lower;
wire [5:0] second_upper;
wire [5:0] second_lower;
wire [5:0] length_upper;
wire [5:0] length_lower;

assign minute_upper = (seconds / 60) / 10;
assign minute_lower = (seconds / 60) % 10;
assign second_upper = (seconds % 60) / 10;
assign second_lower = (seconds % 60) % 10;
assign length_upper = (length / 10) % 10;
assign length_lower = (length % 10);
reg [5:0] output_number = 0;

assign oData = (output_number == 0) ? `ZERO : 
               (output_number == 1) ? `ONE : 
               (output_number == 2) ? `TWO : 
               (output_number == 3) ? `THREE : 
               (output_number == 4) ? `FOUR : 
               (output_number == 5) ? `FIVE : 
               (output_number == 6) ? `SIX : 
               (output_number == 7) ? `SEVEN : 
               (output_number == 8) ? `EIGHT : `NINE;

always@(posedge clk)
begin
    count = count + 1;
    if(count == 8)
        count = 0;
    case(count)
    0: 
    begin
        oControl = 8'b0111_1111; // only make the first one have output
        output_number = minute_upper; // show the number the first one should have
    end
    1: 
    begin
        oControl = 8'b1011_1111;
        output_number = minute_lower;
    end
    2: 
    begin
        oControl = 8'b1101_1111;
        output_number = second_upper;
    end
    3: 
    begin
        oControl = 8'b1110_1111;
        output_number = second_lower;
    end
    4: oControl = 8'b1111_1111;
    5: oControl = 8'b1111_1111;
    6: 
    begin
        oControl = 8'b1111_1101;
        output_number = length_upper;
    end
    7: 
    begin
        oControl = 8'b1111_1110;
        output_number = length_lower;
    end
    endcase
end 
endmodule
