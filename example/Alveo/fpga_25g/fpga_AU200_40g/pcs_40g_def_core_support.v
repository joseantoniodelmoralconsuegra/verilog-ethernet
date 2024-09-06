// ------------------------------------------------------------------------------
//   (c) Copyright 2020-2021 Advanced Micro Devices, Inc. All rights reserved.
// 
//   This file contains confidential and proprietary information
//   of Advanced Micro Devices, Inc. and is protected under U.S. and
//   international copyright and other intellectual property
//   laws.
// 
//   DISCLAIMER
//   This disclaimer is not a license and does not grant any
//   rights to the materials distributed herewith. Except as
//   otherwise provided in a valid license issued to you by
//   AMD, and to the maximum extent permitted by applicable
//   law: (1) THESE MATERIALS ARE MADE AVAILABLE \"AS IS\" AND
//   WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
//   AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//   BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//   INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//   (2) AMD shall not be liable (whether in contract or tort,
//   including negligence, or under any other theory of
//   liability) for any loss or damage of any kind or nature
//   related to, arising under or in connection with these
//   materials, including for any direct, or any indirect,
//   special, incidental, or consequential loss or damage
//   (including loss of data, profits, goodwill, or any type of
//   loss or damage suffered as a result of any action brought
//   by a third party) even if such damage or loss was
//   reasonably foreseeable or AMD had been advised of the
//   possibility of the same.
// 
//   CRITICAL APPLICATIONS
//   AMD products are not designed or intended to be fail-
//   safe, or for use in any application requiring fail-safe
//   performance, such as life-support or safety devices or
//   systems, Class III medical devices, nuclear facilities,
//   applications related to the deployment of airbags, or any
//   other applications that could lead to death, personal
//   injury, or severe property or environmental damage
//   (individually and collectively, \"Critical
//   Applications\"). Customer assumes the sole risk and
//   liability of any use of AMD products in Critical
//   Applications, subject only to applicable laws and
//   regulations governing limitations on product liability.
// 
//   THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//   PART OF THIS FILE AT ALL TIMES.
//
// 
//
//       Owner:          
//       Revision:       $Id: $
//                       $Author: $
//                       $DateTime: $
//                       $Change: $
//       Description:
//
// 
////------------------------------------------------------------------------------


`timescale 1fs/1fs

(* DowngradeIPIdentifiedWarnings="yes" *)
module pcs_40g_def_core_support
(
//// GT Signals

  input  wire gt_rxp_in_0,
  input  wire gt_rxn_in_0,
  output wire gt_txp_out_0,
  output wire gt_txn_out_0,
  input  wire gt_rxp_in_1,
  input  wire gt_rxn_in_1,
  output wire gt_txp_out_1,
  output wire gt_txn_out_1,
  input  wire gt_rxp_in_2,
  input  wire gt_rxn_in_2,
  output wire gt_txp_out_2,
  output wire gt_txn_out_2,
  input  wire gt_rxp_in_3,
  input  wire gt_rxn_in_3,
  output wire gt_txp_out_3,
  output wire gt_txn_out_3,
  output wire tx_mii_clk_0,
  input wire rx_core_clk_0,
  output wire rx_clk_out_0,
  input wire gtwiz_reset_tx_datapath_0,
  input wire gtwiz_reset_rx_datapath_0,
  input  wire [11:0] gt_loopback_in_0,
  output wire [3:0] rxrecclkout_0,

//// RX_0 Signals
  input  wire rx_reset_0,
  output wire user_rx_reset_0,
//// RX_0 User Interface Signals
  output wire [127:0] rx_mii_d_0,
  output wire [15:0] rx_mii_c_0,



//// RX_0 Control Signals
  input  wire ctl_rx_test_pattern_0,





//// RX_0 Stats Signals
  output wire [3:0] stat_rx_block_lock_0,
  output wire stat_rx_framing_err_valid_0_0,
  output wire stat_rx_framing_err_0_0,
  output wire stat_rx_framing_err_valid_1_0,
  output wire stat_rx_framing_err_1_0,
  output wire stat_rx_framing_err_valid_2_0,
  output wire stat_rx_framing_err_2_0,
  output wire stat_rx_framing_err_valid_3_0,
  output wire stat_rx_framing_err_3_0,
  output wire [3:0] stat_rx_vl_demuxed_0,
  output wire [1:0] stat_rx_vl_number_0_0,
  output wire [1:0] stat_rx_vl_number_1_0,
  output wire [1:0] stat_rx_vl_number_2_0,
  output wire [1:0] stat_rx_vl_number_3_0,
  output wire [3:0] stat_rx_synced_0,
  output wire stat_rx_misaligned_0,
  output wire stat_rx_aligned_err_0,
  output wire [3:0] stat_rx_synced_err_0,
  output wire [3:0] stat_rx_mf_len_err_0,
  output wire [3:0] stat_rx_mf_repeat_err_0,
  output wire [3:0] stat_rx_mf_err_0,
  output wire stat_rx_bip_err_0_0,
  output wire stat_rx_bip_err_1_0,
  output wire stat_rx_bip_err_2_0,
  output wire stat_rx_bip_err_3_0,
  output wire stat_rx_aligned_0,
  output wire stat_rx_hi_ber_0,
  output wire stat_rx_status_0,
  output wire [1:0] stat_rx_bad_code_0,
  output wire stat_rx_bad_code_valid_0,
  output wire stat_rx_error_valid_0,
  output wire [7:0] stat_rx_error_0,
  output wire stat_rx_fifo_error_0,
  output wire stat_rx_local_fault_0,




//// TX_0 Signals
  input  wire tx_reset_0,
  output wire user_tx_reset_0,

//// TX_0 User Interface Signals

  input [127:0] tx_mii_d_0,
  input  [15:0] tx_mii_c_0,

//// TX_0 Control Signals
  input  wire ctl_tx_test_pattern_0,


//// TX_0 Stats Signals
  output wire stat_tx_fifo_error_0,
  output wire stat_tx_local_fault_0,





  output wire [3:0] gtpowergood_out_0,
  input wire [11:0] txoutclksel_in_0,
  input wire [11:0] rxoutclksel_in_0,

  input  gt_refclk_p,
  input  gt_refclk_n,
  output wire gt_refclk_out,
  input  wire sys_reset,
  input  wire dclk
);


  wire rx_core_reset_0;
  wire tx_core_reset_0;


  wire gtwiz_reset_all_0;
  wire gtwiz_reset_tx_datapath_out_0;
  wire gtwiz_reset_rx_datapath_out_0;
  wire gtwiz_reset_tx_done_out_0;
  wire gtwiz_reset_rx_done_out_0;
  wire [0:0] gtwiz_reset_qpll0_reset_out_0;
  wire [0:0] gtwiz_reset_qpll1_reset_out_0;
////  Ports present when shared logic is implemented outside core
  wire [3:0] qpll0clk_in;
  wire [3:0] qpll0refclk_in;
  wire [3:0] qpll1clk_in;
  wire [3:0] qpll1refclk_in;
  wire [0:0] gtwiz_reset_qpll0lock_in;
  wire [0:0] gtwiz_reset_qpll1lock_in;

  wire [0:0] qpll0lock;
  wire [0:0] qpll0outclk;
  wire [0:0] qpll0outrefclk;
  wire [0:0] qpll1lock;
  wire [0:0] qpll1outclk;
  wire [0:0] qpll1outrefclk;

  assign qpll0clk_in = ({4{qpll0outclk}});
  assign qpll0refclk_in = ({4{qpll0outrefclk}});
  assign qpll1clk_in = ({4{qpll1outclk}});
  assign qpll1refclk_in = ({4{qpll1outrefclk}});
  assign gtwiz_reset_qpll0lock_in = qpll0lock;
  assign gtwiz_reset_qpll1lock_in = qpll1lock;

  wire qpll0reset_out;
  wire qpll1reset_out;
  wire powergood_out;
  assign powergood_out = &gtpowergood_out_0;
  assign qpll0reset_out = powergood_out ? 1'b0 : 1'b1 ;
  assign qpll1reset_out = powergood_out ? 1'b0 : 1'b1 ;

pcs_40g_def DUT
(
    .gt_rxp_in_0 (gt_rxp_in_0),
    .gt_rxn_in_0 (gt_rxn_in_0),
    .gt_txp_out_0 (gt_txp_out_0),
    .gt_txn_out_0 (gt_txn_out_0),
    .gt_rxp_in_1 (gt_rxp_in_1),
    .gt_rxn_in_1 (gt_rxn_in_1),
    .gt_txp_out_1 (gt_txp_out_1),
    .gt_txn_out_1 (gt_txn_out_1),
    .gt_rxp_in_2 (gt_rxp_in_2),
    .gt_rxn_in_2 (gt_rxn_in_2),
    .gt_txp_out_2 (gt_txp_out_2),
    .gt_txn_out_2 (gt_txn_out_2),
    .gt_rxp_in_3 (gt_rxp_in_3),
    .gt_rxn_in_3 (gt_rxn_in_3),
    .gt_txp_out_3 (gt_txp_out_3),
    .gt_txn_out_3 (gt_txn_out_3),
    .tx_mii_clk_0 (tx_mii_clk_0),
    .rx_core_clk_0 (rx_core_clk_0),
    .rx_clk_out_0 (rx_clk_out_0),
    .rxrecclkout_0 (rxrecclkout_0),

    .gt_loopback_in_0 (gt_loopback_in_0),


//// RX User Interface Signals
    .rx_mii_d_0 (rx_mii_d_0),
    .rx_mii_c_0 (rx_mii_c_0),


//
////// RX Control Signals
    .ctl_rx_test_pattern_0 (ctl_rx_test_pattern_0),





//// RX Stats Signals
    .stat_rx_block_lock_0 (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0_0 (stat_rx_framing_err_valid_0_0),
    .stat_rx_framing_err_0_0 (stat_rx_framing_err_0_0),
    .stat_rx_framing_err_valid_1_0 (stat_rx_framing_err_valid_1_0),
    .stat_rx_framing_err_1_0 (stat_rx_framing_err_1_0),
    .stat_rx_framing_err_valid_2_0 (stat_rx_framing_err_valid_2_0),
    .stat_rx_framing_err_2_0 (stat_rx_framing_err_2_0),
    .stat_rx_framing_err_valid_3_0 (stat_rx_framing_err_valid_3_0),
    .stat_rx_framing_err_3_0 (stat_rx_framing_err_3_0),
    .stat_rx_vl_demuxed_0 (stat_rx_vl_demuxed_0),
    .stat_rx_vl_number_0_0 (stat_rx_vl_number_0_0),
    .stat_rx_vl_number_1_0 (stat_rx_vl_number_1_0),
    .stat_rx_vl_number_2_0 (stat_rx_vl_number_2_0),
    .stat_rx_vl_number_3_0 (stat_rx_vl_number_3_0),
    .stat_rx_synced_0 (stat_rx_synced_0),
    .stat_rx_misaligned_0 (stat_rx_misaligned_0),
    .stat_rx_aligned_err_0 (stat_rx_aligned_err_0),
    .stat_rx_synced_err_0 (stat_rx_synced_err_0),
    .stat_rx_mf_len_err_0 (stat_rx_mf_len_err_0),
    .stat_rx_mf_repeat_err_0 (stat_rx_mf_repeat_err_0),
    .stat_rx_mf_err_0 (stat_rx_mf_err_0),
    .stat_rx_bip_err_0_0 (stat_rx_bip_err_0_0),
    .stat_rx_bip_err_1_0 (stat_rx_bip_err_1_0),
    .stat_rx_bip_err_2_0 (stat_rx_bip_err_2_0),
    .stat_rx_bip_err_3_0 (stat_rx_bip_err_3_0),
    .stat_rx_aligned_0 (stat_rx_aligned_0),
    .stat_rx_hi_ber_0 (stat_rx_hi_ber_0),
    .stat_rx_status_0 (stat_rx_status_0),
    .stat_rx_bad_code_0 (stat_rx_bad_code_0),
    .stat_rx_bad_code_valid_0 (stat_rx_bad_code_valid_0),
    .stat_rx_error_valid_0 (stat_rx_error_valid_0),
    .stat_rx_error_0 (stat_rx_error_0),
    .stat_rx_fifo_error_0 (stat_rx_fifo_error_0),
    .stat_rx_local_fault_0 (stat_rx_local_fault_0),



    .tx_reset_0 (tx_core_reset_0),
//// TX User Interface Signals
    .tx_mii_d_0 (tx_mii_d_0),
    .tx_mii_c_0 (tx_mii_c_0),

//// TX Control Signals
    .ctl_tx_test_pattern_0 (ctl_tx_test_pattern_0),


//// TX Stats Signals
    .stat_tx_fifo_error_0 (stat_tx_fifo_error_0),
    .stat_tx_local_fault_0 (stat_tx_local_fault_0),






    .gt_reset_all_in_0 (gtwiz_reset_all_0),
    .gt_tx_reset_in_0 (gtwiz_reset_tx_datapath_out_0),
    .gt_rx_reset_in_0 (gtwiz_reset_rx_datapath_out_0),
    .gt_reset_tx_done_out_0 (gtwiz_reset_tx_done_out_0),
    .gt_reset_rx_done_out_0 (gtwiz_reset_rx_done_out_0),
    .rx_serdes_reset_0 (rx_serdes_reset_0),

    .qpll0_clk_in_0 (qpll0clk_in ),
    .qpll0_refclk_in_0 (qpll0refclk_in ),
    .qpll1_clk_in_0 (qpll1clk_in ),
    .qpll1_refclk_in_0 (qpll1refclk_in ),
    .gtwiz_reset_qpll0_lock_in_0 (qpll0lock ),
    .gtwiz_reset_qpll0_reset_out_0 (gtwiz_reset_qpll0_reset_out_0 ),
    .gtwiz_reset_qpll1_lock_in_0 (qpll1lock ),
    .gtwiz_reset_qpll1_reset_out_0 (gtwiz_reset_qpll1_reset_out_0 ),
    .txoutclksel_in_0 (txoutclksel_in_0),
    .rxoutclksel_in_0 (rxoutclksel_in_0),
    .gtpowergood_out_0(gtpowergood_out_0),
    .rx_reset_0 (rx_core_reset_0),


    .sys_reset (sys_reset),
    .dclk (dclk)
);



pcs_40g_def_shared_logic_wrapper i_pcs_40g_def_sharedlogic_wrapper
(
    .gt_refclk_p (gt_refclk_p),
    .gt_refclk_n (gt_refclk_n),
    .gt_refclk_out(gt_refclk_out),
    .qpll0reset (gtwiz_reset_qpll0_reset_out_0),
    .qpll1reset (gtwiz_reset_qpll1_reset_out_0),
    .qpll0lock (qpll0lock),
    .qpll0outclk (qpll0outclk),
    .qpll0outrefclk (qpll0outrefclk),
    .qpll1lock (qpll1lock),
    .qpll1outclk (qpll1outclk),
    .qpll1outrefclk (qpll1outrefclk),
    .gt_txusrclk2_0 (tx_mii_clk_0),
    .gt_rxusrclk2_0 (rx_clk_out_0),
    .rx_core_clk_0 (rx_core_clk_0),
    .gt_tx_reset_in_0 (gtwiz_reset_tx_done_out_0|gtwiz_reset_tx_datapath_0),
    .gt_rx_reset_in_0 (gtwiz_reset_rx_done_out_0|gtwiz_reset_rx_datapath_0),
    .tx_core_reset_in_0 (tx_reset_0),
    .rx_core_reset_in_0 (rx_reset_0),
    .tx_core_reset_out_0 (tx_core_reset_0),
    .rx_core_reset_out_0 (rx_core_reset_0),
    .usr_tx_reset_0 (user_tx_reset_0),
    .usr_rx_reset_0 (user_rx_reset_0),
    .rx_serdes_reset_out_0 (rx_serdes_reset_0),
    .gtwiz_reset_all_0 (gtwiz_reset_all_0),
    .gtwiz_reset_tx_datapath_out_0 (gtwiz_reset_tx_datapath_out_0),
    .gtwiz_reset_rx_datapath_out_0 (gtwiz_reset_rx_datapath_out_0),
    .sys_reset(sys_reset),
    .dclk(dclk)
);


endmodule

