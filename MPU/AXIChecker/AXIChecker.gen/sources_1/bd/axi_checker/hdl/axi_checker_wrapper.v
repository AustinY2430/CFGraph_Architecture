//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (lin64) Build 3526262 Mon Apr 18 15:47:01 MDT 2022
//Date        : Wed Nov  8 14:22:43 2023
//Host        : crystal running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target axi_checker_wrapper.bd
//Design      : axi_checker_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module axi_checker_wrapper
   (clk_100MHz,
    d_end_rd,
    d_end_wr,
    d_read_addr,
    d_read_data,
    d_start_rd,
    d_start_wr,
    d_write_addr,
    d_write_data,
    end_rd,
    end_wr,
    read_addr,
    read_data,
    resetn,
    start_rd,
    start_wr,
    write_addr,
    write_data);
  input clk_100MHz;
  output d_end_rd;
  output d_end_wr;
  input [32:0]d_read_addr;
  output [255:0]d_read_data;
  input d_start_rd;
  input d_start_wr;
  input [32:0]d_write_addr;
  input [255:0]d_write_data;
  output end_rd;
  output end_wr;
  input [32:0]read_addr;
  output [255:0]read_data;
  input resetn;
  input start_rd;
  input start_wr;
  input [32:0]write_addr;
  input [255:0]write_data;

  wire clk_100MHz;
  wire d_end_rd;
  wire d_end_wr;
  wire [32:0]d_read_addr;
  wire [255:0]d_read_data;
  wire d_start_rd;
  wire d_start_wr;
  wire [32:0]d_write_addr;
  wire [255:0]d_write_data;
  wire end_rd;
  wire end_wr;
  wire [32:0]read_addr;
  wire [255:0]read_data;
  wire resetn;
  wire start_rd;
  wire start_wr;
  wire [32:0]write_addr;
  wire [255:0]write_data;

  axi_checker axi_checker_i
       (.clk_100MHz(clk_100MHz),
        .d_end_rd(d_end_rd),
        .d_end_wr(d_end_wr),
        .d_read_addr(d_read_addr),
        .d_read_data(d_read_data),
        .d_start_rd(d_start_rd),
        .d_start_wr(d_start_wr),
        .d_write_addr(d_write_addr),
        .d_write_data(d_write_data),
        .end_rd(end_rd),
        .end_wr(end_wr),
        .read_addr(read_addr),
        .read_data(read_data),
        .resetn(resetn),
        .start_rd(start_rd),
        .start_wr(start_wr),
        .write_addr(write_addr),
        .write_data(write_data));
endmodule
