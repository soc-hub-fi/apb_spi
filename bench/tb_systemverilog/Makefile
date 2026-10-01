BUILD_DIR       = $(realpath $(CURDIR))/build
VERIL_BUILD_DIR = $(BUILD_DIR)/verilator_build
TOP_MODULE = tb_apb_spi

BENDER_TARGETS = \
	-t verilator \

WAIVER = ./verilator/waiver.vlt
# runs a GNU shell command: generates simulator file list (flist-plus) which includes source files, include directories and compiler options, (script) tells bender to generate a script or file list. 
SRC_FILES          = $(shell bender script $(BENDER_FLAGS) flist-plus $(BENDER_TARGETS)) 

VDEFS = \
	+define+VERILATOR=1 \

# enables timing construct support in RTL i.e. delays and such.
# waveform tracing generated in fst format (supported by gtkwave)
# for structs, enables struct variables/logic/signals to be seen in waveform
# Shows parameter values in waveform
# Hierarchical verilation design is processed in a modular way (not too beneficial here, more beneficial for large rtl)
# compiles the generated C++ model
# enables loop unrolling for performance, sets maximum limit to 256
# creates build directory
# build is done using all cpu cores \nproc returns number of available cores


#Create SD-card image
.PHONY:
image:
	dd if=/dev/zero of=sdcard.img bs=512 count=131072
	mkfs.fat -F 16 sdcard.img

VFLAGS = \
	--timing \
	--trace-fst \
	--build-jobs 0 \
	--trace-structs \
	--trace-params \
	--hierarchical \
	--build \
	--unroll-count 256 \
	--Mdir $(VERIL_BUILD_DIR) \

.PHONY: 
all: lint verilate simv \

# --lint-only runs verilator as a linter
# --timing enables timing construct support
# --top-module sets top module as tb_apb_spi



.PHONY: lint
lint:
	verilator \
	--sv \
	--lint-only \
	--timing \
	$(WAIVER) \
	--top-module $(TOP_MODULE) \
	$(SRC_FILES) \

.PHONY: _init
_init:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(VERIL_BUILD_DIR)

# --binary Parses .v & .sv files, generates C++ simulation model, Compiles C++ code, links everything into an executbale.
# WAIVER: lints warning expressions are called waivers, a way to tell verilator that warnings are known and reporting can be skipped on them
.PHONY: verilate
verilate: _init
	verilator \
	--binary \
	$(VDEFS) \
	$(VFLAGS) \
	$(WAIVER) \
	--top-module $(TOP_MODULE) \
	$(SRC_FILES) \

.PHONY: simv
simv:
	@$(VERIL_BUILD_DIR)/V$(TOP_MODULE)

.PHONY: cleanv
cleanv:
	rm -rf $(VERIL_BUILD_DIR)

