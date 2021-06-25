`timescale 1ns / 1ps
// macros for direction
`define RIGHT 0
`define DOWN 1
`define LEFT 2
`define UP 3
// macros for states
`define INIT 0
`define GAME 1
`define START 2
`define LOSE 3
`define WIN 4
module snake_control(
    input clk, // clock for snake
    input [1:0] new_direction, 
    output reg [3071:0] screen = 0, // snake
    output reg [3071:0] food_screen = {{150'b0}, 1'b1, {45'b0}, 1'b1, {103'b0}, 1'b1, {100'b0}, 1'b1, {99'b0}, 1'b1, {299'b0}, 1'b1,{349'b0}, 1'b1, {300'b0}, 1'b1, {441'b0}, 1'b1, {34'b0}, 1'b1, {69'b0}, 1'b1, {30'b0}, 1'b1, {99'b0}, 1'b1, {83'b0}, 1'b1, {56'b0}, 1'b1, {10'b0}, 1'b1, {97'b0}, 1'b1, {26'b0}, 1'b1, {74'b0}, 1'b1, {79'b0}, 1'b1, {509'b0}}, // food
    output reg [12:0] length = 4,
    input [7:0] bluetooth_data,
    output reg [2:0] state = `INIT
    );
// control snake position
reg [6:0] snake_x[31:0];
reg [5:0] snake_y[31:0];
reg [1:0] direction = 0;
reg [6:0] new_x;
reg [5:0] new_y;
integer count = 0;
integer endpos = 3;
integer startpos = 0;

always@(posedge clk)
begin
    case(state)
    `INIT: // initialize
    begin
        snake_x[0] <= 0;
        snake_x[1] <= 1;
        snake_x[2] <= 2;
        snake_x[3] <= 3;
        snake_y[0] <= 0;
        snake_y[1] <= 0;
        snake_y[2] <= 0;
        snake_y[3] <= 0;
        count <= 0;
        endpos <= 3;
        startpos <= 0;
        direction <= 0;
        length <= 4;
        screen <= 0;
        food_screen <= {{150'b0}, 1'b1, {45'b0}, 1'b1, {103'b0}, 1'b1, {100'b0}, 1'b1, {99'b0}, 1'b1, {299'b0}, 1'b1,{349'b0}, 1'b1, {300'b0}, 1'b1, {441'b0}, 1'b1, {34'b0}, 1'b1, {69'b0}, 1'b1, {30'b0}, 1'b1, {99'b0}, 1'b1, {83'b0}, 1'b1, {56'b0}, 1'b1, {10'b0}, 1'b1, {97'b0}, 1'b1, {26'b0}, 1'b1, {74'b0}, 1'b1, {79'b0}, 1'b1, {509'b0}};
        state <= `START;        
    end
    `START: // start state, wait for bluetooth data to start game.
    begin
        if(bluetooth_data == 8'b01000001) // A
            state <= `GAME; 
    end
    `GAME:
    begin
        count = count + 1; // generate random numbers for food position
        // change direction
        if(direction - new_direction != 2 && new_direction - direction != 2 && direction != new_direction)
        begin
            // direction changes. Update the direction. 
            direction = new_direction;
        end
        case(direction)
        `RIGHT: 
            begin
                new_x = snake_x[endpos] + 1;
                new_y = snake_y[endpos];
            end
        `DOWN: 
            begin
                new_x = snake_x[endpos];
                new_y = snake_y[endpos] + 1;
            end
        `LEFT: 
            begin
                new_x = snake_x[endpos] - 1;
                new_y = snake_y[endpos];
            end
        `UP: 
            begin
                new_x = snake_x[endpos];
                new_y = snake_y[endpos] - 1;
            end    
        endcase

        // when snake touches the wall, emerge from the other side.
        if(new_x == 64)
        begin
            new_x = 0;
        end
        else if(new_x == 127)
        begin
            new_x = 63;
        end
        else if(new_y == 48)
        begin
            new_y = 0;
        end
        else if(new_y == 63)
        begin
            new_y = 47;
        end

        // if snake eats itself, lose
        if(screen[(new_y) * 64 + (new_x)] == 1 && (new_x != snake_x[startpos] || new_y != snake_y[startpos]))
            state = `LOSE;
        // if snake eats food, length++
        else if(food_screen[(new_y) * 64 + (new_x)] == 1)
        begin
            endpos = endpos + 1;
            length = length + 1;
            food_screen[(new_y) * 64 + (new_x)] = 0;
            food_screen[(count * 1093) % 3072] = 1;
        end
        else
        begin
            screen[(snake_y[startpos]) * 64 + (snake_x[startpos])] = 0;
            startpos = startpos + 1;
            endpos = endpos + 1;
        end
        if(startpos == 32)
            startpos = 0;
        if(endpos == 32)
            endpos = 0;
        
        snake_x[endpos] = new_x;
        snake_y[endpos] = new_y;
        
        screen[(snake_y[endpos]) * 64 + (snake_x[endpos])] = 1;     

        // win condition
        if(length >= 30)
            state = `WIN;   
    end
    `LOSE:
    begin
        if(bluetooth_data == 8'b01000010) // B
            state = `INIT;
    end
    `WIN:
    begin
        if(bluetooth_data == 8'b01000010) // B
            state = `INIT;
    end
    endcase
end
endmodule
