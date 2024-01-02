`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of California, Davis
// Engineer: Austin York
// 
// Create Date: 10/27/2023 12:49:19 PM
// Design Name: Message Generation Unit
// Module Name: MGU
// Project Name: SEGA Architecture
// Target Devices: Xilinx AU280
// Tool Versions: Vivado 2022.1
// Description: Take active vertices and associated edges to propogate new update messages to neighboring vertices
// 
// Dependencies: AXI Engine, Vertex Management Unit, Associated Memory (DDR4)
// 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//===============================================================
//                   Message Generation Unit
//===============================================================
module MGU #(
	parameter VPropWidth   = 32,  // Vertex Prop Width (value that gets changed)
	parameter EIndexWidth  = 32,  // Edge Address Width 32 = 4GB
	parameter EDegreeWidth = 30,  // Edge Degree Width
	parameter DataWidth    = 512, // DDR4 data width
	parameter MsgWidth     = 64,  // output message width (also known as update)
	parameter VMUDataWidth = 94   // Vertex prop and edge information from MPU/VMU
)(
    input 						 clk,            // should be 450 MHz
	input 						 resetn,         // negative reset
//---------------------Message FIFO Signals--------------------//
	output reg    [MsgWidth-1:0] FIFO_data_msg,  // FIFO output message
	output reg                   FIFO_write_msg, // Write FIFO
    input                        FIFO_full_msg, // FIFO empty
	
//-----------------------VMU FIFO Signals----------------------//
	input     [VMUDataWidth-1:0] FIFO_data_vmu_a,  // FIFO Data VMU
	output reg                   FIFO_read_vmu_a,  // Read FIFO
	input                        FIFO_empty_vmu_a, // FIFO empty
	input                        FIFO_read_valid_vmu_a,
	
	input     [VMUDataWidth-1:0] FIFO_data_vmu_b,  // FIFO Data VMU
	output reg                   FIFO_read_vmu_b,  // Read FIFO
	input                        FIFO_empty_vmu_b, // FIFO empty
	input                        FIFO_read_valid_vmu_b,

//-----------------------Begin/Stop Read-----------------------//
	output reg [EIndexWidth-1:0] read_addr,      // old vertex address
	input	     [DataWidth-1:0] read_data,      // old vertex data
	output reg	   			     start_rd,       // start read
	input                        end_rd          // finished rea
);

//----------------------Registers and Wires--------------------//
reg     [DataWidth-1:0] store_read_data; // Store read from DDR4
//reg  [VMUDataWidth-1:0] data_reg;        // Store FIFO data
reg               [2:0] current_edge;    // Current Edge
wire              [3:0] next_edge;       // Edge + 1
reg  [EDegreeWidth-1:0] completed_edges;
wire [EDegreeWidth-1:0] completed_edges_plusone;
reg  [EDegreeWidth-1:0] total_edges;
reg    [VPropWidth-1:0] new_value;       // Updated value
reg    [VPropWidth-1:0] prop;            // active prop
wire             [15:0] weight[7:0];    // edge weight
wire             [47:0] neighbor[7:0];  // edge neighbor vertex
reg              [15:0] active_weight;
reg              [47:0] active_neighbor;
wire  [EIndexWidth-1:0] next_addr;       // next 8 edge read, byte address
reg                     fifo_a;

genvar i;

//--------------------Actively Assigned Values-----------------//
assign next_edge               = current_edge + 1'b1;
assign completed_edges_plusone = completed_edges + 1'b1;
assign next_addr               = {read_addr[31:20], (read_addr[19:6] + 1'b1), 6'b000000};

generate 
for (i=0; i < 8; i=i+1) begin
assign weight[i] = {store_read_data[55+(64*i):48+(64*i)], store_read_data[63+(64*i):56+(64*i)]}; // Left 16 bits (convert to big endian)
assign neighbor[i] = {store_read_data[7+(64*i):0+(64*i)], store_read_data[15+(64*i):8+(64*i)], store_read_data[23+(64*i):16+(64*i)],
                      store_read_data[31+(64*i):24+(64*i)], store_read_data[39+(64*i):32+(64*i)], store_read_data[47+(64*i):40+(64*i)]}; // Right 48 bits (convert to big endian) + offset
end
endgenerate
//-------------------------FSM States--------------------------//
reg [3:0] state;
localparam [3:0]
    IDLE          = 4'd0,
    READ          = 4'd1,
    READ_WAIT     = 4'd2,
    STORE_READ    = 4'd3,
    CHECK_EDGES   = 4'd4,
    COMPUTE       = 4'd5,
    PROPOGATE     = 4'd6;
    
//-------------------------Edge Reads--------------------------//
localparam [2:0]
    ONE           = 3'd0,
    TWO           = 3'd1,
    THREE         = 3'd2,
    FOUR          = 3'd3,
    FIVE          = 3'd4,
    SIX           = 3'd5,
    SEVEN         = 3'd6,
    EIGHT         = 3'd7;
    
//===============================================================
//                       FSM (Main Logic)
//===============================================================
always @(posedge clk)
begin
if (~resetn) // Reset 
begin
    FIFO_read_vmu_a <= 1'b0;
    FIFO_read_vmu_b <= 1'b0;
    FIFO_write_msg <= 1'b0;
    FIFO_data_msg <= {MsgWidth{1'b0}};
    read_addr      <= {EIndexWidth{1'b0}};
    start_rd       <= 1'b0;
    state          <= IDLE;
end
else
begin

    case(state)
    IDLE:         // Wait for data
	begin
	    FIFO_write_msg      <= 1'b0;
	    FIFO_data_msg <= {MsgWidth{1'b0}};
		if(~FIFO_empty_vmu_a) // data in fifo
		begin
		    FIFO_read_vmu_a  <= 1'b1;
		    fifo_a           <= 1'b1;
		    state            <= READ;
		end
		else if (~FIFO_empty_vmu_b)
		begin
		    FIFO_read_vmu_b  <= 1'b1;
		    fifo_a           <= 1'b0;
		    state            <= READ;
		end
	end
	READ:         // Read Edges from DDR4
	begin
	   FIFO_read_vmu_a      <= 1'b0;
	   FIFO_read_vmu_b      <= 1'b0;
	   if (FIFO_read_valid_vmu_a || FIFO_read_valid_vmu_b) begin
		start_rd            <= 1'b1;
		if(fifo_a) begin
            prop                <= FIFO_data_vmu_a[93:62];
            read_addr           <= {12'h44a, FIFO_data_vmu_a[46:33], 6'b000000}; // Edge group of 8
            current_edge        <= FIFO_data_vmu_a[32:30]; // Edge Offset (starting edge value)
            total_edges         <= FIFO_data_vmu_a[29:0];
	    end
	    else begin
            prop                <= FIFO_data_vmu_b[93:62];
            read_addr           <= {12'h44a, FIFO_data_vmu_b[46:33], 6'b000000}; // Edge group of 8
            current_edge        <= FIFO_data_vmu_b[32:30]; // Edge Offset (starting edge value)
            total_edges         <= FIFO_data_vmu_b[29:0];
	    end
	    completed_edges     <= {EDegreeWidth{1'b0}};
		state               <= READ_WAIT;
		end
	end
	READ_WAIT:    // Wait for read to complete
	begin
	    FIFO_write_msg      <= 1'b0;
	    FIFO_data_msg <= {MsgWidth{1'b0}};
		start_rd            <= 1'b0;
		if (end_rd) state   <= STORE_READ;
	end
	STORE_READ:
	begin
	    store_read_data <= read_data;
		state           <= CHECK_EDGES;
	end
    CHECK_EDGES:
    begin
            FIFO_write_msg  <= 1'b0;
            FIFO_data_msg <= {MsgWidth{1'b0}};
            state           <= COMPUTE;
            case(current_edge[2:0])
            ONE:
            begin
                active_weight <= weight[0];
                active_neighbor <= neighbor[0];
            end
            TWO:
            begin
                active_weight <= weight[1];
                active_neighbor <= neighbor[1];
            end 
            THREE:
            begin
                active_weight <= weight[2];
                active_neighbor <= neighbor[2];
            end 
            FOUR:
            begin
                active_weight <= weight[3];
                active_neighbor <= neighbor[3];
            end 
            FIVE:
            begin
                active_weight <= weight[4];
                active_neighbor <= neighbor[4];
            end 
            SIX:
            begin
                active_weight <= weight[5];
                active_neighbor <= neighbor[5];
            end 
            SEVEN:
            begin
                active_weight <= weight[6];
                active_neighbor <= neighbor[6];
            end 
            EIGHT:
            begin
                active_weight <= weight[7];
                active_neighbor <= neighbor[7];
            end
            
            default:
            begin
                state       <= IDLE; //PROPOGATE_END;
            end
            endcase
    end
    COMPUTE:
    begin
        new_value           <= prop + active_weight;
        state               <= PROPOGATE;
    end
    PROPOGATE:
    begin
        if(~FIFO_full_msg) begin
        FIFO_data_msg       <= {active_neighbor[32:0], new_value[30:0]};
        FIFO_write_msg      <= 1'b1;
        
        if (completed_edges_plusone == total_edges)
        begin
            state           <= IDLE; //PROPOGATE_END;
        end
        else if (next_edge[3] == 1'b1)
        begin
            start_rd        <= 1'b1;
            read_addr       <= next_addr; 
            current_edge    <= 3'b000;
            completed_edges <= completed_edges_plusone;
            state           <= READ_WAIT;
        end
        else 
        begin 
            current_edge    <= next_edge;
            completed_edges <= completed_edges_plusone;
            state           <= CHECK_EDGES;
        end
        end
    end
    default: state <= IDLE;
    endcase
end
end
    
endmodule
