

# SD READ and WRITE

These are called Tokens, which the card uses to respond to host when reading and writing transmissions can occur or if errors have occured

0xFC   Start multiple-block write
0xFD   Stop transmission token
0xFE   Data block token (After init, when reading with CMD17 or CMD18, this token is the successful response that is needed before reading can start).

Refer to SD Specifications Part 1 Physical Layer Simplified Specification multiple write and read for more information.

### Read Commands 

Addressing works differently based on the card version:  
Trying to read from sector 100:  
for SDHC and SDXC cards address = 100  
older legacy cards SDSC addr = 100 * 512.  

For SDHC/SDXC cards Block length is 512 bytes

CMD9 SEND_CSD can be used to check card capacity.  
CMD13 SEND_STATUS for status and error information.
CMD17 READ_SINGLE_BLOCK 512-byte sector (or smaller if defined)  
CMD18 READ_MULTIPLE_BLOCK  

CMD12 STOP_TRANSMISSION used in multiple block reads (check whether CMD23 SET_BLOCK_COUNT is supported/needed on newer cards)

if a read operation fails.  
Data error token: 0000 1111 where bits with 1 describe an error:  
bit 3: out of range, bit 2: Card ECC failed, bit 1 CC error and bit 0: Error.

### Write Commands

CMD24  WRITE_BLOCK
CMD25  WRITE_MULTIPLE_BLOCK

Writes data has a START_block token at the beginning, followed after the data comes a data response and as long as the card is handling the data and programming it will stream a busy token (MISO held low). CMD13 SEND_STATUS is adviced to be sent after writing since some errors are checked only during the cards programming and will be stored to registers.

In multiple block writes the stop tran token must be sent to the card to indicate end of transfer.

start block token: 11111110 for the first byte of data
STop tran token: 11111101 after last block.

