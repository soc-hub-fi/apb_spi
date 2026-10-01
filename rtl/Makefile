##Makefile for the modified tb_sdspi

.PHONY: all rtl clean

VERILATOR := verilator
VOBJ      := obj_dir

VFLAGS := -Wall -trace -cc -MMD -Wno-fatal

RTL_FILES := \
	apb_spi_master.sv \
	axi_spi_master.sv \
	spi_master_axi_if.sv \
	spi_master_clkgen.sv \
	spi_master_controller.sv \
	spi_master_fifo.sv \
	spi_master_rx.sv \
	spi_master_tx.sv 
	

all: rtl

rtl: $(VOBJ)/Vapb_spi_master.h

$(VOBJ)/Vapb_spi_master.h: $(RTL_FILES)
	$(VERILATOR) $(VFLAGS) \
	    -top-module apb_spi_master \
	    $(RTL_FILES)

clean:
	rm -rf $(VOBJ)