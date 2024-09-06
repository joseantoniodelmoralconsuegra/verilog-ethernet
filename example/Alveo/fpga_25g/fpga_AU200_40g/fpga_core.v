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
////PCS BASE-R TRAFFIC GENERATOR
module fpga_core #(
  parameter PKT_NUM             = 20    //// Many Internal Counters are based on PKT_NUM = 20
) (
    input                      gen_clk,
    input                      mon_clk,
    input                      dclk,
    input                      usr_fsm_clk,
    input                      sys_reset,
    input                      restart_tx_rx,
    input                      send_continuous_pkts,
 
//// RX Signals
    output wire         rx_reset,
    input  wire         user_rx_reset,
//// RX LBUS Signals
    input  wire [127:0] rx_mii_d,
    input  wire [15:0] rx_mii_c,

//// RX Control Signals
    output wire ctl_rx_test_pattern,


//// RX Stats Signals
    input  wire [3:0] stat_rx_block_lock,
    input  wire stat_rx_framing_err_valid_0,
    input  wire stat_rx_framing_err_0,
    input  wire stat_rx_framing_err_valid_1,
    input  wire stat_rx_framing_err_1,
    input  wire stat_rx_framing_err_valid_2,
    input  wire stat_rx_framing_err_2,
    input  wire stat_rx_framing_err_valid_3,
    input  wire stat_rx_framing_err_3,
    input  wire [3:0] stat_rx_vl_demuxed,
    input  wire [1:0] stat_rx_vl_number_0,
    input  wire [1:0] stat_rx_vl_number_1,
    input  wire [1:0] stat_rx_vl_number_2,
    input  wire [1:0] stat_rx_vl_number_3,
    input  wire [3:0] stat_rx_synced,
    input  wire stat_rx_misaligned,
    input  wire stat_rx_aligned_err,
    input  wire [3:0] stat_rx_synced_err,
    input  wire [3:0] stat_rx_mf_len_err,
    input  wire [3:0] stat_rx_mf_repeat_err,
    input  wire [3:0] stat_rx_mf_err,
    input  wire stat_rx_bip_err_0,
    input  wire stat_rx_bip_err_1,
    input  wire stat_rx_bip_err_2,
    input  wire stat_rx_bip_err_3,
    input  wire stat_rx_aligned,
    input  wire stat_rx_hi_ber,
    input  wire stat_rx_status,
    input  wire [1:0] stat_rx_bad_code,
    input  wire stat_rx_bad_code_valid,
    input  wire stat_rx_error_valid,
    input  wire [7:0] stat_rx_error,
    input  wire stat_rx_fifo_error,
    input  wire stat_rx_local_fault,


//// TX Signals
    output wire         tx_reset,
    input  wire         user_tx_reset,

//// TX LBUS Signals
    output wire [127:0] tx_mii_d,
    output wire [15:0] tx_mii_c,

//// TX Control Signals
    output wire ctl_tx_test_pattern,


//// TX Stats Signals
    input  wire stat_tx_fifo_error,
    input  wire stat_tx_local_fault,



    output wire  [4:0]  completion_status,
    output wire        rx_gt_locked_led,
    output wire        rx_aligned_led
   );

  wire [2:0] data_pattern_select;
  wire insert_crc;
  wire clear_count;
  wire pktgen_enable;
  reg  pktgen_enable_int;
  wire synced_pktgen_enable;
  wire rx_lane_align;
  
  wire tx_total_bytes_overflow;
  wire tx_sent_overflow;
  wire [31:0] tx_packet_count_int;
  wire [47:0] tx_sent_count;
  reg  [47:0] tx_sent_count_int;
  wire [47:0] synced_tx_sent_count;
  wire [63:0] tx_total_bytes;
  reg  [63:0] tx_total_bytes_int;
  wire [63:0] synced_tx_total_bytes;
  wire tx_time_out;
  reg  tx_time_out_int;
  wire synced_tx_time_out;
  wire tx_done;
  reg  tx_done_int;
  wire synced_tx_done;

  wire [3:0] synced_stat_rx_block_lock;
  wire [3:0] synced_stat_rx_synced;
  wire synced_stat_rx_aligned;
  wire synced_stat_rx_status;
  wire synced_restart_tx_rx;

  wire rx_errors;
  reg  rx_errors_int;
  wire synced_rx_errors;
  wire [31:0] rx_data_err_count;
  reg [31:0] rx_data_err_count_int;
  wire [31:0] synced_rx_data_err_count;
  wire [31:0] rx_error_count;
  wire [31:0] rx_prot_err_count; 
  wire [63:0] rx_total_bytes;
  reg  [63:0] rx_total_bytes_int;
  wire [63:0] synced_rx_total_bytes;
  wire [47:0] rx_packet_count;
  reg  [47:0] rx_packet_count_int;
  wire [47:0] synced_rx_packet_count;
  wire rx_packet_count_overflow;
  wire rx_total_bytes_overflow;
  wire rx_prot_err_overflow;
  wire rx_error_overflow;
  
  wire rx_data_err_overflow;

  assign tx_packet_count_int   = send_continuous_pkts ? 32'hFFFFFFFF : PKT_NUM;
//// RX Control Signals tieoff
  assign ctl_rx_test_pattern = 1'b0;
`ifdef SIM_SPEED_UP
  assign ctl_rx_vl_length_minus1 = 16'h003F;
`else
  assign ctl_rx_vl_length_minus1 = 16'h3FFF;
`endif

//// TX Control Signals tieoff
  assign ctl_tx_test_pattern = 1'b0;
  `ifdef SIM_SPEED_UP
  assign ctl_tx_vl_length_minus1 = 16'h003F;
  `else
  assign ctl_tx_vl_length_minus1 = 16'h3FFF;
  `endif


  wire ok_to_start;
  assign ok_to_start = 1'b1;  


  assign rx_errors            = |rx_prot_err_count || |rx_error_count ;

pcs_40g_def_pkt_gen_mon_syncer_level
#(
  .WIDTH       ( 4 )
 ) i_pcs_40g_def_stat_rx_block_lock_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_block_lock  ),
  .dataout       (  synced_stat_rx_block_lock  )
);

pcs_40g_def_pkt_gen_mon_syncer_level
#(
  .WIDTH       ( 4 )
 ) i_pcs_40g_def_stat_rx_synced_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_synced  ),
  .dataout       (  synced_stat_rx_synced  )
);

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_stat_rx_aligned_dclk_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_aligned  ),
  .dataout       (  synced_stat_rx_aligned  )
);

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_stat_rx_aligned_gen_clk_syncer (
  .clk           (  gen_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_aligned  ),
  .dataout       (  rx_lane_align  )
);

  reg stat_rx_status_int;
  always @(posedge mon_clk)
  begin
      stat_rx_status_int   <= stat_rx_status ;
  end

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_stat_rx_status_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  stat_rx_status_int  ),
  .dataout       (  synced_stat_rx_status  )
);

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_restart_tx_rx_syncer (
  .clk           (  usr_fsm_clk  ),
  .reset         (  sys_reset  ),
  .datain        (  restart_tx_rx  ),
  .dataout       (  synced_restart_tx_rx  )
);

  always @(posedge gen_clk)
  begin
      tx_time_out_int   <= tx_time_out ;
  end

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_tx_time_out_syncer (
  .clk          (  usr_fsm_clk ),
  .reset        (  sys_reset  ),
  .datain       (  tx_time_out_int  ),
  .dataout      (  synced_tx_time_out  )
);

  always @(posedge gen_clk)
  begin
      tx_done_int       <= tx_done ;
  end

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_tx_done_syncer (
  .clk          (  usr_fsm_clk ),
  .reset        (  sys_reset  ),
  .datain       (  tx_done_int  ),
  .dataout      (  synced_tx_done  )
);

  always@ (posedge usr_fsm_clk)
  begin
      pktgen_enable_int <= pktgen_enable;
  end

pcs_40g_def_pkt_gen_mon_syncer_level i_pcs_40g_def_pkt_gen_enable_syncer (
    .clk          (  gen_clk  ),
    .reset        (  sys_reset  ),
    .datain       (  pktgen_enable_int  ),
    .dataout      (  synced_pktgen_enable  )
);

  always @(posedge gen_clk)
  begin
      tx_total_bytes_int  <= tx_total_bytes;
  end
  
pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (64)
  ) i_pcs_40g_def_tx_total_bytes_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (tx_total_bytes_int),
    .dataout   (synced_tx_total_bytes)
  );

  always @(posedge gen_clk)
  begin
      tx_sent_count_int <= tx_sent_count;
  end

pcs_40g_def_pkt_gen_mon_syncer_level
  #(
    .WIDTH        (48)
  ) i_pcs_40g_def_tx_packet_count_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (tx_sent_count_int),
    .dataout   (synced_tx_sent_count)
  );

  always @(posedge mon_clk)
  begin
      rx_packet_count_int <= rx_packet_count;
  end

pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (48)
  ) i_pcs_40g_def_rx_packet_count_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (rx_packet_count_int),
    .dataout   (synced_rx_packet_count)
  );

  always @(posedge mon_clk)
  begin
      rx_total_bytes_int  <= rx_total_bytes;
  end

pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (64)
  ) i_pcs_40g_def_rx_total_bytes_syncer (
    .clk       (usr_fsm_clk ),
    .reset     (sys_reset),
    .datain    (rx_total_bytes_int),
    .dataout   (synced_rx_total_bytes)
  );

  always @(posedge mon_clk)
  begin
      rx_errors_int       <= rx_errors;
  end

pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (1)
  ) i_pcs_40g_def_rx_errors_syncer (
    .clk       (usr_fsm_clk),
    .reset     (sys_reset),
    .datain    (rx_errors_int),
    .dataout   (synced_rx_errors)
  );
  always @(posedge mon_clk)
  begin
      rx_data_err_count_int       <= rx_data_err_count;
  end

pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (32)
  ) i_pcs_40g_def_rx_data_err_count_syncer (
    .clk       (usr_fsm_clk),
    .reset     (sys_reset),
    .datain    (rx_data_err_count_int),
    .dataout   (synced_rx_data_err_count)
  );

pcs_40g_def_pcs_baser_support_example_fsm  #(
`ifdef SIM_SPEED_UP
 .STARTUP_TIME (32'd5000)
`else
 .STARTUP_TIME (32'd50_000)
`endif
  ) i_pcs_40g_def_EXAMPLE_FSM  (
  .dclk                        (  usr_fsm_clk  ),
  .fsm_reset                   (  sys_reset || synced_restart_tx_rx  ),
  .send_continuous_pkts        (send_continuous_pkts),
  .stat_rx_block_lock          (  synced_stat_rx_block_lock  ),
  .stat_rx_synced              (  synced_stat_rx_synced  ),
  .stat_rx_aligned             (  synced_stat_rx_aligned  ),
  .stat_rx_status              (  synced_stat_rx_status  ),
  .tx_timeout                  (  synced_tx_time_out  ),
  .tx_done                     (  synced_tx_done  ),
  .ok_to_start                 (  ok_to_start  ),

  .rx_packet_count             (  synced_rx_packet_count  ),
  .rx_total_bytes              (  synced_rx_total_bytes  ),
  .rx_errors                   (  synced_rx_errors  ),
  .rx_data_errors              (  |synced_rx_data_err_count  ),
  .tx_sent_count               (  synced_tx_sent_count  ),
  .tx_total_bytes              (  synced_tx_total_bytes  ),

  .sys_reset                   (   ),
  .pktgen_enable               (  pktgen_enable  ),

  .completion_status           (  completion_status  )
);


  assign tx_reset = sys_reset;
  assign rx_reset = sys_reset;
  assign rx_gt_locked_led = ~user_rx_reset;
  assign rx_aligned_led = stat_rx_aligned;

  assign data_pattern_select     =      3'd0;
  assign clear_count             =      1'b0;
  assign insert_crc              =      1'b0;

  reg [127:0] rx_mii_d_d1;
  reg [15:0] rx_mii_c_d1;
  
  always @(posedge mon_clk)
  begin
      rx_mii_d_d1       <= rx_mii_d;
      rx_mii_c_d1       <= rx_mii_c;
  end
  
// packet generator
(* mark_debug = "true" , dont_touch = "yes" *) wire tx_axis_tready;
(* mark_debug = "true" , dont_touch = "yes" *) wire tx_axis_tvalid;
(* mark_debug = "true" , dont_touch = "yes" *) wire [127:0] tx_axis_tdata;
(* mark_debug = "true" , dont_touch = "yes" *) wire [15:0] tx_axis_tkeep;
(* mark_debug = "true" , dont_touch = "yes" *) wire [0:0] tx_axis_tuser;
(* mark_debug = "true" , dont_touch = "yes" *) wire  tx_axis_tlast;

packetgen #(
    .DATA_WIDTH(128),
    .FREQUENCY(312500),
    .N_FLOWS(1)
)
packetgen_inst(
    .clk(gen_clk),
    .rst(user_tx_reset || restart_tx_rx || !synced_pktgen_enable || !rx_lane_align),
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

assign tx_axis_tuser = 1'b0;

(* mark_debug = "true" , dont_touch = "yes" *) wire rx_axis_tready = 1'b1;
(* mark_debug = "true" , dont_touch = "yes" *) wire rx_axis_tvalid;
(* mark_debug = "true" , dont_touch = "yes" *) wire [127:0] rx_axis_tdata;
(* mark_debug = "true" , dont_touch = "yes" *) wire [15:0] rx_axis_tkeep;
(* mark_debug = "true" , dont_touch = "yes" *) wire [0:0] rx_axis_tuser;
(* mark_debug = "true" , dont_touch = "yes" *) wire  rx_axis_tlast;

(* mark_debug = "true" , dont_touch = "yes" *) wire rx_error_bad_fcs;
(* mark_debug = "true" , dont_touch = "yes" *) wire rx_error_bad_frame;

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
    .tx_clk(gen_clk),
    .tx_rst(user_tx_reset || restart_tx_rx || !synced_pktgen_enable || !rx_lane_align),
    .rx_clk(mon_clk),
    .rx_rst(user_rx_reset || restart_tx_rx),
    .logic_clk(gen_clk),
    .logic_rst(user_tx_reset || restart_tx_rx || !synced_pktgen_enable || !rx_lane_align),

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

    .xgmii_rxd(rx_mii_d),
    .xgmii_rxc(rx_mii_c),
    .xgmii_txd(tx_mii_d),
    .xgmii_txc(tx_mii_c),

    .tx_fifo_overflow(),
    .tx_fifo_bad_frame(),
    .tx_fifo_good_frame(),
    .rx_error_bad_frame(rx_error_bad_frame),
    .rx_error_bad_fcs(rx_error_bad_fcs),
    .rx_fifo_overflow(),
    .rx_fifo_bad_frame(),
    .rx_fifo_good_frame(),

    .cfg_ifg(8'd12),
    .cfg_tx_enable(1'b1),
    .cfg_rx_enable(1'b1)
);

endmodule



module pcs_40g_def_pcs_baser_support_example_fsm  #(
  parameter [31:0] STARTUP_TIME = 32'd20_000,
                   VL_LANES_PER_GENERATOR = 4,
                   GENERATOR_COUNT = 1                  // Number of traffic generators being monitored
  )  (
input wire dclk,
input wire fsm_reset,
input wire [VL_LANES_PER_GENERATOR*GENERATOR_COUNT-1:0] stat_rx_block_lock,
input wire [VL_LANES_PER_GENERATOR*GENERATOR_COUNT-1:0] stat_rx_synced,
input wire stat_rx_aligned,
input wire stat_rx_status,
input wire send_continuous_pkts, 
input wire tx_timeout,
input wire tx_done,
input wire ok_to_start,

input wire [(48 * GENERATOR_COUNT - 1):0] rx_packet_count,
input wire [64 * GENERATOR_COUNT - 1:0] rx_total_bytes,
input wire  rx_errors,
input wire        rx_data_errors,
input wire [(48 * GENERATOR_COUNT - 1):0] tx_sent_count,
input wire [64 * GENERATOR_COUNT - 1:0]  tx_total_bytes,

output reg sys_reset,
output reg pktgen_enable,

output reg [4:0] completion_status
);

localparam [4:0]   NO_START = {5{1'b1}},
                   TEST_START = 5'd0,
                   SUCCESSFUL_COMPLETION = 5'd1,
                   NO_BLOCK_LOCK = 5'd2,
                   PARTIAL_BLOCK_LOCK = 5'd3,
                   INCONSISTENT_BLOCK_LOCK = 5'd4,
                   NO_LANE_SYNC = 5'd5,
                   PARTIAL_LANE_SYNC = 5'd6,
                   INCONSISTENT_LANE_SYNC = 5'd7,
                   NO_ALIGN_OR_STATUS = 5'd8,
                   LOSS_OF_STATUS = 5'd9,
                   TX_TIMED_OUT = 5'd10,
                   NO_DATA_SENT = 5'd11,
                   SENT_COUNT_MISMATCH = 5'd12,
                   BYTE_COUNT_MISMATCH = 5'd13,
                   LBUS_PROTOCOL = 5'd14,
                   BIT_ERRORS_IN_DATA = 5'd15;

/* Parameter definitions of STATE variables for 5 bit state machine */
localparam [4:0]  S0 = 5'b00000,     // S0 = 0
                  S1 = 5'b00001,     // S1 = 1
                  S2 = 5'b00011,     // S2 = 3
                  S3 = 5'b00010,     // S3 = 2
                  S4 = 5'b00110,     // S4 = 6
                  S5 = 5'b00111,     // S5 = 7
                  S6 = 5'b00101,     // S6 = 5
                  S7 = 5'b00100,     // S7 = 4
                  S8 = 5'b01100,     // S8 = 12
                  S9 = 5'b01101,     // S9 = 13
                  S10 = 5'b01111,     // S10 = 15
                  S11 = 5'b01110,     // S11 = 14
                  S12 = 5'b01010,     // S12 = 10
                  S13 = 5'b01011,     // S13 = 11
                  S14 = 5'b01001,     // S14 = 9
                  S15 = 5'b01000,     // S15 = 8
                  S16 = 5'b11000,     // S16 = 24
                  S17 = 5'b11001;     // S17 = 25


reg [4:0] state ;
reg [31:0] common_timer;
reg rx_packet_count_mismatch;
reg rx_byte_count_mismatch;
reg rx_non_zero_error_count;
reg tx_zero_sent;

wire send_continuous_pkts_sync;
pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (32)
  ) i_pcs_40g_def_send_continuous_pkt_syncer (
    .clk       (dclk),
    .reset     (fsm_reset),
    .datain    (send_continuous_pkts),
    .dataout   (send_continuous_pkts_sync)
  );
always @( posedge dclk )
    begin
      if ( fsm_reset == 1'b1 ) begin
        common_timer <= 0;
        state <= S0;
        sys_reset <= 1'b0 ;
        pktgen_enable <= 1'b0;
        completion_status <= NO_START ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        rx_non_zero_error_count <= 0;
        tx_zero_sent <= 0;
      end
      else begin :check_loop
        integer i;
        common_timer <= |common_timer ? common_timer - 1 : common_timer;
        rx_non_zero_error_count <=  rx_data_errors ;
        rx_packet_count_mismatch <= 0;
        rx_byte_count_mismatch <= 0;
        tx_zero_sent <= 0;
        for ( i = 0; i < GENERATOR_COUNT; i=i+1 ) begin
          if ( tx_total_bytes[(64 * i)+:64] != rx_total_bytes[(64 * i)+:64] ) rx_byte_count_mismatch <= 1'b1;
          if ( tx_sent_count[(48 * i)+:48] != rx_packet_count[(48 * i)+:48] ) rx_packet_count_mismatch <= 1'b1;         // Check all generators for received counts equal transmitted count
          if ( ~|tx_sent_count[(48 * i)+:48] ) tx_zero_sent <= 1'b1;                                                       // If any channel fails to send any data, flag zero-sent
        end
        case ( state )
          S0: state <= ok_to_start ? S1 : S0;
          S1: begin
`ifdef SIM_SPEED_UP
                common_timer <= cvt_us ( 32'd100 );               // If this is the example simulation then only wait for 100 us
`else
                common_timer <= cvt_us ( 32'd10_000 );               // Wait for 10ms...do nothing; settling time for MMCs, oscilators, QPLLs etc.
`endif
                completion_status <= TEST_START;
                state <= S2;
              end
          S2: state <= (|common_timer) ? S2 : S3;
          S3: begin
                common_timer <= 3;
                sys_reset <= 1'b1;
                state <= S4;
              end
          S4: state <= (|common_timer) ? S4 : S5;
          S5: begin
                common_timer <= cvt_us( 5 );                    // Allow about 5 us for the reset to propagate into the downstream hardware
                sys_reset <= 1'b0;     // Clear the reset
                state <= S16;
              end
         S16: state <= (|common_timer) ? S16 : S17;
         S17: begin
                common_timer <= cvt_us( STARTUP_TIME );            // Set 20ms wait period
                state <= S6;
              end
          S6: if(|common_timer) state <= |stat_rx_block_lock ? S7 : S6 ;
              else begin
                state <= S15;
                completion_status <= NO_BLOCK_LOCK;
              end
          S7: if(|common_timer) state <= &stat_rx_block_lock ? S8 : S7 ;
              else begin
                state <= S15;
                completion_status <= PARTIAL_BLOCK_LOCK;
              end
          S8: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else state <= |stat_rx_synced ? S9 : S8 ;
              end
              else begin
                state <= S15;
                completion_status <= NO_LANE_SYNC;
              end
          S9: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else state <= &stat_rx_synced ? S10 : S9 ;
              end
              else begin
                state <= S15;
                completion_status <= PARTIAL_LANE_SYNC;
              end
          S10: if(|common_timer) begin
                if( ~&stat_rx_block_lock ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_BLOCK_LOCK;
                end
                else if( ~&stat_rx_synced ) begin
                  state <= S15;
                  completion_status <= INCONSISTENT_LANE_SYNC;
                end
                else begin
                  state <= (stat_rx_aligned && stat_rx_status ) ? S11 : S10 ;
                end
              end
              else begin
                state <= S15;
                completion_status <= NO_ALIGN_OR_STATUS;
              end
          S11: begin
                 state <= S12;
`ifdef SIM_SPEED_UP
                 common_timer <= cvt_us( 32'd50 );            // Set 50us wait period while aligned (simulation only )
`else
                 common_timer <= cvt_us( 32'd1_000 );            // Set 1ms wait period while aligned
`endif
               end
          S12: if(|common_timer) begin
                 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
                   state <= S15;
                   completion_status <= LOSS_OF_STATUS;
                 end
               end
               else begin
                state <= S13;
                pktgen_enable <= 1'b1;                          // Turn on the packet generator
`ifdef SIM_SPEED_UP
                common_timer <= cvt_us( 32'd40 );            // Set wait period for packet transmission
`else
                common_timer <= cvt_us( 32'd10_000 );
`endif
              end
          S13: if(|common_timer) begin
                 if( ~&stat_rx_block_lock || ~&stat_rx_synced || ~stat_rx_aligned || ~stat_rx_status ) begin
                   state <= S15;
                   completion_status <= LOSS_OF_STATUS;
                 end
                 if(send_continuous_pkts_sync) begin
`ifdef SIM_SPEED_UP
                   common_timer <= cvt_us( 32'd50); // After send_continuous_pkts becomes "0" simulation wait for 50 us
`else
                   common_timer <= cvt_us( 32'd1_000); // After send_continuous_pkts becomes "0" simulation wait for 1 ms
`endif
                 end
               end
               else state <= S14;
          S14: begin
                 state <= S15;
                 completion_status <= SUCCESSFUL_COMPLETION;
                 if(tx_timeout || ~tx_done) completion_status <= TX_TIMED_OUT;
                 else if(rx_packet_count_mismatch) completion_status <= SENT_COUNT_MISMATCH;
                 else if(rx_byte_count_mismatch) completion_status <= BYTE_COUNT_MISMATCH;
                 else if(rx_errors) completion_status <= LBUS_PROTOCOL;
                 else if(rx_non_zero_error_count) completion_status <= BIT_ERRORS_IN_DATA;
                 else if(tx_zero_sent) completion_status <= NO_DATA_SENT;
               end
          S15: state <= S15;            // Finish and wait forever
        endcase
      end
    end


function [31:0] cvt_us( input [31:0] d );
cvt_us = ( ( d * 300 ) + 3 ) / 4 ;
endfunction

endmodule


module pcs_40g_def_pkt_gen_mon_syncer_level
#(
  parameter WIDTH       = 1,
  parameter RESET_VALUE = 1'b0
 )
(
  input  wire clk,
  input  wire reset,

  input  wire [WIDTH-1:0] datain,
  output wire [WIDTH-1:0] dataout
);

  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] dataout_reg;
  reg  [WIDTH-1:0] meta_nxt;
  wire [WIDTH-1:0] dataout_nxt;

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off

  integer i;
  integer seed;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta2;
  reg  [WIDTH-1:0] meta_state;
  reg  [WIDTH-1:0] meta_state_nxt;
  reg  [WIDTH-1:0] last_datain;

  initial seed       = `SEED;
  initial meta_state = {WIDTH{RESET_VALUE}};

  always @*
    begin
      for (i=0; i < WIDTH; i = i + 1)
        begin
          if ( meta_state[i] !== 1'b1 &&
               last_datain[i] !== datain[i] &&
               $dist_uniform(seed,0,9999) < 5000 &&
               meta[i] !== datain[i] )
            begin
              meta_nxt[i]       = meta[i];
              meta_state_nxt[i] = 1'b1;
            end
          else
            begin
              meta_nxt[i]       = datain[i];
              meta_state_nxt[i] = 1'b0;
            end
        end // for

      last_datain = datain;
    end

  always @( posedge clk )
    begin
      meta_state <= meta_state_nxt;
    end


// pragma translate_on
`else
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta;
  (* ASYNC_REG = "TRUE" *) reg  [WIDTH-1:0] meta2;
  always @*
    begin
      meta_nxt = datain;
    end

`endif

  always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 )
        begin
          meta  <= {WIDTH{RESET_VALUE}};
          meta2 <= {WIDTH{RESET_VALUE}};
        end
      else
        begin
          meta  <= meta_nxt;
          meta2 <= meta;
        end
    end

  assign dataout_nxt = meta2;

  always @( posedge clk or posedge reset )
    begin
      if ( reset == 1'b1 )
        begin
          dataout_reg <= {WIDTH{RESET_VALUE}};
        end
      else
        begin
          dataout_reg <= dataout_nxt;
        end
    end

  assign dataout = dataout_reg;

`ifdef SARANCE_RTL_DEBUG
// pragma translate_off

// pragma translate_on
`endif

endmodule // syncer_level


