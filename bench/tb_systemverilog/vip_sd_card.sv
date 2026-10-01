//TODO
// -> Create function for CRC calculation -> OPTIONAL

module vip_sd_card #(
) (
    input logic mosi,
    input logic cs,
    input logic sclk,
    output logic miso
); 

    import sd_reg_pkg::ocr_t;
    ocr_t ocr = '{1'b0, 1'b0, 1'b0, 4'b0, 9'h1FF, 7'hFF, 1'b0, 7'hFF};


   //Check if the dummy SD-card image exists
    integer fd;
    byte sector_buf[512];
    initial begin
        fd = $fopen("sdcard.img", "r");
        if (fd == 0) begin
        $display("Failed to open the SD-card image!");
        $finish;
        end        
        $fclose(fd);
    end


    localparam time TA = 100ns; // after clk edge, when values are driven
    localparam time TT = 4.8us; // after clk edge, when values are read/sampled

    typedef struct packed{
        logic [7:0] cmd;
        logic [7:0] crc;
        logic [39:0] response;   // response bytes to send on MISO
        logic [2:0] resp_len;    // number of response bytes
        bit read_block;
        bit write_block;
    } sd_cmd_t;

    sd_cmd_t rx_cmd;

    localparam sd_cmd_t SD_CMDS[7] = '{
        '{8'h40, 8'h95, 40'h01,         1,  0,  0}, // CMD0
        '{8'h48, 8'h87, 40'h01000001AA, 5,  0,  0}, // CMD8
        '{8'h77, 8'h65, 40'h01,         1,  0,  0}, // CMD55
        '{8'h69, 8'h77, 40'h00,         1,  0,  0}, // ACMD41
        '{8'h7A, 8'hFD, 40'h0040FF8000, 5,  0,  0}, // CMD58
        '{8'h51, 8'h55, 40'h00,         1,  1,  0}, // CMD17 BLOCK READ
        '{8'h58, 8'h6F, 40'h00,         1,  0,  1}  // CMD24 BLOCK WRITE
    };

    //CMD names
    typedef enum logic [7:0] {
        CMD0    = 8'h40,
        CMD8    = 8'h48,
        CMD55   = 8'h77,
        ACMD41  = 8'h69,
        CMD58   = 8'h7A,
        CMD17   = 8'h51,
        CMD24   = 8'h58
        } cmd_num;
    cmd_num cmd;

    logic [7:0] counter;
    logic [47:0] data_packet;
    // when CRC is detected, rsp is asserted to enable response.
    bit rsp = 0;
    logic miso_line;
    logic [39:0] tx;

    // "task reaches end" flags
    bit miso_gen_end_flag, cmd_crc_check_end_flag;

    // does not take into account interruptions in sclk 
    task automatic powerup(logic mosi, logic cs, logic sclk);
        logic [7:0] cycle_cnt = 0;
        @(posedge sclk);

        for (cycle_cnt = 0; cycle_cnt < 74; cycle_cnt++) begin
            if(~cs | ~mosi) begin
                $display("\tSD-CARD: powerup of an sd card needs atleast 74 sclk cycles where cs & mosi are high");
            end
            @(posedge sclk);
        end
        $display("\tSD-CARD: powerup finished correctly, CMD0 can be sent.");
    endtask


    task automatic send_byte(
        input [7:0] data_byte
    );
        logic [7:0] tmp_byte;        
        begin
            tmp_byte = data_byte;
            for (integer j = 0; j < 8; j++)begin
                miso_line = tmp_byte[7];
                tmp_byte = tmp_byte << 1;
                @(negedge sclk);
            end
        end
    endtask

    task automatic receive_byte(
        output [7:0] data_byte
    );
        logic [7:0] tmp_byte;
        begin
            tmp_byte = 8'h00;
            for (integer j = 0; j < 8; j++) begin
                @(posedge sclk);
                tmp_byte[7-j] = mosi;             
                data_byte = tmp_byte;    
            end
        end
    endtask
    
    task automatic miso_generate();
        miso_gen_end_flag = 0;
        do begin            
            while(~rsp) begin 
                miso_line = 1;
                @(negedge sclk);
            end;                        
            
            if (rx_cmd.read_block) begin
                $display("SD-CARD: START BLOCK READ!\n");
                
                //Send token
                send_byte(8'hFE);
                $display("SD-CARD: TOKEN SENDED!\n");

                //Read image
                fd = $fopen("sdcard.img", "r");
                $fread(sector_buf,fd);
                $fclose(fd);
        
                //Send 512 bytes of data
                for (integer k = 0; k < 512; k++)begin
                    send_byte(sector_buf[k]);
                end

                //SEND CRC -> not implemented

            end

            else if (rx_cmd.write_block) begin
                logic [7:0] input_byte;
                
                $display("SD-CARD: START BLOCK WRITE!");

                // Read bytes until start token 0xFE is received
                do begin
                    receive_byte(input_byte);
                end while (input_byte != 8'hFE);

                $display("SD-CARD: GOT THE TOKEN FROM THE MASTER!");

                //Write 512 bytes of data
                fd = $fopen("sdcard.img", "w");
                for (integer k = 0; k < 512; k++)begin
                    receive_byte(input_byte);                    
                    $fwrite(fd, "%c",input_byte);                    
                end
                
                //CRC -> not implemented yet

                $fclose(fd);
                $display("SD-CARD: BLOCK WRITE COMPLETE!");                

            end

            else begin
                //Send regular CMD response
                tx = rx_cmd.response << (40-rx_cmd.resp_len*8);
                for (integer i = 0; i < rx_cmd.resp_len; i++) begin
                    send_byte(tx[39:32]);
                    tx = tx << 8;
                end
            end
            rsp = 0;
        end while(rsp);
        miso_gen_end_flag = 1;
        $display("\t###SD-CARD: Task miso_generate reached its end ###");
        
    endtask

    task automatic detect_CMD_and_CRC();
        data_packet = 0;
        cmd_crc_check_end_flag = 0;        

        // cs and mosi should be high for powerup, when cs goes low, we read mosi
        @(negedge mosi);

        //CMD and CRC reading
        do begin @(posedge sclk);
            data_packet[0] =  mosi;
            counter++; 
            if (counter < 8'd48) begin
                data_packet =  data_packet << 1;
            end
            else begin
                counter = 0;
                data_packet[0] =  mosi;
                rx_cmd.crc = {data_packet[7:0]};
                rx_cmd.cmd = {data_packet[47:40]};

                //Search matching command from the structure
                foreach (SD_CMDS[i]) begin
                    if (SD_CMDS[i].cmd == rx_cmd.cmd &&
                        SD_CMDS[i].crc == rx_cmd.crc) begin
                        //Copy the matching command from the table
                        rx_cmd = SD_CMDS[i];
                        cmd = cmd_num'(rx_cmd.cmd);
                        $display("SD-CARD: %s detected, CRC: %2h\n", cmd.name(),rx_cmd.crc);
                        rsp = 1;
                    end
                end
                @(posedge sclk);
                data_packet = 0;
            end
        end while (~cs & ~rsp);
        cmd_crc_check_end_flag = 1;
        $display("\t###SD-CARD: Task detect_CMD_and_CRC has reached its end ###");
    endtask

    assign miso = miso_line;

endmodule : vip_sd_card
