`timescale 1ns / 1ps
module bluetooth_single_char_tb;
reg clk,rst;
reg get;
wire [7:0] bluetooth_data;
//integer i;
bluetooth blt(.clk(clk), .rst(rst), .get(get), .data(bluetooth_data));
initial
begin
    clk <= 0;
    forever #1 clk = ~clk;
end

initial
begin
    rst = 1;
    get = 1;
    #5 rst =  0;
    #100 get = 0;
    #28 get = 1; // modified baudrate parameter to make simulation easier
    #28 get = 0;
    #28 get = 0;
    #28 get = 0;
    #28 get = 0;
    #28 get = 0;
    #28 get = 1;
    #28 get = 0;
    #28 get = 1;
    #28 get = 1;
    
end
endmodule