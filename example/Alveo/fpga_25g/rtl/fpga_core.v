/*

Copyright (c) 2014-2021 Alex Forencich

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
 * FPGA core logic
 */
module fpga_core #
(
    parameter SW_CNT = 4,
    parameter LED_CNT = 3,
    parameter UART_CNT = 1,
    parameter QSFP_CNT = 2,
    parameter CH_CNT = QSFP_CNT*4
)
(
    /*
     * Clock: 156.25MHz
     * Synchronous reset
     */
    input  wire                  clk,
    input  wire                  rst,

    /*
     * GPIO
     */
    input  wire [SW_CNT-1:0]     sw,
    output wire [LED_CNT-1:0]    led,
    output wire [QSFP_CNT-1:0]   qsfp_led_act,
    output wire [QSFP_CNT-1:0]   qsfp_led_stat_g,
    output wire [QSFP_CNT-1:0]   qsfp_led_stat_y,

    /*
     * UART
     */
    output wire [UART_CNT-1:0]   uart_txd,
    input  wire [UART_CNT-1:0]   uart_rxd,

    /*
     * Ethernet
     */
    input  wire [CH_CNT-1:0]     eth_tx_clk,
    input  wire [CH_CNT-1:0]     eth_tx_rst,
    output wire [CH_CNT*64-1:0]  eth_txd,
    output wire [CH_CNT*8-1:0]   eth_txc,
    input  wire [CH_CNT-1:0]     eth_rx_clk,
    input  wire [CH_CNT-1:0]     eth_rx_rst,
    input  wire [CH_CNT*64-1:0]  eth_rxd,
    input  wire [CH_CNT*8-1:0]   eth_rxc
);

// AXI between MAC and Ethernet modules
wire [63:0] rx_axis_tdata;
wire [7:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [63:0] rx_axis_tdata_qsfp1;
wire [7:0] rx_axis_tkeep_qsfp1;
wire rx_axis_tvalid_qsfp1;
wire rx_axis_tready_qsfp1;
wire rx_axis_tlast_qsfp1;
wire rx_axis_tuser_qsfp1;

wire [63:0] tx_axis_tdata;
wire [7:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;

wire [63:0] tx_axis_tdata_qsfp1;
wire [7:0] tx_axis_tkeep_qsfp1;
wire tx_axis_tvalid_qsfp1 = 0;
wire tx_axis_tready_qsfp1;
wire tx_axis_tlast_qsfp1;
wire tx_axis_tuser_qsfp1;

// Ethernet frame between Ethernet modules and UDP stack
wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [63:0] rx_eth_payload_axis_tdata;
wire [7:0] rx_eth_payload_axis_tkeep;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire rx_eth_hdr_ready_qsfp1;
wire rx_eth_hdr_valid_qsfp1;
wire [47:0] rx_eth_dest_mac_qsfp1;
wire [47:0] rx_eth_src_mac_qsfp1;
wire [15:0] rx_eth_type_qsfp1;
wire [63:0] rx_eth_payload_axis_tdata_qsfp1;
wire [7:0] rx_eth_payload_axis_tkeep_qsfp1;
wire rx_eth_payload_axis_tvalid_qsfp1;
wire rx_eth_payload_axis_tready_qsfp1;
wire rx_eth_payload_axis_tlast_qsfp1;
wire rx_eth_payload_axis_tuser_qsfp1;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [63:0] tx_eth_payload_axis_tdata;
wire [7:0] tx_eth_payload_axis_tkeep;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready_qsfp1;
wire tx_eth_hdr_valid_qsfp1;
wire [47:0] tx_eth_dest_mac_qsfp1;
wire [47:0] tx_eth_src_mac_qsfp1;
wire [15:0] tx_eth_type_qsfp1;
wire [63:0] tx_eth_payload_axis_tdata_qsfp1;
wire [7:0] tx_eth_payload_axis_tkeep_qsfp1;
wire tx_eth_payload_axis_tvalid_qsfp1;
wire tx_eth_payload_axis_tready_qsfp1;
wire tx_eth_payload_axis_tlast_qsfp1;
wire tx_eth_payload_axis_tuser_qsfp1;

// Configuration
wire [47:0] local_mac   = 48'h02_00_00_00_00_00;
wire [31:0] local_ip    = {8'd192, 8'd168, 8'd1,   8'd128};
wire [31:0] gateway_ip  = {8'd192, 8'd168, 8'd1,   8'd1};
wire [31:0] subnet_mask = {8'd255, 8'd255, 8'd255, 8'd0};


//assign led = sw;
assign led = 1'b0;

assign uart_txd = uart_rxd;

generate

genvar n;

for (n = 1; n < 3; n = n + 1) begin
    assign eth_txd[n*64 +: 64] = 64'h0707070707070707;
    assign eth_txc[n*8 +: 8] = 8'hff;
end

for (n = 5; n < CH_CNT; n = n + 1) begin
    assign eth_txd[n*64 +: 64] = 64'h0707070707070707;
    assign eth_txc[n*8 +: 8] = 8'hff;
end

endgenerate

// packet generator
packetgen #(
    .DATA_WIDTH(64),
    .FREQUENCY(156250),
    .N_FLOWS(2)
)
packetgen_inst(
    .clk(clk),
    .rst(rst),
    .axis_tdata(tx_axis_tdata),
    .axis_tkeep(tx_axis_tkeep),
    .axis_tvalid(tx_axis_tvalid),
    .axis_tready(tx_axis_tready),
    .axis_tlast(tx_axis_tlast),

    .s_axil_awaddr({32{1'b0}}),
    .s_axil_awprot({3{1'b0}}),
    .s_axil_awvalid(1'b0),
    .s_axil_awready(),
    .s_axil_wdata({32{1'b0}}),
    .s_axil_wstrb({4{1'b0}}),
    .s_axil_wvalid(1'b0),
    .s_axil_wready(),
    .s_axil_bresp(),
    .s_axil_bvalid(),
    .s_axil_bready(1'b0),
    .s_axil_araddr({32{1'b0}}),
    .s_axil_arprot({3{1'b0}}),
    .s_axil_arvalid(1'b0),
    .s_axil_arready(),
    .s_axil_rdata(),
    .s_axil_rresp(),
    .s_axil_rvalid(),
    .s_axil_rready(1'b0)

);


ila_0 ila_packetgen_inst (
    .clk(clk), 
    
    .probe0(tx_axis_tdata),
    .probe1(tx_axis_tkeep),
    .probe2(tx_axis_tvalid),
    .probe3(tx_axis_tready),
    .probe4(tx_axis_tlast)
);

eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_10g_fifo_inst (
    .rx_clk(eth_rx_clk[0 +: 1]),
    .rx_rst(eth_rx_rst[0 +: 1]),
    .tx_clk(eth_tx_clk[0 +: 1]),
    .tx_rst(eth_tx_rst[0 +: 1]),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(1'b0), // .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .xgmii_rxd(eth_rxd[0 +: 64]),
    .xgmii_rxc(eth_rxc[0 +: 8]),
    .xgmii_txd(eth_txd[0+: 64]),
    .xgmii_txc(eth_txc[0*8 +: 8]),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

ila_1 ila_eth_mac_10g_fifo_inst (
    .clk(eth_tx_clk[0 +: 1]), // .clk(clk),  // 
    
    .probe0(eth_txd[0+: 64]),
    .probe1(eth_txc[0*8 +: 8])
);


eth_mac_10g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_10g_fifo_inst_qspf1 (
    .rx_clk(eth_rx_clk[4 +: 1]),
    .rx_rst(eth_rx_rst[4 +: 1]),
    .tx_clk(eth_tx_clk[4 +: 1]),
    .tx_rst(eth_tx_rst[4 +: 1]),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata_qsfp1),
    .tx_axis_tkeep(tx_axis_tkeep_qsfp1),
    .tx_axis_tvalid(tx_axis_tvalid_qsfp1),
    .tx_axis_tready(tx_axis_tready_qsfp1),
    .tx_axis_tlast(tx_axis_tlast_qsfp1),
    .tx_axis_tuser(tx_axis_tuser_qsfp1),

    .rx_axis_tdata(rx_axis_tdata_qsfp1),
    .rx_axis_tkeep(rx_axis_tkeep_qsfp1),
    .rx_axis_tvalid(rx_axis_tvalid_qsfp1),
    .rx_axis_tready(rx_axis_tready_qsfp1),
    .rx_axis_tlast(rx_axis_tlast_qsfp1),
    .rx_axis_tuser(rx_axis_tuser_qsfp1),

    .xgmii_rxd(eth_rxd[(1*4+0)*64 +: 64]), // Changes to lane 1 of qsfp1 ([5,8])
    .xgmii_rxc(eth_rxc[(1*4+0)*8 +: 8]),   //
    .xgmii_txd(eth_txd[(1*4+0)*64 +: 64]), //
    .xgmii_txc(eth_txc[(1*4+0)*8 +: 8]),   //

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(),
    .rx_error_bad_fcs(),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

ila_2 ila_eth_mac_10g_fifo_qsfp1_inst (
    .clk(clk), // .clk(eth_rx_clk[4 +: 1]), // 
    
    .probe0(rx_axis_tdata_qsfp1),
    .probe1(rx_axis_tkeep_qsfp1),
    .probe2(rx_axis_tvalid_qsfp1),
    .probe3(rx_axis_tready_qsfp1),
    .probe4(rx_axis_tlast_qsfp1),
    .probe5(rx_axis_tuser_qsfp1)
);

endmodule

`resetall
