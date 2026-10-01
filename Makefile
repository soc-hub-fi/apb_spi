.PHONY: sv_tb cpp_tb sim_cpp

sv_tb: 
	$(MAKE) -C bench/tb_systemverilog \
	cleanv \
	image \
	verilate \
	simv

# cpp_tb:
# 	$(MAKE) -C rtl rtl \
# 
# 
# sim_cpp:
# 	$(MAKE) -C rtl/obj_dir -f Vapb_spi_master.mk \
# 	
# do_cpp:
# 	$(MAKE) -C bench/cpp sdcard.img \
# 
# 1: 
# 	$(MAKE) -C bench/cpp \
# 
# sim:
# 	./bench/cpp/tb_sdspi \
# 
