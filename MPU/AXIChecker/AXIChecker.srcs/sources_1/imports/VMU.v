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
//      Vertex Managment Unit
//=====================================
module VMU #(
	parameter ADDRWIDTH = 33,
	parameter DATAWIDTH = 256,
	parameter VERTEXWIDTHBYTES = 16,
	parameter SUPERBLOCKS = 64, // Each superblock is 4x4 blocks = 16 total blocks per superblock
	parameter BLOCKS = 1024,
	parameter BLOCK_SIZE = 8, // 8B Blocks (8 B per RAM addr = 1 Block)
	parameter MGUWIDTH = 94 // 32 vertex, 32 edge index, 30 edge degree
)(
	
	input                      clk,          // clock
	input                      resetn,       // negative reset

	//----------------------MPU Signals----------------------//
	input                      MPU_VMU_FIFO_Empty,
	input      [(ADDRWIDTH-1):0] MPU_VMU_FIFO_ReadData,
	output reg                 MPU_VMU_FIFO_Read,
	input                      MPU_VMU_FIFO_Read_Valid,

	//----------------------AXI Signals----------------------//
	output reg                 start_rd,
	output reg [(ADDRWIDTH-1):0] read_addr,
	input      [(DATAWIDTH-1):0] read_data,
	input                      end_rd,
	output               [7:0] rburst,
	input                      axi_in_use_mpu,
	output reg                 axi_in_use_vmu,

	//----------------------FIFO to MGU----------------------//
	input                      FIFO_full_mgu_a, // More than 8 entries in buffer are free
	output reg  [(MGUWIDTH-1):0] FIFO_data_mgu_a,
	output reg                 FIFO_write_mgu_a,
	
	input                      FIFO_full_mgu_b, // More than 8 entries in buffer are free
	output reg  [(MGUWIDTH-1):0] FIFO_data_mgu_b,
	output reg                 FIFO_write_mgu_b,
	
	input                      Message_FIFO_Empty,
	
	//----------------------RAM Signals----------------------//
	output reg [12:0] RAM_address_a,
	output reg [71:0] RAM_din_a,
	input      [71:0] RAM_dout_a,
	output reg        WrEnable_a,
	output            RAM_enable_a
	
);

// Universal Signals
reg [(DATAWIDTH-1):0] store_read_data[7:0];
reg [(DATAWIDTH-1):0] active_read_data;
wire         [12:0] next_RAM_address;
reg                 LOCK;
reg                 UNLOCK;

wire [127:0] vertex[1:0]; // 2 Vertices
wire  [31:0] prop[1:0]; // Prop of vertex
wire  [31:0] edge_index[1:0];   // Base address of edge
wire  [29:0] edge_degree[1:0];  // Number of edges

// Vertices and edge information
assign vertex[0]      = active_read_data[127:0];
assign vertex[1]      = active_read_data[255:128];
assign prop[0]        = {vertex[0][71:64], vertex[0][79:72], vertex[0][87:80], vertex[0][95:88]};
assign prop[1]        = {vertex[1][71:64], vertex[1][79:72], vertex[1][87:80], vertex[1][95:88]};
assign edge_index[0]  = {vertex[0][39:32], vertex[0][47:40], vertex[0][55:48], vertex[0][63:56]};
assign edge_index[1]  = {vertex[1][39:32], vertex[1][47:40], vertex[1][55:48], vertex[1][63:56]};
assign edge_degree[0] = {vertex[0][7:2], vertex[0][15:8], vertex[0][23:16], vertex[0][31:24]};
assign edge_degree[1] = {vertex[1][7:2], vertex[1][15:8], vertex[1][23:16], vertex[1][31:24]};

assign next_RAM_address = RAM_address_a + 1'b1;

assign RAM_enable_a = 1'b1;

// Burst Read
assign rburst = 8'd7; // 8 reads


// STATES 
reg [3:0] state_a;
localparam [3:0]
	IDLE      = 4'd0,
	FIFO_WAIT = 4'd1,
	RAM_WAIT  = 4'd2,
	READ_RAM  = 4'd3,
	ACTIVATE  = 4'd4,
	WRITE_RAM = 4'd5,
	START          = 4'd6,
	WAIT           = 4'd7,
	READ_BLOCK     = 4'd8,
	CHECK_BLOCK_GROUP = 4'd9,
	READ_WAIT      = 4'd10,
	READ_CYCLE     = 4'd11,
	RESET_WAIT     = 4'd12,
	RESET_BLOCK    = 4'd13;
	
reg [3:0] state_b;
localparam [3:0]
    PARTITION = 4'd1,
    PARTITION_WAIT = 4'd2;

//==========================
// Tracker Timing Module
//==========================
reg  [7:0] total_active_blocks;
wire [7:0] next_total_active_blocks;
reg  [7:0] counter;
wire [7:0] next_counter;
reg        start_check;
reg        new_active;

assign next_total_active_blocks = total_active_blocks + 1'b1;
assign next_counter = counter + 1'b1;

always @(posedge clk) 
begin
if (~resetn) 
begin
    total_active_blocks <= 8'd0;
    counter <= 8'd0;
    start_check <= 1'b0;
    LOCK <= 1'b0;
end
else if (new_active)
begin 
    total_active_blocks <= next_total_active_blocks;
    counter <= 8'd0;
end
else if ((total_active_blocks >= 9'd128) && (~FIFO_full_mgu_a && ~FIFO_full_mgu_b) && (state_a==IDLE) && Message_FIFO_Empty)
begin
    total_active_blocks <= 8'd0;
    start_check <= 1'b1;
    LOCK <= 1'b1;
end
else if ((counter[6] == 1'b1) && (total_active_blocks > 8'd0) && (~FIFO_full_mgu_a && ~FIFO_full_mgu_b) && (state_a==IDLE) && Message_FIFO_Empty)
begin
    counter <= 8'd0;
    total_active_blocks <= 8'd0;
    start_check <= 1'b1;
    LOCK <= 1'b1;
end
else
begin
    counter <= next_counter;
    start_check <= 1'b0;
    if(UNLOCK) LOCK <= 1'b0;
end
end

//==========================
// Update Block Module
//==========================
wire  [9:0] block_address;
wire  [6:0] block_group_address;
wire  [5:0] vertex_bit_address;
reg  [71:0] temp_block_update;
reg [ADDRWIDTH-1:0] vertex_address;

// Vertex address to block address
assign block_address           = vertex_address[19:10]; // RAM address
assign vertex_bit_address      = vertex_address[9:4]; // 64 bits for vertex data
assign block_group_address     = {5'b10000, vertex_address[9:8]}; // 4 bits for 4 groups of 16 vertex data

//==========================
// Reading Blocks & Send Vertices to FIFO
//==========================
wire  [1:0] next_group;
wire  [1:0] previous_group;
reg   [6:0] group;
wire  [6:0] next_vertex_b;
reg   [5:0] vertex_b;
wire  [6:0] next_vertex_a;
reg   [5:0] vertex_a;
wire  [7:0] next_addr;
wire  [5:0] next_addr_4;
reg   [2:0] read_counter;
wire  [3:0] next_read_counter;
reg  [71:0] temp_block;
reg  [71:0] temp_block_partition;
reg         start_partition;
reg   [2:0] partition_count;
wire  [3:0] next_partition_count;
reg         have_read;

// Next read addr address
assign next_addr = read_addr[15:8] + 1'b1; // Next 16
assign next_addr_4 = read_addr[15:10] + 1'b1; // next 64
assign next_read_counter = read_counter + 1'b1;
assign next_partition_count = partition_count + 1'b1;

assign next_group = group[1:0] + 1'b1;
assign previous_group = group[1:0] - 1'b1;
assign next_vertex_a = vertex_a + 2'b10;
assign next_vertex_b = vertex_b + 2'b10;

    
always @(posedge clk)
begin
if(~resetn)
begin
    start_rd       <= 1'b0;
    have_read       <= 1'b0;
	FIFO_write_mgu_a <= 1'b0;
	FIFO_write_mgu_b <= 1'b0;
	start_partition <= 1'b0;
	axi_in_use_vmu <= 1'b0;
	read_addr      <= {1'b0, 32'h44A00000}; // Base address
	state_a        <= IDLE;
	MPU_VMU_FIFO_Read <= 1'b0;
	RAM_address_a  <= 13'd0;
	RAM_din_a      <= 72'd0;
	WrEnable_a     <= 1'b0;
	new_active     <= 1'b0;
	UNLOCK         <= 1'b0;
	state_b        <= IDLE;
end
else 
begin
case(state_a)
	IDLE:
	begin
	    axi_in_use_vmu <= 1'b0;
	    WrEnable_a <= 1'b0;
	    UNLOCK <= 1'b1;
	    if (start_check) state_a <= START;
		else if(~MPU_VMU_FIFO_Empty && ~LOCK) begin
		    MPU_VMU_FIFO_Read <= 1'b1;
			state_a <= FIFO_WAIT;
		end
	end
	FIFO_WAIT:
	begin
	    MPU_VMU_FIFO_Read <= 1'b0;
	    if (MPU_VMU_FIFO_Read_Valid) begin
            vertex_address <= MPU_VMU_FIFO_ReadData;
            RAM_address_a <= MPU_VMU_FIFO_ReadData[22:10];
            state_a <= RAM_WAIT;
	    end
	end
	RAM_WAIT:
	begin
	   state_a <= READ_RAM;
	end
	READ_RAM: // Read block active bits (64 bits)
	begin
		temp_block_update <= RAM_dout_a;
		state_a    <= ACTIVATE;
	end
	ACTIVATE: // Check if already active
	begin
		if (temp_block_update[vertex_bit_address] == 1'b0)
		begin
		    new_active <= 1'b1;
		    temp_block_update[block_group_address] <= 1'b1;
			temp_block_update[vertex_bit_address] <= 1'b1;
			state_a <= WRITE_RAM;
		end
		else
		begin
			state_a <= IDLE; // Skip cycle if already active
		end
	end
	WRITE_RAM: // Write back activated block bit
	begin
	    new_active <= 1'b0;
		RAM_din_a  <= temp_block_update;
		WrEnable_a <= 1'b1;
		state_a    <= IDLE;
	end
// Read from RAM for active vertices
    START:
	begin
        read_counter <= 3'd0;
        read_addr  <= {1'b0, 32'h44A00000};
        RAM_din_a   <= 72'd0;
        UNLOCK <= 1'b0;
        axi_in_use_vmu <= 1'b1;
        RAM_address_a <= 13'd0;
        state_a <= WAIT;
	end
	WAIT:
	begin
	   if (RAM_address_a[7] == 1'b1) begin // Last 1024 address (1024 blocks)
	       state_a <= IDLE;
	    end
	   else state_a <= READ_BLOCK;
	end
	READ_BLOCK:
	begin
		  group <= 7'd64;
		  temp_block <= RAM_dout_a;
	      state_a <= CHECK_BLOCK_GROUP;
	end
	CHECK_BLOCK_GROUP: // Read block active bits (64 bits)
	begin
	    start_partition <= 1'b0;
	    if (~axi_in_use_mpu) begin
	    if (temp_block[67:64] == 4'b0000) begin // Skip if block is not active
	       RAM_address_a <= next_RAM_address;
	       read_addr[15:0] <= {next_addr_4, 10'b0000000000};
	       state_a <= WAIT;
	    end
	    else if (temp_block[group] == 1'b0) // Skip if group not active
	    begin
	        read_addr[15:0] <= {next_addr, 8'b00000000};
	        if (group[1:0]==2'b11 && have_read)
	 	    begin
	 	         WrEnable_a    <= 1'b1;
	 	         have_read     <= 1'b0;
	 	         state_a       <= RESET_BLOCK;
	 	         end
	       else group[1:0] <= next_group;
	    end
	    else
	    begin
	       start_rd <= 1'b1;
	       have_read <= 1'b1;
		   state_a <= READ_WAIT;
		end
		end
    end
    READ_WAIT:
    begin
        start_rd <= 1'b0;
        if(end_rd) state_a <= READ_CYCLE;
    end
	READ_CYCLE: // Read 8 Times (16 vertices)
	begin // Give temp block to partition reduces needed cycles before reading temp block
	    store_read_data[read_counter] <= read_data;
	 	if (read_counter == 3'b111) // Finished 8 Reads (start partition)
	 	begin
	 	    read_counter  <= 3'b000;
	 	    start_partition <= 1'b1;
	 	    read_addr[15:0] <=  {next_addr, 8'b00000000};
	 	    vertex_a <= (group[1:0]*5'd16);
            vertex_b <= (group[1:0]*5'd16) + 1'b1;
	 	    if (group[1:0]==2'b11)
	 	    begin
	 	         WrEnable_a    <= 1'b1;
	 	         state_a         <= RESET_BLOCK;
	 	         end
	 	    else begin
	 	         state_a <= CHECK_BLOCK_GROUP;
	 	         group[1:0]   <= next_group;
	 	    end
	 	end
	 	else
	 	begin
	 	    read_counter <= next_read_counter;
	 	end
	end
	RESET_BLOCK:
	begin
	   WrEnable_a    <= 1'b0;
	   start_partition <= 1'b0;
	   RAM_address_a <= next_RAM_address;
	   state_a         <= WAIT;
	end
	default: state_a <= IDLE;
	endcase
	
case(state_b) // Completes a partition in max 2 cycles (always outpaces AXI reads)
    IDLE:
    begin
        FIFO_write_mgu_a <= 1'b0;
        FIFO_write_mgu_b <= 1'b0;
        FIFO_data_mgu_a <= 94'd0;
        FIFO_data_mgu_b <= 94'd0;
        partition_count <= 3'd0;
        if (start_partition) begin 
            temp_block_partition <= temp_block;
            active_read_data <= store_read_data[0];
            state_b <= PARTITION;
            end
    end
    PARTITION:
    begin
            if (temp_block_partition[vertex_a]) begin 
                FIFO_write_mgu_a <= 1'b1;
                FIFO_data_mgu_a <= {prop[0], edge_index[0], edge_degree[0]};
            end
            else begin 
                FIFO_write_mgu_a <= 1'b0;
                FIFO_data_mgu_a <= 94'd0;
            end
            vertex_a <= next_vertex_a;
            
            if (temp_block_partition[vertex_b]) begin 
                FIFO_write_mgu_b <= 1'b1;
                FIFO_data_mgu_b <= {prop[1], edge_index[1], edge_degree[1]};
            end
            else begin 
                FIFO_write_mgu_b <= 1'b0;
                FIFO_data_mgu_b <= 94'd0;
            end
            vertex_b <= next_vertex_b;
            
        if(next_partition_count[3] == 1'b1) state_b <= IDLE;
        else begin 
            partition_count <= next_partition_count;
            active_read_data <= store_read_data[next_partition_count];
            if (temp_block_partition[vertex_a] || temp_block_partition[vertex_b]) state_b <= PARTITION_WAIT;
        end
    end
    PARTITION_WAIT:
    begin
        FIFO_write_mgu_a <= 1'b0;
        FIFO_write_mgu_b <= 1'b0;
        state_b <= PARTITION;
    end
    default: state_b <= IDLE;
    endcase
end
end
endmodule
