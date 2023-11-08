/*
 * Original Source: Copyright 2019 - 2020, RC4ML, Zhejiang University, https://github.com/RC4ML/Shuhai
 * Modifications: Austin York, University of California, Davis
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
//             Read Engine
//=====================================
module rd_engine #(
    parameter ENGINE_ID   = 0,
    parameter ADDR_WIDTH  = 33,                   // 8G-->33 bits
    parameter DATA_WIDTH  = 256,                  // 256 HBM & 512 DDR4
    parameter ID_WIDTH    = 6,    
    parameter LEN_WIDTH   = 8
)(
    input                         clk,            // should be 450MHz
    input                         resetn,          // negative reset 

    //-------------------Begin/Stop Read----------------------//
    input                         start,
    input      [ADDR_WIDTH - 1:0] read_addr,
    output reg [DATA_WIDTH - 1:0] read_data,
    output reg                    end_of_read,

    //----------------------AXI Signals----------------------//
    // Read Address (Output)  
    output                        m_axi_ARVALID,  // rd address valid
    output reg [ADDR_WIDTH - 1:0] m_axi_ARADDR,   // rd byte address
    output reg   [ID_WIDTH - 1:0] m_axi_ARID,     // rd address id
    output reg  [LEN_WIDTH - 1:0] m_axi_ARLEN,    // rd burst=awlen+1
    output reg              [2:0] m_axi_ARSIZE,   // rd 3'b101, 32B
    output reg              [1:0] m_axi_ARBURST,  // rd burst type: 01 (INC), 00 (FIXED)
    output reg              [1:0] m_axi_ARLOCK,   // rd no
    output reg              [3:0] m_axi_ARCACHE,  // rd no
    output reg              [2:0] m_axi_ARPROT,   // rd no
    output reg              [3:0] m_axi_ARQOS,    // rd no
    output reg              [3:0] m_axi_ARREGION, // rd no
    input                         m_axi_ARREADY,  // rd ready to accept address.

    // Read Data (input)
    input                         m_axi_RVALID,   // rd data valid
    input      [DATA_WIDTH - 1:0] m_axi_RDATA,    // rd data // NEED TO STORE THIS VALUE
    input                         m_axi_RLAST,    // rd data last
    input        [ID_WIDTH - 1:0] m_axi_RID,      // rd data id
    input                   [1:0] m_axi_RRESP,    // rd data status
    output                        m_axi_RREADY    // rd ready to accept data
);

reg started;
wire resp;
reg guard_ARVALID, guard_RREADY;

always @(posedge clk) 
begin
    if(~resetn)
        started  <= 1'b0;
    else 
        started  <= start;
end

//----------------------Parameters----------------------//
always @(posedge clk) 
begin
    m_axi_ARID     <= {ID_WIDTH{1'b0}};
    m_axi_ARLEN    <= {LEN_WIDTH{1'b0}}; // 1-1 length, 1 burst
    m_axi_ARSIZE   <= (DATA_WIDTH==256)? 3'b101:3'b110; // 256-bit or 512-bit.
    m_axi_ARBURST  <= 2'b01;   // INC, not FIXED (00)
    m_axi_ARLOCK   <= 2'b00;   // Normal memory operation
    m_axi_ARCACHE  <= 4'b0000; // 4'b0011: Normal, non-cacheable, modifiable, bufferable (Xilinx recommends)
    m_axi_ARPROT   <= 3'b010;  // 3'b000: Normal, secure, data
    m_axi_ARQOS    <= 4'b0000; // Not participating in any Qos schem, a higher value indicates a higher priority transaction
    m_axi_ARREGION <= 4'b0000; // Region indicator, default to 0
    m_axi_ARADDR   <= read_addr; // rd address
end

assign m_axi_RREADY  = guard_RREADY;  // Ready for data
assign m_axi_ARVALID = guard_ARVALID; // Address valid
assign resp          = (m_axi_RRESP==2'b00 || m_axi_RRESP==2'b01) ? 1'b1:1'b0; // 00/01 OKAY, 10/11 ERRORS

//----------------------FSM For Addr & Data----------------------//
reg [2:0] state;
localparam [2:0]
    RD_IDLE     = 3'b000,
    RD_ADDR     = 3'b001,
    RD_DATA     = 3'b010,
    RD_END      = 3'b011,
    RD_RETRY    = 3'b100;

always@(posedge clk) 
begin
if(~resetn)
begin
    state         <= RD_IDLE;
    read_data     <= {DATA_WIDTH{1'b0}};
    end_of_read   <= 1'b0;
    guard_ARVALID <= 1'b0;
    guard_RREADY  <= 1'b0;
end
else 
begin

    case (state)

        RD_IDLE: 
        begin
            end_of_read   <= 1'b0;
            guard_ARVALID <= 1'b0;
            guard_RREADY  <= 1'b0;
            if(started)
            begin
                read_data <= {DATA_WIDTH{1'b0}};
                state     <= RD_ADDR;
            end  
        end

        RD_ADDR: // Read Address
        begin  
            if (m_axi_ARREADY & m_axi_ARVALID) // Address is ready
            begin
                guard_ARVALID  <= 1'b0;
                state          <= RD_DATA;  
            end
            else guard_ARVALID <= 1'b1;
        end
        
        RD_DATA: // Read Data and Check Response (IMPORTANT! ONLY 1 BURST)
        begin
            if (m_axi_RLAST & m_axi_RVALID & resp) // Last read and successful
            begin
                guard_RREADY   <= 1'b1;
                read_data      <= m_axi_RDATA;
                state          <= RD_END;           
            end
            else if (m_axi_RLAST & m_axi_RVALID & ~resp) // Last read and failed
            begin
                guard_RREADY   <= 1'b1;
                state          <= RD_RETRY;
            end
        end

        RD_END:  // End Read
        begin
            guard_RREADY       <= 1'b0;
            end_of_read        <= 1'b1; 
            state              <= RD_IDLE;
        end

        RD_RETRY: // Read Retry delay 1 cycle
        begin
            guard_RREADY       <= 1'b0;
            state              <= RD_ADDR;
        end
        
        default: state       <= RD_IDLE;             
    endcase
end 
end
endmodule
