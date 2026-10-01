#!/bin/bash
clear
printf "Started compiling\n\n"
make clean
make rtl
cd obj_dir && make -f Vapb_spi_master.mk
printf "\nVerilator archive created!\n\n"
cd ../../bench/cpp
if [[ ! -f "sdcard.img" ]]; then
   make sdcard.img
   printf "\nSD-card image created!\n\n"
fi
make clean
make
printf "\nStarting simulation:\n\n"
./tb_sdspi