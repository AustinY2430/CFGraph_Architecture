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

module tb_top();

reg clk, d_start_rd, d_start_wr, start_rd, start_wr, start_rd1;
wire d_end_wr, d_end_rd, end_rd, end_wr, end_rd1;
reg [32:0] d_raddr, d_waddr, raddr, waddr, raddr1;
reg [255:0] d_wdata, wdata;
wire [255:0] d_rdata, rdata, rdata1;
reg resetn;
reg [63:0] update;
reg update_ready;
wire update_resp;
//reg [1:0] MPU_control;
wire [95:0] FIFO_data;
reg FIFO_full;

axi_checker_wrapper AXI_CHECK(
    .clk_100MHz(clk),
    .d_end_rd(d_end_rd),
    .d_end_wr(d_end_wr),
    .d_read_addr(d_raddr),
    .d_read_data(d_rdata),
    .d_start_rd(d_start_rd),
    .d_start_wr(d_start_wr),
    .d_write_addr(d_waddr),
    .d_write_data(d_wdata),
    .end_rd(end_rd),
    .end_wr(end_wr),
    .read_addr(raddr),
    .read_data(rdata),
    .resetn(resetn),
    .start_rd(start_rd),
    .start_wr(start_wr),
    .write_addr(waddr),
    .write_data(wdata)
);

MPU u_MPU(
    .clk(clk),
    .resetn(resetn),
    .update(update),
    .update_ready(update_ready),
    .update_resp(update_resp),
    //.control(MPU_control),
    .start_rd(start_rd),
    .read_addr(raddr),
    .read_data(rdata),
    .end_rd(end_rd),
    .start_wr(start_wr),
    .write_addr(waddr),
    .write_data(wdata),
    .end_wr(end_wr),
    .FIFO_data(FIFO_data),
    .FIFO_ready(FIFO_ready),
    .FIFO_full(FIFO_full)
);

localparam [7:0] transactions = 2;

// 100 MHz Clock
initial clk = 1'b0;
always #5ns clk = ~clk;

initial begin
// Reset
resetn = 1'b0;

update = 64'd0;
update_ready = 1'b0;
//MPU_control = 2'b00;

//start_rd = 1'b0;
//start_wr = 1'b0;
//wdata = 256'd0;

d_start_rd = 1'b0;
d_start_wr = 1'b0;
d_wdata = 256'd0; 
#250ns;
resetn = 1'b1;
#100ns;

// Write
$display("Starting Write from Driver");
d_waddr = 33'b0_0100_0100_1010_0000_0000_0000_0000_0000; 
for (int i=0; i<transactions; i=i+1) begin
d_start_wr = 1'b1;
d_wdata = {128'd0, 32'b1111_1111_1111_1111_1111_1111_1111_1111,  //temp prop
                   32'b1111_1111_1111_1111_1111_1111_1111_1111,  //prop
                   32'b0000_0000_0000_0000_0000_0000_0000_0100,  //edge index
                   32'b0000_0000_0000_0000_0000_0000_0000_0001}; //edge degree
repeat(2) @(posedge clk);
d_start_wr = 1'b0;
wait(d_end_wr==1'b1);
repeat(1) @(posedge clk);
d_waddr = d_waddr + 32; // 32 Bytes
$display("wdata=%0h, waddr=%0h", d_wdata, d_waddr);
end

//// Write
//$display("Starting Write");
//waddr = 33'b0_0100_0100_1001_1111_1111_1111_1110_0000; // Starting address 33'b0_0100_0100_1010_0000_0000_0000_0000_0000; 
//for (int i=0; i<transactions; i=i+1) begin
//start_wr = 1'b1;
//wdata = wdata + 1;
//waddr = waddr + 32;
//repeat(2) @(posedge clk);
//start_wr = 1'b0;
//repeat(1) @(posedge end_wr);
//repeat(1) @(posedge clk);
//$display("wdata=%0h, waddr=%0h", wdata, waddr);
//end

//// Read from MPU
//$display("Starting Read");
//raddr = 33'b0_0100_0100_1001_1111_1111_1111_1110_0000; // Starting address 33'b0_0100_0100_1010_0000_0000_0000_0000_0000;
//for (int i=0; i<transactions; i=i+1) begin
//start_rd = 1'b1;
//raddr = raddr + 32;
//repeat(2) @(posedge clk);
//start_rd = 1'b0;
//repeat(1) @(posedge end_rd);
//repeat(1) @(posedge clk);
//$display("rdata=%0h, raddr=%0h", rdata, raddr);
//end

// Send update to MPU
update = {33'b0_0100_0100_1010_0000_0000_0000_0000_0000, 31'b000_0000_0000_0000_0000_0000_0000_0010};
update_ready = 1'b1;
FIFO_full = 1'b0;
//MPU_control = 2'b10;
wait(update_resp==1'b1);
repeat(1) @(posedge clk);
update = 64'd0;
update_ready = 1'b0;

wait(end_wr==1'b1);

repeat(1) @(posedge clk);

update = {33'b0_0100_0100_1010_0000_0000_0000_0000_0000 + 32, 31'b000_0000_0000_0000_0000_0000_0000_0110};
update_ready = 1'b1;
FIFO_full = 1'b0;
//MPU_control = 2'b10;
wait(update_resp==1'b1);
repeat(1) @(posedge clk);
update = 64'd0;
update_ready = 1'b0;

wait(end_wr==1'b1);

repeat(10) @(posedge clk);
$finish;
end

// Declare the agent
axi_checker_axi_vip_0_0_slv_mem_t slv_agent;

initial begin
//Create an agent
slv_agent = new("master vip agent",AXI_CHECK.axi_checker_i.axi_vip_0.inst.IF);
// set print out verbosity level
//slv_agent.set_verbosity(400);
//Start the agent
slv_agent.start_slave();
end

endmodule
