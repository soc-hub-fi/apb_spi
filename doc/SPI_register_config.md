

# SPI confgi for SD card operations

## SPI registers

**Reset values** 0x0000_0000
**ADDR for registers** = BASE ADDR + 0000 for first and then increments by 4.  
Example in pulp base 0x1a10_2000 so status reg: 0x1a10_2000 and CLKDIV reg: 0x1a10_2004

### STATUS REG

Bit 11:8 CS:ChipSelect Set to: 4'b0001 to use the first cs signal at output.  
Bit 4 SRST:SoftwareReset.  
Clears FIFOs and abort active transfers.  
Bit 3 QWR:Quad WriteCommand. **Not used.**    
Bit 2 QRD:QuadReadCommand. **Not used.**
Bit 1 WR:WriteCommand.  
Bit 0 RD:ReadCommand.  

### CLKDIVIDER

Bit 7:0 CLKDIV SCLK for the SD-card needs to be 100-400kHz for init so CLKDIV needs to divide system clk to this range.

### SPICMD

Bit 31:0 SPICMD This is sent first, length can be controlled with SPILEN. Needs to follow SD card init commands step by step. More info about SD-card commands in SD.md, SD_INIT.md and SD_init_commands.md.

**TODO: add more precise instructions**

### SPIADR

Bit 31:0 SPIADR This is sent after SPICMD and can be also controlled with SPILEN register. Used for read and write operations. Depends on how we store our data into the sd-card bootloader at sector 0 to sector ??? after that RTOS???

### SPILEN

Bit 31:16 DATALEN  
After SPICMD and SPIADDR have been sent to the slave i.e. SD-card in our case, the DATALEN can be sent to the card.  

Bit 13:8 ADDRLEN define address length.  
Address length for sd card is 32 bits.

Bit 5:0 CMDLEN define command length.  
Number of bits sent. For the SD_card CMD length should be 6 bits.

### SPIDUM 

Bit 31:16 DUMMYWR writes dummy cycles, used in power up before init, atleast 74 cycles need to pass before first command to give card time to power up. Used also after command and address have been sent, before sending data.

Bit 15:0 DUMMYRD same as for write.

Mentioned in a masters thesis: https://repository.rit.edu/cgi/viewcontent.cgi?article=10950&context=theses that "To manage clock domain crossing or prevent data getting skipped, 8 pulses are inserted between command and response." The exact amount of dummy cycles needed, needs to be confirmed but the sd card reads all data with a counter in groups of 8 based on 8 cycles of the sclk.

### TXFIFO

Bit 31:0 TX Write data into fifo.

### RXFIFO

Bit 31:0 RX read data from fifo.

### INTCFG Interrupt configuration

datasheet has blank but holds: EN, CNTEN, CNTRX, CNTTX, RHTX, THTX

For defining interrupt triggers when an RX transfer count reaches a defined value. H marking half for both rx and tx indicating fifo reaching or dropping over/under a threshold. Used for indicating an empty or full fifo.


**TODO figure out and confirm usage of the interrupts**
