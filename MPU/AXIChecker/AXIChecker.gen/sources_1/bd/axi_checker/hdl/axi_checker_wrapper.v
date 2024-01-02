//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (lin64) Build 3526262 Mon Apr 18 15:47:01 MDT 2022
//Date        : Thu Dec 21 15:06:45 2023
//Host        : COE-CS-crystal running 64-bit Ubuntu 22.04.3 LTS
//Command     : generate_target axi_checker_wrapper.bd
//Design      : axi_checker_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module axi_checker_wrapper
   (MPU_VMU_FIFO_Empty,
    MPU_VMU_FIFO_Full,
    MPU_VMU_FIFO_Read,
    MPU_VMU_FIFO_ReadData,
    MPU_VMU_FIFO_Read_Valid,
    MPU_VMU_FIFO_Write,
    MPU_VMU_FIFO_WriteData,
    Message_FIFO_Empty,
    Message_FIFO_Full,
    Message_FIFO_Read,
    Message_FIFO_ReadData,
    Message_FIFO_Read_Valid,
    Message_FIFO_Write,
    Message_FIFO_WriteData,
    VMU_to_MGU_FIFO_A_Empty,
    VMU_to_MGU_FIFO_A_Full,
    VMU_to_MGU_FIFO_A_Read,
    VMU_to_MGU_FIFO_A_ReadData,
    VMU_to_MGU_FIFO_A_Read_Valid,
    VMU_to_MGU_FIFO_A_Write,
    VMU_to_MGU_FIFO_A_WriteData,
    VMU_to_MGU_FIFO_B_Empty,
    VMU_to_MGU_FIFO_B_Full,
    VMU_to_MGU_FIFO_B_Read,
    VMU_to_MGU_FIFO_B_ReadData,
    VMU_to_MGU_FIFO_B_Read_Valid,
    VMU_to_MGU_FIFO_B_Write,
    VMU_to_MGU_FIFO_B_WriteData,
    WrEnable_a,
    addr_a,
    clk_100MHz,
    din_a,
    dout_a,
    enable_a,
    end_rd,
    end_rd_edge,
    end_wr,
    end_wr_edge,
    rburst,
    rburst_edge,
    read_addr,
    read_addr_edge,
    read_data,
    read_data_edge,
    reset,
    resetn,
    start_rd,
    start_rd_edge,
    start_wr,
    start_wr_edge,
    wburst,
    wburst_edge,
    write_addr,
    write_addr_edge,
    write_data,
    write_data_edge);
  output MPU_VMU_FIFO_Empty;
  output MPU_VMU_FIFO_Full;
  input MPU_VMU_FIFO_Read;
  output [32:0]MPU_VMU_FIFO_ReadData;
  output MPU_VMU_FIFO_Read_Valid;
  input MPU_VMU_FIFO_Write;
  input [32:0]MPU_VMU_FIFO_WriteData;
  output Message_FIFO_Empty;
  output Message_FIFO_Full;
  input Message_FIFO_Read;
  output [63:0]Message_FIFO_ReadData;
  output Message_FIFO_Read_Valid;
  input Message_FIFO_Write;
  input [63:0]Message_FIFO_WriteData;
  output VMU_to_MGU_FIFO_A_Empty;
  output VMU_to_MGU_FIFO_A_Full;
  input VMU_to_MGU_FIFO_A_Read;
  output [93:0]VMU_to_MGU_FIFO_A_ReadData;
  output VMU_to_MGU_FIFO_A_Read_Valid;
  input VMU_to_MGU_FIFO_A_Write;
  input [93:0]VMU_to_MGU_FIFO_A_WriteData;
  output VMU_to_MGU_FIFO_B_Empty;
  output VMU_to_MGU_FIFO_B_Full;
  input VMU_to_MGU_FIFO_B_Read;
  output [93:0]VMU_to_MGU_FIFO_B_ReadData;
  output VMU_to_MGU_FIFO_B_Read_Valid;
  input VMU_to_MGU_FIFO_B_Write;
  input [93:0]VMU_to_MGU_FIFO_B_WriteData;
  input WrEnable_a;
  input [12:0]addr_a;
  input clk_100MHz;
  input [71:0]din_a;
  output [71:0]dout_a;
  input enable_a;
  output end_rd;
  output end_rd_edge;
  output end_wr;
  output end_wr_edge;
  input [7:0]rburst;
  input [7:0]rburst_edge;
  input [32:0]read_addr;
  input [32:0]read_addr_edge;
  output [255:0]read_data;
  output [511:0]read_data_edge;
  input reset;
  input resetn;
  input start_rd;
  input start_rd_edge;
  input start_wr;
  input start_wr_edge;
  input [7:0]wburst;
  input [7:0]wburst_edge;
  input [32:0]write_addr;
  input [32:0]write_addr_edge;
  input [255:0]write_data;
  input [511:0]write_data_edge;

  wire MPU_VMU_FIFO_Empty;
  wire MPU_VMU_FIFO_Full;
  wire MPU_VMU_FIFO_Read;
  wire [32:0]MPU_VMU_FIFO_ReadData;
  wire MPU_VMU_FIFO_Read_Valid;
  wire MPU_VMU_FIFO_Write;
  wire [32:0]MPU_VMU_FIFO_WriteData;
  wire Message_FIFO_Empty;
  wire Message_FIFO_Full;
  wire Message_FIFO_Read;
  wire [63:0]Message_FIFO_ReadData;
  wire Message_FIFO_Read_Valid;
  wire Message_FIFO_Write;
  wire [63:0]Message_FIFO_WriteData;
  wire VMU_to_MGU_FIFO_A_Empty;
  wire VMU_to_MGU_FIFO_A_Full;
  wire VMU_to_MGU_FIFO_A_Read;
  wire [93:0]VMU_to_MGU_FIFO_A_ReadData;
  wire VMU_to_MGU_FIFO_A_Read_Valid;
  wire VMU_to_MGU_FIFO_A_Write;
  wire [93:0]VMU_to_MGU_FIFO_A_WriteData;
  wire VMU_to_MGU_FIFO_B_Empty;
  wire VMU_to_MGU_FIFO_B_Full;
  wire VMU_to_MGU_FIFO_B_Read;
  wire [93:0]VMU_to_MGU_FIFO_B_ReadData;
  wire VMU_to_MGU_FIFO_B_Read_Valid;
  wire VMU_to_MGU_FIFO_B_Write;
  wire [93:0]VMU_to_MGU_FIFO_B_WriteData;
  wire WrEnable_a;
  wire [12:0]addr_a;
  wire clk_100MHz;
  wire [71:0]din_a;
  wire [71:0]dout_a;
  wire enable_a;
  wire end_rd;
  wire end_rd_edge;
  wire end_wr;
  wire end_wr_edge;
  wire [7:0]rburst;
  wire [7:0]rburst_edge;
  wire [32:0]read_addr;
  wire [32:0]read_addr_edge;
  wire [255:0]read_data;
  wire [511:0]read_data_edge;
  wire reset;
  wire resetn;
  wire start_rd;
  wire start_rd_edge;
  wire start_wr;
  wire start_wr_edge;
  wire [7:0]wburst;
  wire [7:0]wburst_edge;
  wire [32:0]write_addr;
  wire [32:0]write_addr_edge;
  wire [255:0]write_data;
  wire [511:0]write_data_edge;

  axi_checker axi_checker_i
       (.MPU_VMU_FIFO_Empty(MPU_VMU_FIFO_Empty),
        .MPU_VMU_FIFO_Full(MPU_VMU_FIFO_Full),
        .MPU_VMU_FIFO_Read(MPU_VMU_FIFO_Read),
        .MPU_VMU_FIFO_ReadData(MPU_VMU_FIFO_ReadData),
        .MPU_VMU_FIFO_Read_Valid(MPU_VMU_FIFO_Read_Valid),
        .MPU_VMU_FIFO_Write(MPU_VMU_FIFO_Write),
        .MPU_VMU_FIFO_WriteData(MPU_VMU_FIFO_WriteData),
        .Message_FIFO_Empty(Message_FIFO_Empty),
        .Message_FIFO_Full(Message_FIFO_Full),
        .Message_FIFO_Read(Message_FIFO_Read),
        .Message_FIFO_ReadData(Message_FIFO_ReadData),
        .Message_FIFO_Read_Valid(Message_FIFO_Read_Valid),
        .Message_FIFO_Write(Message_FIFO_Write),
        .Message_FIFO_WriteData(Message_FIFO_WriteData),
        .VMU_to_MGU_FIFO_A_Empty(VMU_to_MGU_FIFO_A_Empty),
        .VMU_to_MGU_FIFO_A_Full(VMU_to_MGU_FIFO_A_Full),
        .VMU_to_MGU_FIFO_A_Read(VMU_to_MGU_FIFO_A_Read),
        .VMU_to_MGU_FIFO_A_ReadData(VMU_to_MGU_FIFO_A_ReadData),
        .VMU_to_MGU_FIFO_A_Read_Valid(VMU_to_MGU_FIFO_A_Read_Valid),
        .VMU_to_MGU_FIFO_A_Write(VMU_to_MGU_FIFO_A_Write),
        .VMU_to_MGU_FIFO_A_WriteData(VMU_to_MGU_FIFO_A_WriteData),
        .VMU_to_MGU_FIFO_B_Empty(VMU_to_MGU_FIFO_B_Empty),
        .VMU_to_MGU_FIFO_B_Full(VMU_to_MGU_FIFO_B_Full),
        .VMU_to_MGU_FIFO_B_Read(VMU_to_MGU_FIFO_B_Read),
        .VMU_to_MGU_FIFO_B_ReadData(VMU_to_MGU_FIFO_B_ReadData),
        .VMU_to_MGU_FIFO_B_Read_Valid(VMU_to_MGU_FIFO_B_Read_Valid),
        .VMU_to_MGU_FIFO_B_Write(VMU_to_MGU_FIFO_B_Write),
        .VMU_to_MGU_FIFO_B_WriteData(VMU_to_MGU_FIFO_B_WriteData),
        .WrEnable_a(WrEnable_a),
        .addr_a(addr_a),
        .clk_100MHz(clk_100MHz),
        .din_a(din_a),
        .dout_a(dout_a),
        .enable_a(enable_a),
        .end_rd(end_rd),
        .end_rd_edge(end_rd_edge),
        .end_wr(end_wr),
        .end_wr_edge(end_wr_edge),
        .rburst(rburst),
        .rburst_edge(rburst_edge),
        .read_addr(read_addr),
        .read_addr_edge(read_addr_edge),
        .read_data(read_data),
        .read_data_edge(read_data_edge),
        .reset(reset),
        .resetn(resetn),
        .start_rd(start_rd),
        .start_rd_edge(start_rd_edge),
        .start_wr(start_wr),
        .start_wr_edge(start_wr_edge),
        .wburst(wburst),
        .wburst_edge(wburst_edge),
        .write_addr(write_addr),
        .write_addr_edge(write_addr_edge),
        .write_data(write_data),
        .write_data_edge(write_data_edge));
endmodule
