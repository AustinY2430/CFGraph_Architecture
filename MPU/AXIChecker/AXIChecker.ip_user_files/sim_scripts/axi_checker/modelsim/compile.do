vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/axi_infrastructure_v1_1_0
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/axi_vip_v1_1_12
vlib modelsim_lib/msim/generic_baseblocks_v2_1_0
vlib modelsim_lib/msim/axi_register_slice_v2_1_26
vlib modelsim_lib/msim/fifo_generator_v13_2_7
vlib modelsim_lib/msim/axi_data_fifo_v2_1_25
vlib modelsim_lib/msim/axi_crossbar_v2_1_27

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xpm modelsim_lib/msim/xpm
vmap axi_infrastructure_v1_1_0 modelsim_lib/msim/axi_infrastructure_v1_1_0
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap axi_vip_v1_1_12 modelsim_lib/msim/axi_vip_v1_1_12
vmap generic_baseblocks_v2_1_0 modelsim_lib/msim/generic_baseblocks_v2_1_0
vmap axi_register_slice_v2_1_26 modelsim_lib/msim/axi_register_slice_v2_1_26
vmap fifo_generator_v13_2_7 modelsim_lib/msim/fifo_generator_v13_2_7
vmap axi_data_fifo_v2_1_25 modelsim_lib/msim/axi_data_fifo_v2_1_25
vmap axi_crossbar_v2_1_27 modelsim_lib/msim/axi_crossbar_v2_1_27

vlog -work xilinx_vip -64 -incr -mfcu -sv -L axi_vip_v1_1_12 -L xilinx_vip "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/clk_vip_if.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm -64 -incr -mfcu -sv -L axi_vip_v1_1_12 -L xilinx_vip "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work axi_infrastructure_v1_1_0 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu -sv -L axi_vip_v1_1_12 -L xilinx_vip "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0_pkg.sv" \

vlog -work axi_vip_v1_1_12 -64 -incr -mfcu -sv -L axi_vip_v1_1_12 -L xilinx_vip "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/1033/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work xil_defaultlib -64 -incr -mfcu -sv -L axi_vip_v1_1_12 -L xilinx_vip "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0.sv" \

vlog -work generic_baseblocks_v2_1_0 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/b752/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_26 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/0a3f/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_7 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_7 -64 -93 \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_7 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_25 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/5390/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_27 -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/3fa0/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib -64 -incr -mfcu "+incdir+../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl" "+incdir+/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/include" \
"../../../bd/axi_checker/ip/axi_checker_axi_crossbar_0_0/sim/axi_checker_axi_crossbar_0_0.v" \
"../../../bd/axi_checker/ipshared/7913/rd_engine.v" \
"../../../bd/axi_checker/ipshared/7913/wr_engine.v" \
"../../../bd/axi_checker/ipshared/7913/axi_engine.v" \
"../../../bd/axi_checker/ip/axi_checker_axi_engine_0_0/sim/axi_checker_axi_engine_0_0.v" \
"../../../bd/axi_checker/ip/axi_checker_axi_engine_0_1/sim/axi_checker_axi_engine_0_1.v" \
"../../../bd/axi_checker/sim/axi_checker.v" \

vlog -work xil_defaultlib \
"glbl.v"

