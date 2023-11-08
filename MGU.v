`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: MGU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//Updated to match Austin nomincalture
//NOTE: parameters do not control memory shapes (must be remade with vivado IP tool)
parameter VertexWidth  = 16,  // Vertex Value Width (value that gets changed)
parameter VertexStart  = 64,  // Vertex value location of first bit in memory (value that gets changed) Ex: 128 bit vertex in memory 95:64 is vertex value that needs to be checked so start is 64
parameter AddrWidth    = 33,  // 33 = 8GB Memory
parameter DataWidth    = 256, // HBM data width
parameter MessageWidth = 64,   // Ouput message width 
parameter vertexWidth  = 96,   //

parameter integer C_M_AXI_THREAD_ID_WIDTH       = 1,
parameter integer C_M_AXI_ADDR_WIDTH            = 32,
parameter integer C_M_AXI_DATA_WIDTH            = 512,
parameter integer C_M_AXI_AWUSER_WIDTH          = 1,
parameter integer C_M_AXI_ARUSER_WIDTH          = 1,
parameter integer C_M_AXI_WUSER_WIDTH           = 1,
parameter integer C_M_AXI_RUSER_WIDTH           = 1,
parameter integer C_M_AXI_BUSER_WIDTH           = 1,
// Base address of targeted slave
parameter C_M_AXI_TARGET = 'h00000000,
// Number of address bits to test before wrapping   
parameter integer C_OFFSET_WIDTH = 9,
/* Burst length for transactions, in C_M_AXI_DATA_WIDTHs.
Non-2^n lengths will eventually cause bursts across 4K
address boundaries.*/
parameter integer C_M_AXI_BURST_LEN = 16
			 
// DECODE MESSAGE (Default)
// 63:31 Vertex Address
// 30:29 Reduction Engine Control
// 28:0 Vertex Update
	
// Vertex structure
// 95:64 Property
// 63:32 Edge location
// 31:0  Edge Degree	
`define VERTEXPROPERTYRANGE 95:64
`define VERTEXPROPERTYWIDTH 32	
`define VERTEXEDGELOCATIONRANGE 63:32
`define VERTEXEDGELOCATIONWIDTH 32	
`define VERTEXEDGEDEGREERANGE 31:0
`define VERTEXEDGEDEGREEWIDTH 32		 
`define MAXEDGEBURST 32		 
		 
module MGU(
    output [MessageWidth-1:0] messageOut,
    input [vertexWidth-1:0] vertexIn,
    input vertexInValid,
    output vertexReq,
    input clk,
    input resetN,
    // Master Interface Read Address
    output [C_M_AXI_THREAD_ID_WIDTH-1:0] 	 M_AXI_ARID,
    output [C_M_AXI_ADDR_WIDTH-1:0] 	 M_AXI_ARADDR,
    output [8-1:0] 			 M_AXI_ARLEN,
    output [3-1:0] 			 M_AXI_ARSIZE,
    output [2-1:0] 			 M_AXI_ARBURST,
    output [2-1:0] 			 M_AXI_ARLOCK,
    output [4-1:0] 			 M_AXI_ARCACHE,
    output [3-1:0] 			 M_AXI_ARPROT,
    // AXI3 output wire [4-1:0] 		 M_AXI_ARREGION,
    output [4-1:0] 			 M_AXI_ARQOS,
    output [C_M_AXI_ARUSER_WIDTH-1:0] 	 M_AXI_ARUSER,
    output  				 M_AXI_ARVALID,
    input   				 M_AXI_ARREADY,
    
    // Master Interface Read Data 
    input  [C_M_AXI_THREAD_ID_WIDTH-1:0] 	 M_AXI_RID,
    input  [C_M_AXI_DATA_WIDTH-1:0] 	 M_AXI_RDATA,
    input  [2-1:0] 			 M_AXI_RRESP,
    input   				 M_AXI_RLAST,
    input   [C_M_AXI_RUSER_WIDTH-1:0] 	 M_AXI_RUSER,
    input   				 M_AXI_RVALID,
    output  				 M_AXI_RREADY
    );

   wire vertexFifoFull;
   wire vertexReq = ~vertexFifoFull;
   wire vertexFifoValid;
  

   reg [2:0] readEngineState;
   localparam [2:0]
     REIDLE = 3'b000,
     REREADVERTEX = 3'b001,
     REBUFFERAXICOMMANDS = 3'b002;
   


   
//Memory instantiations

 MGUVertexFIFO vertexInputBuffer (
  .clk(clk),      // input wire clk
  .srst(resetN),    // input wire srst
  .din(vertexIn),      // input wire [95 : 0] din
  .wr_en(vertexInValid),  // input wire wr_en
  .rd_en(),  // input wire rd_en
  .dout(vertexOut),    // output wire [95 : 0] dout
  .full(vertexBufferFull),    // output wire full
  .empty(vertexBufferEmpty),  // output wire empty
  .valid(vertexBufferValid)  // output wire valid
);

MGUMessageOutFIFO messageOutBuffer (
  .clk(clk),                // input wire clk
  .srst(resetN),              // input wire srst
  .din(egressMessageData),                // input wire [63 : 0] din
  .wr_en(egressMessageWrite),            // input wire wr_en
  .rd_en(),            // input wire rd_en
  .dout(messageOut),              // output wire [63 : 0] dout
  .full(messageOutBufferFull),              // output wire full
  .empty(),            // output wire empty
  .data_count(messageOutBufferDatadCount)  // output wire [9 : 0] data_count
);


axiCommandFifo edgeReadsBuffer (
  .clk(clk),      // input wire clk
  .srst(resetN),    // input wire srst
  .din(edgeReadsBufferDin),      // input wire [39 : 0] din
  .wr_en(edgeReadsBufferWrite),  // input wire wr_en
  .rd_en(edgeReadsBufferRead),  // input wire rd_en
  .dout(edgeReadsBufferDout),    // output wire [39 : 0] dout
  .full(edgeReadsBufferFull),    // output wire full
  .empty(edgeReadsBufferEmpty)  // output wire empty
);

	   
endmodule
