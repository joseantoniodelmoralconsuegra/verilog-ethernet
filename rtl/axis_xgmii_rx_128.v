/*

Copyright (c) 2015-2017 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * AXI4-Stream XGMII frame receiver (XGMII in, AXI out)
 */
module axis_xgmii_rx_128 #
(
    parameter DATA_WIDTH = 128,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter CTRL_WIDTH = (DATA_WIDTH/8),
    parameter PTP_TS_ENABLE = 0,
    parameter PTP_TS_FMT_TOD = 1,
    parameter PTP_TS_WIDTH = PTP_TS_FMT_TOD ? 96 : 64,
    parameter USER_WIDTH = (PTP_TS_ENABLE ? PTP_TS_WIDTH : 0) + 1
)
(
    input  wire                     clk,
    input  wire                     rst,

    /*
     * XGMII input
     */
    input  wire [DATA_WIDTH-1:0]    xgmii_rxd,
    input  wire [CTRL_WIDTH-1:0]    xgmii_rxc,

    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire                     m_axis_tvalid,
    output wire                     m_axis_tlast,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,

    /*
     * PTP
     */
    input  wire [PTP_TS_WIDTH-1:0]  ptp_ts,

    /*
     * Configuration
     */
    input  wire                     cfg_rx_enable,

    /*
     * Status
     */
    output wire [1:0]               start_packet,
    output wire                     error_bad_frame,
    output wire                     error_bad_fcs
);

// bus width assertions
initial begin
    if (DATA_WIDTH != 128) begin
        $error("Error: Interface width must be 128");
        $finish;
    end

    if (KEEP_WIDTH * 8 != DATA_WIDTH || CTRL_WIDTH * 8 != DATA_WIDTH) begin
        $error("Error: Interface requires byte (8-bit) granularity");
        $finish;
    end
end

localparam [7:0]
    ETH_PRE = 8'h55,
    ETH_SFD = 8'hD5;

localparam [7:0]
    XGMII_IDLE = 8'h07,
    XGMII_START = 8'hfb,
    XGMII_TERM = 8'hfd,
    XGMII_ERROR = 8'hfe;

localparam [1:0]
    STATE_IDLE = 2'd0,
    STATE_PAYLOAD = 2'd1,
    STATE_LAST = 2'd2,
    STATE_PREAMBLE = 2'd3;

reg [1:0] state_reg = STATE_IDLE, state_next, state_prev = STATE_IDLE;

// datapath control signals
reg reset_crc;

reg lanes_swapped = 1'b0;
reg lanes_swapped_reg = 1'b0;
reg [63:0] swap_rxd = 32'd0;
reg [7:0] swap_rxc = 8'd0;
reg [7:0] swap_rxc_term = 8'd0;

reg [63:0] swap_rxd_reg = 32'd0;
reg [7:0] swap_rxc_reg = 8'd0;
reg [7:0] swap_rxc_term_reg = 8'd0;

reg [DATA_WIDTH-1:0] xgmii_rxd_masked = {DATA_WIDTH{1'b0}};
reg [CTRL_WIDTH-1:0] xgmii_term = {CTRL_WIDTH{1'b0}};
reg [CTRL_WIDTH-1:0] xgmii_term_d0 = {CTRL_WIDTH{1'b0}};
reg [CTRL_WIDTH-1:0] xgmii_term_d1 = {CTRL_WIDTH{1'b0}};
reg [3:0] term_lane_reg = 0, term_lane_d0_reg = 0, term_lane_d1_reg = 0, term_lane_d2_reg, term_lane_reg_2 = 0;
reg term_present_reg = 1'b0, term_present_d0_reg = 1'b0, term_present_reg_2 = 1'b0;
reg framing_error_reg = 1'b0, framing_error_d0_reg = 1'b0, framing_error_d1_reg = 1'b0, framing_error_d2_reg = 1'b0, framing_error_reg_data = 1'b0;

reg [DATA_WIDTH-1:0] xgmii_rxd_d0 = {DATA_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0] xgmii_rxd_d1 = {DATA_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0] xgmii_rxd_d2 = {DATA_WIDTH{1'b0}};
reg [DATA_WIDTH-1:0] xgmii_rxd_d0_no_masked = {DATA_WIDTH{1'b0}};

reg [CTRL_WIDTH-1:0] xgmii_rxc_d0 = {CTRL_WIDTH{1'b0}};
reg [CTRL_WIDTH-1:0] xgmii_rxc_d1 = {CTRL_WIDTH{1'b0}};
reg [CTRL_WIDTH-1:0] xgmii_rxc_d0_no_masked = {CTRL_WIDTH{1'b0}};

reg xgmii_start_swap = 1'b0;
reg xgmii_start_d0 = 1'b0;
reg xgmii_start_d1 = 1'b0;

reg [3:0] chivato = 4'h0;

reg [DATA_WIDTH-1:0] m_axis_tdata_reg = {DATA_WIDTH{1'b0}}, m_axis_tdata_next;
reg [KEEP_WIDTH-1:0] m_axis_tkeep_reg = {KEEP_WIDTH{1'b0}}, m_axis_tkeep_next;
reg m_axis_tvalid_reg = 1'b0, m_axis_tvalid_next;
reg m_axis_tlast_reg = 1'b0, m_axis_tlast_next;
reg [USER_WIDTH-1:0] m_axis_tuser_reg = {USER_WIDTH{1'b0}}, m_axis_tuser_next;

reg [1:0] start_packet_reg = 2'b00;
reg error_bad_frame_reg = 1'b0, error_bad_frame_next;
reg error_bad_fcs_reg = 1'b0, error_bad_fcs_next;

reg [PTP_TS_WIDTH-1:0] ptp_ts_reg = 0;
reg [PTP_TS_WIDTH-1:0] ptp_ts_adj_reg = 0;
reg ptp_ts_borrow_reg = 0;

reg [31:0] crc_state = 32'hFFFFFFFF;

wire [31:0] crc_next;

wire [15:0] crc_valid;
reg [15:0] crc_valid_save;
reg [15:0] crc_valid_save_2;

assign crc_valid[15] = crc_next == ~32'h2144df1c; // Complemento bit a bit: 0xDEBB20E3
assign crc_valid[14] = crc_next == ~32'hc622f71d; // Complemento bit a bit: 0x39DD08E2
assign crc_valid[13] = crc_next == ~32'hb1c2a1a3; // Complemento bit a bit: 0x4E3D5E5C
assign crc_valid[12] = crc_next == ~32'h9d6cdf7e; // Complemento bit a bit: 0x62932081
assign crc_valid[11] = crc_next == ~32'h6522df69; // Complemento bit a bit: 0x9ADDC096
assign crc_valid[10] = crc_next == ~32'he60914ae; // Complemento bit a bit: 0x19F6EB51
assign crc_valid[9] = crc_next == ~32'he38a6876; // Complemento bit a bit: 0x1C759789
assign crc_valid[8] = crc_next == ~32'h6b87b1ec; // Complemento bit a bit: 0x94784E13
assign crc_valid[7] = crc_next == ~32'h7bd5c66f;   // crc_next == 32'h842A3990 ***
assign crc_valid[6] = crc_next == ~32'h0f74c682;   // crc_next == 32'hf08bb97d ***
assign crc_valid[5] = crc_next == ~32'hd1bb79c7;   // crc_next == 32'h2e448638 ***
assign crc_valid[4] = crc_next == ~32'hd7d303e7;   // crc_next == 32'h282cfc18 ***
assign crc_valid[3] = crc_next == ~32'hecbb4b55;   // crc_next == 32'h1344b4aa ****
assign crc_valid[2] = crc_next == ~32'hc9eff1bd;   // crc_next == 32'h36100e42 ***
assign crc_valid[1] = crc_next == ~32'h671bcf4d;   // crc_next == 32'h98e430b2 ***
assign crc_valid[0] = crc_next == ~32'hda08c96f;   // crc_next == 32'h25f73690 ***


reg [4+16-1:0] last_ts_reg = 0;
reg [4+16-1:0] ts_inc_reg = 0;

assign m_axis_tdata = m_axis_tdata_reg;
assign m_axis_tkeep = m_axis_tkeep_reg;
assign m_axis_tvalid = m_axis_tvalid_reg;
assign m_axis_tlast = m_axis_tlast_reg;
assign m_axis_tuser = m_axis_tuser_reg;

assign start_packet = start_packet_reg;
assign error_bad_frame = error_bad_frame_reg;
assign error_bad_fcs = error_bad_fcs_reg;

reg [127:0] data_in;

always @(*) begin
    data_in = {xgmii_rxd_d1[63:0], xgmii_rxd_d2[127:64]};

    if (data_in[63:0] == 64'hD555555555555500) begin
        data_in[63:0] = 64'h0000000000000000;
    end
    if (data_in[127:64] == 64'hD555555555555500) begin
        data_in[127:64] = 64'h0000000000000000;
    end
end

lfsr #(
    .LFSR_WIDTH(32),
    .LFSR_POLY(32'h4c11db7),
    .LFSR_CONFIG("GALOIS"),
    .LFSR_FEED_FORWARD(0),
    .REVERSE(1),
    .DATA_WIDTH(128),
    .STYLE("AUTO")
)
eth_crc (
    .data_in(data_in),
    .state_in(crc_state),
    .data_out(),
    .state_out(crc_next)
);

// Mask input data
integer j;

always @* begin
    for (j = 0; j < 16; j = j + 1) begin
        xgmii_rxd_masked[j*8 +: 8] = xgmii_rxc[j] ? 8'd0 : xgmii_rxd[j*8 +: 8];
        xgmii_term[j] = xgmii_rxc[j] && (xgmii_rxd[j*8 +: 8] == XGMII_TERM);
    end
end

always @* begin
    state_next = STATE_IDLE;

    reset_crc = 1'b0;

    m_axis_tdata_next = xgmii_rxd_d2; // m_axis_tdata_next = xgmii_rxd_d1;
    m_axis_tkeep_next = {KEEP_WIDTH{1'b1}};
    m_axis_tvalid_next = 1'b0;
    m_axis_tlast_next = 1'b0;
    m_axis_tuser_next = m_axis_tuser_reg;
    m_axis_tuser_next[0] = 1'b0;

    error_bad_frame_next = 1'b0;
    error_bad_fcs_next = 1'b0;

    case (state_reg)
        STATE_IDLE: begin
            // idle state - wait for packet
            reset_crc = 1'b1;
            
            if (xgmii_start_d1 && cfg_rx_enable) begin
                // start condition

                // reset_crc = 1'b0;
                // m_axis_tvalid_next = 1'b1; //
                state_next = STATE_PREAMBLE;
            end else begin
                state_next = STATE_IDLE;
            end

            if (state_prev == STATE_PAYLOAD && (
                (term_lane_d1_reg == 0 && crc_valid[7]) || 
                (term_lane_d1_reg == 1 && crc_valid[8]) ||
                (term_lane_d1_reg == 2 && crc_valid[9]) ||
                (term_lane_d1_reg == 3 && crc_valid[10]) ||
                (term_lane_d1_reg == 4 && crc_valid[11]) ||
                (term_lane_d1_reg == 5 && crc_valid[12]) ||
                (term_lane_d1_reg == 6 && crc_valid[13]) ||
                (term_lane_d1_reg == 7 && crc_valid[14]) ||
                (term_lane_d1_reg == 8 && crc_valid[15]) )) begin
                // CRC valid
            end else if (state_prev == STATE_LAST && (
                (term_lane_d2_reg == 15 && crc_valid[3]) ||
                (term_lane_d2_reg == 14 && crc_valid_save[5]) ||
                (term_lane_d2_reg == 13 && crc_valid_save[4]) || 
                (term_lane_d2_reg == 12 && crc_valid_save[3]) ||
                (term_lane_d2_reg == 11 && crc_valid_save[2]) ||
                (term_lane_d2_reg == 10 && crc_valid_save[1]) ||
                (term_lane_d2_reg == 9 && crc_valid_save[0]) )) begin
                // CRC valid
            end else if (state_prev == STATE_LAST && !(
                (term_lane_d2_reg == 15 && crc_valid[3]) ||
                (term_lane_d2_reg == 14 && crc_valid_save[5]) ||
                (term_lane_d2_reg == 13 && crc_valid_save[4]) || 
                (term_lane_d2_reg == 12 && crc_valid_save[3]) ||
                (term_lane_d2_reg == 11 && crc_valid_save[2]) ||
                (term_lane_d2_reg == 10 && crc_valid_save[1]) ||
                (term_lane_d2_reg == 9 && crc_valid_save[0]) )) begin
                // CRC not valid
                error_bad_frame_next = 1'b1;
                error_bad_fcs_next = 1'b1;
            end else if (state_prev == STATE_PAYLOAD && !(
                (term_lane_d1_reg == 0 && crc_valid_save[7]) || 
                (term_lane_d1_reg == 1 && crc_valid_save[8]) ||
                (term_lane_d1_reg == 2 && crc_valid_save[9]) ||
                (term_lane_d1_reg == 3 && crc_valid_save[10]) ||
                (term_lane_d1_reg == 4 && crc_valid_save[11]) ||
                (term_lane_d1_reg == 5 && crc_valid_save[12]) ||
                (term_lane_d1_reg == 6 && crc_valid_save[13]) ||
                (term_lane_d1_reg == 7 && crc_valid_save[14]) ||
                (term_lane_d1_reg == 8 && crc_valid_save[15]) )) begin
                // CRC not valid
                error_bad_frame_next = 1'b1;
                error_bad_fcs_next = 1'b1;
            end
            
        end
        STATE_PREAMBLE: begin
            // read payload
            reset_crc = 1'b0;

            if (state_prev == STATE_LAST && (
                (term_lane_d2_reg == 15 && crc_valid[6]) ||
                (term_lane_d2_reg == 14 && crc_valid[5]) ||
                (term_lane_d2_reg == 13 && crc_valid[4]) || 
                (term_lane_d2_reg == 12 && crc_valid[3]) ||
                (term_lane_d2_reg == 11 && crc_valid[2]) ||
                (term_lane_d2_reg == 10 && crc_valid[1]) ||
                (term_lane_d2_reg == 9 && crc_valid[0]) )) begin
                // CRC valid
            end else if (state_prev == STATE_LAST && !(
                (term_lane_d2_reg == 15 && crc_valid[6]) ||
                (term_lane_d2_reg == 14 && crc_valid_save[5]) ||
                (term_lane_d2_reg == 13 && crc_valid_save[4]) || 
                (term_lane_d2_reg == 12 && crc_valid_save[3]) ||
                (term_lane_d2_reg == 11 && crc_valid_save[2]) ||
                (term_lane_d2_reg == 10 && crc_valid_save[1]) ||
                (term_lane_d2_reg == 9 && crc_valid_save[0]) )) begin
                error_bad_frame_next = 1'b1;
                error_bad_fcs_next = 1'b1;
            end

            m_axis_tdata_next = {xgmii_rxd_d1[63:0], xgmii_rxd_d2[127:64]};
            m_axis_tkeep_next = {KEEP_WIDTH{1'b1}};
            m_axis_tvalid_next = 1'b1;
            m_axis_tlast_next = 1'b0;
            m_axis_tuser_next[0] = 1'b0;
            
            if (framing_error_d0_reg) begin // if (framing_error_reg || framing_error_d0_reg) begin
                // control or error characters in packet
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b1;
                error_bad_frame_next = 1'b1;
                reset_crc = 1'b1;
                state_next = STATE_IDLE;
            end else begin
                state_next = STATE_PAYLOAD;
            end
        end
        STATE_PAYLOAD: begin
            // read payload

            m_axis_tdata_next = {xgmii_rxd_d1[63:0], xgmii_rxd_d2[127:64]};
            m_axis_tkeep_next = {KEEP_WIDTH{1'b1}};
            m_axis_tvalid_next = 1'b1;
            m_axis_tlast_next = 1'b0;
            m_axis_tuser_next[0] = 1'b0;
            
            if (framing_error_d1_reg) begin // if (framing_error_reg || framing_error_d0_reg) begin // if (framing_error_d1_reg || framing_error_d0_reg) begin  //
                // control or error characters in packet
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b1;
                error_bad_frame_next = 1'b1;
                reset_crc = 1'b1;
                state_next = STATE_IDLE;
            end else if (term_present_d0_reg) begin

                if (crc_valid == 32'b0) begin
                    reset_crc = 1'b0;
                end else begin
                    reset_crc = 1'b1;
                end
                
                if (term_lane_d0_reg <= 8) begin
                    m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (CTRL_WIDTH-4-term_lane_d0_reg);
                    m_axis_tlast_next = 1'b1;
                    state_next = STATE_IDLE;
                end else if (term_lane_d0_reg > 8 && term_lane_d0_reg <= 12) begin // need extra cycle
                    m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (CTRL_WIDTH-4-term_lane_d0_reg);
                    m_axis_tlast_next = 1'b1;
                    state_next = STATE_LAST;
                end else if (term_lane_d0_reg > 12) begin
                    // end this cycle
                    m_axis_tkeep_next = {KEEP_WIDTH{1'b1}};
                    m_axis_tlast_next = 1'b0;
                    state_next = STATE_LAST;
                end else begin
                    state_next = STATE_LAST;
                end
            end else begin
                state_next = STATE_PAYLOAD;
            end
        end
        STATE_LAST: begin
            // last cycle of packet
            if (term_lane_d1_reg > 8 && term_lane_d1_reg <= 12) begin
                m_axis_tdata_next = {64'b0, xgmii_rxd_d2[127:64]};
                m_axis_tkeep_next = 16'b0;
                m_axis_tvalid_next = 1'b0;
                m_axis_tlast_next = 1'b0;
                m_axis_tuser_next[0] = 1'b0;
            end else if (term_lane_d1_reg == 13) begin
                m_axis_tdata_next = {64'b0, xgmii_rxd_d2[127:64]};
                m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (term_lane_d1_reg+2);
                m_axis_tvalid_next = 1'b1;
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b0;
            end else if (term_lane_d1_reg == 14) begin
                m_axis_tdata_next = {64'b0, xgmii_rxd_d2[127:64]};
                m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (term_lane_d1_reg);
                m_axis_tvalid_next = 1'b1;
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b0;
            end else if (term_lane_d1_reg == 15) begin
                m_axis_tdata_next = {64'b0, xgmii_rxd_d2[127:64]};
                m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (term_lane_d1_reg-2);
                m_axis_tvalid_next = 1'b1;
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b0;
            end else begin
                m_axis_tdata_next = {64'b0, xgmii_rxd_d2[127:64]};
                m_axis_tkeep_next = {KEEP_WIDTH{1'b1}} >> (CTRL_WIDTH+4-term_lane_d1_reg);
                m_axis_tvalid_next = 1'b1;
                m_axis_tlast_next = 1'b1;
                m_axis_tuser_next[0] = 1'b0;
            end
                
            reset_crc = 1'b1;

            if (xgmii_start_d1 && cfg_rx_enable) begin
                // start condition
                reset_crc = 1'b0;
                state_next = STATE_PREAMBLE;
                if (crc_valid == 32'b0) begin
                    reset_crc = 1'b0;
                end else begin
                    reset_crc = 1'b1;
                end
            end else begin
                state_next = STATE_IDLE;
            end
        end
    endcase
end

integer i;

always @(posedge clk) begin
    state_reg <= state_next;
    state_prev <= state_reg;

    m_axis_tdata_reg <= m_axis_tdata_next;
    m_axis_tkeep_reg <= m_axis_tkeep_next;
    m_axis_tvalid_reg <= m_axis_tvalid_next;
    m_axis_tlast_reg <= m_axis_tlast_next;
    m_axis_tuser_reg <= m_axis_tuser_next;

    start_packet_reg <= 2'b00;
    error_bad_frame_reg <= error_bad_frame_next;
    error_bad_fcs_reg <= error_bad_fcs_next;

    swap_rxd <= xgmii_rxd_masked[127:64]; 
    swap_rxc <= xgmii_rxc[15:8];
    swap_rxc_term <= xgmii_term[15:8];

    swap_rxd_reg <= swap_rxd; 
    swap_rxc_reg <= swap_rxc;
    swap_rxc_term_reg <= swap_rxc_term;

    xgmii_start_swap <= 1'b0;
    xgmii_start_d0 <= xgmii_start_swap;

    xgmii_rxd_d0_no_masked <= xgmii_rxd;
    xgmii_rxc_d0_no_masked <= xgmii_rxc;

    xgmii_rxc_d1 <= xgmii_rxc_d0;

    xgmii_term_d0 <= xgmii_term;
    xgmii_term_d1 <= xgmii_term_d0;

    lanes_swapped_reg <= lanes_swapped;
    chivato <= 1'b0;

    term_present_d0_reg <= term_present_reg_2;

    term_lane_d1_reg <= term_lane_d0_reg;
    term_lane_d2_reg <= term_lane_d1_reg;
    framing_error_d1_reg <= framing_error_d0_reg;
    framing_error_d2_reg <= framing_error_d1_reg;

    framing_error_reg <= 0;

    // lane swapping and termination character detection
    if (lanes_swapped) begin
        xgmii_rxd_d0 <= {xgmii_rxd_masked[63:0], swap_rxd};
        xgmii_rxc_d0 <= {xgmii_rxc[7:0], swap_rxc};

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        term_lane_reg_2 <= 0;
        term_present_reg_2 <= 1'b0;
        // framing_error_reg <= {xgmii_rxc[7:0], swap_rxc} != 0;

        for (i = CTRL_WIDTH-1; i >= 0; i = i - 1) begin
            if ({xgmii_term[7:0], swap_rxc_term} & (1 << i)) begin
                term_lane_reg <= i;
                term_present_reg <= 1'b1;
                term_lane_reg_2 <= i;
                term_present_reg_2 <= 1'b1;
                framing_error_reg <= ({xgmii_rxc[7:0], swap_rxc} & ({CTRL_WIDTH{1'b1}} >> (CTRL_WIDTH-i))) != 0;
                lanes_swapped <= 1'b0;
            end
        end
    end else begin
        xgmii_rxd_d0 <= xgmii_rxd_masked;
        xgmii_rxc_d0 <= xgmii_rxc;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        term_lane_reg_2 <= 0;
        term_present_reg_2 <= 1'b0;
        // framing_error_reg <= xgmii_rxc != 0;

        for (i = CTRL_WIDTH-1; i >= 0; i = i - 1) begin
            if (xgmii_rxc[i] && (xgmii_rxd[i*8 +: 8] == XGMII_TERM)) begin
                term_lane_reg <= i;
                term_present_reg <= 1'b1;
                term_lane_reg_2 <= i;
                term_present_reg_2 <= 1'b1;
                framing_error_reg <= (xgmii_rxc & ({CTRL_WIDTH{1'b1}} >> (CTRL_WIDTH-i))) != 0;
                lanes_swapped <= 1'b0;
            end
        end
    end


    // start control character detection
    if (xgmii_rxc[0] && xgmii_rxd[7:0] == XGMII_START) begin
        lanes_swapped <= 1'b0;

        xgmii_start_d0 <= 1'b1;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= xgmii_rxc[15:1] != 0;
    end else if (xgmii_rxc[8] && xgmii_rxd[71:64] == XGMII_START) begin
        lanes_swapped <= 1'b1;

        xgmii_start_swap <= 1'b1;

        term_lane_reg <= 0;
        term_present_reg <= 1'b0;
        framing_error_reg <= xgmii_rxc[15:9] != 0;
    end

    // capture timestamps
    if (xgmii_start_swap) begin
        start_packet_reg <= 2'b10;
    end

    if (xgmii_start_d0) begin
        if (!lanes_swapped) begin
            start_packet_reg <= 2'b01;
        end
    end

    term_lane_d0_reg <= term_lane_reg_2;
    framing_error_d0_reg <= framing_error_reg;

    if (reset_crc) begin
        crc_state <= 32'hFFFFFFFF;
    end else begin
        crc_state <= crc_next;
    end

    crc_valid_save <= crc_valid;
    crc_valid_save_2 <= crc_valid_save;

    xgmii_rxd_d1 <= xgmii_rxd_d0;
    xgmii_rxd_d2 <= xgmii_rxd_d1;
    xgmii_start_d1 <= xgmii_start_d0;

    last_ts_reg <= ptp_ts;
    ts_inc_reg <= ptp_ts - last_ts_reg;


    if (rst) begin
        state_reg <= STATE_IDLE;

        m_axis_tvalid_reg <= 1'b0;

        start_packet_reg <= 2'b00;
        error_bad_frame_reg <= 1'b0;
        error_bad_fcs_reg <= 1'b0;

        xgmii_rxc_d0 <= {CTRL_WIDTH{1'b0}};

        xgmii_start_swap <= 1'b0;
        xgmii_start_d0 <= 1'b0;
        xgmii_start_d1 <= 1'b0;

        lanes_swapped <= 1'b0;
    end
end

endmodule

`resetall

