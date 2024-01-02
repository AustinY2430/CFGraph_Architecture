vlib work
vlib activehdl

vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/xil_defaultlib
vlib activehdl/axi_vip_v1_1_12
vlib activehdl/blk_mem_gen_v8_4_5
vlib activehdl/fifo_generator_v13_2_7

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap xil_defaultlib activehdl/xil_defaultlib
vmap axi_vip_v1_1_12 activehdl/axi_vip_v1_1_12
vmap blk_mem_gen_v8_4_5 activehdl/blk_mem_gen_v8_4_5
vmap fifo_generator_v13_2_7 activehdl/fifo_generator_v13_2_7

vlog -work xilinx_vip  -sv2k12 "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/clk_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0_pkg.sv" \

vlog -work axi_vip_v1_1_12  -sv2k12 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/1033/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0.sv" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_1_0/sim/axi_checker_axi_vip_1_0_pkg.sv" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_1_0/sim/axi_checker_axi_vip_1_0.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ipshared/40fd/rd_engine.v" \
"../../../bd/axi_checker/ipshared/40fd/wr_engine.v" \
"../../../bd/axi_checker/ipshared/40fd/axi_engine.v" \
"../../../bd/axi_checker/ip/axi_checker_AXI_Engine_0_2/sim/axi_checker_AXI_Engine_0_2.v" \
"../../../bd/axi_checker/ip/axi_checker_AXI_Engine_1_1/sim/axi_checker_AXI_Engine_1_1.v" \

vlog -work blk_mem_gen_v8_4_5  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_blk_mem_gen_0_0/sim/axi_checker_blk_mem_gen_0_0.v" \

vlog -work fifo_generator_v13_2_7  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_7 -93 \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_7  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_0/sim/axi_checker_fifo_generator_0_0.v" \
"../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_1/sim/axi_checker_fifo_generator_0_1.v" \
"../../../bd/axi_checker/ip/axi_checker_fifo_generator_1_0/sim/axi_checker_fifo_generator_1_0.v" \
"../../../bd/axi_checker/sim/axi_checker.v" \
"../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_2/sim/axi_checker_fifo_generator_0_2.v" \

vlog -work xil_defaultlib \
"glbl.v"

