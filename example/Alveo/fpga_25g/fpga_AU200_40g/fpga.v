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
 * FPGA top-level module
 */
module fpga (
    /*
     * Reset: Push button, active low
     */
    input  wire       reset,

    /*
     * GPIO
     */
    input  wire [3:0] sw,
    output wire [2:0] led,

    /*
     * I2C for board management
     */
    inout  wire       i2c_scl,
    inout  wire       i2c_sda,

    /*
     * UART
     */
    output wire       uart_txd,
    input  wire       uart_rxd,

    /*
     * Ethernet: QSFP28
     */
    output wire [3:0] qsfp0_tx_p,
    output wire [3:0] qsfp0_tx_n,
    input  wire [3:0] qsfp0_rx_p,
    input  wire [3:0] qsfp0_rx_n,
    // input  wire       qsfp0_mgt_refclk_0_p,
    // input  wire       qsfp0_mgt_refclk_0_n,
    input  wire       qsfp0_mgt_refclk_1_p,
    input  wire       qsfp0_mgt_refclk_1_n,
    output wire       qsfp0_modsell,
    output wire       qsfp0_resetl,
    input  wire       qsfp0_modprsl,
    input  wire       qsfp0_intl,
    output wire       qsfp0_lpmode,
    output wire       qsfp0_refclk_reset,
    output wire [1:0] qsfp0_fs,

    // output wire [3:0] qsfp1_tx_p,
    // output wire [3:0] qsfp1_tx_n,
    // input  wire [3:0] qsfp1_rx_p,
    // input  wire [3:0] qsfp1_rx_n,
    // input  wire       qsfp1_mgt_refclk_0_p,
    // input  wire       qsfp1_mgt_refclk_0_n,
    input  wire       qsfp1_mgt_refclk_1_p,
    input  wire       qsfp1_mgt_refclk_1_n,
    output wire       qsfp1_modsell,
    output wire       qsfp1_resetl,
    input  wire       qsfp1_modprsl,
    input  wire       qsfp1_intl,
    output wire       qsfp1_lpmode,
    output wire       qsfp1_refclk_reset,
    output wire [1:0] qsfp1_fs
);

// Clock and reset
wire cfgmclk_int;

wire clk_161mhz_ref_int;

// Internal 125 MHz clock
wire clk_125mhz_mmcm_out;
wire clk_125mhz_int;
wire rst_125mhz_int;

wire mmcm_rst;
wire mmcm_locked;
wire mmcm_clkfb;

// MMCM instance
// 161.13 MHz in, 125 MHz out
// PFD range: 10 MHz to 500 MHz
// VCO range: 800 MHz to 1600 MHz
// M = 64, D = 11 sets Fvco = 937.5 MHz (in range)
// Divide by 7.5 to get output frequency of 125 MHz
MMCME4_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKOUT0_DIVIDE_F(7.5),
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT0_PHASE(0),
    .CLKOUT1_DIVIDE(1),
    .CLKOUT1_DUTY_CYCLE(0.5),
    .CLKOUT1_PHASE(0),
    .CLKOUT2_DIVIDE(1),
    .CLKOUT2_DUTY_CYCLE(0.5),
    .CLKOUT2_PHASE(0),
    .CLKOUT3_DIVIDE(1),
    .CLKOUT3_DUTY_CYCLE(0.5),
    .CLKOUT3_PHASE(0),
    .CLKOUT4_DIVIDE(1),
    .CLKOUT4_DUTY_CYCLE(0.5),
    .CLKOUT4_PHASE(0),
    .CLKOUT5_DIVIDE(1),
    .CLKOUT5_DUTY_CYCLE(0.5),
    .CLKOUT5_PHASE(0),
    .CLKOUT6_DIVIDE(1),
    .CLKOUT6_DUTY_CYCLE(0.5),
    .CLKOUT6_PHASE(0),
    .CLKFBOUT_MULT_F(64),
    .CLKFBOUT_PHASE(0),
    .DIVCLK_DIVIDE(11),
    .REF_JITTER1(0.010),
    .CLKIN1_PERIOD(6.206),
    .STARTUP_WAIT("FALSE"),
    .CLKOUT4_CASCADE("FALSE")
)
clk_mmcm_inst (
    .CLKIN1(clk_161mhz_ref_int),
    .CLKFBIN(mmcm_clkfb),
    .RST(mmcm_rst),
    .PWRDWN(1'b0),
    .CLKOUT0(clk_125mhz_mmcm_out),
    .CLKOUT0B(),
    .CLKOUT1(),
    .CLKOUT1B(),
    .CLKOUT2(),
    .CLKOUT2B(),
    .CLKOUT3(),
    .CLKOUT3B(),
    .CLKOUT4(),
    .CLKOUT5(),
    .CLKOUT6(),
    .CLKFBOUT(mmcm_clkfb),
    .CLKFBOUTB(),
    .LOCKED(mmcm_locked)
);

BUFG
clk_125mhz_bufg_inst (
    .I(clk_125mhz_mmcm_out),
    .O(clk_125mhz_int)
);

sync_reset #(
    .N(4)
)
sync_reset_125mhz_inst (
    .clk(clk_125mhz_int),
    .rst(~mmcm_locked),
    .out(rst_125mhz_int)
);

// SI570 I2C
wire i2c_scl_i;
wire i2c_scl_o = 1'b1;
wire i2c_scl_t = 1'b1;
wire i2c_sda_i;
wire i2c_sda_o = 1'b1;
wire i2c_sda_t = 1'b1;

assign i2c_scl_i = i2c_scl;
assign i2c_scl = i2c_scl_t ? 1'bz : i2c_scl_o;
assign i2c_sda_i = i2c_sda;
assign i2c_sda = i2c_sda_t ? 1'bz : i2c_sda_o;

// startupe3 instance
wire cfgmclk;

STARTUPE3
startupe3_inst (
    .CFGCLK(),
    .CFGMCLK(cfgmclk),
    .DI(4'd0),
    .DO(),
    .DTS(1'b1),
    .EOS(),
    .FCSBO(1'b0),
    .FCSBTS(1'b1),
    .GSR(1'b0),
    .GTS(1'b0),
    .KEYCLEARB(1'b1),
    .PACK(1'b0),
    .PREQ(),
    .USRCCLKO(1'b0),
    .USRCCLKTS(1'b1),
    .USRDONEO(1'b0),
    .USRDONETS(1'b1)
);

BUFG
cfgmclk_bufg_inst (
    .I(cfgmclk),
    .O(cfgmclk_int)
);

// configure SI5335 clock generators
reg qsfp_refclk_reset_reg = 1'b1;
reg sys_reset_reg = 1'b1;

reg [9:0] reset_timer_reg = 0;

assign mmcm_rst = sys_reset_reg;

always @(posedge cfgmclk_int) begin
    if (&reset_timer_reg) begin
        if (qsfp_refclk_reset_reg) begin
            qsfp_refclk_reset_reg <= 1'b0;
            reset_timer_reg <= 0;
        end else begin
            qsfp_refclk_reset_reg <= 1'b0;
            sys_reset_reg <= 1'b0;
        end
    end else begin
        reset_timer_reg <= reset_timer_reg + 1;
    end

    if (!reset) begin
        qsfp_refclk_reset_reg <= 1'b1;
        sys_reset_reg <= 1'b1;
        reset_timer_reg <= 0;
    end
end

// XLGMII 40G PHY + MAC
// QSFP0
assign qsfp0_modsell = 1'b0;
assign qsfp0_resetl = 1'b1;
assign qsfp0_lpmode = 1'b0;
assign qsfp0_refclk_reset = qsfp_refclk_reset_reg;
assign qsfp0_fs = 2'b10;

wire         qsfp0_mgt_refclk_1;
assign clk_161mhz_ref_int = qsfp0_mgt_refclk_1;

// eth_40g_gt_exdes #(
wrapper_40g #(
)
qsfp0_phy_mac_inst (
    .gt_rxn_in_0(qsfp0_rx_n[0]),
    .gt_rxp_in_0(qsfp0_rx_p[0]),
    .gt_rxn_in_1(qsfp0_rx_n[1]),
    .gt_rxp_in_1(qsfp0_rx_p[1]),
    .gt_rxn_in_2(qsfp0_rx_n[2]),
    .gt_rxp_in_2(qsfp0_rx_p[2]),
    .gt_rxn_in_3(qsfp0_rx_n[3]),
    .gt_rxp_in_3(qsfp0_rx_p[3]),
    .gt_txn_out_0(qsfp0_tx_n[0]),
    .gt_txp_out_0(qsfp0_tx_p[0]),
    .gt_txn_out_1(qsfp0_tx_n[1]),
    .gt_txp_out_1(qsfp0_tx_p[1]),
    .gt_txn_out_2(qsfp0_tx_n[2]),
    .gt_txp_out_2(qsfp0_tx_p[2]),
    .gt_txn_out_3(qsfp0_tx_n[3]),
    .gt_txp_out_3(qsfp0_tx_p[3]),

    .send_continuous_pkts_0(1'b1),

    .rx_gt_locked_led(),
    .rx_aligned_led(),
    .completion_status(),

    .sys_reset(1'b0),
    .restart_tx_rx(1'b0),

    .gt_refclk_p(qsfp0_mgt_refclk_1_p),
    .gt_refclk_n(qsfp0_mgt_refclk_1_n),
    .gt_refclk_out(qsfp0_mgt_refclk_1),

    .dclk(clk_125mhz_int)
);

endmodule

`resetall
