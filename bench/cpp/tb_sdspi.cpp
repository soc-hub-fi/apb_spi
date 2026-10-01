////////////////////////////////////////////////////////////////////////////////
//
// Filename:	bench/cpp/tb_sdspi.cpp
// {{{
// Project:	SD-Card controller
//
// Purpose:	Exercise all of the functionality contained within the Verilog
//		core, from bring up through read to write and read-back.
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
// }}}
// Copyright (C) 2016-2025, Gisselquist Technology, LLC
// {{{
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
// }}}
// License:	GPL, v3, as defined and found on www.gnu.org,
// {{{
//		http://www.gnu.org/licenses/gpl.html
//
////////////////////////////////////////////////////////////////////////////////
// * 05-08-2026
//		-> Modified to use APB instead of the original Wishbone interface.
//		**Aapo Manni (aapo.manni@tuni.fi)**
////////////////////////////////////////////////////////////////////////////////

// }}}
// Include files
// {{{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <Vapb_spi_master.h>
#include "testb.h"
#include "apb_tb.h"
#include "sdspisim.h"
// }}}

// MACRO definitions
// {{{
// #define	OPT_LITTLE_ENDIAN

typedef struct {
	uint32_t fifo0;
	uint32_t fifo1;
	int	 r_frame;
} SDCMD;


#define REG_STATUS 		0x1A102000
#define REG_CLKDIV 		0x1A102004
#define REG_SPICMD 		0x1A102008
#define REG_SPIADR 		0x1A10200c
#define REG_SPILEN 		0x1A102010
#define REG_SPIDUM 		0x1A102014
#define REG_TXFIFO 		0x1A102018
#define REG_RXFIFO 		0x1A102020
#define REG_INTCFG 		0x1A102024
#define REG_INTSTA 		0x1A102028

//Status register values
#define WRITE_OP		0x00000122
#define READ_OP			0x00000121

//Response frame sizes
#define R1				1
#define R3				5
#define R7				5

//Register values
#define CLK_DIV_INIT	0x7c
#define CLK_DIV_DATA	0x1
#define CMD_DATA_LEN	0x00300000 //48 bits
#define BYTE			0x00080000 //8 bits
#define DUT_BUF_LEN		0x00200000 //32 bits


//SD CMDs
#define CMD0			((SDCMD){0x40000000, 0x00950000, R1})
#define CMD8			((SDCMD){0x48000001, 0xAA870000, R7})
#define CMD55			((SDCMD){0x77000000, 0x00650000, R1})
#define ACMD41			((SDCMD){0x69400000, 0x00770000, R1})
#define CMD58			((SDCMD){0x7A000000, 0x00FD0000, R3})
#define CMD16			((SDCMD){0x50000002, 0x00150000, R1})
#define CMD17			((SDCMD){0x51000000, 0x00550000, R1})
#define CMD24			((SDCMD){0x58000000, 0x006F0000, R1})
#define CMD9			((SDCMD){0x49000000, 0x00AF0000, R1})
#define CMD10			((SDCMD){0x4A000000, 0x001B0000, R1})

class	SDSPI_TB : public apb_TB<Vapb_spi_master> {
	SDSPISIM	*m_sdspi;
public:

	unsigned	OCR(void) { return m_sdspi->OCR(); }

	SDSPI_TB(const char *sdcard_image) {
		// {{{
		if (0 != access(sdcard_image, R_OK)) {
			fprintf(stderr, "Cannot open %s for reading\n", sdcard_image);
			exit(EXIT_FAILURE);
		} if (0 != access(sdcard_image, W_OK)) {
			fprintf(stderr, "Cannot open %s for writing\n", sdcard_image);
			exit(EXIT_FAILURE);
		}

		m_sdspi = new SDSPISIM(true);
		m_sdspi->load(sdcard_image);
		// }}}
	}

	virtual	void	tick(void) {
		// {{{
		TESTB<Vapb_spi_master>::tick();

		core()->spi_sdi1 = (*m_sdspi)(core()->spi_csn0, core()->spi_clk, core()->spi_sdo0);
		// }}}
	}

	Vapb_spi_master *core(void) {
		return m_core;
	}


	void wait_for_idle(void){
		//Waits for DUT FSM to go idle
		while ((apb_read(REG_STATUS)& 0x1) == 0)
			;
	}


uint64_t sdcmd(SDCMD cmd, bool csn_toggle = true){

		///////////////////////SEND COMMAND/////////////////////////
		apb_write(REG_SPILEN, CMD_DATA_LEN);
		apb_write(REG_TXFIFO, cmd.fifo0);
		apb_write(REG_TXFIFO, cmd.fifo1);
		apb_write(REG_STATUS, WRITE_OP);

		//Waiting for TX
		wait_for_idle();

		///////////////////////READ RESPONSE///////////////////////
		int FRAME = cmd.r_frame;
		unsigned r = 0;
		uint8_t response[FRAME] = {0};
		//Wait for first non-0xFF byte
		do{
			apb_write(REG_SPILEN, BYTE);
			apb_write(REG_STATUS, READ_OP);

			//Waiting for RX
			wait_for_idle();
			r = apb_read(REG_RXFIFO);

		}while((r & 0xFF) == 0xFF);
		response[0] = (r & 0xFF);

		//Append next bytes
		for (int i = 1; i < FRAME; i++) {
			apb_write(REG_SPILEN, BYTE);
			apb_write(REG_STATUS, READ_OP);

			//Waiting for RX
			wait_for_idle();
			r = apb_read(REG_RXFIFO);
			response[i] = (r & 0xFF);
		}

		if (csn_toggle){
			apb_write(REG_STATUS, 0); //CSn toggle
		}

		//DEBUG PRINTS
		/*
		printf("RESPONSE BYTES: [ ");
		for (int i = 0; i < FRAME; i++) {
			printf("%02X ", response[i]);
		}
		printf("]   --->   [ RESPONSE FRAME(%d) ]\n",FRAME);

		*/

		uint64_t resp = 0;
		//Pack the response bytes according to the frame
		for (int i = 0; i < FRAME; i++){
			resp = (resp << 8) | response[i];
		}
		return resp;

	}

void read(SDCMD cmd, int ln, unsigned *data) {

	unsigned	len = ln/4;
	uint64_t 	r,token;

	r = sdcmd(cmd,false); //disable CSn toggle
	assert (r == 0);

	//Poll for token 0xFE
	do{
		apb_write(REG_SPILEN, BYTE);
		apb_write(REG_STATUS, READ_OP);

		//Waiting for RX
		wait_for_idle();
		token = apb_read(REG_RXFIFO);

	}while((token & 0xFF) != 0xFE);

	//read the block
	for (int i = 0; i<len; i++){

		apb_write(REG_SPILEN, DUT_BUF_LEN); //32-bit reads
		apb_write(REG_STATUS, READ_OP);

		//Waiting for RX
		wait_for_idle();
		data[i] = apb_read(REG_RXFIFO);

	}

	apb_write(REG_STATUS, 0); //Toggle CSn

}

unsigned blockcrc(int len, char *buf) const {
	//Function to calculate block CRC in write-operation
	unsigned int fill = 0, taps = 0x1021;

	for(int i=0; i<len; i++) {
		fill ^= ((buf[i]&0x0ff) << 8);
		for(int j=0; j<8; j++) {
			if (fill&0x8000)
				fill = (fill<<1)^taps;
			else
				fill <<= 1;
		}
	}
	fill &= 0x0FFFF;
	return fill;
}

void write(SDCMD cmd, unsigned arg, int ln, unsigned *data) {

	unsigned	len = ln/4;
	uint64_t	r;

	r = sdcmd(cmd,false);
	assert(r == 0);

	//send start token
	apb_write(REG_SPILEN, DUT_BUF_LEN);
	apb_write(REG_TXFIFO, 0x000000FE);
	apb_write(REG_STATUS, WRITE_OP);

	//Wait for TX
	wait_for_idle();

	//Start block write
	for (int i = 0; i < len; i++){
		apb_write(REG_SPILEN, DUT_BUF_LEN);
		apb_write(REG_TXFIFO,data[i]);
		apb_write(REG_STATUS, WRITE_OP);

		//wait for tx
		wait_for_idle();
	}

	//Byte reordering for CRC calculation
	uint8_t tx[ln];
	for (int i = 0; i < len; i++) {
		tx[4*i+0] = (data[i] >> 24) & 0xff;
		tx[4*i+1] = (data[i] >> 16) & 0xff;
		tx[4*i+2] = (data[i] >>  8) & 0xff;
		tx[4*i+3] = (data[i] >>  0) & 0xff;
	}

	//Calculate CRC
	unsigned crc = blockcrc(ln, (char *)tx);
	printf("CALCULATED CRC: 0x%04X\n",crc);
	apb_write(REG_TXFIFO,(((unsigned) crc << 16 | 0xFFFF)));
	apb_write(REG_STATUS, WRITE_OP);

	//wait for tx
	wait_for_idle();
	apb_write(REG_STATUS, 0); //Toggle CSn

}
	////////////////////////////////////////////////////////////////////////


	uint64_t read_ocr(void) {
		// {{{
		unsigned	r;
		r = sdcmd(CMD58);
		TBASSERT((*this),(r & 0) == 0);
		//fprintf(stderr, "R:   0x%08x\nOCR: 0x%08x\n", r, m_sdspi->OCR());
		TBASSERT((*this), (r == m_sdspi->OCR()));
		return r;
		// }}}
	}

void read_csd(unsigned *data) {
		// {{{
		read(CMD9, 16, data);

		for(int k=0; k<4; k++)
			printf("CSD[%d] = 0x%08x\n", k, data[k]);

		for(int k=0; k<4; k++) {
			unsigned v;
			v = 0;
#ifdef	OPT_LITTLE_ENDIAN
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CSD(k*4+3-i);
#else
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CSD(k*4+i);
#endif

			TBASSERT((*this), v == data[k]);
		}

		// }}}
	}

void read_cid(unsigned *data) {
		// {{{
		read(CMD10, 16, data);
		for(int k=0; k<4; k++) {
			unsigned v;
			v = 0;
#ifdef	OPT_LITTLE_ENDIAN
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CID(k*4+3-i);
#else
			for(int i=0; i<4; i++)
				v = (v<<8) | m_sdspi->CID(k*4+i);
#endif

			TBASSERT((*this), v == data[k]);
		}
		// }}}
	}

void start_up_cycles(void){

	//10 bytes of 0xFF, CSn = high
	for (int i = 0; i<10; i++){
		apb_write(REG_SPILEN, BYTE);
		apb_write(REG_TXFIFO, 0xFF000000);
		apb_write(REG_STATUS, 0x00000022); //Write op, CSn high
		wait_for_idle();

	}
}


};

int	main(int argc, char **argv) {

	const char	SDIMAGE_FILENAME[] = "sdcard.img";
	const char	VCD_FILENAME[] = "trace.vcd";
	SDSPI_TB	tb(SDIMAGE_FILENAME);
	unsigned	resp;

	unsigned	boot_sector[128], test_sector[128], buf[128];

	tb.opentrace(VCD_FILENAME);
	tb.core()->HRESETn = 0;
	tb.tick();
	tb.core()->HRESETn = 1;
	tb.tick();


	//Initializes apb_spi_master
	tb.apb_write(REG_CLKDIV,CLK_DIV_INIT);

	//Send startup cycles
	tb.start_up_cycles();

	// GO_IDLE
	printf("_________________________________________________________________\n\n");
	printf("[SEND_GO_IDLE]\n\n");
	assert(0x01 == tb.sdcmd(CMD0));

	//SEND_IF_COND
	printf("_________________________________________________________________\n\n");
	printf("[SEND_IF_COND]\n\n");
	assert(0x01AA == (tb.sdcmd(CMD8) & 0xFFFF));

	// Wait for the card to start up
	printf("_________________________________________________________________\n\n");
	printf("[CARD_START_UP]\n\n");
	do {
		assert (0x00 == tb.sdcmd(CMD55));
		resp = tb.sdcmd(ACMD41);
		assert (resp == 0 || resp == 0x01);
	} while(resp == 0x01);


	// Read the OCR register
	printf("_________________________________________________________________\n\n");
	printf("[READ_OCR_REGISTER]\n\n");
	printf("[OCR: 0x%08X]\n", resp = tb.read_ocr());
	assert(resp == tb.OCR());

	//Speed up the interface
	tb.apb_write(REG_CLKDIV,CLK_DIV_DATA);

	// Read the CSD register -> OPTIONAL
	printf("_________________________________________________________________\n\n");
	printf("[READ_CSD_REGISTER]\n\n");
	tb.read_csd(test_sector);
	fprintf(stderr, "Read\n");
	printf("CSD: ");
	for(int k=0; k<4; k++)
		printf("%08x%c", test_sector[k], (k < 3) ? ':':'\n');


	// Read the CID register -> OPTIONAL
	printf("_________________________________________________________________\n\n");
	printf("[READ_CID_REGISTER]\n\n");
	tb.read_cid(test_sector);
	printf("CID: ");
	for(int k=0; k<4; k++)
		printf("%08x%c", test_sector[k], (k < 3) ? ':':'\n');

	// Read the original boot sector
	printf("_________________________________________________________________\n\n");
	printf("[READ_THE_ORIGINAL_BOOT_SECTOR]\n\n");
	tb.read(CMD17, 512, boot_sector);


	// Write random data to the boot sector
	printf("_________________________________________________________________\n\n");
	printf("[WRITE_RANDOM_DATA_TO_BOOT_SECTOR]\n\n");
	for(unsigned k=0; k<128; k++)
		test_sector[k] = rand();
	tb.write(CMD24, 0, 512, test_sector);


	// Read the random data back
	printf("_________________________________________________________________\n\n");
	printf("[READ_RANDOM_DATA_BACK]\n\n");
	tb.read(CMD17, 512, buf);


	// Check that it was correctly written
	printf("_________________________________________________________________\n\n");
	printf("[CHECK_WRITTEN_DATA]\n\n");
	for(unsigned k=0; k<128; k++) {
	fprintf(stderr, "BUF[%3d] = 0x%08x, TST[%3d] = 0x%08x\n", k, buf[k], k, test_sector[k]);
	}
	for(unsigned k=0; k<128; k++) {
	fprintf(stderr, "BUF[%d] = 0x%08x\n", k, buf[k]);
	fprintf(stderr, "TST[%d] = 0x%08x\n", k, test_sector[k]);
		assert(buf[k] == test_sector[k]);
	}
	printf("\nSUCCESS!\n");

	// Restore the boot sector
	printf("_________________________________________________________________\n\n");
	printf("[RESTORE_BOOT_SECTOR]\n\n");
	tb.write(CMD24, 0, 512, boot_sector);

	// Read it back again
	printf("_________________________________________________________________\n\n");
	printf("[READ_DATA]\n\n");
	tb.read(CMD17, 512, buf);

	// Check that it was properly stored
	printf("_________________________________________________________________\n\n");
	printf("[CHECK_DATA_STORAGE] ---> ");
	for(unsigned k=0; k<128; k++)
		assert(buf[k] == boot_sector[k]);
	printf("SUCCESS!\n");
	printf("_________________________________________________________________\n\n");

};
