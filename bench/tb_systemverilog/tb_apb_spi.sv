/*  This testbench checks mandatory phases used in SD-card initialization (CMD0-CMD58)
//  and single block read/write operation (CMD17,CMD24) with the SD-card emulator.
//  
//  
//  Doesn't include at the moment:
//      -> CID/CSD checks
//      -> CRC calculation and checking during single block read/write  (CRC hardcoded during CMDs)
//      -> Doesn't consider delays that occur during SD-card communications
//      
*/      
module tb_apb_spi #() ();

    logic clk, rst_n;

    // APB & SPI Busses
    apb_interface #(
        .ADDR_W(12),
        .DATA_W(32)
    ) apb_bus ();
 
    logic [31:0] cmd;
    logic [31:0] addr;
    logic [31:0] fifo;
    
    // Unused out & in of DUT
    logic   unused_out, unused_in;
    logic [7:0] cmd_num [0:6] = '{0, 8, 55, 41, 58, 17, 24}; 
    logic[127:0] mosi_val; 
    (* keep *)
    logic [127:0] counter= 0;
    (* keep *)
    logic spi_clk, mosi, miso, csn;
    logic DUT_sd_out;
    logic out_en;
    logic acmd_no_rsp;
    bit card_found;

    int RW_test_amount = 4;

    
    // TODO correct bit widths
    logic [8:0] DUT_STATUS_REG; // shows STATUS_REG signals
    logic [7:0] REG_CLKDIV; 
    logic [31:0] REG_SPICMD; 
    logic [31:0] REG_SPIADR; 
    logic [27:0] REG_SPILEN; 
    logic [8:0] REG_SPIDUM; 
    logic [8:0] REG_TXFIFO; 
    logic [8:0] REG_RXFIFO; 
    logic [8:0] REG_INTCFG; 
    logic [8:0] REG_INTSTA; 
    logic [3:0] write_address;

    assign write_address = i_dut.u_axiregs.write_address;
    assign  unused_in = 1'b0;

    assign REG_CLKDIV = {
        i_dut.u_axiregs.spi_clk_div
    };

    assign REG_SPILEN = {
        i_dut.u_axiregs.spi_data_len,
        i_dut.u_axiregs.spi_addr_len,
        i_dut.u_axiregs.spi_cmd_len
    };

    assign REG_SPICMD = {
        i_dut.u_axiregs.spi_cmd
    };

    assign REG_SPIADR = {
        i_dut.u_axiregs.spi_addr
    };
    // TODO Other register assignments
    assign DUT_STATUS_REG = {
        i_dut.u_axiregs.spi_csreg,
        i_dut.u_axiregs.spi_swrst,
        i_dut.u_axiregs.spi_qwr,
        i_dut.u_axiregs.spi_qrd,
        i_dut.u_axiregs.spi_wr,
        i_dut.u_axiregs.spi_rd
        };

    initial begin
        counter = 0;
        card_found = 0;
        $dumpfile("trace.vcd");
        $dumpvars(0, i_dut);
        $display("\n\t###TESTING###");
        #50us;
        fork
            i_vip.init();
            i_vip.sd_powerup();
            
        join
        
        /*INIT PHASES*/
        for(int i = 0; i< 5; i++) begin
            fork
                i_sd_card.miso_generate();
                i_sd_card.detect_CMD_and_CRC();
                i_vip.CMD(cmd_num[i]);
            join_none
            #50ns;
            wait(i_vip.cmd_task_done && i_sd_card.miso_gen_end_flag && i_sd_card.cmd_crc_check_end_flag);
            
            //if the cmd executed is ACMD41 and card responded busy, loop back to cmd55
            if((cmd_num[i] == 41) & i_vip.acmd_no_rsp) i -= 2;
            #10ns;

        end
        
        /* READ/WRITE TESTS */
        for (int i = 0; i < RW_test_amount; i++)begin            
                //CMD24 write random data to the image
                fork
                    $display("TEST %0d: WRITE RANDOM DATA",i);
                    i_sd_card.miso_generate();
                    i_sd_card.detect_CMD_and_CRC();
                    i_vip.CMD(cmd_num[6]);
                join

                //CMD17 read if the written random data was stored correctly
                fork
                    $display("TEST %0d: READ RANDOM DATA",i);
                    i_sd_card.miso_generate();
                    i_sd_card.detect_CMD_and_CRC();
                    i_vip.CMD(cmd_num[5]);
                join
       
        end

        //END SIMULATION
        $finish(0);

    end
      
    assign cmd = mosi_val[95:64];
    assign addr = mosi_val[63:32];
    assign fifo = mosi_val[31:0];
    // ---

    apb_spi_master #() i_dut (
        .HCLK (apb_bus.PCLK),
        .HRESETn (apb_bus.PRESETn),
        .PADDR (apb_bus.PADDR),
        .PWDATA (apb_bus.PWDATA),
        .PWRITE (apb_bus.PWRITE),
        .PSEL (apb_bus.PSEL),
        .PENABLE (apb_bus.PENABLE),
        .PRDATA (apb_bus.PRDATA),
        .PREADY (apb_bus.PREADY),
        .PSLVERR (apb_bus.PSLVERR),

        .events_o(),
        .out_en(out_en),
        .spi_clk(spi_clk), // connect to SPI SD-Card
        .spi_csn0(csn), // connect to SPI SD-Card
        .spi_csn1(),
        .spi_csn2(),
        .spi_csn3(),
        .spi_mode(),
        .spi_sdo0(DUT_sd_out), // connect to SPI SD-Card
        .spi_sdo1(),
        .spi_sdo2(),
        .spi_sdo3(),
        .spi_sdi0(), 
        .spi_sdi1(miso), // connect to SPI SD-Card
        .spi_sdi2(),
        .spi_sdi3()
    );
    

    vip_apb_spi #() i_vip (
        .apb_mst (apb_bus.APB_Master),
        .cs(csn),
        .sclk( spi_clk)
    );

     vip_sd_card #() i_sd_card (
        .mosi (mosi),
        .cs (csn),
        .sclk (spi_clk),
        .miso (miso)
    );

    out_enable #() i_out_en (
        .rst_n (apb_bus.PRESETn),
        .sclk (spi_clk),
        .mosi_i (DUT_sd_out),
        .mosi_o (mosi),
        .out_en (out_en),
        .chip_select (csn)
    );


endmodule : tb_apb_spi
