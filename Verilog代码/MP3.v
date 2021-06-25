`timescale 1ns / 1ps

module MP3(
    input clk, // system clock
    input rst, // reset
    input MP3_DREQ, // MP3 input
    input MP3_MISO,
    output reg MP3_MOSI, // MP3 output
    output MP3_SCLK,
    output reg MP3_CS,
    output reg MP3_DCS,
    output reg MP3_RSET,
    output reg [4:0] state=1 // MP3 state (for debug)
);
// MP3 data (32 bits long)
wire [31:0] data;
// commands
reg [31:0] cmd_mode=32'h02000804;
reg [31:0] cmd_vol=32'h020B3333;
reg [31:0] cmd_bass=32'h02020055;
reg [31:0] cmd_clockf=32'h02039800;
reg [31:0] cmd_to_send;
reg [3:0] cmd_count = 0; //count of cmd
reg [5:0] cmd_pos; //digit pos in cmd
reg [14:0] data_count; //count of data
reg [5:0] data_pos; //digit pos in data
// states
reg [4:0] RESET = 1;
reg [4:0] INITIALIZE = 2;
reg [4:0] SEND_CMD = 4;
reg [4:0] PLAYMUSIC = 8;
reg [4:0] SEND_DATA = 16;
// clock for MP3 (0.5MHz)
clock_divider #(99) clk_1M(clk, MP3_SCLK);
// block memory generator for music data
blk_mem_gen_bgm music(.clka(clk), .addra(data_count), .douta(data));

// refresh data on the negedge of clock
always @(negedge MP3_SCLK)
begin
    if(rst)
    state<=RESET;

    case(state)
    RESET:
    begin
        MP3_RSET<=0; // reset MP3
        MP3_CS<=1; // CS and DCS is effective when value is 0
        MP3_DCS<=1;
        cmd_count<=0;
        cmd_pos<=30;
        state<=INITIALIZE; // change state
    end

    INITIALIZE: //before state machine comes here, cs should be 1, count should be 31, pos should be the next pos
    begin
        MP3_RSET<=1; //very important
        if(MP3_DREQ)
        begin
            if(cmd_count == 4) // finished writing all commands
            begin
                data_pos<=30;
                data_count<=0;
                state<=PLAYMUSIC; // change state
            end
            else
            begin
                MP3_CS<=0;
                state<=SEND_CMD;
                case(cmd_count)
                0: 
                begin
                    cmd_to_send<=cmd_mode;
                    MP3_MOSI<=cmd_mode[31]; // refresh a bit when setting CS to 0, write data from 31 to 0
                end
                1: 
                begin
                    cmd_to_send<=cmd_bass;
                    MP3_MOSI<=cmd_bass[31];
                end
                2:  
                begin
                    cmd_to_send<=cmd_clockf;
                    MP3_MOSI<=cmd_clockf[31];
                end
                3:  
                begin
                    cmd_to_send<=cmd_vol;
                    MP3_MOSI<=cmd_vol[31];
                end
                endcase
            end 
        end
    end

    SEND_CMD:
    begin
        if(cmd_pos == 63) // -1
        begin
            cmd_count<=cmd_count+1;
            cmd_pos<=30;
            MP3_CS<=1; // make it ineffective. Very important
            state<=INITIALIZE;
        end
        else
        begin
            MP3_MOSI<=cmd_to_send[cmd_pos];
            cmd_pos<=cmd_pos-1;
        end 
    end

    PLAYMUSIC:
    begin
        if(MP3_DREQ)
        begin
            if(data_count == 22262) // total length
                state<=RESET;
            else
            begin
                MP3_DCS<=0;
                MP3_MOSI<=data[31];
                state<=SEND_DATA;
            end 
        end
    end

    SEND_DATA:
    begin
        if(data_pos == 63)
        begin
            data_count<=data_count+1;
            data_pos<=30;
            MP3_DCS<=1;
            state<=PLAYMUSIC;
        end
        else
        begin
            MP3_MOSI<=data[data_pos];
            data_pos<=data_pos-1;
        end 
    end
    endcase
end
endmodule