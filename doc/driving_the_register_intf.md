To drive the SPI controller using the APB register interface: write the register address into PADDR and data into PWDATA.

Below the data used in the systemverilog testbench to drive init (provide 80 clk cycles of sclk to the sd card), set sclk to 25MHz after init phase is over 
configure the registers for single block data read and write, and all the cmd configs for init and single write/read.

REG_STATUS 4'b0000 // BASEREG + 0x00  
REG_CLKDIV 4'b0001 // BASEREG + 0x04  
REG_SPICMD 4'b0010 // BASEREG + 0x08  
REG_SPIADR 4'b0011 // BASEREG + 0x0C  
REG_SPILEN 4'b0100 // BASEREG + 0x10  
REG_SPIDUM 4'b0101 // BASEREG + 0x14  
REG_TXFIFO 4'b0110 // BASEREG + 0x18  
REG_RXFIFO 4'b1000 // BASEREG + 0x20  
REG_INTCFG 4'b1001 // BASEREG + 0x24  
REG_INTSTA 4'b1010 // BASEREG + 0x28  

```
	 apb_addr_data init_apb [0:3]='{
        '{12'(`CLKDIV_ADDR), clk_speed_init},
        '{12'(`SPILEN_ADDR), 32'h00500000},
        '{12'(`TXFIFO_ADDR), 32'hFFFFFFFF},
        '{12'(`STATUS_ADDR), 32'h02}
    };

     apb_addr_data sclk_25 [0:2]='{
        '{12'(`SPILEN_ADDR), 32'h00500000},
        '{12'(`TXFIFO_ADDR), 32'hFFFFFFFF},
        '{12'(`STATUS_ADDR), 32'h02}
    };
   
    apb_addr_data cmd_apb_write_config [0:2] = '{
        '{12'(`SPILEN_ADDR), 32'h00300000},
        '{12'(`STATUS_ADDR), 32'h0122},
        '{12'(`SPILEN_ADDR), 32'h00300000}
    };

    apb_addr_data cmd_apb_read_config [0:1] = '{
        '{12'(`SPILEN_ADDR), 32'h00080000},
        '{12'(`STATUS_ADDR), 32'h0121}
    };
    apb_addr_data cmd0 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h40000000},
        '{12'(`TXFIFO_ADDR), 32'h00950000}
    };

    apb_addr_data cmd8 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h48000001},
        '{12'(`TXFIFO_ADDR), 32'hAA870000}
    };

    apb_addr_data cmd55 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h77000000},
        '{12'(`TXFIFO_ADDR), 32'h00650000}
    };
    
    apb_addr_data acmd41 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h69400000},
        '{12'(`TXFIFO_ADDR), 32'h00770000}
    };

    apb_addr_data cmd58 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h7A000000},
        '{12'(`TXFIFO_ADDR), 32'h00FD0000}
    };

    apb_addr_data cmd17 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h51000000},
        '{12'(`TXFIFO_ADDR), 32'h00550000}
    };

    apb_addr_data cmd24 [0:1] = '{
        '{12'(`TXFIFO_ADDR), 32'h58000000},
        '{12'(`TXFIFO_ADDR), 32'h006F0000}
    };
```
