`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2023 01:01:11 PM
// Design Name: 
// Module Name: tb_top
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
import axi_vip_pkg::*;
import axi_checker_axi_vip_0_0_pkg::*;
import axi_checker_axi_vip_1_0_pkg::*;

module tb_top();

parameter VERTEX_DATAWIDTH = 128*2;
parameter EDGE_DATAWIDTH = 64*8;
int num_vertices_written;
int num_edges_written;
int thousand_cycles;
int file;
int vertex_axi_writes;
int vertex_axi_reads;
int edge_axi_reads;
int no_more_reads;
int max_MSG;
int max_MPU_to_MGU;
int updated_vertex;

reg [71:0] RAM_din_a_init;
reg WrEnable_a_init;
reg [12:0] RAM_address_a_init;

reg clk;
reg resetn;
wire reset;
assign reset = ~resetn;

// Axi engine signals
reg start_rd_v, start_wr_v, start_rd_e, start_wr_e;
reg end_rd_v, end_wr_v, end_rd_e, end_wr_e;
reg   [32:0] raddr_v, waddr_v, raddr_e, waddr_e;
reg  [VERTEX_DATAWIDTH-1:0] rdata_v, wdata_v;
reg  [EDGE_DATAWIDTH-1:0] rdata_e, wdata_e;

// Driver axi signals ---------------------
// Driver is using axi engine 
reg         vertex_axi_in_use;
reg         edge_axi_in_use;
reg  [63:0] first_message;
// Read Vertex
reg         D_read_v;
reg  [32:0] D_raddr_v;
reg [VERTEX_DATAWIDTH-1:0] D_rdata_v;
reg         D_end_read_v;
// Write Vertex
reg         D_write_v;
reg  [32:0] D_waddr_v;
reg [VERTEX_DATAWIDTH-1:0] D_wdata_v;
reg         D_end_write_v;
// Read Edge
reg         D_read_e;
reg  [32:0] D_raddr_e;
reg [EDGE_DATAWIDTH-1:0] D_rdata_e;
reg         D_end_read_e;
// Write Edge
reg         D_write_e;
reg  [32:0] D_waddr_e;
reg [EDGE_DATAWIDTH-1:0] D_wdata_e;
reg         D_end_write_e;

// MPU axi signals -----------------------
// Read Vertex
reg         MPU_read;
reg  [32:0] MPU_raddr;
wire  [7:0] MPU_rburst;
reg [VERTEX_DATAWIDTH-1:0] MPU_rdata;
reg         MPU_end_read;
// Write Vertex
reg         MPU_write;
reg  [32:0] MPU_waddr;
wire  [7:0] MPU_wburst;
reg [VERTEX_DATAWIDTH-1:0] MPU_wdata;
reg         MPU_end_write;

// VMU axi signals ------------------------
reg         VMU_read;
reg  [32:0] VMU_raddr;
reg [VERTEX_DATAWIDTH-1:0] VMU_rdata;
reg         VMU_end_read;
wire  [7:0] VMU_rburst;
wire        vmu_using_axi;
wire        mpu_using_axi;
// MGU axi signals ------------------------
// Read Edge
reg         MGU_read; 
reg  [31:0] MGU_raddr;     
reg [EDGE_DATAWIDTH-1:0] MGU_rdata;
reg         MGU_end_read;


// RAM Signals 
wire [12:0] RAM_address_a;
wire [71:0] RAM_din_a, RAM_dout_a;
wire WrEnable_a, enable_a;

// AXI VIP Base Address
localparam [31:0] base_addr = 32'b0100_0100_1010_0000_0000_0000_0000_0000; 
localparam [15:0] weighted_edge = 16'd1;
localparam [65:0] infinity = 66'b11_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
int offset = 8; // 32 Bytes
reg [7:0] rburst, wburst, rburst_edge, wburst_edge;


parameter num_vertices = 4048;
parameter num_edges = 88256; // 6 are zeros
parameter num_edges_leftover = num_edges % 8;
parameter num_edges_groups = (num_edges - num_edges_leftover) / 8;
int even_edge;

// Vertex Memory 
bit [127:0] v_mem_b[num_vertices-1:0]; // Vertex

// Edge Memory
bit [63:0] e_mem_b[num_edges-1:0]; // Edge 

// Golden Reference Model 
bit [127:0] v_mem_gf[num_vertices-1:0];
bit [63:0] message_fifo [$];
bit [93:0] active_vertex_metadata [$];
bit [63:0] first_message_gf;
bit [32:0] vertex_address1;
bit [30:0] update_value;
bit [31:0] prop;
bit [31:0] edge_address;
bit [29:0] edge_degree;

bit [15:0] weight;
bit [47:0] neighbor;
bit [30:0] new_value;
bit [32:0] new_address;
bit [31:0] prop2;
bit [31:0] edge_address2;
bit [29:0] edge_degree2;

int gf_cycles;

// Message FIFO Signals 
wire Message_FIFO_Empty;
wire Message_FIFO_Full;
wire Message_FIFO_Read;
wire [63:0] Message_FIFO_ReadData;
wire Message_FIFO_Read_Valid;
wire Message_FIFO_Write;
wire [63:0] Message_FIFO_WriteData;

reg Message_FIFO_Write_First;
reg [63:0] Message_FIFO_WriteData_First;

// MPU to VMU FIFO (Vertex Address)
wire MPU_VMU_FIFO_Empty;
wire MPU_VMU_FIFO_Full;
wire MPU_VMU_FIFO_Read;
wire [32:0] MPU_VMU_FIFO_ReadData;
wire MPU_VMU_FIFO_Read_Valid;
wire MPU_VMU_FIFO_Write;
wire [32:0] MPU_VMU_FIFO_WriteData;

// VMU to MGU FIFO A Signals 
wire VMU_to_MGU_FIFO_A_Empty;
wire VMU_to_MGU_FIFO_A_Full;
wire VMU_to_MGU_FIFO_A_Read;
wire [93:0] VMU_to_MGU_FIFO_A_ReadData;
wire VMU_to_MGU_FIFO_A_Read_Valid;
wire VMU_to_MGU_FIFO_A_Write;
wire [93:0] VMU_to_MGU_FIFO_A_WriteData;

// VMU to MGU FIFO B Signals
wire VMU_to_MGU_FIFO_B_Empty;
wire VMU_to_MGU_FIFO_B_Full;
wire VMU_to_MGU_FIFO_B_Read;
wire [93:0] VMU_to_MGU_FIFO_B_ReadData;
wire VMU_to_MGU_FIFO_B_Read_Valid;
wire VMU_to_MGU_FIFO_B_Write;
wire [93:0] VMU_to_MGU_FIFO_B_WriteData;

axi_checker_wrapper AXI_CHECK(
    .clk_100MHz(clk),
    .reset(reset),
    .resetn(resetn),
    // Edge axi engine
    .end_rd_edge(end_rd_e),
    .end_wr_edge(end_wr_e),
    .read_addr_edge(raddr_e),
    .rburst_edge(rburst_edge),
    .wburst_edge(wburst_edge),
    .read_data_edge(rdata_e),
    .start_rd_edge(start_rd_e),
    .start_wr_edge(start_wr_e),
    .write_addr_edge(waddr_e),
    .write_data_edge(wdata_e),
    // Vertex axi engine
    .end_rd(end_rd_v),
    .end_wr(end_wr_v),
    .read_addr(raddr_v),
    .rburst(rburst),
    .wburst(wburst),
    .read_data(rdata_v),
    .start_rd(start_rd_v),
    .start_wr(start_wr_v),
    .write_addr(waddr_v),
    .write_data(wdata_v),
    // BRAM Signals
    .addr_a(RAM_address_a | RAM_address_a_init),
    .din_a(RAM_din_a | RAM_din_a_init),
    .dout_a(RAM_dout_a),
    .WrEnable_a(WrEnable_a | WrEnable_a_init),
    .enable_a(enable_a),
    // FIFO Signals
    .Message_FIFO_Empty(Message_FIFO_Empty),
    .Message_FIFO_Full(Message_FIFO_Full),
    .Message_FIFO_Read(Message_FIFO_Read),
    .Message_FIFO_ReadData(Message_FIFO_ReadData),
    .Message_FIFO_Read_Valid(Message_FIFO_Read_Valid),
    .Message_FIFO_Write(Message_FIFO_Write | Message_FIFO_Write_First),
    .Message_FIFO_WriteData(Message_FIFO_WriteData | Message_FIFO_WriteData_First),
    .MPU_VMU_FIFO_Empty(MPU_VMU_FIFO_Empty),
    .MPU_VMU_FIFO_Full(MPU_VMU_FIFO_Full),
    .MPU_VMU_FIFO_Read(MPU_VMU_FIFO_Read),
    .MPU_VMU_FIFO_ReadData(MPU_VMU_FIFO_ReadData),
    .MPU_VMU_FIFO_Read_Valid(MPU_VMU_FIFO_Read_Valid),
    .MPU_VMU_FIFO_Write(MPU_VMU_FIFO_Write),
    .MPU_VMU_FIFO_WriteData(MPU_VMU_FIFO_WriteData),
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
    .VMU_to_MGU_FIFO_B_WriteData(VMU_to_MGU_FIFO_B_WriteData)
);

MPU #(.DataWidth(VERTEX_DATAWIDTH)) u_MPU(
    .clk(clk),
    .resetn(resetn),
    // message
    .FIFO_data_msg(Message_FIFO_ReadData),
    .FIFO_read_msg(Message_FIFO_Read),
    .FIFO_empty_msg(Message_FIFO_Empty),
    .FIFO_read_valid_msg(Message_FIFO_Read_Valid),
    // read
    .start_rd(MPU_read),
    .read_addr(MPU_raddr),
    .read_data(MPU_rdata),
    .end_rd(MPU_end_read),
    .rburst(MPU_rburst),
    // write
    .start_wr(MPU_write),
    .write_addr(MPU_waddr),
    .write_data(MPU_wdata),
    .end_wr(MPU_end_write),
    .wburst(MPU_wburst),
    //Axi
    .axi_in_use_vmu(vertex_axi_in_use || vmu_using_axi),
    .axi_in_use_mpu(mpu_using_axi),
    // MPU-VMU Signals
    .MPU_VMU_FIFO_Full(MPU_VMU_FIFO_Full),
    .MPU_VMU_FIFO_WriteData(MPU_VMU_FIFO_WriteData),
    .MPU_VMU_FIFO_Write(MPU_VMU_FIFO_Write)
);

VMU u_VMU(
    .clk(clk),
    .resetn(resetn),
    // MPU-VMU signals
    .MPU_VMU_FIFO_Empty(MPU_VMU_FIFO_Empty),
    .MPU_VMU_FIFO_ReadData(MPU_VMU_FIFO_ReadData),
	.MPU_VMU_FIFO_Read(MPU_VMU_FIFO_Read),
	.MPU_VMU_FIFO_Read_Valid(MPU_VMU_FIFO_Read_Valid),
	// AXI Signals
    .start_rd(VMU_read),
    .read_addr(VMU_raddr),
    .read_data(VMU_rdata),
    .rburst(VMU_rburst),
    .end_rd(VMU_end_read),
    .axi_in_use_mpu(mpu_using_axi),
	.axi_in_use_vmu(vmu_using_axi),
    // Fifo to MGU
    .FIFO_data_mgu_a(VMU_to_MGU_FIFO_A_WriteData),
    .FIFO_write_mgu_a(VMU_to_MGU_FIFO_A_Write),
    .FIFO_full_mgu_a(VMU_to_MGU_FIFO_A_Full),
    
    .FIFO_data_mgu_b(VMU_to_MGU_FIFO_B_WriteData),
    .FIFO_write_mgu_b(VMU_to_MGU_FIFO_B_Write),
    .FIFO_full_mgu_b(VMU_to_MGU_FIFO_B_Full),
    
    .Message_FIFO_Empty(Message_FIFO_Empty),
    // BRAM Signals
    .RAM_address_a(RAM_address_a),
    .RAM_din_a(RAM_din_a),
    .RAM_dout_a(RAM_dout_a),
    .WrEnable_a(WrEnable_a),
    .RAM_enable_a(enable_a)
);

MGU #(.DataWidth(EDGE_DATAWIDTH)) u_MGU(
    .clk(clk),
    .resetn(resetn),
    // Fifo message output
    .FIFO_data_msg(Message_FIFO_WriteData),  // FIFO output message
	.FIFO_write_msg(Message_FIFO_Write), // Write FIFO
    .FIFO_full_msg(Message_FIFO_Full), // FIFO empty
	
    // VMU FIFO Signals
	.FIFO_data_vmu_a(VMU_to_MGU_FIFO_A_ReadData),  // FIFO Data VMU
	.FIFO_read_vmu_a(VMU_to_MGU_FIFO_A_Read),  // Read FIFO
	.FIFO_empty_vmu_a(VMU_to_MGU_FIFO_A_Empty), // FIFO empty
	.FIFO_read_valid_vmu_a(VMU_to_MGU_FIFO_A_Read_Valid),
	
	.FIFO_data_vmu_b(VMU_to_MGU_FIFO_B_ReadData),  // FIFO Data VMU
	.FIFO_read_vmu_b(VMU_to_MGU_FIFO_B_Read),  // Read FIFO
	.FIFO_empty_vmu_b(VMU_to_MGU_FIFO_B_Empty), // FIFO empty
	.FIFO_read_valid_vmu_b(VMU_to_MGU_FIFO_B_Read_Valid),

    // Begin/Stop Read
	.read_addr(MGU_raddr),      // old vertex address
	.read_data(MGU_rdata),      // old vertex data
	.start_rd(MGU_read),       // start read
	.end_rd(MGU_end_read)          // finished rea
);


// 100 MHz Clock
initial clk = 1'b0;
always #5ns clk = ~clk;

initial begin
vertex_axi_writes = 0;
vertex_axi_reads = 0;
edge_axi_reads = 0;
while(1) begin 
repeat(1) @(posedge clk)
if(MPU_write) vertex_axi_writes = vertex_axi_writes + 1;
if(MPU_read || VMU_read) vertex_axi_reads = vertex_axi_reads + 1;
if(MGU_read) edge_axi_reads = edge_axi_reads + 1;
end
end

// Reformat memory
initial begin
    // PE Mem
    $readmemh("Vertices.mem", v_mem_b);
    $readmemh("Edges.mem", e_mem_b);
    
    // GF
    $readmemh("Vertices.mem", v_mem_gf);
    gf_cycles = 0;
    new_value = 0;
    first_message_gf = 64'd0; //{33'hef00, 31'd0};
    message_fifo[0] = first_message_gf;
    while(gf_cycles < 4) begin
    $display("Cycle=%0d", gf_cycles);
        while(message_fifo.size > 0) begin
            //$display("New Message");
            vertex_address1 = message_fifo[0][63:35];
            update_value   = message_fifo[0][30:0];
            message_fifo   = message_fifo[1:$];
            //if (vertex_address1 > num_vertices) $stop;
            //if (vertex_address1 == 21) $display("Address=%0d, Value=%0d", vertex_address1, update_value);
            prop         = {v_mem_gf[vertex_address1][71:64], v_mem_gf[vertex_address1][79:72], v_mem_gf[vertex_address1][87:80], v_mem_gf[vertex_address1][95:88]};
            edge_address = {v_mem_gf[vertex_address1][39:32], v_mem_gf[vertex_address1][47:40], v_mem_gf[vertex_address1][55:48], v_mem_gf[vertex_address1][63:56]};
            edge_degree  = {v_mem_gf[vertex_address1][7:2], v_mem_gf[vertex_address1][15:8], v_mem_gf[vertex_address1][23:16], v_mem_gf[vertex_address1][31:24]};
            //if (vertex_address1 == 21) $display("Property=%h, Edge Address=%0d, Edge Degree=%0d", prop, edge_address, edge_degree);
            if (prop > update_value) begin
                prop = update_value;
                //if (vertex_address1 == 21) $display("Update Vertex");
                v_mem_gf[vertex_address1][127:64] = {prop[7:0], prop[15:8], prop[23:16], prop[31:24], prop[7:0], prop[15:8], prop[23:16], prop[31:24]};
                if (edge_degree > 0) begin
                    active_vertex_metadata = {active_vertex_metadata, {prop, edge_address, edge_degree}};
                end
            end
        end
        
        while (active_vertex_metadata.size > 0) begin
            //$display("New Edge List");
            prop2 = active_vertex_metadata[0][93:62];
            edge_address2 = active_vertex_metadata[0][61:30];
            edge_degree2 = active_vertex_metadata[0][29:0];
            active_vertex_metadata = active_vertex_metadata[1:$];
            for(int i=0; i < edge_degree2; i=i+1) begin
               neighbor = {e_mem_b[edge_address2 + i][7:0], e_mem_b[edge_address2 + i][15:8], e_mem_b[edge_address2 + i][23:16], 
                            e_mem_b[edge_address2 + i][31:24], e_mem_b[edge_address2 + i][39:32], e_mem_b[edge_address2 + i][47:40]};
               weight = {e_mem_b[edge_address2 + i][55:48], e_mem_b[edge_address2 + i][63:56]};
               new_address = neighbor[32:0];
               new_value[15:0] = prop2[15:0] + weight;
               message_fifo = {message_fifo, {new_address, new_value}};
               //if (new_address == 21) $display("New Edge");
               //if (new_address == 21) $display("prop=%d, edge address=%0d, edge degree=%0d", prop2, edge_address2, edge_degree2);
               //if (new_address == 21) $display("Weight=%d, Neighbor=%d", weight, neighbor);
               //if (new_address == 21) $display("Vertex Address=%d, New Value=%d", new_address, new_value);
            end
            end
            gf_cycles = gf_cycles + 1;
        end
//        $stop;
end

initial begin
// Reset
resetn = 1'b0;

// Assign Driver axi signals
vertex_axi_in_use = 1'b0;
edge_axi_in_use = 1'b0;
D_write_v = 1'b0;
D_read_v = 1'b0;
D_write_e = 1'b0;
D_read_e = 1'b0;
num_vertices_written = 0;
num_edges_written = 0;
thousand_cycles = 0;
no_more_reads = 0;
max_MSG = 0;
max_MPU_to_MGU = 0;
Message_FIFO_Write_First = 1'b0;
Message_FIFO_WriteData_First = 64'd0;

repeat(1) @(posedge clk);
WrEnable_a_init = 1'b1;
RAM_din_a_init = 72'd0;
for (int i=0; i < 500; i=i+1) begin
    RAM_address_a_init = i;
    repeat(1) @(posedge clk);
end
WrEnable_a_init = 1'b0;
/*for (int i=0; i < 500; i=i+1) begin
    RAM_address_a_init = i;
    repeat(1) @(posedge clk);
    $display("Ram out[%d]=%d", i, RAM_dout_a);
end*/
RAM_address_a_init = 13'd0;

//repeat(20) @(posedge clk);
resetn = 1'b1;
repeat(3) @(posedge clk);

// Write
$display("Starting Vertex Write from Driver");
D_waddr_v = {1'b0, base_addr};
vertex_axi_in_use = 1'b1;
D_waddr_v = D_waddr_v - offset*32;
for (int j=0; j<(num_vertices/16); j=j+1) begin
repeat(3) @(posedge clk);
D_write_v = 1'b1;
D_waddr_v = D_waddr_v + offset*32; // 32 Bytes offset for new memory address location
for (int i=0; i<(16); i=i+2) begin
D_wdata_v = {v_mem_b[i+1+(j*16)], v_mem_b[i+(j*16)]}; //vertex
repeat(1) @(posedge clk);
D_write_v = 1'b0;
repeat(1) @(posedge clk);
wait(D_end_write_v==1'b1);
//$display("Vertex data=%h Written to address=%d", D_wdata_v, (D_waddr_v - base_addr));
num_vertices_written = num_vertices_written + 2;
end
end
vertex_axi_in_use = 1'b0;
repeat(3) @(posedge clk);
// Write Edges
$display("Starting Edges Write from Driver");
D_waddr_e = {1'b0, base_addr};
edge_axi_in_use = 1'b1;
D_waddr_e = D_waddr_e - offset*64;
for (int j=0; j<(num_edges/64); j=j+1) begin
repeat(3) @(posedge clk);
D_write_e = 1'b1;
D_waddr_e = D_waddr_e + offset*64; // 64 Bytes offset for new memory address location
for (int i=0; i<(64); i=i+8) begin
D_wdata_e = {e_mem_b[i+7+(j*64)], e_mem_b[i+6+(j*64)], e_mem_b[i+5+(j*64)], e_mem_b[i+4+(j*64)], 
            e_mem_b[i+3+(j*64)], e_mem_b[i+2+(j*64)], e_mem_b[i+1+(j*64)], e_mem_b[i+(j*64)]}; //edge
repeat(1) @(posedge clk);
D_write_e = 1'b0;
repeat(1) @(posedge clk);
wait(D_end_write_e==1'b1);
//$display("Vertex data=%h Written to address=%d", D_wdata_v, (D_waddr_v - base_addr));
num_edges_written = num_edges_written + 8;
end
end
edge_axi_in_use = 1'b0;
repeat(1) @(posedge clk);
//$stop;

//$display("Vertices=%d, Edges=%d, Edge Groups=%d", num_vertices, num_edges, num_edges_groups);
//$display("Vertices Written=%d, Edges Written=%d", num_vertices_written, num_edges_written);
//$stop;
first_message = 64'd0; //{33'hef00, 31'd0};; //{1'b0, base_addr, 31'd0}; // Starting vertex
Message_FIFO_Write_First = 1'b1;
Message_FIFO_WriteData_First = first_message;
repeat(1) @(posedge clk);
Message_FIFO_Write_First = 1'b0;
Message_FIFO_WriteData_First = 64'd0;
//while(1) begin
//repeat(1000) @(posedge clk);
//$stop;
//end
while(no_more_reads < 1000) begin
repeat(1) @(posedge clk);
if(MPU_read || MGU_read || VMU_read) begin
    no_more_reads = 0;
end
else no_more_reads = no_more_reads + 1;
end
$display("VertexReads=%d, VertexWrites=%d, EdgeReads=%d", vertex_axi_reads, vertex_axi_writes, edge_axi_reads);
$display("Max MSG Size=%d, Max MPU to MGU Size=%d", max_MSG, max_MPU_to_MGU);
//$stop;

//==================
// READ VERTICES
$display("Starting Vertex Read from Driver");
D_raddr_v = {1'b0, base_addr};
vertex_axi_in_use = 1'b1;
for (int j=0; j<(num_vertices/16); j=j+1) begin
D_read_v = 1'b1;
repeat(1) @(posedge clk);
for (int i=0; i<16; i=i+2) begin
D_read_v = 1'b0;
while(D_end_read_v==1'b0) begin
repeat(1) @(posedge clk);
end
repeat(1) @(posedge clk);
v_mem_b[i+1+(j*16)] = D_rdata_v[255:128]; //vertex activate
v_mem_b[i+(j*16)] = D_rdata_v[127:0]; //vertex activate

D_raddr_v = D_raddr_v + offset*4; // 32 Bytes offset for new memory address location
end
repeat(1) @(posedge clk);
end
vertex_axi_in_use = 1'b0;
repeat(3) @(posedge clk);
updated_vertex = 0;
for (int i=0; i<num_vertices; i=i+1) begin
if (v_mem_b[i][127:64] != 128'hFFFFFFFFFFFFFFFF) updated_vertex = updated_vertex + 1;
end
for(int i=0; i < num_vertices; i=i+1) begin
if (v_mem_b[i] != v_mem_gf[i]) begin
    $display("Vertex Mismatch @ Vertex=%d, Test=%h, GF=%h", i, v_mem_b[i], v_mem_gf[i]);
end
end
$display("Vertices Updated=%d", updated_vertex);
$stop;
//=============================

file = $fopen("Output.txt", "w");
if (file == 0) begin
      $display("Error opening file for writing");
      $finish;
end

    $fwrite(file, "@%h\n", 00000000);
for(int i=0; i<num_vertices; i=i+1) begin
    $fwrite(file, "%h\n", v_mem_b[i]);
end
$fclose(file);

$finish;
end

// Declare the agents
axi_checker_axi_vip_0_0_slv_mem_t slv_agent1;
axi_checker_axi_vip_1_0_slv_mem_t slv_agent2;

initial begin
//Create agents
slv_agent1 = new("slave_vertex vip agent",AXI_CHECK.axi_checker_i.Vertex_Mem_AXIVer.inst.IF);
slv_agent2 = new("slave_edge vip agent", AXI_CHECK.axi_checker_i.Edge_Mem_AXIVer.inst.IF);
// set print out verbosity level
//slv_agent.set_verbosity(400);
//Start the agents
slv_agent1.start_slave();
slv_agent2.start_slave();

end

// AXI Engine Mux
always_comb begin
// Vertex Engine
if(vertex_axi_in_use) begin
    start_rd_v    = D_read_v;
    D_end_read_v  = end_rd_v;
    raddr_v       = D_raddr_v;
    D_rdata_v     = rdata_v;
    rburst = 8'd7;
    wburst = 8'd7;
    start_wr_v    = D_write_v;
    D_end_write_v = end_wr_v;
    waddr_v       = D_waddr_v;
    wdata_v       = D_wdata_v;
end
else if (vmu_using_axi && ~mpu_using_axi)
begin
    start_rd_v = VMU_read;
    VMU_end_read = end_rd_v;
    raddr_v = VMU_raddr;
    VMU_rdata = rdata_v;
    rburst = VMU_rburst;
    wburst = 8'd0;
    start_wr_v    = MPU_write;
    MPU_end_write = end_wr_v;
    waddr_v       = MPU_waddr;
    wdata_v       = MPU_wdata;
    
    D_end_read_v = 1'b0;
    D_end_write_v = 1'b0;
end
else begin
    start_rd_v    = MPU_read;
    MPU_end_read  = end_rd_v;
    raddr_v       = MPU_raddr;
    MPU_rdata     = rdata_v;
    rburst = MPU_rburst;
    wburst = MPU_wburst;
    start_wr_v    = MPU_write;
    MPU_end_write = end_wr_v;
    waddr_v       = MPU_waddr;
    wdata_v       = MPU_wdata;
    
    D_end_read_v = 1'b0;
    D_end_write_v = 1'b0;
end

// Edge Engine
if(edge_axi_in_use) begin
    start_rd_e    = D_read_e;
    D_end_read_e  = end_rd_e;
    raddr_e       = D_raddr_e;
    D_rdata_e     = rdata_e;
    rburst_edge = 8'd7;
    wburst_edge = 8'd7;
    start_wr_e    = D_write_e;
    D_end_write_e = end_wr_e;
    waddr_e       = D_waddr_e;
    wdata_e       = D_wdata_e;
end
else begin
    start_rd_e    = MGU_read; 
    MGU_end_read  = end_rd_e;
    raddr_e       = {1'b0, MGU_raddr};
    MGU_rdata     = rdata_e;
    rburst_edge = 8'd0;
    wburst_edge = 8'd0;
    start_wr_e    = 1'b0;
    D_end_write_e = 1'b0;
    waddr_e       = 33'd0;
    wdata_e       = 512'd0;
    
    D_end_read_e = 1'b0;
    D_end_write_e = 1'b0;
end
end
endmodule
