`timescale 1ns / 10ps
/*
 * Source: Austin York, University of California, Davis
 *
 * This hardware operator is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//=====================================
//      Message Processing Unit
//=====================================
module MPU #(
	parameter VPropWidth     = 32,  // Vertex Prop Width (value that gets changed)
	parameter VPropStart     = 64,  // Vertex prop location of first bit in memory (value that gets changed) Ex: 128 bit vertex in memory 95:64 is vertex value that needs to be checked so start is 64
	parameter EIndexWidth    = 32,  // Edge Address Width
	parameter EDegreeWidth   = 30,  // Edge Degree Width
	parameter AddrWidth      = 33,  // 33 = 8GB Memory
	parameter DataWidth      = 256, // HBM data width
	parameter MsgWidth       = 64,  // Input message width
	parameter MGUUpdateWidth = 94 // VPropWidth+EIndexWidth+EDegreeWidth
)(
	input                      clk,          // should be 450 MHz
	input                      resetn,       // negative reset
	//----------------------Message Signals----------------------//
	input       [(MsgWidth-1):0] FIFO_data_msg,       // vertex  message
	output reg                 FIFO_read_msg, // message available
	input                      FIFO_empty_msg,  // message received
	input                      FIFO_read_valid_msg,

	//-------------------Begin/Stop Read/Write-------------------//
	output reg [(AddrWidth-1):0] read_addr,    // old vertex address
	input	   [(DataWidth-1):0] read_data,    // old vertex data
	output               [7:0] rburst,
	output reg [(AddrWidth-1):0] write_addr,   // updated vertex address, same as old
	output reg [(DataWidth-1):0] write_data,   // updated vertex data
	output               [7:0] wburst,
	output reg                 start_rd,     // start read
	output reg                 start_wr,     // start write
	input                      end_rd,       // finished read
	input                      end_wr,       // finished write
	input                      axi_in_use_vmu,
	output reg                 axi_in_use_mpu,
	
	//----------------------Update to VMU----------------------//
	input                      MPU_VMU_FIFO_Full,
	output reg                 MPU_VMU_FIFO_Write,
	output reg [(AddrWidth-1):0] MPU_VMU_FIFO_WriteData
);

reg      [(MsgWidth-1):0] msg_reg;         // Store message
reg    [(VPropWidth-1):0] old_temp_prop;   // decoded old temp vertex value
reg    [(VPropWidth-1):0] old_prop;        // decoded old vertex value
reg    [(VPropWidth-1):0] new_value;       // decoded new vertex value
wire   [(VPropWidth-1):0] temp_result;     // temp result
wire   [(VPropWidth-1):0] result;          // result of update
wire                    update;          // decide to update vertex
wire                    send;            // Send if need to propogate edges
reg     [(DataWidth-1):0] store_read_data; // store old vertices
reg   [(EIndexWidth-1):0] edge_index;      // Base address of edge
reg  [(EDegreeWidth-1):0] edge_degree;     // Number of edges = edge degree
reg                     start_send;      // start sending data to MGU
wire [((DataWidth/2)-1):0] vertex[1:0];
reg                     which_vertex;
reg     [(AddrWidth-1):0] previous_addr;


assign vertex[0] = store_read_data[127:0];
assign vertex[1] = store_read_data[255:128];

assign rburst = 8'd0;
assign wburst = 8'd0;
// MESSAGE DECODE
// Left most 33 bits is address 
// Leftover is update value

//----------------------FSM----------------------//
reg [3:0] state;
localparam [3:0]
	IDLE         = 4'd0,
	WAIT         = 4'd1,
	READ         = 4'd2,
	READ_WAIT    = 4'd3,
	STORE_READ   = 4'd4,
	REDUCE       = 4'd5,
	CHECK_UPDATE = 4'd6,
	FIFO_WAIT    = 4'd7,
	WRITE_WAIT   = 4'd8;

always @(posedge clk)
begin
if(~resetn)
begin
	read_addr     <= {AddrWidth{1'b0}};
	write_addr    <= {AddrWidth{1'b0}};
	write_data    <= {DataWidth{1'b0}};
	start_rd      <= 1'b0;
	previous_addr <= {AddrWidth{1'b1}};
	axi_in_use_mpu <= 1'b0;
	start_wr      <= 1'b0;
	FIFO_read_msg <= 1'b0;
	start_send    <= 1'b0;
	state         <= IDLE;
end
else
begin
	
	case(state)
	IDLE:         // Wait for Message
	begin
	    axi_in_use_mpu <= 1'b0;
		if(~FIFO_empty_msg && ~MPU_VMU_FIFO_Full) // Message is ready to read and pass values
		begin
		    FIFO_read_msg   <= 1'b1;
		    state           <= WAIT;
		end
	end
	WAIT:         // One cycle wait to get data from fifo read
	begin
	   FIFO_read_msg        <= 1'b0;
	   if (FIFO_read_valid_msg) begin
	   msg_reg              <= FIFO_data_msg;
	   read_addr       <= {1'b0, 12'h44a, FIFO_data_msg[50:36], 5'b00000}; // 1 bit for which vertex of the 2. 4 bits for 16 bytes per vertex offset
	   which_vertex    <= FIFO_data_msg[35];
	   state                <= READ;
	   end
	end
	READ:         // Read Old Vertices from HBM
	begin
	   if (~axi_in_use_vmu) begin
	       axi_in_use_mpu <= 1'b1;
	   if (previous_addr==read_addr) begin
	       store_read_data <= write_data;
	       state <= REDUCE;
	       end
	   else begin
		   start_rd     <= 1'b1; // Start read
		   state        <= READ_WAIT;
	   end
	   end
	end
	READ_WAIT:    // Wait for read to complete
	begin
	    start_rd        <= 1'b0;
	    if (end_rd) begin
	       state <= STORE_READ;
	    end
	end
	STORE_READ:
	begin
	   store_read_data <= read_data;
	   state <= REDUCE;
	end
	REDUCE:       // Reduce Values
	begin
	    previous_addr       <= read_addr;
		new_value           <= {1'b0, msg_reg[30:0]}; // New Vertex Value
		case(which_vertex)
		1'b0:
		begin
            old_temp_prop   <= {vertex[0][103:96], vertex[0][111:104], vertex[0][119:112], vertex[0][127:120]}; // Old Temp Prop Value
            old_prop        <= {vertex[0][71:64], vertex[0][79:72], vertex[0][87:80], vertex[0][95:88]}; // Old Prop Value
            edge_index      <= {vertex[0][39:32], vertex[0][47:40], vertex[0][55:48], vertex[0][63:56]};
            edge_degree     <= {vertex[0][7:2], vertex[0][15:8], vertex[0][23:16], vertex[0][31:24]};
		end
		1'b1:
		begin
            old_temp_prop   <= {vertex[1][103:96], vertex[1][111:104], vertex[1][119:112], vertex[1][127:120]}; // Old Temp Prop Value
            old_prop        <= {vertex[1][71:64], vertex[1][79:72], vertex[1][87:80], vertex[1][95:88]}; // Old Prop Value
            edge_index      <= {vertex[1][39:32], vertex[1][47:40], vertex[1][55:48], vertex[1][63:56]};
            edge_degree     <= {vertex[1][7:2], vertex[1][15:8], vertex[1][23:16], vertex[1][31:24]};
		end
		endcase
		state               <= CHECK_UPDATE;
	end
	CHECK_UPDATE: // Decide to update vertex and write back
	begin
	    if (update) state   <= WRITE_WAIT;
	    else if (send) state  <= FIFO_WAIT;
		else state <= IDLE;
		
	    if (send) begin
		   MPU_VMU_FIFO_Write <= 1'b1;
	       MPU_VMU_FIFO_WriteData <= FIFO_data_msg[63:31];
		end
		else begin
		   MPU_VMU_FIFO_Write <= 1'b0;
	       MPU_VMU_FIFO_WriteData <= 33'd0;
		end
		
		write_addr      <= read_addr; // Pass same address as read
		if (update) 
		begin
		    start_wr        <= 1'b1;
		    case(which_vertex)
		    1'b0:
		    begin
			write_data      <= {store_read_data[255:128], temp_result[7:0], temp_result[15:8], temp_result[23:16], temp_result[31:24], 
			                     result[7:0], result[15:8], result[23:16], result[31:24], store_read_data[(VPropStart-1):0]}; // Position new vertex value correctly only change result property
			end
			1'b1:
			begin
			write_data      <= {temp_result[7:0], temp_result[15:8], temp_result[23:16], temp_result[31:24], 
			                     result[7:0], result[15:8], result[23:16], result[31:24], store_read_data[(VPropStart-1+128):0]};
			end
			endcase
		end
		else begin
		    start_wr <= 1'b0;
		    write_data <= store_read_data;
		end
	end
	FIFO_WAIT:
	begin
		MPU_VMU_FIFO_Write  <= 1'b0;
		state <= IDLE;
	end
	WRITE_WAIT:   // Wait for write to finish
	begin
		start_wr            <= 1'b0;
		MPU_VMU_FIFO_Write  <= 1'b0;
		if (end_wr) begin
		    axi_in_use_mpu  <= 1'b0;
			state           <= IDLE;
		end
	end
	default: state          <= IDLE;
	endcase
end
end

ReductionEngine #(
    .VPropWidth  (VPropWidth  ), 
    .EDegreeWidth(EDegreeWidth)
    ) 
inst_ReductionEngine(
	//.control    (control_reg  ), 
	.old_temp_p (old_temp_prop), 
	.old_p      (old_prop     ), 
	.edge_degree(edge_degree  ), 
	.new_v      (new_value    ), 
	.result     (result       ), 
	.temp_result(temp_result  ), 
	.update     (update       ),
	.send       (send         )
);
endmodule

//=====================================
//         Reduction Engine
//=====================================
module ReductionEngine #(
	parameter VPropWidth   = 32,
	parameter EDegreeWidth = 30
)(
	//input 	                [1:0] control,     // graph vertex calculation
	input      [VPropWidth-1:0] old_temp_p,  // old temp prop
	input      [VPropWidth-1:0] old_p,       // old prop
	input    [EDegreeWidth-1:0] edge_degree, // old edge degree
	input      [VPropWidth-1:0] new_v,       // new value
	output reg [VPropWidth-1:0] result,      // vertex prop result
	output reg [VPropWidth-1:0] temp_result, // temp vertex prop result
	output reg                  update,      // determine to update vertex
	output reg                  send
);
wire BFS_Check_Send, BFS_Check_Update;
assign BFS_Check_Send = ((new_v < old_temp_p) && (edge_degree > 0));
assign BFS_Check_Update = (new_v < old_temp_p);
	
always @(*)
begin
//case(control)

//2'b10: // MIN new_v <= old_temp_p (BFS) (SSSP)
//begin
	result      = BFS_Check_Update ? new_v : old_p;
	temp_result = BFS_Check_Update ? new_v : old_temp_p;
	update      = BFS_Check_Update ? 1'b1 : 1'b0;
	send        = BFS_Check_Send   ? 1'b1 : 1'b0;
end

//default:
//begin
//	result      = old_p;
//	temp_result = old_temp_p;
//	active      = 1'b0;
//end
//endcase
//end
endmodule
