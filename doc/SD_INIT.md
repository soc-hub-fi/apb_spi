

# SD-INIT

`sd command info file holds command by command explanation of the init`

- SD card is initialised with a specific set of commands and responses.

- At start up, the SD card needs atleast 74 SCLK cycles before a command can be given to give the SD card enough time to power up. 

The MOSI Master out Slave in wire & the Chip select (CS) wire need to be set high at the beginning. The SCLK needs to be between 100-400kHz for start up and initialization phase. After init the clock can be 20-25 MHz (some cards are reported to work up to 50MHz but spec guarantees only 20-25MHz).

When 74 cycles have passed, both MOSI and CS can be set low.

When CS is low, an operation is ongoing. The SD card will have Master in Slave out (MISO) wire high when it is ready to receive data.

When MOSI goes from high to low, that tells the card that data transfer has started. 

Data is sent in 48 bit packets where the first clocked MOSI = 0 is the first bit of the packet, after that MOSI needs to be 1 (called transfer in progress bit) and after that there are 6 bits to tell the card which command argument is issued. 

The sd card reads in 8 bit groups, so it counts the SCLK 8 times and reads that data based on the defined packet structure of the SD-card specification.

### PACKET STRUCTURE

| start bit | transmission | CMD (comand argument) | additional argument | additional argument  | additional argument  | additional argument | CRC (Error checking) | delay and signal for ending the operation/transmission. |
| --- |  --- | --- | --- | --- | --- | --- | --- | --- |
| 1 bit | 1 bit | 6 bits | 8bits | 8bits | 8bits | 8bits | 7 bits | 1bit |

## INIT COMMANDS and responses

| COMMAND | Purpose | Dataline (MOSI) | Response |
| --- | --- | --- | --- |
| CMD0 | Reset card and request SPI mode | 0x 40 00 00 00 95 | R1 = 0x01 idle state entered |
| CMD8 | Check voltage range and card generation | 48 00 00 01 AA 87 | R7 echo ending in 0x01AA for SDv2+ |
| CMD55 | Prefix next command as application-specific | 77 00 00 00 00 01 |  R1 = 0x01 while still idle |
| ACMD41 | init command: send same command & check response until ready | 69 40 00 00 00 01 | 0x01 busy, when 0x00 it is ready | 
| CMD58 | Read OCR and card capacity status | 7A 00 00 00 00 01 | R3; use CCS to distinguish SDSC from SDHC/SDXC |
| CMD16 | Set block length for SDSC access | 50 00 00 02 00 01 | Use when you need 512-byte SDSC block transfers | 


| CMD59 | CRC error checking on or off | 7B 00 00 00 01 (+CRC) enabled | 7B 00 00 00 00 (+CRC) disabled |
| ---- | --- | --- | --- |

#### Init in binary for mosi line

CMD0 : 01000000 00000000 00000000 00000000 10010101  
CMD8 : 01001000 00000000 00000000 00000001 10101010 10000111  
CMD55 : 01110111 00000000 00000000 00000000 00000000 00000001  
ACMD41 : 01101001 01000000 00000000 00000000 00000000 00000001  
CMD58 : 01111010 00000000 00000000 00000000 00000000 00000001  
CMD16 : 01010000 00000000 00000000 00000010 00000000 00000001

Note dummy crc for cmd55 and below.

More speccifics to the additional arguments should be looked up from the sd card specification. FIRST TWO commands need CRC bits calculated and compared for error checking, other commands are not required to have them unless the designer wants to enable CRC.

Refer to simplified physical specification of the sd card https://www.sdcard.org/downloads/pls/ or consisely collected to https://www.it-sd.com/articles/secure-digital-card-commands/ for more information on commands, additional fields and their responses.

