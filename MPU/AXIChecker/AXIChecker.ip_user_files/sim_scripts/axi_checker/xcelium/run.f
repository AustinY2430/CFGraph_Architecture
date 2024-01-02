-makelib xcelium_lib/xilinx_vip -sv \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/axi_vip_if.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/clk_vip_if.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/xilinx_vip/hdl/rst_vip_if.sv" \
-endlib
-makelib xcelium_lib/xpm -sv \
  "/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/home/austin01/Xilinx/Vivado/2022.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/axi_infrastructure_v1_1_0 \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0_pkg.sv" \
-endlib
-makelib xcelium_lib/axi_vip_v1_1_12 -sv \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/1033/hdl/axi_vip_v1_1_vl_rfs.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib -sv \
  "../../../bd/axi_checker/ip/axi_checker_axi_vip_0_0/sim/axi_checker_axi_vip_0_0.sv" \
  "../../../bd/axi_checker/ip/axi_checker_axi_vip_1_0/sim/axi_checker_axi_vip_1_0_pkg.sv" \
  "../../../bd/axi_checker/ip/axi_checker_axi_vip_1_0/sim/axi_checker_axi_vip_1_0.sv" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/axi_checker/ipshared/40fd/rd_engine.v" \
  "../../../bd/axi_checker/ipshared/40fd/wr_engine.v" \
  "../../../bd/axi_checker/ipshared/40fd/axi_engine.v" \
  "../../../bd/axi_checker/ip/axi_checker_AXI_Engine_0_2/sim/axi_checker_AXI_Engine_0_2.v" \
  "../../../bd/axi_checker/ip/axi_checker_AXI_Engine_1_1/sim/axi_checker_AXI_Engine_1_1.v" \
-endlib
-makelib xcelium_lib/blk_mem_gen_v8_4_5 \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/axi_checker/ip/axi_checker_blk_mem_gen_0_0/sim/axi_checker_blk_mem_gen_0_0.v" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/simulation/fifo_generator_vlog_beh.v" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.vhd" \
-endlib
-makelib xcelium_lib/fifo_generator_v13_2_7 \
  "../../../../AXIChecker.gen/sources_1/bd/axi_checker/ipshared/83df/hdl/fifo_generator_v13_2_rfs.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_0/sim/axi_checker_fifo_generator_0_0.v" \
  "../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_1/sim/axi_checker_fifo_generator_0_1.v" \
  "../../../bd/axi_checker/ip/axi_checker_fifo_generator_1_0/sim/axi_checker_fifo_generator_1_0.v" \
  "../../../bd/axi_checker/sim/axi_checker.v" \
  "../../../bd/axi_checker/ip/axi_checker_fifo_generator_0_2/sim/axi_checker_fifo_generator_0_2.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

