module out_enable #() (
    input logic rst_n,
    input logic sclk,
    input logic chip_select,
    input logic mosi_i,
    input logic out_en,
    output logic mosi_o

);

logic mosi_line;
logic [5:0]counter;
bit transfer_flag_d, transfer_flag_q;
logic mosi_old;
/* 
always_ff @(posedge sclk, negedge rst_n) begin
    
    if (~rst_n) begin
        transfer_flag_q <= 0;
        counter <= 0;
        mosi_old <= 0;
    end else begin

        mosi_old <= mosi_i;

        if ( transfer_flag_q & (counter < 'd46) ) begin
            counter++;
        end

        transfer_flag_q <= transfer_flag_d;
    end
end

always_comb begin

    // default values:
    transfer_flag_d = 0;

    // to start a sequence of a transfer cs must be low & the first two bits sent are 0 & 1 to initiate transfer
    if (~chip_select &  ~mosi_old & mosi_i) begin
        transfer_flag_d = 1;
    end else begin
        transfer_flag_d = transfer_flag_q;
    end
    // a CMD from the mosi line is 48 bits long, after that dummy value 1 is sent for the receiver phase of the transfer
    if (counter == 'd46 | chip_select) begin
        mosi_line = 1;
        transfer_flag_d = 0;
    end else  begin
        mosi_line = mosi_i;
    end 
end */
always_comb begin
    if (out_en) begin
        mosi_line = mosi_i;
    end else begin
        mosi_line = 1;
    end
end
assign mosi_o = mosi_line;

endmodule : out_enable