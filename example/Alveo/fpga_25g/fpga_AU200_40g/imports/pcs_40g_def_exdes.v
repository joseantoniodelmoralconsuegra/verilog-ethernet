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
module pcs_40g_def_exdes
(
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
  input wire send_continuous_pkts_0,
    output wire       rx_gt_locked_led,
    output wire       rx_aligned_led,
    output wire [4:0] completion_status,

    input             sys_reset,
    input             restart_tx_rx,

    input             gt_refclk_p,
    input             gt_refclk_n,
    input             dclk
);

`ifdef SIM_SPEED_UP
  parameter PKT_NUM         = 20;    //// Many Internal Counters are based on PKT_NUM = 20
`else
  parameter PKT_NUM         = 1000;    //// Many Internal Counters are based on PKT_NUM = 1000
`endif
  wire gt_refclk_out;

  wire gtwiz_reset_tx_datapath_0; 
  wire gtwiz_reset_rx_datapath_0; 
  assign gtwiz_reset_tx_datapath_0 = 1'b0; 
  assign gtwiz_reset_rx_datapath_0 = 1'b0; 
  wire rx_gt_locked_led_0;
  wire rx_aligned_led_0;

  wire rx_core_clk_0;
  wire rx_clk_out_0;
  wire tx_mii_clk_0;
  //assign rx_core_clk_0 = tx_mii_clk_0; 
  assign rx_core_clk_0 = rx_clk_out_0;

//// For other GT loopback options please change the value appropriately
//// For example, for internal loopback gt_loopback_in[2:0] = 3'b010;
//// For more information and settings on loopback, refer GT Transceivers user guide

  wire [11:0] gt_loopback_in_0;
  assign gt_loopback_in_0 = {4{3'b000}};
//// RX_0 Signals
  wire rx_reset_0;
  wire user_rx_reset_0;

//// RX_0 User Interface Signals
  wire [127:0] rx_mii_d_0;
  wire [15:0] rx_mii_c_0;

//// RX_0 Control Signals
  wire ctl_rx_test_pattern_0;


//// RX_0 Stats Signals
  wire [3:0] stat_rx_block_lock_0;
  wire stat_rx_framing_err_valid_0_0;
  wire stat_rx_framing_err_0_0;
  wire stat_rx_framing_err_valid_1_0;
  wire stat_rx_framing_err_1_0;
  wire stat_rx_framing_err_valid_2_0;
  wire stat_rx_framing_err_2_0;
  wire stat_rx_framing_err_valid_3_0;
  wire stat_rx_framing_err_3_0;
  wire [3:0] stat_rx_vl_demuxed_0;
  wire [1:0] stat_rx_vl_number_0_0;
  wire [1:0] stat_rx_vl_number_1_0;
  wire [1:0] stat_rx_vl_number_2_0;
  wire [1:0] stat_rx_vl_number_3_0;
  wire [3:0] stat_rx_synced_0;
  wire stat_rx_misaligned_0;
  wire stat_rx_aligned_err_0;
  wire [3:0] stat_rx_synced_err_0;
  wire [3:0] stat_rx_mf_len_err_0;
  wire [3:0] stat_rx_mf_repeat_err_0;
  wire [3:0] stat_rx_mf_err_0;
  wire stat_rx_bip_err_0_0;
  wire stat_rx_bip_err_1_0;
  wire stat_rx_bip_err_2_0;
  wire stat_rx_bip_err_3_0;
  wire stat_rx_aligned_0;
  wire stat_rx_hi_ber_0;
  wire stat_rx_status_0;
  wire [1:0] stat_rx_bad_code_0;
  wire stat_rx_bad_code_valid_0;
  wire stat_rx_error_valid_0;
  wire [7:0] stat_rx_error_0;
  wire stat_rx_fifo_error_0;
  wire stat_rx_local_fault_0;


//// TX_0 Signals
  wire tx_reset_0;
  wire user_tx_reset_0;

//// TX_0 User Interface Signals
  wire [127:0] tx_mii_d_0;
  wire [15:0] tx_mii_c_0;

//// TX_0 Control Signals
  wire ctl_tx_test_pattern_0;


//// TX_0 Stats Signals
  wire stat_tx_fifo_error_0;
  wire stat_tx_local_fault_0;





  wire rx_serdes_reset_0;
  wire [4:0] completion_status_0;
  wire [3:0] rxrecclkout_0;
  wire [3:0] gtpowergood_out_0;
  wire [11:0] txoutclksel_in_0;
  wire [11:0] rxoutclksel_in_0;
  assign txoutclksel_in_0 = {4{3'b101}};     // This value should not be changed as per gtwizard 
  assign rxoutclksel_in_0 = {4{3'b101}};    // This value should not be changed as per gtwizard


  wire usr_fsm_clk;
  
pcs_40g_def_clk_wiz_0 i_CLK_GEN_0
   (
   //// Clock in ports
    .clk_in1    (dclk), 
    .clk_out1   (usr_fsm_clk),
    .reset      (1'b0),
    .locked     ()
 );
pcs_40g_def_core_support i_pcs_40g_def_core_support
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
    .rx_reset_0 (rx_reset_0),
    .user_rx_reset_0 (user_rx_reset_0),
  
    
//// RX User Interface Signals
    .rx_mii_d_0 (rx_mii_d_0),
    .rx_mii_c_0 (rx_mii_c_0),


//// RX Control Signals
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



    .tx_reset_0 (tx_reset_0),
    .user_tx_reset_0 (user_tx_reset_0),
//// TX User Interface Signals
    .tx_mii_d_0 (tx_mii_d_0),
    .tx_mii_c_0 (tx_mii_c_0),

//// TX Control Signals
    .ctl_tx_test_pattern_0 (ctl_tx_test_pattern_0),


//// TX Stats Signals
    .stat_tx_fifo_error_0 (stat_tx_fifo_error_0),
    .stat_tx_local_fault_0 (stat_tx_local_fault_0),




    .gtwiz_reset_tx_datapath_0 (gtwiz_reset_tx_datapath_0),
    .gtwiz_reset_rx_datapath_0 (gtwiz_reset_rx_datapath_0),
    .gtpowergood_out_0 (gtpowergood_out_0),
    .txoutclksel_in_0 (txoutclksel_in_0),
    .rxoutclksel_in_0 (rxoutclksel_in_0),
    .gt_refclk_p(gt_refclk_p),
    .gt_refclk_n(gt_refclk_n),
    .gt_refclk_out(gt_refclk_out),
    .sys_reset (sys_reset),
    .dclk (dclk)
);


pcs_40g_def_pkt_gen_mon #(
.PKT_NUM (PKT_NUM))
 i_pcs_40g_def_pkt_gen_mon_0
(
 .gen_clk (tx_mii_clk_0),
    .mon_clk (rx_core_clk_0),
    .dclk (dclk),
    .usr_fsm_clk (usr_fsm_clk),
    .sys_reset (sys_reset),
    .restart_tx_rx (restart_tx_rx),
    .send_continuous_pkts (send_continuous_pkts_0),
     
//// User Interface signals
    .completion_status (completion_status_0),
    .rx_reset (rx_reset_0),
    .user_rx_reset(user_rx_reset_0),
//// RX User IF Signals
    .rx_mii_d (rx_mii_d_0),
    .rx_mii_c (rx_mii_c_0),

//// RX Control Signals
    .ctl_rx_test_pattern (ctl_rx_test_pattern_0),


//// RX Stats Signals
    .stat_rx_block_lock (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0 (stat_rx_framing_err_valid_0_0),
    .stat_rx_framing_err_0 (stat_rx_framing_err_0_0),
    .stat_rx_framing_err_valid_1 (stat_rx_framing_err_valid_1_0),
    .stat_rx_framing_err_1 (stat_rx_framing_err_1_0),
    .stat_rx_framing_err_valid_2 (stat_rx_framing_err_valid_2_0),
    .stat_rx_framing_err_2 (stat_rx_framing_err_2_0),
    .stat_rx_framing_err_valid_3 (stat_rx_framing_err_valid_3_0),
    .stat_rx_framing_err_3 (stat_rx_framing_err_3_0),
    .stat_rx_vl_demuxed (stat_rx_vl_demuxed_0),
    .stat_rx_vl_number_0 (stat_rx_vl_number_0_0),
    .stat_rx_vl_number_1 (stat_rx_vl_number_1_0),
    .stat_rx_vl_number_2 (stat_rx_vl_number_2_0),
    .stat_rx_vl_number_3 (stat_rx_vl_number_3_0),
    .stat_rx_synced (stat_rx_synced_0),
    .stat_rx_misaligned (stat_rx_misaligned_0),
    .stat_rx_aligned_err (stat_rx_aligned_err_0),
    .stat_rx_synced_err (stat_rx_synced_err_0),
    .stat_rx_mf_len_err (stat_rx_mf_len_err_0),
    .stat_rx_mf_repeat_err (stat_rx_mf_repeat_err_0),
    .stat_rx_mf_err (stat_rx_mf_err_0),
    .stat_rx_bip_err_0 (stat_rx_bip_err_0_0),
    .stat_rx_bip_err_1 (stat_rx_bip_err_1_0),
    .stat_rx_bip_err_2 (stat_rx_bip_err_2_0),
    .stat_rx_bip_err_3 (stat_rx_bip_err_3_0),
    .stat_rx_aligned (stat_rx_aligned_0),
    .stat_rx_hi_ber (stat_rx_hi_ber_0),
    .stat_rx_status (stat_rx_status_0),
    .stat_rx_bad_code (stat_rx_bad_code_0),
    .stat_rx_bad_code_valid (stat_rx_bad_code_valid_0),
    .stat_rx_error_valid (stat_rx_error_valid_0),
    .stat_rx_error (stat_rx_error_0),
    .stat_rx_fifo_error (stat_rx_fifo_error_0),
    .stat_rx_local_fault (stat_rx_local_fault_0),

    .tx_reset (tx_reset_0),
    .user_tx_reset (user_tx_reset_0),
//// TX User IF Signals
    .tx_mii_d (tx_mii_d_0),
    .tx_mii_c (tx_mii_c_0),

//// TX Control Signals
    .ctl_tx_test_pattern (ctl_tx_test_pattern_0),


//// TX Stats Signals
    .stat_tx_fifo_error (stat_tx_fifo_error_0),
    .stat_tx_local_fault (stat_tx_local_fault_0),


    .rx_gt_locked_led (rx_gt_locked_led_0),
    .rx_aligned_led (rx_aligned_led_0)
    );


assign rx_gt_locked_led = rx_gt_locked_led_0;
assign rx_aligned_led = rx_aligned_led_0;
assign completion_status = completion_status_0;

endmodule




