onbreak {quit -force}
onerror {quit -force}

asim +access +r +m+axi_checker -L xilinx_vip -L xpm -L axi_infrastructure_v1_1_0 -L xil_defaultlib -L axi_vip_v1_1_12 -L blk_mem_gen_v8_4_5 -L fifo_generator_v13_2_7 -L xilinx_vip -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.axi_checker xil_defaultlib.glbl

set NumericStdNoWarnings 1
set StdArithNoWarnings 1

do {wave.do}

view wave
view structure

do {axi_checker.udo}

run -all

endsim

quit -force
