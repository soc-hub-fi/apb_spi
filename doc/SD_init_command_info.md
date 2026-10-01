

# SD_INIT COMMAND INFO

Start. CS high for atleast 74 cycles for the card to power up. 
1. CMD0 (GO_IDLE_STATE) (response format R1).
    - Triggers the SD-card to use SPI-interface  
Commands start from MSB to LSB with a start_bit (0) and transmission_bit (1), after them the 6 command bits follow: so start is seen as 0100 0000 or h'40

    So CMD0 is seen when data is set h'40. After CMD0, 4 bytes follow that configure parameter data and fifth for error checking (CRC). Only CMD0 (GO_IDLE_STATE) and CMD8 (SEND_IF_COND) must have valid CRC. Optional for other commands. CRC can be skipped (how??). The response from the SD card 0x01 means that idle state has been entered.

2. CMD8 (SEND_IF_COND) (response format R7) (determines whether SDXC is supported)
    Error here? bits 
    - send MOSI: 0x48 00 00 01 AA 87
    - Modern cards expect R7 response, where tail echoes 0x00 00 01 AA
    - ver1.x cards give illegal command. Use CMD58 to read OCR and determine if the plugged in card is an sd memory card at all.

3. CMD55 (response format R1)
    - Tells the card that the next command is application specific aka. ACMD. This is used for a newer way to init in an SD-specific way. Replaced CMD1 (older) as init command. MMC and Early SD-cards used CMD1.

4. ACMD41 (response format R1)  `Important for different card versions, affects data block reading`
    - After the ACMD41 loop succeeds, send CMD58 to read the OCR register and inspect the CCS bit.  
    - if CCS = 1: (card type: SDHC or SDXC) Memory commands use block addressing and 512-byte blocks.  
    - if CCS = 0: SDSC. Memory commands use byte addressing; set 512-byte block length with CMD16 if needed.  

    - if response is not idle, loop back to CMD55. 
    - SDUC cards can stay busy and not reply ready to host during ACMD41, indicating that SPI is not supported. 

5. CMD58 READ_OCR (response format R3)
    - Reads OCR HCS-bit (High capacity select) register to determine SD card cappacity, high capacity SDHC or standard v2 sd card is determined by this.
    - Provides sd card host with the cards voltage range support and tells if the card does not support the voltage range given at ACMD41.

    TODO section 5.1 of https://academy.cba.mit.edu/classes/networking_communications/SD/SD.pdf for more info on ocr

6. CMD16 SET_BLOCKLEN (response format R1 + data)  
`This command is sent for different types of sd cards to conf block length, 512 bytes allow to be used with atleast SDHC and older cards, command is not needed to be sent for SDHC since 512 is default for it but other cards need this command.`
 -  "In case of SDHC and SDXC Cards, block length is fixed to 512 Bytes regardless of the block length set by CMD16." -https://www.taterli.com/wp-content/uploads/2017/05/Physical-Layer-Simplified-SpecificationV6.0.pdf 
 - max 512-bytes.

CS (or SSEL) is set high after this and SCLK can be increased.

    check response format from simplified datasheet physical layer 
    https://www.sdcard.org/downloads/pls/pdf/?p=Part1_Physical_Layer_Simplified_Specification_Ver9.10.jpg&f=Part1PhysicalLayerSimplifiedSpecificationVer9.10Fin_20231201.pdf&e=EN_SS9_1 
