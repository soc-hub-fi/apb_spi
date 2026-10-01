##Makefile for new tb_sdspi

.PHONY: all clean
all:
CXX:= g++
OBJDIR := obj-pc
RTLD   := ../../rtl
ifeq ($(VERILATOR_ROOT),)
VERILATOR := verilator
VERILATOR_ROOT ?= $(shell bash -c '$(VERILATOR) -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
else
VERILATOR := $(VERILATOR_ROOT)/bin/verilator
endif
export $(VERILATOR)
VROOT := $(VERILATOR_ROOT)
VINCD := $(VERILATOR_ROOT)/include
INCS   := -I $(VINCD) -I $(VINCD)/vlstd -I $(RTLD)/obj_dir
CFLAGS  := -O3
PROGRAMS := tb_sdspi
all: $(PROGRAMS)

SOURCES := tb_sdspi.cpp sdspisim.cpp
HEADERS := sdspisim.h apb_tb.h testb.h
OBJECTS := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(SOURCES)))
VLSRCS  := verilated.cpp verilated_vcd_c.cpp verilated_threads.cpp
VLOBJS  := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(VLSRCS)))
VLIBS   := $(RTLD)/obj_dir/Vapb_spi_master__ALL.a

## Build patterns: .cpp to .o
## {{{
$(OBJDIR)/%.o: %.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VROOT)/include/%.cpp
	$(mk-objdir)
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@
## }}}

## tb_sdspi
## {{{
tb_sdspi: $(OBJECTS) $(VLIBS) $(VLOBJS)
		$(CXX) -no-pie $(CFLAGS) $(OBJECTS) $(VLIBS) $(VLOBJS) -lpthread -o $@
## }}}

sdcard.img:
	dd if=/dev/zero of=sdcard.img bs=512 count=131072
	mkfs.fat -F 16 sdcard.img

## test
## {{{
test: tb_sdspi sdcard.img
	./tb_sdspi
## }}}

define	mk-objdir
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR)/; fi"
endef

tags: $(SOURCES) $(HEADERS)
	@ctags $(SOURCES)

.PHONY: clean
## {{{
clean:
	rm -rf $(OBJDIR)/ $(PROGRAMS)
	rm -f *.vcd
## }}}
## Dependency handling
## {{{
define	build-depends
	@echo "Building dependencies"
	$(mk-objdir)
	@$(CXX) $(CPPFLAGS) $(INCS) -MM zipcpu_tb.cpp $(VLIB) $(SOURCES) > $(OBJDIR)/xdepends.txt
	@sed -e 's/^.*.o: /$(OBJDIR)\/&/' < $(OBJDIR)/xdepends.txt > $(OBJDIR)/depeends.txt
	@rm $(OBJDIR)/xdepends.txt
endef

.PHONY: depends
depends: tags $(OBJDIR)/
	$(build-depends)

-include $(OBJDIR)/depends.txt
## }}}



