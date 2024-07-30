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
    output wire [CH_CNT*128-1:0]  eth_txd,
    output wire [CH_CNT*16-1:0]   eth_txc,
    input  wire [CH_CNT-1:0]     eth_rx_clk,
    input  wire [CH_CNT-1:0]     eth_rx_rst,
    input  wire [CH_CNT*128-1:0]  eth_rxd,
    input  wire [CH_CNT*16-1:0]   eth_rxc
);

// AXI between MAC and Ethernet modules
wire [127:0] rx_axis_tdata;
wire [15:0] rx_axis_tkeep;
wire rx_axis_tvalid;
wire rx_axis_tready;
wire rx_axis_tlast;
wire rx_axis_tuser;

wire [127:0] rx_axis_tdata_qsfp1;
wire [15:0] rx_axis_tkeep_qsfp1;
wire rx_axis_tvalid_qsfp1;
wire rx_axis_tready_qsfp1;
wire rx_axis_tlast_qsfp1;
wire rx_axis_tuser_qsfp1;

wire [127:0] tx_axis_tdata;
wire [15:0] tx_axis_tkeep;
wire tx_axis_tvalid;
wire tx_axis_tready;
wire tx_axis_tlast;
wire tx_axis_tuser;

wire [127:0] tx_axis_tdata_qsfp1;
wire [15:0] tx_axis_tkeep_qsfp1;
wire tx_axis_tvalid_qsfp1;
wire tx_axis_tready_qsfp1;
wire tx_axis_tlast_qsfp1;
wire tx_axis_tuser_qsfp1;

// Ethernet frame between Ethernet modules and UDP stack
wire rx_eth_hdr_ready;
wire rx_eth_hdr_valid;
wire [47:0] rx_eth_dest_mac;
wire [47:0] rx_eth_src_mac;
wire [15:0] rx_eth_type;
wire [127:0] rx_eth_payload_axis_tdata;
wire [15:0] rx_eth_payload_axis_tkeep;
wire rx_eth_payload_axis_tvalid;
wire rx_eth_payload_axis_tready;
wire rx_eth_payload_axis_tlast;
wire rx_eth_payload_axis_tuser;

wire rx_eth_hdr_ready_qsfp1;
wire rx_eth_hdr_valid_qsfp1;
wire [47:0] rx_eth_dest_mac_qsfp1;
wire [47:0] rx_eth_src_mac_qsfp1;
wire [15:0] rx_eth_type_qsfp1;
wire [127:0] rx_eth_payload_axis_tdata_qsfp1;
wire [15:0] rx_eth_payload_axis_tkeep_qsfp1;
wire rx_eth_payload_axis_tvalid_qsfp1;
wire rx_eth_payload_axis_tready_qsfp1;
wire rx_eth_payload_axis_tlast_qsfp1;
wire rx_eth_payload_axis_tuser_qsfp1;

wire tx_eth_hdr_ready;
wire tx_eth_hdr_valid;
wire [47:0] tx_eth_dest_mac;
wire [47:0] tx_eth_src_mac;
wire [15:0] tx_eth_type;
wire [127:0] tx_eth_payload_axis_tdata;
wire [15:0] tx_eth_payload_axis_tkeep;
wire tx_eth_payload_axis_tvalid;
wire tx_eth_payload_axis_tready;
wire tx_eth_payload_axis_tlast;
wire tx_eth_payload_axis_tuser;

wire tx_eth_hdr_ready_qsfp1;
wire tx_eth_hdr_valid_qsfp1;
wire [47:0] tx_eth_dest_mac_qsfp1;
wire [47:0] tx_eth_src_mac_qsfp1;
wire [15:0] tx_eth_type_qsfp1;
wire [127:0] tx_eth_payload_axis_tdata_qsfp1;
wire [15:0] tx_eth_payload_axis_tkeep_qsfp1;
wire tx_eth_payload_axis_tvalid_qsfp1;
wire tx_eth_payload_axis_tready_qsfp1;
wire tx_eth_payload_axis_tlast_qsfp1;
wire tx_eth_payload_axis_tuser_qsfp1;

// Place first payload byte onto LEDs

reg [7:0] led_reg = 0;

//assign led = sw;
assign led = led_reg;

assign uart_txd = uart_rxd;

generate

genvar n;

for (n = 1; n < 3; n = n + 1) begin
    assign eth_txd[n*128 +: 128] = 128'h07070707070707070707070707070707;
    assign eth_txc[n*16 +: 16] = 16'hffff;
end

for (n = 5; n < CH_CNT; n = n + 1) begin
    assign eth_txd[n*128 +: 128] = 128'h07070707070707070707070707070707;
    assign eth_txc[n*16 +: 16] = 16'hffff;
end

endgenerate

// packet generator
packetgen #(
    .DATA_WIDTH(128),
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

eth_mac_40g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_40g_fifo_inst (
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

    .xgmii_rxd(eth_rxd[0*128 +: 128]),
    .xgmii_rxc(eth_rxc[0*16 +: 16]),
    .xgmii_txd(eth_txd[0*128 +: 128]),
    .xgmii_txc(eth_txc[0*16 +: 16]),

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

eth_axis_rx #(
    .DATA_WIDTH(128)
)
eth_axis_rx_inst (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata),
    .s_axis_tkeep(rx_axis_tkeep),
    .s_axis_tvalid(rx_axis_tvalid),
    .s_axis_tready(rx_axis_tready),
    .s_axis_tlast(rx_axis_tlast),
    .s_axis_tuser(rx_axis_tuser),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid),
    .m_eth_hdr_ready(rx_eth_hdr_ready),
    .m_eth_dest_mac(rx_eth_dest_mac),
    .m_eth_src_mac(rx_eth_src_mac),
    .m_eth_type(rx_eth_type),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata),
    .m_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

/* eth_axis_tx #(
    .DATA_WIDTH(128)
)
eth_axis_tx_inst (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid),
    .s_eth_hdr_ready(tx_eth_hdr_ready),
    .s_eth_dest_mac(tx_eth_dest_mac),
    .s_eth_src_mac(tx_eth_src_mac),
    .s_eth_type(tx_eth_type),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata),
    .s_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser),
    // AXI output
    .m_axis_tdata(tx_axis_tdata),
    .m_axis_tkeep(tx_axis_tkeep),
    .m_axis_tvalid(tx_axis_tvalid),
    .m_axis_tready(tx_axis_tready),
    .m_axis_tlast(tx_axis_tlast),
    .m_axis_tuser(tx_axis_tuser),
    // Status signals
    .busy()
); */


eth_mac_40g_fifo #(
    .ENABLE_PADDING(1),
    .ENABLE_DIC(1),
    .MIN_FRAME_LENGTH(64),
    .TX_FIFO_DEPTH(4096),
    .TX_FRAME_FIFO(1),
    .RX_FIFO_DEPTH(4096),
    .RX_FRAME_FIFO(1)
)
eth_mac_40g_fifo_inst_qsfp1 (
    .rx_clk(eth_rx_clk[4 +: 1]),
    .rx_rst(eth_rx_rst[4 +: 1]),
    .tx_clk(eth_tx_clk[4 +: 1]),
    .tx_rst(eth_tx_rst[4 +: 1]),
    .logic_clk(clk),
    .logic_rst(rst),

    .tx_axis_tdata(tx_axis_tdata),
    .tx_axis_tkeep(tx_axis_tkeep),
    .tx_axis_tvalid(tx_axis_tvalid),
    .tx_axis_tready(tx_axis_tready),
    .tx_axis_tlast(tx_axis_tlast),
    .tx_axis_tuser(tx_axis_tuser),

    .rx_axis_tdata(rx_axis_tdata),
    .rx_axis_tkeep(rx_axis_tkeep),
    .rx_axis_tvalid(rx_axis_tvalid),
    .rx_axis_tready(rx_axis_tready),
    .rx_axis_tlast(rx_axis_tlast),
    .rx_axis_tuser(rx_axis_tuser),

    .xgmii_rxd(eth_rxd[(1*4+0)*128 +: 128]),
    .xgmii_rxc(eth_rxc[(1*4+0)*16 +: 16]),
    .xgmii_txd(eth_txd[(1*4+0)*128 +: 128]),
    .xgmii_txc(eth_txc[(1*4+0)*16 +: 16]),

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


eth_axis_rx #(
    .DATA_WIDTH(128)
)
eth_axis_rx_inst_qsfp1 (
    .clk(clk),
    .rst(rst),
    // AXI input
    .s_axis_tdata(rx_axis_tdata_qsfp1),
    .s_axis_tkeep(rx_axis_tkeep_qsfp1),
    .s_axis_tvalid(rx_axis_tvalid_qsfp1),
    .s_axis_tready(rx_axis_tready_qsfp1),
    .s_axis_tlast(rx_axis_tlast_qsfp1),
    .s_axis_tuser(rx_axis_tuser_qsfp1),
    // Ethernet frame output
    .m_eth_hdr_valid(rx_eth_hdr_valid_qsfp1),
    .m_eth_hdr_ready(rx_eth_hdr_ready_qsfp1),
    .m_eth_dest_mac(rx_eth_dest_mac_qsfp1),
    .m_eth_src_mac(rx_eth_src_mac_qsfp1),
    .m_eth_type(rx_eth_type_qsfp1),
    .m_eth_payload_axis_tdata(rx_eth_payload_axis_tdata_qsfp1),
    .m_eth_payload_axis_tkeep(rx_eth_payload_axis_tkeep_qsfp1),
    .m_eth_payload_axis_tvalid(rx_eth_payload_axis_tvalid_qsfp1),
    .m_eth_payload_axis_tready(rx_eth_payload_axis_tready_qsfp1),
    .m_eth_payload_axis_tlast(rx_eth_payload_axis_tlast_qsfp1),
    .m_eth_payload_axis_tuser(rx_eth_payload_axis_tuser_qsfp1),
    // Status signals
    .busy(),
    .error_header_early_termination()
);

eth_axis_tx #(
    .DATA_WIDTH(128)
)
eth_axis_tx_inst_qsfp1 (
    .clk(clk),
    .rst(rst),
    // Ethernet frame input
    .s_eth_hdr_valid(tx_eth_hdr_valid_qsfp1),
    .s_eth_hdr_ready(tx_eth_hdr_ready_qsfp1),
    .s_eth_dest_mac(tx_eth_dest_mac_qsfp1),
    .s_eth_src_mac(tx_eth_src_mac_qsfp1),
    .s_eth_type(tx_eth_type_qsfp1),
    .s_eth_payload_axis_tdata(tx_eth_payload_axis_tdata_qsfp1),
    .s_eth_payload_axis_tkeep(tx_eth_payload_axis_tkeep_qsfp1),
    .s_eth_payload_axis_tvalid(tx_eth_payload_axis_tvalid_qsfp1),
    .s_eth_payload_axis_tready(tx_eth_payload_axis_tready_qsfp1),
    .s_eth_payload_axis_tlast(tx_eth_payload_axis_tlast_qsfp1),
    .s_eth_payload_axis_tuser(tx_eth_payload_axis_tuser_qsfp1),
    // AXI output
    .m_axis_tdata(tx_axis_tdata_qsfp1),
    .m_axis_tkeep(tx_axis_tkeep_qsfp1),
    .m_axis_tvalid(tx_axis_tvalid_qsfp1),
    .m_axis_tready(tx_axis_tready_qsfp1),
    .m_axis_tlast(tx_axis_tlast_qsfp1),
    .m_axis_tuser(tx_axis_tuser_qsfp1),
    // Status signals
    .busy()
);


endmodule

`resetall
