
## SD_Card init steps

Power on  
Keep CS (chip select) high  
Send at least 74 (preferably 80) dummy clock pulses and provide MOSI high  
Pull CS low  
Send CMD0 to access idle state  
Send CMD8 to check the voltage range and card version  
Repeatedly send CMD55 + ACMD41 until the card leaves idle state (R1=0x00)  
CMD58 Detect whether the card is SDHC/SDXC or SDSC  
Increase the SPI speed  
- https://skoopsy.dev/stm32/2026/06/09/STM32-13-sd-card-transport.html

## Sources for SD card init

https://nodeloop.org/guides/sd-card-spi-init-guide/ 
"A practical SPI-mode startup sequence for SD, SDHC, and SDXC card bring-up, with command frames, expected responses, and the failure patterns that usually waste the most time."

https://skoopsy.dev/stm32/2026/06/09/STM32-13-sd-card-transport.html
"Talking to a microSD card over SPI"

### sd spi-mode spec simplified version 2017

https://academy.cba.mit.edu/classes/networking_communications/SD/SD.pdf
p.227

### sd protocol spi spec from emulator creator

https://problemkaputt.de/gbatek-dsi-sd-mmc-protocol-command-response-register-summary.htm  
https://problemkaputt.de/gbatek-dsi-sd-mmc-protocol-and-i-o-ports.htm 

### SDSPI controller github

ZipCPU/sdspi: SD-Card controller, using either SPI, SDIO, or eMMC interfaces 
https://github.com/ZipCPU/sdspi/tree/master

### SPI overview source

https://www.analog.com/en/resources/analog-dialogue/articles/introduction-to-spi-interface.html

### SD-Commands

https://www.it-sd.com/articles/secure-digital-card-commands/
