# APB_SPI Controller with Systemverilog and C++ Testbenches

This repository uses the PULP Platforms APB_SPI controller. With small changes to software reset and a cs_trail added to the STATUS_REG of the IP's register interface.  
The SPI cntroller was used in pulpino, datasheet (section 5.3 SPI Master) https://www.pulp-platform.org/docs/pulpino_datasheet.pdf  

This repo contains a C++ Testbench from ZipCpu/sdspi (Dan Gisselquist), which was modified to use APB instead of wishbone for driving the SPI-Controller.  
A Systemverilog testbench has also been implemented.  

The C++ TB has assertions so it is safer to run if modifying the IP, Systemverilog testbench in its current state does only printouts. Both generate waveforms that can be analysed with gtkwave. 

To run the tesbenches:  
	make sv_tb in the root of the repository to compile and run the systemverilog testbench.  
	./rtl/compile_tb.sh for the C++ testbench.

Tools:  
- Verilator (5.020 & 5.050) tested
- bender (0.32.1) install bender and run bender update in the root of the repository

## Documentation

The doc/ folder consists of notes on the spi and using spi with an sd-card. A links file holds some reading material off the internet.

# SPI controller input/config for SD-card communication

BASEADDR DEFAULT = 0x0000 0000 Can be changed to what ever value, APB_SPI_CONTROLLER registers memory mapped:

| REGISTER   | ADDR           | Description |
| ---------- | -------------- | --- |
| REG_STATUS | BASEREG + 0x00 | Controls chipselect pins 3:0 |
| REG_CLKDIV | BASEREG + 0x04 | Divides system clk to provide sclk with required frequency |
| REG_SPICMD | BASEREG + 0x08 | 32 bit register which can be used for output (MOSI) | 
| REG_SPIADR | BASEREG + 0x0C | 32 bit register, also used for MOSI |
| REG_SPILEN | BASEREG + 0x10 | Sets the bit width of TX/RX FIFO (set bits 31:16), SPICMD_REG (set bits 5:0), & SPIADR_REG (set bits 13:8) |
| REG_SPIDUM | BASEREG + 0x14 | Setting a value to bits 31:16 activates a setting to write dummy cycles between sending SPICMD & SPIADR with mosi low, providing sclk. Bits 15:0 do the same for read | 
| REG_TXFIFO | BASEREG + 0x18 | Data to be buffered to MOSI after registers SPICMD & SPIADR have been sent (note if spicmd and adr length have been defined as 0 in SPILEN register, then the IP will only use the FIFO) |
| REG_RXFIFO | BASEREG + 0x20 | Same as TX but for receiving data |
| REG_INTCFG | BASEREG + 0x24 | Enables interrupt, has counters for RX, TX, RHTX and THTX, documentation on these in pulpino datasheet is not fully written, yet to be figured out the bit positions |
| REG_INTSTA | BASEREG + 0x28 | --- |

# SPI ports

| SIGNAL | Direction  | Description |
| --- | --- | --- |
|spiclk| output | Masterclk |
|spi_csn0|output| Chip select 0|
|spi_csn1|output| Chip select 1|
|spi_csn2|output| Chip select 2|
|spi_csn3|output| Chip select 3|
|spi_mode[1:0]|output| SPI mode|
|spi_sdo0|output| Output line MOSI|
|spi_sdo1|output| Output line MOSI|
|spi_sdo2|output| Output line MOSI|
|spi_sdo3|output| Output line MOSI|
|spi_sdo0|input| Input line MISO|
|spi_sdo1|input| Input line MISO|
|spi_sdo2|input| Input line MISO|
|spi_sdo3|input| Input line MISO|
|Event_o[1:0]|output| Event/Interrupt|

| COMMAND | Purpose                                                      | Dataline (MOSI)   | Response + info                                     |
| ------- | ------------------------------------------------------------ | ----------------- | --------------------------------------------------- |
| CMD0    | Reset card and request SPI mode                              | 40 00 00 00 00 95 | R1 = 0x01 idle state entered                        |
| CMD8    | Check voltage range and card generation                      | 48 00 00 01 AA 87 | R7 echo ending in 0x01AA for SDv2+                  |
| CMD55   | Prefix next command as application-specific                  | 77 00 00 00 00 65 | R1 = 0x01 while still idle                          |
| ACMD41  | init command: send same command & check response until ready | 69 40 00 00 00 77 | 0x01 busy, when 0x00 it is ready                    |
| CMD58   | Read OCR and card capacity status                            | 7A 00 00 00 00 FD | R3; use CCS to distinguish SDSC from SDHC/SDXC      |
| CMD16   | Set block length for SDSC access                             | 50 00 00 02 00 15 | R1; Use when you need 512-byte SDSC block transfers |
| CMD17   | Reads one block set by CMD16 (default 512kB)                 | 51 00 00 00 00 55 | R1                                                  |
| CMD24   | Writes one data block                                        | 58 00 00 00 00 6F | R1                                                  |

|  INIT  |
| :----: |
|  CMD0  |
|  CMD8  |
| CMD55  |
| ACMD41 |
| CMD58  |

| SD-card Command width | R1 response width | R3 response width | R7 response width |
| :-------------------: | :---------------: | :---------------: | :---------------: |
|        48 bits        |      8 bits       |      40 bits      |      40 bits      |

## CONFIG  

### CLKDIV
CLKDIV defines the time it takes for the clock to change polarity
**For SD-card init CMD0-CMD58 set CLKDIV so that 2xSYSTEM_CLK/CLKDIV=400kHz i.e. CLKDIV = 2xSYSTEMCLK/400kHz**  
**After that SCLK can be increased to 25-50MHz, The SPI-mode can not check card capabilities for data throughput, it treats all cards as class 0 speed cards (card can not specify performance) High speed is stated to be the same as SD-bus mode which would promise up to 50MHz 3.3V signaling.**

SDHC and SDXC cards (most modern cards) support 50MHz but older SDSC cards do not support anymore than 25MHz. There are apparently some SDHC cards that do not support 50MHz.

**Check CMD6 from specification, unsure if SPI-mode supports this speed query of CMD6**

PWDATA value configured for the sdspi tb of zipcpu.

| Config CLKDIV reg                                              | PADDR            | PWDATA |
| -------------------------------------------------------------- | ---------------- | ------ |
| Set spi controller to write with normal SPI, chipselect to cs0 | BASE ADDR + 0x04 | 32'hF8 |

### **SPILEN**

|                                      32 : 0                                       |
| :-------------------------------------------------------------------------------: |
|             31:16 FIFO width - 15:8 SPIADDR width - 7:0 SPICMD width              |
| Max length for FIFO : 65535 (16'hFFFF), SPIADDR : 63 (8'h3F), SPICMD : 63 (8'h3F) |

To send all data with TXFIFO, set SPILEN to PWDATA = 32'h00300000, the first two bytes from MSB define FIFO length. 32'h00300000 will configure this to 48 bits equal to the sd-card CMD length.  
`Note: when setting the length to lower than 32 bits, the missing bits from the length are cut from LSB side. if we want to write 16 bit length to CMD: 16'h4000, it needs to be written to input (PWDATA) as 32'h40000000. Not 32'h4000`

FIFO length can be changed between read and write but the value  in spilen is configured when the spi_master_controller goes into idle and rd or write from status register is issued.

| Config SPILEN reg | PADDR            | PWDATA       |
| ----------------- | ---------------- | ------------ |
| FIFO to 48 bits for sending a CMD  | BASE ADDR + 0010 | 32'h00300000 |

For RESPONSES the RXFIFO length needs to be long enough to give the sd card time to process, give atleast 8 bits after Transfer is done, and receive the response (response width varies, check which response is used for the sent CMD) and 8 bits extra after the response to provide an sclk to the card for end processing.


### **STATUS REG, start write to sd-card**
`Note: if spicmd and spiaddr have length set to larger than 0, they are sent before sending from txfifo, all of the data in these registers will be chained together`

PWDATA 32'h0122 starts a standard SPI write transaction, using chip select cs0, setting a chip_select trail bit to ensure that the cs0 stays low between transfer and receive states. SPILEN, CLKDIV, and TXFIFO should be written before STATUS is written.  

STATUS should be written to only when the spi_master_controller is in the idle state.

| Config status reg to initiate transfer                                           | PADDR            | PWDATA   |
| -------------------------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to write with normal SPI, chipselect to cs0 and cs trail to 1 | BASE ADDR + 0x00 | 32'h0122 |


| Config status reg to initiate reception of data                                 | PADDR            | PWDATA   |
| ------------------------------------------------------------------------------- | ---------------- | -------- |
| Set spi controller to read with normal SPI, chipselect to cs0 and cs trail to 1 | BASE ADDR + 0x00 | 32'h0121 |

## SD-card INIT

To drive a cmd to the sd card: SPI_LEN register must be configured with fifo length and optionally cmd and adr registers that are used as buffers for sending the serial data once spi write has been written to the STATUS_REG.

We configured only the FIFO depth for sneding our CMDs and data. 
As an example to send CMD0 to the sd-card we configure the SPILEN register with 32'h00300000 which sets the fifo depth to 48 bits for the sd-card CMD length, then the TXFIFO is written with the CMD0 data in two commands like shown below, finally the STATUS_REG is written with 32'h0121 to configure chipselect, cs_trail and spi write.

Writing the STATUS_REG with the spi_write initiates the transfer from the fifo for the duration of sclk cycles defined based on the SPILEN. Note that we also defined the CLKDIV value based off our system clock and sd-specification for the init phase. 

The PWDATA width is only 32 bits so to write more into the fifo just means writing several 32 bit values. The values are written MSB first and then shifted to the left.
### **CMD0**

| PWDATA       |
| ------------ |
| 32'h40000000 |
| 32'h00950000 |


### **CMD8**

| PWDATA       |
| ------------ |
| 32'h48000001 |
| 32'hAA870000 |


### **CMD55**

| PWDATA       |
| ------------ |
| 32'h77000000 |
| 32'h00650000 |


### **ACMD41**

| PWDATA       |
| ------------ |
| 32'h69400000 |
| 32'h00770000 |


### **CMD58** 

| PWDATA       |
| ------------ |
| 32'h7A000000 |
| 32'h00FD0000 |

**INIT Done**

### **CMD16** 

Sets block len to 512 (ensures older cards follow the same partioning of data as newer cards do, wont affect newer cards)

| PWDATA       |
| ------------ |
| 32'h50000001 |
| 32'h00150000 |

## WRITE COMMANDS

### Single write **CMD24** 
| PWDATA       |
| ------------ |
| 32'h58000000 |
| 32'h006F0000 |

## READ COMMANDS

### Single read **CMD17**
| PWDATA       |
| ------------ |
| 32'h51000000 |
| 32'h00550000 |

