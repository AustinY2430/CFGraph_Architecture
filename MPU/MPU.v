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
	parameter VPropWidth   = 32,  // Vertex Prop Width (value that gets changed)
	parameter VPropStart   = 64,  // Vertex prop location of first bit in memory (value that gets changed) Ex: 128 bit vertex in memory 95:64 is vertex value that needs to be checked so start is 64
	parameter EIndexWidth  = 32,  // Edge Address Width
	parameter EDegreeWidth = 32,  // Edge Degree Width
	parameter AddrWidth    = 33,  // 33 = 8GB Memory
	parameter DataWidth    = 256, // HBM data width
	parameter UpdateWidth  = 65   // Input message width
)(
	input                        clk,          // should be 450 MHz
	input                        resetn,       // negative reset
	//----------------------Message Signals----------------------//
	input    [UpdateWidth - 1:0] update,       // vertex update message
	input                        update_ready, // message available
	output reg                   update_resp,  // message received
	input                  [1:0] control,      // ALU Control (graph type)

	//-------------------Begin/Stop Read/Write-------------------//
	output reg [AddrWidth - 1:0] read_addr,     // old vertex address
	input	   [DataWidth - 1:0] read_data,     // old vertex data
	output reg [AddrWidth - 1:0] write_addr,    // updated vertex address, same as old
	output reg [DataWidth - 1:0] write_data,    // updated vertex data
	output reg                   start_rd,      // start read
	output reg                   start_wr,      // start write
	input                        end_rd,        // finished read
	input                        end_wr,        // finished write
	
	//----------------------Update to MGU----------------------//
	output reg [VPropWidth+EIndexWidth+EDegreeWidth:0] MGU_data, // {VertexProp, Edge Addr, Edge Range}
	output reg                   MGU_ready,     // MGU data is ready for MGU to ready
	input                        MGU_resp       // MGU response
);

reg [UpdateWidth - 1:0] update_reg;      // Store message
reg               [1:0] control_reg;     // Store control
reg  [VPropWidth - 1:0] old_temp_prop;   // decoded old temp vertex value
reg  [VPropWidth - 1:0] old_prop;        // decoded old vertex value
reg  [VPropWidth - 1:0] new_value;       // decoded new vertex value
wire [VPropWidth - 1:0] result;          // result of update
wire 	                active;          // decide to update vertex
reg   [DataWidth - 1:0] store_read_data; // store old vertices
reg     [EIndexWidth:0] edge_index;      // Base address of edge
reg    [EDegreeWidth:0] edge_degree;     // Number of edges = edge degree
reg    [EDegreeWidth:0] old_degree;      // Old Edge Degree
reg                     start_send;      // start sending data to MGU


assign edge_index  = store_read_data[(EIndexWidth+EDegreeWidth-1):(EIndexWidth)];
assign edge_degree = store_read_data[(EDegreeWidth-1):0];



//----------------------FSM----------------------//
reg [2:0] state;
localparam [2:0]
	IDLE         = 3'b000,
	READ         = 3'b001,
	READ_WAIT    = 3'b010,
	REDUCE       = 3'b011,
	CHECK_ACTIVE = 3'b100,
	WRITE        = 3'b101,
	WRITE_WAIT   = 3'b110;

always @(posedge clk)
begin
if(~resetn)
begin
	state           <= IDLE;
	new_value       <= {VPropWidth{1'b0}};
	old_prop        <= {VPropWidth{1'b0}};
	old_temp_prop   <= {VPropWidth{1'b0}};
	old_degree      <= {EDegreeWidth{1'b0}};
	read_addr       <= {AddrWidth{1'b0}};
	write_addr      <= {AddrWidth{1'b0}};
	write_data      <= {DataWidth{1'b0}};
	update_reg      <= {UpdateWidth{1'b0}};
	store_read_data <= {DataWidth{1'b0}};
	start_rd        <= 1'b0;
	start_wr        <= 1'b0;
	update_resp     <= 1'b0;
	control_reg     <= 2'b00;
	start_send      <= 1'b0;
end
else
begin
	
	case(state)

	IDLE:         // Wait for update
	begin
		if(update_ready) // Update is ready to read
		begin
		    control_reg     <= control; // Reduction Engine
		    update_resp     <= 1'b1;
		    update_reg      <= update;
		    state           <= READ;
		end
	end

	READ:         // Read Old Vertices from HBM
	begin
		start_rd            <= 1'b1; // Start read
		read_addr           <= update_reg[(UpdateWidth-1):(UpdateWidth-AddrWidth)]; // Left half is address
		state               <= READ_WAIT;
	end

	READ_WAIT:    // Wait for read to complete
	begin
	    	update_resp         <= 1'b0;
		start_rd            <= 1'b0;
		if (end_rd)
		begin
			store_read_data <= read_data;
			state           <= REDUCE;
		end
	end

	REDUCE:       // Reduce Values
	begin
		new_value           <= update_reg[(VPropWidth-1):0]; // New Vertex Value
		old_prop            <= store_read_data[(VPropStart+VPropWidth-1):(VPropStart)]; // Old Prop Value
		old_temp_prop       <= store_read_data[(VPropStart+(VPropWidth*2)-1):(VPropStart+VPropWidth)]; // Old Temp Prop Value
		old_degree          <= store_read_data[EDegreeWidth-1:0]; // Old Edge Degree
		state               <= CHECK_ACTIVE;
	end

	CHECK_ACTIVE: // Decide to activate vertex
	begin
		if (active) 
		begin
			write_data  <= {store_read_data[(DataWidth-1):(DataWidth/2)], temp_result, result, store_read_data[(VPropStart-1):0]}; // Position new vertex value correctly
			write_addr  <= update_reg[(UpdateWidth-1):(UpdateWidth-AddrWidth)]; // Pass same address as read
			start_send  <= 1'b1;
			state       <= WRITE;
		end
		else state          <= IDLE;
	end

	WRITE:        // Write back updated vertex
	begin
		start_wr            <= 1'b1;
		state               <= WRITE_WAIT;
	end

	WRITE_WAIT:   // Wait for write to finish
	begin
		start_wr            <= 1'b0;
		if (end_wr) begin
			state       <= IDLE;
		end
	end

	default: state <= IDLE;
	endcase
end
end


//----------------------FSM----------------------//
reg [2:0] state_a;
localparam [2:0]
	MGU_WAIT = 3'b000,
	MGU_RESP = 3'b001;
	
	
always @(posedge clk) 
begin
if(~resetn)
begin
    MGU_data  <= 96'd0;
    MGU_ready <= 1'b0;
    state_a   <= MGU_WAIT;
end
else
begin 

    case(state_a)

    MGU_WAIT:
    begin
        if(active & start_send)
        begin
            MGU_data  <= {result, edge_index, edge_degree};
            MGU_ready <= 1'b1;
            state_a   <= MGU_RESP;
        end
        else MGU_data <= 96'd0;
    end
	    
    MGU_RESP:
    begin
        if (MGU_resp) 
        begin
            MGU_ready <= 1'b0;
            state_a   <= MGU_WAIT;
        end
    end
    
    default: state_a  <= MGU_WAIT;
    endcase
end
end

ReductionEngine #(.VPropWidth  (VPropWidth  ), 
		  .EDegreeWidth(EDegreeWidth)) 
inst_ReductionEngine(
	.resetn     (resetn       ), 
	.control    (control_reg  ), 
	.old_temp_p (old_temp_prop), 
	.old_p      (old_prop     ), 
	.old_degree (old_degree   ), 
	.new_v      (new_value    ), 
	.result     (result       ), 
	.temp_result(temp_result  ), 
	.active     (active       )
);
endmodule

//=====================================
//         Reduction Engine
//=====================================
module ReductionEngine #(
	parameter VPropWidth   = 32,
	parameter EDegreeWidth = 32
)(
	input 		              resetn,      // negative reset
	input 	                [1:0] control,     // graph vertex calculation
	input      [VPropWidth - 1:0] old_temp_p,  // old temp prop
	input      [VPropWidth - 1:0] old_p,       // old prop
	input    [EDegreeWidth - 1:0] old_degree,  // old edge degree
	input      [VPropWidth - 1:0] new_v,       // new value
	output reg [VPropWidth - 1:0] result,      // vertex prop result
	output reg [VPropWidth - 1:0] temp_result, // temp vertex prop result
	output reg                    active       // determine to update vertex
);

always @(*)
begin
if(~resetn)
begin
	result      = {VPropWidth{1'b0}};
	temp_result = {VPropWidth{1'b0}};
	active      = 1'b0;
end
else
begin
case(control)

2'b10: // MIN new_v <= old_temp_p (BFS) (SSSP)
begin
	result      = ((new_v < old_temp_p) && (old_degree > 0)) ? new_v : old_p;
	temp_result = ((new_v < old_temp_p) && (old_degree > 0)) ? new_v : old_temp_p;
	active      = ((new_v < old_temp_p) && (old_degree > 0)) ? 1'b1 : 1'b0;
end

default:
begin
	result      = old_p;
	temp_result = old_temp_p;
	active      = 1'b0;
end
endcase
end
end
endmodule
