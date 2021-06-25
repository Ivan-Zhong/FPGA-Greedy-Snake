`timescale 1ns / 1ps
module vga_tb();
reg clk;
wire Hsynq, Vsynq;
wire [3:0] Red;
wire [3:0] Blue;
wire [3:0] Green;
top top_inst(.clk(clk), .Hsynq(Hsynq), .Vsynq(Vsynq), .Red(Red), .Blue(Blue), .Green(Green));

initial
begin
    clk = 0;
    forever #1 clk = ~clk;
end

endmodule
