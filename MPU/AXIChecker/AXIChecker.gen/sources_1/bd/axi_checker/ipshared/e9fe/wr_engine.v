`timescale 1ns / 1ps

//=====================================
//             Write Engine
//=====================================
module wr_engine #(
    parameter ENGINE_ID   = 0,
    parameter ADDR_WIDTH  = 33,                   // 8G-->33 bits
    parameter DATA_WIDTH  = 256,                  // 256 HBM & 512 DDR4
    parameter ID_WIDTH    = 6,
    parameter LEN_WIDTH   = 8
)(
    input                         clk,            // should be 450MHz
    input                         resetn,          // negative reset

    //-------------------Begin/Stop Write--------------------//
    input                         start,
    input      [ADDR_WIDTH - 1:0] write_addr,
    input      [DATA_WIDTH - 1:0] write_data,
    output reg                    end_of_write,

    //----------------------AXI Signals----------------------//
    // Write Address (Output) 
    output                        m_axi_AWVALID,  // wr address valid
    output reg [ADDR_WIDTH - 1:0] m_axi_AWADDR,   // wr byte address
    output reg   [ID_WIDTH - 1:0] m_axi_AWID,     // wr address id
    output reg  [LEN_WIDTH - 1:0] m_axi_AWLEN,    // wr burst = awlen+1
    output reg              [2:0] m_axi_AWSIZE,   // wr 3'b101, 32B
    output reg              [1:0] m_axi_AWBURST,  // wr burst type: 01 (INC), 00 (FIXED)
    output reg              [1:0] m_axi_AWLOCK,   // wr no
    output reg              [3:0] m_axi_AWCACHE,  // wr no
    output reg              [2:0] m_axi_AWPROT,   // wr no
    output reg              [3:0] m_axi_AWQOS,    // wr no
    output reg              [3:0] m_axi_AWREGION, // wr no
    input                         m_axi_AWREADY,  // wr ready to accept address.

    // Write Data (Output)
    output                        m_axi_WVALID,   // wr data valid
    output reg [DATA_WIDTH - 1:0] m_axi_WDATA,    // wr data
    output reg [DATA_WIDTH/8-1:0] m_axi_WSTRB,    // wr data strob
    output                        m_axi_WLAST,    // wr last beat in a burst
    output reg   [ID_WIDTH - 1:0] m_axi_WID,      // wr data id
    input                         m_axi_WREADY,   // wr ready to accept data

    // Write Response (Input)
    input                         m_axi_BVALID,   // wr response valid
    input                   [1:0] m_axi_BRESP,    // wr response status
    input        [ID_WIDTH - 1:0] m_axi_BID,      // wr response id
    output                        m_axi_BREADY    // wr response ready
);

reg started;
wire response;
reg guard_AWVALID, guard_WVALID, guard_BREADY, guard_WLAST;

always @(posedge clk)
begin
if (~resetn)
    started   <= 1'b0;
else
    started   <= start;
end

//----------------------Parameters----------------------//
always @(posedge clk)
begin
    m_axi_AWID     <= {ID_WIDTH{1'b0}};
    m_axi_AWLEN    <= {LEN_WIDTH{1'b0}}; // 1-1 length, 1 beat
    m_axi_AWSIZE   <= (DATA_WIDTH == 256)? 3'b101:3'b110; //just for 256-bit or 512-bit.
    m_axi_AWBURST  <= 2'b00;   // INC (01), FIXED (00)
    m_axi_AWLOCK   <= 2'b00;   // Normal memory operation
    m_axi_AWCACHE  <= 4'b0000; // 4'b0011; // Normal, non-cacheable, modifiable, bufferable (Xilinx recommends)
    m_axi_AWPROT   <= 3'b010;  // 3'b000;  // Normal, secure, data
    m_axi_AWQOS    <= 4'b0000; // Not participating in any Qos schem, a higher value indicates a higher priority transaction
    m_axi_AWREGION <= 4'b0000; // Region indicator, default to 0
    m_axi_WDATA    <= write_data; // wr data
    m_axi_AWADDR    <= write_addr;
    m_axi_WSTRB    <= {(DATA_WIDTH/8){1'b1}}; // wr select by byte
    m_axi_WID      <= {ID_WIDTH{1'b0}}; // wr id
end


assign m_axi_BREADY  = guard_BREADY;  // Always ready
assign m_axi_AWVALID = guard_AWVALID; // wr address valid
assign m_axi_WLAST   = guard_WLAST;   // wlast is 1 for the last beat.
assign m_axi_WVALID  = guard_WVALID;  // wr data valid
assign response      = (m_axi_BRESP==2'b00 || m_axi_BRESP==2'b01) ? 1'b1:1'b0; // 00/01 OKAY, 10/11 ERRORS

//----------------------FSM For Addr & Data----------------------//
reg [2:0] state;
localparam [2:0]
    WR_IDLE     = 3'b000,
    WR_ADDR     = 3'b001,
    WR_DATA     = 3'b010,
    WR_END      = 3'b011,
    WR_RETRY    = 3'b100;

always@(posedge clk)
begin
if (~resetn) begin
    state <= WR_IDLE;
    end_of_write  <= 1'b0;
    guard_AWVALID <= 1'b0;
    guard_WVALID  <= 1'b0;
    guard_BREADY  <= 1'b0;
    guard_WLAST   <= 1'b0;
    end
else
begin
//    end_of_write  <= 1'b0;
//    guard_AWVALID <= 1'b0;
//    guard_WVALID  <= 1'b0;
//    guard_BREADY  <= 1'b0;
//    guard_WLAST   <= 1'b0;
    case (state)
        
        WR_IDLE:
        begin
            end_of_write  <= 1'b0;
            guard_BREADY   <= 1'b0;
            guard_AWVALID  <= 1'b0;
            guard_WVALID       <= 1'b0;
            guard_WLAST        <= 1'b0;
            if (started)
                state          <= WR_ADDR;
        end
        
        WR_ADDR: // Write Address
        begin
            guard_AWVALID      <= 1'b1;
            //m_axi_AWADDR       <= write_addr;
            if (m_axi_AWREADY)// & m_axi_AWVALID)
                state          <= WR_DATA;
        end
        
        WR_DATA: // Write Data
        begin
            guard_AWVALID      <= 1'b0;
            guard_WVALID       <= 1'b1;
            guard_WLAST        <= 1'b1;
            if (m_axi_WREADY)// & guard_WVALID)
            begin
                state          <= WR_END;
            end
        end
        
        WR_END:  // End Write and Check Response
        begin
            guard_WVALID       <= 1'b0;
            guard_WLAST        <= 1'b0;
            if (m_axi_BVALID & response) // Write successful
            begin
                guard_BREADY   <= 1'b1;
                end_of_write   <= 1'b1;
                state          <= WR_IDLE;
            end
            else if (m_axi_BVALID & ~response) // Write failed
            begin
                guard_BREADY   <= 1'b1;
                state          <= WR_RETRY;
            end
        end

        WR_RETRY: // Write retry delay 1 cycle
        begin
            guard_BREADY   <= 1'b0;
            state              <= WR_ADDR;
        end
        
        default: state         <= WR_IDLE;
    endcase
end
end
endmodule
