`timescale 1ns / 1ps
// states
`define INIT 0
`define GAME 1
`define START 2
`define LOSE 3
`define WIN 4
module top(
    input clk, // system clock
    input rst, // reset
    input left, // direction control
    input right,
    input up,
    input down,
    output Hsynq, // VGA output
    output Vsynq,
    output [3:0] Red,
    output [3:0] Green,
    output [3:0] Blue,
    output [6:0] oData, // seven segment display output
    output [7:0] oControl,  
    input MP3_DREQ, // MP3 input
    input MP3_MISO,
    output MP3_MOSI, // MP3 output
    output MP3_SCLK,
    output MP3_CS,
    output MP3_DCS,
    output MP3_RSET,    
    output [4:0] mp3_state,
    input bluetooth_get, // bluetooth input
    output [7:0] bluetooth_data // bluetooth output
);

parameter point_number = 48 * 64; // 10*10 block

// divided clocks
wire clk_25MHz; // clock for VGA
wire clk_4Hz; // clock for snake to move
wire clk_500Hz; // clock for seven segment display
wire clk_1Hz; // clock for timing

// for VGA
wire enable_V_Counter;
wire [15:0] H_Count_Value;
wire [15:0] V_Count_Value;

// snake and food
wire [point_number - 1:0] snake_screen;
wire [point_number - 1:0] food_screen;

// time passed (in seconds)
reg [15:0] sec = 0;

// snake length
wire [12:0] length;

// new direction
reg [1:0] new_direction = 0;

// previous bluetooth data (to detect new commands)
reg [7:0] previous_bluetooth_data = 0;

// address for the background picture in game
wire [16:0] addra;

// address for the background picture out game
wire [16:0] outgame_addra;

// picture data in every state
wire [11:0] game_image_data;
wire [11:0] win_image_data;
wire [11:0] lose_image_data;
wire [11:0] start_image_data;

// for calculating picture position in game
wire [8:0] image_x;
wire [8:0] image_y;

// game state
wire [2:0] game_state;

// seven segment control data
wire [7:0] sevenseg_control;

// control music reset
wire music_rst;

// clocks
// clock for VGA
clock_divider VGA_Clock_gen(clk, clk_25MHz);
// clock for snake to move
clock_divider #(3124999) snake_Clock_gen(clk, clk_4Hz);
// clock for seven segment display
clock_divider #(99999) sevenseg_clock(.clk(clk), .divided_clk(clk_500Hz));
// clock for timing
clock_divider #(49999999) timing_clock(.clk(clk), .divided_clk(clk_1Hz));

// VGA counters
horizontal_counter VGA_Horiz(clk_25MHz, enable_V_Counter, H_Count_Value);
vertical_counter VGA_Verti(clk_25MHz, enable_V_Counter, V_Count_Value);

// snake and food
snake_control snake(.clk(clk_4Hz), .new_direction(new_direction), .screen(snake_screen), .food_screen(food_screen), .length(length), .bluetooth_data(bluetooth_data), .state(game_state));

// bluetooth
bluetooth blt(.clk(clk), .rst(rst), .get(bluetooth_get), .data(bluetooth_data));

// MP3
MP3 game_sound(.clk(clk), .rst(music_rst), .MP3_DREQ(MP3_DREQ), .MP3_CS(MP3_CS), .MP3_DCS(MP3_DCS), .MP3_RSET(MP3_RSET), .MP3_SCLK(MP3_SCLK), .MP3_MOSI(MP3_MOSI), .state(mp3_state));

// seven segment: for time and length display
sevenseg_clock_length sv(.clk(clk_500Hz), .seconds(sec), .length(length), .oControl(sevenseg_control), .oData(oData));

// decide new direction based on input from FPGA and bluetooth
always@(posedge clk_500Hz)
begin
    if(right == 1)
        new_direction = 2'b00;
    else if(down == 1)
        new_direction = 2'b01;
    else if(left == 1)
        new_direction = 2'b10;
    else if(up == 1)
        new_direction = 2'b11;
    else if(bluetooth_data != previous_bluetooth_data)
    begin
        if(bluetooth_data == 8'b01010101)
        begin
            new_direction = 2'b11;
            previous_bluetooth_data = bluetooth_data;
        end
        else if(bluetooth_data == 8'b01001000)
        begin
            new_direction = 2'b10;
            previous_bluetooth_data = bluetooth_data;
        end
        else if(bluetooth_data == 8'b01001010)
        begin
            new_direction = 2'b01;
            previous_bluetooth_data = bluetooth_data;
        end
        else if(bluetooth_data == 8'b01001011)
        begin
            new_direction = 2'b00;
            previous_bluetooth_data = bluetooth_data;
        end
    end
    else
        new_direction = new_direction;
end

// count seconds passed
always@(posedge clk_1Hz)
begin
    if(game_state == `GAME)
        sec = sec + 1;
    else
        sec = 0;
end

// only display seven segment output when it's in the game.
assign oControl = (game_state == `GAME) ? sevenseg_control : 8'b1111_1111;

// only play music when it's in the game.
assign music_rst = (game_state == `GAME) ? 0 : 1;

// when it's in the game, calculate which address to fetch data.
assign image_x = (H_Count_Value >= 144 && H_Count_Value <= 463 && V_Count_Value >= 35 && V_Count_Value <= 274) ? H_Count_Value - 144 : 
(H_Count_Value >= 464 && H_Count_Value <= 783 && V_Count_Value >= 35 && V_Count_Value <= 274) ? 783 - H_Count_Value : 
(H_Count_Value >= 144 && H_Count_Value <= 463 && V_Count_Value >= 275 && V_Count_Value <= 514) ? H_Count_Value - 144 : 
(H_Count_Value >= 464 && H_Count_Value <= 783 && V_Count_Value >= 275 && V_Count_Value <= 514) ? 783 - H_Count_Value : 0;

assign image_y = (H_Count_Value >= 144 && H_Count_Value <= 463 && V_Count_Value >= 35 && V_Count_Value <= 274) ? V_Count_Value - 35 : 
(H_Count_Value >= 464 && H_Count_Value <= 783 && V_Count_Value >= 35 && V_Count_Value <= 274) ? V_Count_Value - 35 : 
(H_Count_Value >= 144 && H_Count_Value <= 463 && V_Count_Value >= 275 && V_Count_Value <= 514) ? 514 - V_Count_Value : 
(H_Count_Value >= 464 && H_Count_Value <= 783 && V_Count_Value >= 275 && V_Count_Value <= 514) ? 514 - V_Count_Value : 0;

assign addra = image_y * 320 + image_x;

// when it's not in the game, calculate data address.
assign outgame_addra = (H_Count_Value >= 784 || H_Count_Value <= 143 || V_Count_Value >= 515 || V_Count_Value <= 34) ? 0 :
(H_Count_Value - 144) / 2 + ((V_Count_Value - 35) / 2) * 320;

// block memory generator instances for pictures.
blk_mem_gen_game game_image(.clka(clk), .addra(addra), .douta(game_image_data));
blk_mem_gen_start start_image(.clka(clk), .addra(outgame_addra), .douta(start_image_data));
blk_mem_gen_win win_image(.clka(clk), .addra(outgame_addra), .douta(win_image_data));
blk_mem_gen_lose lose_image(.clka(clk), .addra(outgame_addra), .douta(lose_image_data));

// Hsynq and Vsynq output
assign Hsynq = (H_Count_Value < 96) ? 1'b1 : 1'b0;
assign Vsynq = (V_Count_Value < 2) ? 1'b1 : 1'b0;

// RGB output
assign Red = (H_Count_Value >= 784 || H_Count_Value <= 143 || V_Count_Value >= 515 || V_Count_Value <= 34) ? 4'h0 : (game_state == `GAME) ? 
             (snake_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'hF : 
             (food_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'hF : game_image_data[11:8] :
             (game_state == `START || game_state == `INIT) ? start_image_data[11:8] : 
             (game_state == `WIN) ? win_image_data[11:8] : lose_image_data[11:8];
             
assign Green = (H_Count_Value >= 784 || H_Count_Value <= 143 || V_Count_Value >= 515 || V_Count_Value <= 34) ? 4'h0 : (game_state == `GAME) ? 
               (snake_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'hF : 
               (food_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'hF : game_image_data[7:4] : 
               (game_state == `START || game_state == `INIT) ? start_image_data[7:4] : 
               (game_state == `WIN) ? win_image_data[7:4] : lose_image_data[7:4];
                                
assign Blue = (H_Count_Value >= 784 || H_Count_Value <= 143 || V_Count_Value >= 515 || V_Count_Value <= 34) ? 4'h0 : (game_state == `GAME) ? 
              (snake_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'hF : 
              (food_screen[((V_Count_Value - 35) / 10) * 64 + ((H_Count_Value - 144) / 10)]) ? 4'h0 : game_image_data[3:0] :
               (game_state == `START || game_state == `INIT) ? start_image_data[3:0] : 
               (game_state == `WIN) ? win_image_data[3:0] : lose_image_data[3:0];
endmodule
