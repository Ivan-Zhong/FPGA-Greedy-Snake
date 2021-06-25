module bluetooth(
    input clk, // system clock
    input rst, // reset
    input get, // TXD
    output reg [7:0] data // bluetooth output
);

parameter baudParam = 10417; // corresponds to 9600 baudrate
reg buffer1 = 1; // use two buffers to detect the start of new data
reg buffer2 = 1;
wire cycle_en; // enable a cycle
reg data_en; // enable data reading and clock dividing
reg [14:0] baudCount; // counter to divide clock
reg [3:0] dataPos; // position to write new bit

assign cycle_en = ~buffer1 & buffer2; // always detecting

always@(posedge clk)
begin
    if(rst)
    begin
        buffer1<=1; // initial values
        buffer2<=1;
        data_en<=0;
        baudCount<=0;
        dataPos<=4'b1111;
        data<=0;
    end
    else
    begin
        buffer1<=get;
        buffer2<=buffer1; 

        if(cycle_en)
            data_en<=1;
        
        if(data_en)
        begin
            if(baudCount == baudParam - 1)
            begin
                baudCount<=0;
                if(dataPos == 7)
                begin
                    dataPos<=4'b1111; // -1
                    data_en<=0;
                end
                else
                    dataPos<=dataPos+1;
            end
            else
            begin
               baudCount<=baudCount+1; 
            end
        end

        if(data_en && baudCount == baudParam/2 && dataPos>=0)
        begin
            data[dataPos]<=get; // get data in the middle
        end
    end
end
endmodule