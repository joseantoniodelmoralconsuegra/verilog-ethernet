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
module pcs_40g_def_pkt_gen_mon #(
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
  
pcs_40g_def_pcs_baser_support_pkt_io1 #(
  .FIXED_PACKET_LENGTH ( 256 ),
  .TRAF_MIN_LENGTH     ( 64 ),
  .TRAF_MAX_LENGTH     ( 9000 )
) i_pcs_40g_def_TRAFFIC_GENERATOR (
  .tx_clk ( gen_clk ),
  .rx_clk ( mon_clk ),
  .tx_reset ( user_tx_reset | restart_tx_rx),
  .send_continuous_pkts (send_continuous_pkts),
  .rx_reset ( user_rx_reset | restart_tx_rx),
  .tx_enable ( synced_pktgen_enable ),
  .rx_enable ( 1'b1 ),
  .data_pattern_select ( data_pattern_select ),
  .insert_crc ( insert_crc ),
  .tx_packet_count ( tx_packet_count_int ),
  .clear_count ( clear_count ),

  .rx_lane_align ( rx_lane_align ),

  .tx_mii_d (tx_mii_d),
  .tx_mii_c (tx_mii_c),
  .rx_mii_d (rx_mii_d_d1),
  .rx_mii_c (rx_mii_c_d1),

  .tx_time_out ( tx_time_out ),
  .tx_done ( tx_done ),
  .rx_protocol_error ( rx_protocol_error ),
  .rx_packet_count ( rx_packet_count ),
  .rx_total_bytes ( rx_total_bytes ),
  .rx_prot_err_count ( rx_prot_err_count ),
  .rx_error_count ( rx_error_count ),
  .rx_packet_count_overflow ( rx_packet_count_overflow ),
  .rx_total_bytes_overflow ( rx_total_bytes_overflow ),
  .rx_prot_err_overflow ( rx_prot_err_overflow ),
  .rx_error_overflow ( rx_error_overflow ),
  .tx_sent_count ( tx_sent_count ),
  .tx_sent_overflow ( tx_sent_overflow ),
  .tx_total_bytes ( tx_total_bytes ),
  .tx_total_bytes_overflow ( tx_total_bytes_overflow ),
  .rx_data_err_count ( rx_data_err_count ),
  .rx_data_err_overflow ( rx_data_err_overflow )
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

module pcs_40g_def_pcs_baser_support_pkt_io1 #(
  parameter integer FIXED_PACKET_LENGTH = 9_000,
                    TRAF_MIN_LENGTH = 64,
                    TRAF_MAX_LENGTH = 9000
               ) (

  input  wire tx_clk,
  input  wire rx_clk,
  input  wire tx_reset,
  input  wire rx_reset,
  input  wire send_continuous_pkts,
  input  wire tx_enable,
  input  wire rx_enable,
  input  wire [2:0] data_pattern_select,
  input  wire insert_crc,
  input  wire [31:0] tx_packet_count,
  input  wire clear_count,
  input  wire rx_lane_align,
  output wire [127:0] tx_mii_d,
  output wire [15:0] tx_mii_c,
  input  wire [127:0] rx_mii_d,
  input  wire [15:0] rx_mii_c,
  output wire tx_time_out,
  output wire tx_done,
  output wire rx_protocol_error,
  output wire [47:0] rx_packet_count,
  output wire [63:0] rx_total_bytes,
  output wire [31:0] rx_prot_err_count,
  output wire [31:0] rx_error_count,
  output wire rx_packet_count_overflow,
  output wire rx_total_bytes_overflow,
  output wire rx_prot_err_overflow,
  output wire rx_error_overflow,
  output wire [47:0] tx_sent_count,
  output wire tx_sent_overflow,
  output wire [63:0] tx_total_bytes,
  output wire tx_total_bytes_overflow,
  output wire [31:0] rx_data_err_count,
  output wire rx_data_err_overflow
);

wire pkt_tx_busy;

pcs_40g_def_pcs_baser_support_pkt_gen1
  #(
  .pkt_len ( FIXED_PACKET_LENGTH )
  ) i_pcs_40g_def_PKT_GEN1 (                       // Generator to send 1 packet
  .tx_mii_clk                     ( tx_clk ),
  .tx_mii_reset                   ( tx_reset ),

  .enable                         (  tx_enable && ~data_pattern_select[2]   ),
  .insert_crc                     (  insert_crc  ),
  .data_select                    (  data_pattern_select[1:0]  ),
  .packet_count                   (  tx_packet_count  ),
  .send_continuous_pkts ( send_continuous_pkts ),
  .tx_mii_d                       (  tx_mii_d  ),
  .tx_mii_c                       (  tx_mii_c  ),

  .time_out                       (  tx_time_out  ),
  .busy                           (  pkt_tx_busy ),
  .done                           (  tx_done  )
);

assign     rx_data_err_count            =             32'h0;
assign     rx_data_err_overflow         =             1'b0;

pcs_40g_def_pcs_baser_support_traf_chk1 i_pcs_40g_def_TRAF_CHK1 (

  .mii_clk          ( rx_clk ),
  .mii_reset        ( rx_reset ),
  .enable           ( rx_enable ),
  .clear_count      ( clear_count ),

  .mii_d            ( rx_mii_d ),
  .mii_c            ( rx_mii_c ),

  .protocol_error   ( rx_protocol_error ),
  .packet_count     ( rx_packet_count ),
  .total_bytes      ( rx_total_bytes ),
  .prot_err_count   ( rx_prot_err_count ),
  .error_count      ( rx_error_count ),
  .packet_count_overflow   ( rx_packet_count_overflow ),
  .total_bytes_overflow    ( rx_total_bytes_overflow ),
  .prot_err_overflow       ( rx_prot_err_overflow ),
  .error_overflow          ( rx_error_overflow )
);

pcs_40g_def_pcs_baser_support_traf_chk1 i_pcs_40g_def_TRAF_CHK2 (                         // Counter for packets sent

  .mii_clk          ( tx_clk ),
  .mii_reset        ( tx_reset ),
  .enable           ( tx_enable || pkt_tx_busy ),
  .clear_count      ( clear_count ),

  .mii_d            ( tx_mii_d ),
  .mii_c            ( tx_mii_c ),

  .protocol_error   ( ),
  .packet_count     ( tx_sent_count ),
  .total_bytes      ( tx_total_bytes ),
  .prot_err_count   ( ),
  .error_count      ( ),
  .packet_count_overflow   ( tx_sent_overflow ),
  .total_bytes_overflow    ( tx_total_bytes_overflow ),
  .prot_err_overflow       ( ),
  .error_overflow          ( )
);




endmodule

module pcs_40g_def_pcs_baser_support_pkt_gen1
  #(
  parameter integer pkt_len = 300
  ) (                       // Generator to send 1 packet

  input  wire enable,
  input  wire insert_crc,
  input  wire [1:0] data_select,
  input  wire [31:0] packet_count,
  input  wire send_continuous_pkts,
  input  wire tx_mii_clk,
  input  wire tx_mii_reset,
  output  reg [127:0] tx_mii_d,
  output  reg [15:0]  tx_mii_c,

  output wire time_out,                 // 1 second timeout
  output reg  busy,                 // indicator that the traffic generator is operating
  output wire done
);

reg [1:0] q_en;
reg [2:0] state;
reg [31:0] rand1;
wire [31:0] nxt_rand1;
wire [127:0] nxt_d;
reg [127:0] d_buff;
reg [31:0] counter;
reg [127:0] op_data;
reg [1:0] d_sel;

wire [127:0]  op_mask;
reg [29:0] op_timer;
reg [31:0] packet_counter;
reg z_pkt;
reg [2:0] bsy_cntr;

localparam [63:0] preamble   = 64'hFB_55_55_55_55_55_55_D5 ;      // Broadcast
localparam [47:0] dest_addr   = 48'hFF_FF_FF_FF_FF_FF;            // Broadcast
localparam [47:0] source_addr = 48'h14_FE_B5_DD_9A_82;            // Hardware address of xowjcoppens40
localparam [15:0] length_type = 16'h0600;                       // XEROX NS IDP
localparam [175:0] eth_header = { preamble, dest_addr, source_addr, length_type} ;

localparam [32:0] CRC_POLYNOMIAL = 33'b100000100110000010001110110110111;
//     G(x) = x32 + x26 + x23 + x22 + x16 + x12 + x11 + x10 + x8 + x7 + x5 + x4 + x2 + x + 1

localparam [32:0] DATA_POLYNOMIAL = 33'b100001000001010000000010010000001;
localparam [31:0] init_crc = 32'b11010111011110111101100110001011;

localparam integer xfer_cnt = pkt_len/16,
                   xfer_rmdr = pkt_len%16 ,
                   nz_rmdr = ( xfer_rmdr == 0 ) ? 1 : xfer_rmdr ;
localparam [15:0] xfer_ctl = (xfer_rmdr==0) ? { 16 { 1'b0 }} : { { 16-nz_rmdr{1'b1}}, {nz_rmdr{1'b0}} } ;

localparam integer crc_cnt = (pkt_len-4)/16,
                   crc_rmdr = (pkt_len-4)%16,
                   crc_insrt = (xfer_rmdr == 0) ? 0 : (128 - (xfer_rmdr * 8)),
                   crc_bits = (xfer_rmdr >= 4) ? 32 : (xfer_rmdr*8),
                   nz_bits = (crc_bits == 0) ? 32 : crc_bits,
                   crc_residue_bits = (crc_cnt != xfer_cnt) ? (32 - crc_bits) : 32,
                   crc_residue_start = (crc_cnt != xfer_cnt) ? crc_bits : 0;


localparam integer full_bits = xfer_rmdr * 8,
                   empty_bits =  128 - full_bits;
generate
if (full_bits==0) assign op_mask = {128{1'b1}} ;
else assign op_mask = { {full_bits{1'b1}} , {empty_bits{1'b0}} } ;
endgenerate
reg set_eop;

localparam [31:0] PKT0_CRC = gen_CRC_const(pkt_len-4,1'b0);
localparam [31:0] PKT1_CRC = gen_CRC_const(pkt_len-4,1'b1);
localparam [31:0] PKT3_CRC = gen_CRC3(pkt_len-4);

reg [31:0] op_crc;
reg en_residue;

reg [8:0] header_bit_count ;

always @(*) case(d_sel)
  2'b00: begin op_data = {128{1'b0}}; op_crc = PKT0_CRC; end
  2'b01: begin op_data = {128{1'b1}}; op_crc = PKT1_CRC; end
  default: begin op_data = d_buff; op_crc = PKT3_CRC; end
endcase

/* Parameter definitions of STATE variables for 3 bit state machine */

localparam [2:0]
    S0  = 3'b000,           // S0  = 0
    S1  = 3'b001,           // S1  = 1
    S2  = 3'b011,           // S2  = 3
    S3  = 3'b010,           // S3  = 2
    S4  = 3'b110,           // S4  = 6
    S5  = 3'b111,           // S5  = 7
    S6  = 3'b101,           // S6  = 5
    S7  = 3'b100;           // S7  = 4

pcs_40g_def_pcs_baser_support_pktprbs_gen #(
  .BIT_COUNT(128)
) i_pcs_40g_def_PKT_PRBS_GEN (
  .ip(rand1),
  .op(nxt_rand1),
  .datout(nxt_d)
);

  reg  send_continuous_pkts_sync_d;
  wire send_continuous_pkts_sync;
pcs_40g_def_pkt_gen_mon_syncer_level 
  #(
    .WIDTH        (32)
  ) i_pcs_40g_def_send_continuous_pkt_syncer (
    .clk       (tx_mii_clk),
    .reset     (tx_mii_reset),
    .datain    (send_continuous_pkts),
    .dataout   (send_continuous_pkts_sync)
  );
assign time_out = ~|op_timer,
       done     = (state==S7);

always @( posedge tx_mii_clk )
    begin
      if ( tx_mii_reset == 1'b1 ) begin
    tx_mii_d <= { 16 { 8'h07 }} ;
    tx_mii_c <= { 16 { 1'b1 }} ;

    state <= S0;
    q_en <= 0;
    rand1 <= init_crc;
    counter <= 0;
    d_buff <= 128'd0 ;
    d_sel <= 0;
    z_pkt <= 0;
    op_timer <= 30'd390625000 ;
    en_residue <= 0;
    packet_counter <= 0;
    set_eop <= 0;
    bsy_cntr <= 0;
    send_continuous_pkts_sync_d <= 0;
  end
  else begin
    tx_mii_d <= { 16 { 8'h07 }} ;                // default to idle
    tx_mii_c <= { 16 { 1'b1 }} ;
    set_eop <= 0;

    if (send_continuous_pkts_sync)
      send_continuous_pkts_sync_d <= 1'b1;
    else if ( state == S7 )
      send_continuous_pkts_sync_d <= 1'b0;

    q_en <= {q_en, enable};

    header_bit_count <= 0;
    case(state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: state <= S2;
      S2: begin
            packet_counter <= packet_count;
            rand1 <= init_crc;
            d_sel <= data_select;
            counter <= xfer_cnt;
            state <= S3;
          end
      S3: begin
            d_buff <= swapn(nxt_d);
            rand1 <= nxt_rand1;
            counter <= |counter ? counter - 1 : 0;
            z_pkt <= ~|counter;
            en_residue <= 0;
            state <= |packet_count ? S4 : S7;
            packet_counter <= &packet_counter ?  packet_counter : packet_counter-1;
            header_bit_count <= 9'd175 ;
          end
      S4,S5: begin  :zulu
            reg [127:0] tx_datain;
            d_buff <= swapn(nxt_d);
            rand1 <= nxt_rand1;
            counter <= |counter ? counter - 1 : 0;
            z_pkt <= 0;
            header_bit_count <= header_bit_count[8] ? header_bit_count : header_bit_count - 128 ;
            if(~|counter && (xfer_rmdr==0) || z_pkt) end_packet;
            else begin
              tx_datain = op_data;
              if(!header_bit_count[8]) begin            // if there is some header left to send, then send it
                if(header_bit_count<127) tx_datain[127-:48] = eth_header[0+:48] ;
                else tx_datain = eth_header[header_bit_count-:128] ;
              end
              tx_mii_c <= { 16 { 1'b0 }} ;
              tx_mii_d <= swapn(tx_datain);
              if(state==S4) tx_mii_c[0] <= 1'b1;
              state <= |counter ? S5 : S6;
            end
            en_residue <= insert_crc && (counter==1) && (xfer_cnt != crc_cnt) && (crc_bits!= 0) ;
            if( en_residue ) begin
              tx_datain[0+:crc_residue_bits] = op_crc[crc_residue_start+:crc_residue_bits];
              tx_mii_d <= swapn(tx_datain);
            end
          end
      S6: end_packet;
      S7: state <= |q_en ? S7 : S0;

    endcase

    case(state)
      S0,S7:    op_timer <= 30'd390625000 ;
      S4,S5,S6: op_timer <= 30'd390625000 ;
      default:  op_timer <= |op_timer ? op_timer - 1 : op_timer ;
    endcase

    if(set_eop) begin tx_mii_d[0+:8] <= 8'hFD ; tx_mii_c[0] <= 1'b1; end

    if ( state <= S0 ) begin
      bsy_cntr <= |bsy_cntr ? bsy_cntr - 1 : bsy_cntr ;             // Hold the busy signal for 8 additional cycles.
      busy <= |bsy_cntr;
    end
    else begin
      busy <= 1'b1;
      bsy_cntr <= {3{1'b1}};
    end

  end
end

task end_packet;
reg [127:0]  tmp_dat;
begin
  tmp_dat = op_data & op_mask | ~op_mask & { 16 { 8'h07 }} ;
  if(insert_crc) tmp_dat[crc_insrt+:nz_bits] = op_crc[0+:nz_bits];

  tx_mii_d <= swapn ( tmp_dat ) ;
  tx_mii_c <= xfer_ctl ;

  rand1 <= init_crc;
  counter <= xfer_cnt;
  //state <= (|packet_counter && |q_en) ? S3 : S7;
  if(send_continuous_pkts_sync_d)
    state <= (send_continuous_pkts_sync) ? S3 : S7;
  else
  state <= (|packet_counter && |q_en) ? S3 : S7;
  set_eop <= (full_bits==0) ;
  if(full_bits != 0 ) tx_mii_d[full_bits+:8] <= 8'hFD ;
end
endtask

function [31:0] gen_CRC_const ( input integer n, input const_data );
integer i,j;
reg [31:0] loc_poly;
begin
  loc_poly = {32{1'b1}};           // synthesis loop_limit 100000
  for(i=0; i<(n*8); i=i+1) begin
    if(i <= 111 ) loc_poly = ({33{(loc_poly[31] ^ eth_header[ crc_jiggle( 111 - i ) ])}} & CRC_POLYNOMIAL) ^ {loc_poly,1'b0};
    else                          loc_poly = ({33{(loc_poly[31] ^ const_data)}} & CRC_POLYNOMIAL) ^ {loc_poly,1'b0};
  end
  for(i=0;i<=31;i=i+1) gen_CRC_const[i] = ~loc_poly[{i[3+:2],~i[0+:3]}];
end
endfunction

function [31:0] gen_CRC3 ( input integer n );
integer i;
reg [31:0] dat_gen;
reg [31:0] loc_poly;
begin
  loc_poly = {32{1'b1}};
  dat_gen = init_crc;           // synthesis loop_limit 100000

  for(i=0; i<(n*8); i=i+1) begin
    dat_gen = {dat_gen,^(DATA_POLYNOMIAL & {dat_gen,1'b0})};
    if(i <= 111 ) loc_poly = ({33{(loc_poly[31] ^ eth_header[ crc_jiggle( 111 - i ) ])}} & CRC_POLYNOMIAL) ^ {loc_poly,1'b0};
    else                          loc_poly = ({33{(loc_poly[31] ^ dat_gen[0])}} & CRC_POLYNOMIAL) ^ {loc_poly,1'b0};
  end

  for(i=0;i<=31;i=i+1) gen_CRC3[i] = ~loc_poly[{i[3+:2],~i[0+:3]}];
end
endfunction

function integer  crc_jiggle ( input integer d );
crc_jiggle = { d[31:3], ~d[2:0] } ;
endfunction

function [127:0]  swapn (input [127:0]  d);
integer i;
for (i=0; i<=(127); i=i+8) swapn[i+:8] = d[(127-i)-:8];
endfunction

endmodule

module pcs_40g_def_pcs_baser_support_traf_chk1 (

  input wire mii_clk,
  input wire mii_reset,
  input wire enable,
  input wire clear_count,

  input wire [127:0] mii_d,
  input wire [15:0]  mii_c,


  output reg protocol_error,
  output wire [47:0] packet_count,
  output wire [63:0] total_bytes,
  output wire [31:0] prot_err_count,
  output wire [31:0] error_count,
  output wire packet_count_overflow,
  output wire prot_err_overflow,
  output wire error_overflow,
  output wire total_bytes_overflow
);

/* Parameter definitions of STATE variables for 1 bit state machine */
localparam [1:0]  S0 = 2'b00,
                  S1 = 2'b01,
                  S2 = 2'b11,
                  S3 = 2'b10;
reg [48:0] pct_cntr;
reg [32:0] perr_cntr, err_cntr;

reg [1:0] state ;
reg [1:0] q_en;
reg [4:0] delta_bytes;
reg [4:0] ss_bytes;
reg [64:0] byte_cntr;
reg inc_pct_cntr;
reg inc_err_cntr;

assign packet_count           = pct_cntr[48] ? {48{1'b1}} : pct_cntr[47:0],
       packet_count_overflow  = pct_cntr[48],
       prot_err_count         = perr_cntr[32] ? {32{1'b1}} : perr_cntr[31:0],
       prot_err_overflow      = perr_cntr[32],
       error_count            = err_cntr[32] ? {32{1'b1}} : err_cntr[31:0],
       error_overflow         = err_cntr[32],
       total_bytes            = byte_cntr[64] ? {64{1'b1}} : byte_cntr[63:0],
       total_bytes_overflow   = byte_cntr[64];

integer i;
always @( posedge mii_clk )
    begin
      if ( mii_reset == 1'b1 ) begin
    q_en <= 0;
    state <= S0;
    protocol_error <= 0;
    pct_cntr <= 49'h0;
    err_cntr <= 33'h0;
    perr_cntr <= 33'h0;
    byte_cntr <= 65'h0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    delta_bytes <= 0;
    ss_bytes <= 0;
  end
  else begin
    delta_bytes <= 0;
    ss_bytes <= 0;
    inc_pct_cntr <= 0;
    inc_err_cntr <= 0;
    protocol_error <= 0;
    q_en <= {q_en, enable};

    case (state)
      S0: if (q_en == 2'b01) state <= S1;
      S1: begin :start_check
            integer i;
            reg [4:0] byte_count;
            reg start_flag;
            start_flag = 0;
            byte_count = 5'd0;
            for(i=0; i<15;i=i+4) if( (mii_d[i*8+:8] == 8'hFB) && mii_c[i] ) begin start_flag = 1; byte_count = 16-i; end
            if( start_flag ) state <= S2;
            delta_bytes <= byte_count;
          end
      S2: begin :end_check
            integer i,j;
            reg [4:0] byte_count1,byte_count2;
            reg start_flag,end_flag;
            start_flag = 0;
            end_flag = 0;
            byte_count1 = 5'd16;
            byte_count2 = 5'd0;
            for(i=15;i>=0;i=i-1) if( (mii_d[i*8+:8] == 8'hFD) && mii_c[i] ) begin end_flag = 1; byte_count1 = i; end
            for(j=0; j<15;j=j+4) if( (mii_d[j*8+:8] == 8'hFB) && mii_c[j] ) begin start_flag = 1; byte_count2 = 16-j; end
            if( end_flag ) begin
              state <= S1;
              inc_pct_cntr <= 1'b1;
            end
            if( start_flag ) state <= S2;
            delta_bytes <= byte_count1;
            ss_bytes    <= byte_count2;
          end

      default: state <= S0;
    endcase

    if ( &q_en )  begin :error_check
      integer i;
      for(i=0; i<15;i=i+1) if( (mii_d[i*8+:8] == 8'hFE) && mii_c[i] ) inc_err_cntr <= 1;
    end


    if(~|q_en) state <= S0;
    if(!byte_cntr[64]) byte_cntr <= byte_cntr + {1'b0,delta_bytes} + {1'b0,ss_bytes};
    if(protocol_error && !perr_cntr[32]) perr_cntr <= perr_cntr + 1;
    if(inc_pct_cntr && !pct_cntr[48])  pct_cntr <= pct_cntr + 1;
    if(inc_err_cntr && !err_cntr[32]) err_cntr <= err_cntr + 1;
    if(clear_count)begin
      byte_cntr <= 65'h0;
      pct_cntr <= 49'h0;
      err_cntr <= 33'h0;
      perr_cntr <= 33'h0;
    end
  end
end

`ifdef SARANCE_RTL_DEBUG
// synthesis translate_off
  reg [8*12-1:0] state_text;                    // Enumerated type conversion to text
  always @(state) case (state)
    S0: state_text = "S0" ;
    S1: state_text = "S1" ;
    S2: state_text = "S2" ;
    S3: state_text = "S3" ;
  endcase
`endif

endmodule

module pcs_40g_def_pcs_baser_support_pktprbs_gen
 #(
  parameter BIT_COUNT = 64
) (
  input   wire [31:0] ip,
  output  wire [31:0] op,
  output  wire [(BIT_COUNT-1):0] datout
);

//     G(x) = x32 + x27 + x21 + x19 + x10 + x7 + 1
localparam [32:0] CRC_POLYNOMIAL = 33'b100001000001010000000010010000001;

localparam REMAINDER_SIZE = 32;

generate

case (BIT_COUNT)

  1280: begin :gen_1280_loop
          assign op[0] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31],
                 op[1] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[29],
                 op[2] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30],
                 op[3] = ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 op[4] = ip[0]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 op[5] = ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 op[6] = ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 op[7] = ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 op[8] = ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 op[9] = ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 op[10] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 op[11] = ip[0]^ip[1]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 op[12] = ip[0]^ip[1]^ip[2]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[30],
                 op[13] = ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[31],
                 op[14] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[28],
                 op[15] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[29],
                 op[16] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[30],
                 op[17] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 op[18] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[26],
                 op[19] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[27],
                 op[20] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[28],
                 op[21] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[29],
                 op[22] = ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[30],
                 op[23] = ip[5]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[31],
                 op[24] = ip[0]^ip[6]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28],
                 op[25] = ip[1]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 op[26] = ip[2]^ip[8]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 op[27] = ip[3]^ip[9]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 op[28] = ip[0]^ip[4]^ip[7]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 op[29] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[25]^ip[28]^ip[29],
                 op[30] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[18]^ip[21]^ip[26]^ip[29]^ip[30],
                 op[31] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[22]^ip[27]^ip[30]^ip[31];

          assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                 datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                 datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                 datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                 datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                 datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                 datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                 datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                 datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                 datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                 datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                 datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                 datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                 datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                 datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                 datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                 datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                 datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                 datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                 datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                 datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                 datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                 datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                 datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                 datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                 datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                 datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                 datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                 datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                 datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                 datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                 datout[128] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[129] = ip[3]^ip[4]^ip[5]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[130] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[131] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[132] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[133] = ip[0]^ip[1]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[134] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[135] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[136] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[137] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[138] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[139] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[140] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[24]^ip[30]^ip[31],
                 datout[141] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[19]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[142] = ip[1]^ip[5]^ip[8]^ip[10]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[143] = ip[0]^ip[4]^ip[7]^ip[9]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[144] = ip[3]^ip[8]^ip[9]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[145] = ip[2]^ip[7]^ip[8]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[146] = ip[1]^ip[6]^ip[7]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[147] = ip[0]^ip[5]^ip[6]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[148] = ip[4]^ip[5]^ip[6]^ip[9]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[149] = ip[3]^ip[4]^ip[5]^ip[8]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[150] = ip[2]^ip[3]^ip[4]^ip[7]^ip[16]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[151] = ip[1]^ip[2]^ip[3]^ip[6]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[152] = ip[0]^ip[1]^ip[2]^ip[5]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[153] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[154] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[155] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[18]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[156] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[17]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[157] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[158] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[15]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[159] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[13]^ip[16]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[161] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[162] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[163] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[164] = ip[3]^ip[4]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[165] = ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[166] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[167] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[168] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[169] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[170] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[171] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[172] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[173] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[174] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[175] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[176] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[177] = ip[0]^ip[3]^ip[4]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[178] = ip[2]^ip[3]^ip[6]^ip[9]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[179] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[180] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[181] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[182] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[183] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[184] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[22]^ip[25]^ip[28]^ip[29],
                 datout[185] = ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[186] = ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[187] = ip[1]^ip[2]^ip[3]^ip[6]^ip[10]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[188] = ip[0]^ip[1]^ip[2]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[189] = ip[0]^ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[190] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[191] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[192] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[193] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[194] = ip[1]^ip[2]^ip[4]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[195] = ip[0]^ip[1]^ip[3]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[196] = ip[0]^ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[197] = ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[198] = ip[0]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[199] = ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[200] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[201] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[202] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[203] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[204] = ip[1]^ip[3]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[205] = ip[0]^ip[2]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[206] = ip[1]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[207] = ip[0]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[208] = ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[19]^ip[21]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[209] = ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[18]^ip[20]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[210] = ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[17]^ip[19]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[211] = ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[16]^ip[18]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[212] = ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[15]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27],
                 datout[213] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[14]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26],
                 datout[214] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[13]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25],
                 datout[215] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[216] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[217] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[218] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[219] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[220] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[221] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[222] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[223] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[24]^ip[28]^ip[30],
                 datout[224] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[225] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[226] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[227] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[228] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[229] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[230] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[231] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[232] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[233] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[234] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[235] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[236] = ip[0]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[237] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[238] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[239] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[240] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[241] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[242] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[243] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[244] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[245] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[246] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[247] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[248] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[249] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[250] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[251] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[252] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[253] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[254] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[255] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[18]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[256] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[257] = ip[0]^ip[5]^ip[7]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[258] = ip[4]^ip[10]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[259] = ip[3]^ip[9]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[260] = ip[2]^ip[8]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[261] = ip[1]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[262] = ip[0]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[263] = ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[264] = ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[265] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[266] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[19]^ip[21]^ip[22]^ip[28],
                 datout[267] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[18]^ip[20]^ip[21]^ip[27],
                 datout[268] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[17]^ip[19]^ip[20]^ip[26],
                 datout[269] = ip[0]^ip[3]^ip[4]^ip[5]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[31],
                 datout[270] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[15]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[271] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[14]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[272] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[273] = ip[0]^ip[1]^ip[3]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[274] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[275] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[276] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[277] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[278] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[279] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[280] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[281] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[282] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[283] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[284] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[285] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[286] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[287] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[288] = ip[0]^ip[3]^ip[4]^ip[5]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[289] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[290] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[291] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[292] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[293] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[294] = ip[1]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[295] = ip[0]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[296] = ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[297] = ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[298] = ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[299] = ip[0]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[300] = ip[1]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[301] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[302] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[303] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[304] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[305] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29],
                 datout[306] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28],
                 datout[307] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27],
                 datout[308] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[25]^ip[31],
                 datout[309] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[24]^ip[30],
                 datout[310] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29],
                 datout[311] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[312] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[313] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[314] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[315] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[316] = ip[1]^ip[3]^ip[5]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[317] = ip[0]^ip[2]^ip[4]^ip[6]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[318] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[319] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[320] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[321] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[322] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[323] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[324] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[325] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[326] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[327] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[328] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[329] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[330] = ip[1]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[28]^ip[30]^ip[31],
                 datout[331] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[27]^ip[29]^ip[30],
                 datout[332] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[333] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[334] = ip[0]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[27]^ip[29]^ip[31],
                 datout[335] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[30]^ip[31],
                 datout[336] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[27]^ip[29]^ip[30],
                 datout[337] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[29],
                 datout[338] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[339] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[340] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[341] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[342] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[343] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[344] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[345] = ip[1]^ip[4]^ip[10]^ip[11]^ip[12]^ip[14]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[346] = ip[0]^ip[3]^ip[9]^ip[10]^ip[11]^ip[13]^ip[19]^ip[22]^ip[23]^ip[27]^ip[29]^ip[30],
                 datout[347] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[31],
                 datout[348] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[19]^ip[20]^ip[21]^ip[27]^ip[28]^ip[30],
                 datout[349] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[18]^ip[19]^ip[20]^ip[26]^ip[27]^ip[29],
                 datout[350] = ip[3]^ip[5]^ip[6]^ip[7]^ip[17]^ip[19]^ip[20]^ip[25]^ip[28]^ip[31],
                 datout[351] = ip[2]^ip[4]^ip[5]^ip[6]^ip[16]^ip[18]^ip[19]^ip[24]^ip[27]^ip[30],
                 datout[352] = ip[1]^ip[3]^ip[4]^ip[5]^ip[15]^ip[17]^ip[18]^ip[23]^ip[26]^ip[29],
                 datout[353] = ip[0]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[22]^ip[25]^ip[28],
                 datout[354] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[355] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[356] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[357] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[358] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[359] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[360] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[361] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[362] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[363] = ip[1]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[29]^ip[31],
                 datout[364] = ip[0]^ip[1]^ip[2]^ip[3]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30],
                 datout[365] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[366] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[367] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[368] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[369] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[370] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[371] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[372] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[373] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[374] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[375] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[376] = ip[0]^ip[2]^ip[6]^ip[11]^ip[14]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[377] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[18]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[378] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[379] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[380] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[381] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[382] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[383] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[384] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[385] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[386] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[387] = ip[0]^ip[1]^ip[2]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[388] = ip[0]^ip[1]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[389] = ip[0]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[390] = ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[391] = ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[392] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[393] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[394] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[395] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[396] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[397] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[398] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[399] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[400] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[401] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[402] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[403] = ip[0]^ip[2]^ip[6]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[404] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[405] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[406] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[407] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[408] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[409] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[25]^ip[26]^ip[28],
                 datout[410] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[411] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[412] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[413] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[414] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[415] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[416] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[417] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^
                         ip[28]^ip[29]^ip[31],
                 datout[418] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[419] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[420] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[15]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[421] = ip[0]^ip[1]^ip[2]^ip[8]^ip[11]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[422] = ip[0]^ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[423] = ip[0]^ip[5]^ip[8]^ip[12]^ip[16]^ip[17]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[424] = ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[425] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[426] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[427] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[428] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[429] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[430] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30],
                 datout[431] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[432] = ip[1]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[18]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[433] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[434] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[435] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[436] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[437] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[438] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[439] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[440] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[441] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^
                         ip[30]^ip[31],
                 datout[442] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[443] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[444] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[445] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[446] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[447] = ip[1]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[448] = ip[0]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[449] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[31],
                 datout[450] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30],
                 datout[451] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[452] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[453] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[454] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[455] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[17]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[456] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[457] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[458] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[25]^ip[27]^ip[29],
                 datout[459] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[28]^ip[31],
                 datout[460] = ip[1]^ip[3]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[461] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[462] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[463] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[464] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[465] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[466] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[467] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[468] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[19]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[469] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[20]^ip[22]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[470] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[471] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[472] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[473] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[474] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[475] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[476] = ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[477] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[11]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[478] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[479] = ip[0]^ip[2]^ip[5]^ip[12]^ip[15]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[480] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[481] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[482] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[483] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[484] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[485] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[486] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 datout[487] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 datout[488] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 datout[489] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[490] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[491] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[492] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[493] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[494] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[495] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[496] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[497] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[498] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[499] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[500] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 datout[501] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 datout[502] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 datout[503] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 datout[504] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 datout[505] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[506] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[507] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[508] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[509] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[510] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[511] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[512] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[513] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[514] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[515] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[516] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[517] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[25]^ip[27]^ip[29]^
                         ip[31],
                 datout[518] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[519] = ip[0]^ip[1]^ip[3]^ip[4]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[520] = ip[0]^ip[2]^ip[3]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[521] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[522] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[523] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[524] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[525] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[526] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[527] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[528] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[529] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[530] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[531] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[532] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[533] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[534] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[31],
                 datout[535] = ip[0]^ip[1]^ip[3]^ip[5]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[536] = ip[0]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[537] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[15]^ip[18]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[538] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[17]^ip[21]^ip[22]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[539] = ip[1]^ip[3]^ip[4]^ip[10]^ip[13]^ip[16]^ip[18]^ip[21]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[540] = ip[0]^ip[2]^ip[3]^ip[9]^ip[12]^ip[15]^ip[17]^ip[20]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[541] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[542] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[543] = ip[0]^ip[4]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[544] = ip[3]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[545] = ip[2]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[546] = ip[1]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[547] = ip[0]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[548] = ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[21]^ip[24]^ip[27]^ip[31],
                 datout[549] = ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[26]^ip[30],
                 datout[550] = ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[22]^ip[25]^ip[29],
                 datout[551] = ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[21]^ip[24]^ip[28],
                 datout[552] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[20]^ip[23]^ip[27],
                 datout[553] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[16]^ip[19]^ip[22]^ip[26],
                 datout[554] = ip[0]^ip[1]^ip[5]^ip[8]^ip[10]^ip[15]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 datout[555] = ip[0]^ip[4]^ip[6]^ip[7]^ip[14]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[556] = ip[3]^ip[5]^ip[9]^ip[13]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[557] = ip[2]^ip[4]^ip[8]^ip[12]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[558] = ip[1]^ip[3]^ip[7]^ip[11]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[559] = ip[0]^ip[2]^ip[6]^ip[10]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[560] = ip[1]^ip[5]^ip[6]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[561] = ip[0]^ip[4]^ip[5]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[30],
                 datout[562] = ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[563] = ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[564] = ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[565] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[566] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[567] = ip[1]^ip[4]^ip[5]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[568] = ip[0]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[569] = ip[2]^ip[3]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[570] = ip[1]^ip[2]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[571] = ip[0]^ip[1]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[572] = ip[0]^ip[6]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[573] = ip[5]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[574] = ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[575] = ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[576] = ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[28],
                 datout[577] = ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27],
                 datout[578] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26],
                 datout[579] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[21]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[580] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30],
                 datout[581] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[31],
                 datout[582] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30],
                 datout[583] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[584] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[585] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[586] = ip[0]^ip[5]^ip[7]^ip[8]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[587] = ip[4]^ip[7]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[588] = ip[3]^ip[6]^ip[8]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[589] = ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[590] = ip[1]^ip[4]^ip[6]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[591] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[592] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[593] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[594] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[595] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[596] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[27]^ip[30],
                 datout[597] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[29]^ip[31],
                 datout[598] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[28]^ip[30],
                 datout[599] = ip[0]^ip[1]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[600] = ip[0]^ip[4]^ip[6]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[601] = ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[602] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[603] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[604] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[605] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[22]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[606] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[21]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[607] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[608] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[12]^ip[15]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[609] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[610] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[611] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[31],
                 datout[612] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[30],
                 datout[613] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[614] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[615] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[616] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[617] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[618] = ip[1]^ip[2]^ip[3]^ip[8]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[619] = ip[0]^ip[1]^ip[2]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[620] = ip[0]^ip[1]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[621] = ip[0]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[622] = ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[623] = ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[624] = ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[625] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[626] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[627] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 datout[628] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[629] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[630] = ip[1]^ip[3]^ip[5]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[631] = ip[0]^ip[2]^ip[4]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[632] = ip[1]^ip[3]^ip[6]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[633] = ip[0]^ip[2]^ip[5]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[634] = ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[635] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[636] = ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[637] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[638] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[639] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[640] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[30],
                 datout[641] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[29]^ip[31],
                 datout[642] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[643] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[644] = ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[645] = ip[0]^ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[646] = ip[0]^ip[2]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[27]^ip[29]^ip[31],
                 datout[647] = ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[28]^ip[30]^ip[31],
                 datout[648] = ip[0]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[27]^ip[29]^ip[30],
                 datout[649] = ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[650] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[651] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[26]^ip[27]^ip[29],
                 datout[652] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[25]^ip[26]^ip[28],
                 datout[653] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[24]^ip[25]^ip[27],
                 datout[654] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[31],
                 datout[655] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[656] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[657] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[658] = ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[659] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[660] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[661] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[662] = ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[663] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[664] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[665] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[666] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[667] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[668] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[669] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[670] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[671] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[19]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[672] = ip[0]^ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[22]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[673] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[674] = ip[0]^ip[2]^ip[5]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[675] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[16]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[676] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[15]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[677] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[14]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[678] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[13]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[679] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[12]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[680] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[681] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[30],
                 datout[682] = ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[29]^ip[31],
                 datout[683] = ip[0]^ip[1]^ip[3]^ip[6]^ip[12]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[28]^ip[30],
                 datout[684] = ip[0]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[685] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[686] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[687] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[688] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[689] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[690] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[25]^ip[28]^ip[31],
                 datout[691] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[692] = ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[693] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[694] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[695] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[31],
                 datout[696] = ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[30]^ip[31],
                 datout[697] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[26]^ip[29]^ip[30],
                 datout[698] = ip[1]^ip[3]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[699] = ip[0]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[700] = ip[1]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[701] = ip[0]^ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[702] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[703] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[704] = ip[2]^ip[8]^ip[10]^ip[13]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[705] = ip[1]^ip[7]^ip[9]^ip[12]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[706] = ip[0]^ip[6]^ip[8]^ip[11]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[707] = ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[31],
                 datout[708] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[30],
                 datout[709] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[29],
                 datout[710] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[28],
                 datout[711] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[27],
                 datout[712] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26],
                 datout[713] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[714] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[715] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[716] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[717] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^
                         ip[27]^ip[28]^ip[29]^ip[31],
                 datout[718] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^
                         ip[28]^ip[30]^ip[31],
                 datout[719] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^
                         ip[27]^ip[29]^ip[30],
                 datout[720] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[721] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[722] = ip[0]^ip[1]^ip[3]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[723] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[724] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[725] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[726] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[727] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[728] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[729] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[730] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[731] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[732] = ip[0]^ip[1]^ip[2]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[733] = ip[0]^ip[1]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[734] = ip[0]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[735] = ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[736] = ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[737] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[29],
                 datout[738] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^
                         ip[28],
                 datout[739] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^
                         ip[27],
                 datout[740] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^
                         ip[26],
                 datout[741] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[742] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[743] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[744] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[14]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[745] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[746] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[747] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[748] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[749] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[750] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[751] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[752] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[753] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[754] = ip[0]^ip[1]^ip[3]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[755] = ip[0]^ip[2]^ip[7]^ip[10]^ip[13]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[756] = ip[1]^ip[12]^ip[17]^ip[18]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[757] = ip[0]^ip[11]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[758] = ip[6]^ip[9]^ip[10]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[759] = ip[5]^ip[8]^ip[9]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[760] = ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[761] = ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[762] = ip[2]^ip[5]^ip[6]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27],
                 datout[763] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26],
                 datout[764] = ip[0]^ip[3]^ip[4]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25],
                 datout[765] = ip[2]^ip[3]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[766] = ip[1]^ip[2]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[30],
                 datout[767] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[29],
                 datout[768] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[769] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[770] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[14]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[771] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29],
                 datout[772] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[12]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[773] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[774] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[775] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[13]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[776] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[777] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[778] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^
                         ip[29]^ip[30]^ip[31],
                 datout[779] = ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[780] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[781] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[782] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[783] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[784] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[785] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[786] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[787] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[17]^ip[19]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[788] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[16]^ip[20]^ip[22]^ip[23]^ip[28]^ip[30]^ip[31],
                 datout[789] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[790] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[17]^ip[19]^ip[21]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[791] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[792] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[18]^ip[20]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[793] = ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[794] = ip[0]^ip[2]^ip[7]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[795] = ip[1]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[796] = ip[0]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[797] = ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[798] = ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[799] = ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29],
                 datout[800] = ip[2]^ip[3]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[15]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28],
                 datout[801] = ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[21]^ip[23]^ip[25]^ip[27],
                 datout[802] = ip[0]^ip[1]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[18]^ip[20]^ip[22]^ip[24]^ip[26],
                 datout[803] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[31],
                 datout[804] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[805] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[806] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[14]^ip[15]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[807] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[808] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[809] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[810] = ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[811] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[812] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[813] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[814] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[815] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[21]^ip[24]^ip[28]^ip[31],
                 datout[816] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[817] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[818] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[819] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[820] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[821] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[822] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[823] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[824] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[18]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[825] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[826] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[31],
                 datout[827] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[828] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[14]^ip[16]^ip[19]^ip[23]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[829] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[15]^ip[20]^ip[22]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[830] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[831] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[19]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[832] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[20]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[833] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[834] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[835] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[836] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[837] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[838] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[839] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[840] = ip[0]^ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[841] = ip[0]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[842] = ip[1]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[843] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[844] = ip[5]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[845] = ip[4]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[846] = ip[3]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[847] = ip[2]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[848] = ip[1]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27],
                 datout[849] = ip[0]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26],
                 datout[850] = ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[31],
                 datout[851] = ip[1]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[30],
                 datout[852] = ip[0]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[29],
                 datout[853] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[854] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[855] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[856] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[23]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[857] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[858] = ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[859] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[860] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[861] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[862] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[863] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[864] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[865] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[866] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[867] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[868] = ip[0]^ip[1]^ip[4]^ip[7]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[869] = ip[0]^ip[3]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[870] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[871] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[872] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[873] = ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[874] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[875] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29],
                 datout[876] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28],
                 datout[877] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[878] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[879] = ip[1]^ip[2]^ip[3]^ip[4]^ip[10]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[880] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[881] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[882] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[883] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[884] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[885] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[886] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[887] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[888] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[889] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[890] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[891] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[14]^ip[15]^ip[17]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[892] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[893] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[894] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[895] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[896] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[30],
                 datout[897] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[898] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[899] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[900] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[901] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[902] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[903] = ip[1]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[904] = ip[0]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[905] = ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[906] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[907] = ip[0]^ip[1]^ip[4]^ip[9]^ip[14]^ip[15]^ip[17]^ip[22]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[908] = ip[0]^ip[3]^ip[6]^ip[8]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[909] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[910] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[911] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[912] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[913] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[914] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29],
                 datout[915] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[916] = ip[0]^ip[1]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[917] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[918] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[919] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[920] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[921] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[922] = ip[1]^ip[2]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[923] = ip[0]^ip[1]^ip[2]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[924] = ip[0]^ip[1]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[925] = ip[0]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[926] = ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[927] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[928] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[929] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[930] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[931] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[932] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[933] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[934] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30],
                 datout[935] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29],
                 datout[936] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[26]^ip[28],
                 datout[937] = ip[1]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[938] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[939] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[940] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[941] = ip[0]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[942] = ip[2]^ip[4]^ip[10]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[943] = ip[1]^ip[3]^ip[9]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[944] = ip[0]^ip[2]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[945] = ip[1]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[946] = ip[0]^ip[5]^ip[6]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[947] = ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[948] = ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[949] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[27]^ip[29],
                 datout[950] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28],
                 datout[951] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[19]^ip[20]^ip[21]^ip[25]^ip[27],
                 datout[952] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[19]^ip[24]^ip[31],
                 datout[953] = ip[0]^ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[20]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[954] = ip[0]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[955] = ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[956] = ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[957] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[958] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[959] = ip[2]^ip[3]^ip[4]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[960] = ip[1]^ip[2]^ip[3]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[961] = ip[0]^ip[1]^ip[2]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[29],
                 datout[962] = ip[0]^ip[1]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[963] = ip[0]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[964] = ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[22]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[965] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[21]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[966] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[967] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28],
                 datout[968] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27],
                 datout[969] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26],
                 datout[970] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[971] = ip[0]^ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[972] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[14]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[973] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[974] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[975] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[976] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[977] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[978] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[979] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[980] = ip[2]^ip[3]^ip[4]^ip[8]^ip[9]^ip[11]^ip[14]^ip[19]^ip[23]^ip[27]^ip[30]^ip[31],
                 datout[981] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[10]^ip[13]^ip[18]^ip[22]^ip[26]^ip[29]^ip[30],
                 datout[982] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[12]^ip[17]^ip[21]^ip[25]^ip[28]^ip[29],
                 datout[983] = ip[0]^ip[1]^ip[5]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[984] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[985] = ip[3]^ip[5]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[986] = ip[2]^ip[4]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[987] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[28]^ip[29],
                 datout[988] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28],
                 datout[989] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[25]^ip[27]^ip[31],
                 datout[990] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30],
                 datout[991] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[992] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[993] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[994] = ip[1]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[995] = ip[0]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[996] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[997] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[998] = ip[0]^ip[3]^ip[4]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[999] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[28]^ip[30]^ip[31],
                 datout[1000] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[27]^ip[29]^ip[30],
                 datout[1001] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[26]^ip[28]^ip[29],
                 datout[1002] = ip[0]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1003] = ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1004] = ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[1005] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[1006] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^
                         ip[31],
                 datout[1007] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[1008] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[1009] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[1010] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[23]^ip[27]^ip[29],
                 datout[1011] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[22]^ip[26]^ip[28],
                 datout[1012] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[21]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1013] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[14]^ip[18]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[1014] = ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[13]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1015] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[1016] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1017] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1018] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[13]^ip[14]^ip[17]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1019] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[16]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1020] = ip[2]^ip[3]^ip[5]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1021] = ip[1]^ip[2]^ip[4]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1022] = ip[0]^ip[1]^ip[3]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1023] = ip[0]^ip[2]^ip[8]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[1024] = ip[1]^ip[6]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[1025] = ip[0]^ip[5]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[1026] = ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1027] = ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[14]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[1028] = ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[13]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[1029] = ip[1]^ip[2]^ip[3]^ip[4]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[1030] = ip[0]^ip[1]^ip[2]^ip[3]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27],
                 datout[1031] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[31],
                 datout[1032] = ip[0]^ip[1]^ip[5]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[30]^ip[31],
                 datout[1033] = ip[0]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1034] = ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1035] = ip[2]^ip[4]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1036] = ip[1]^ip[3]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1037] = ip[0]^ip[2]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[1038] = ip[1]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[1039] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[30],
                 datout[1040] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1041] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[1042] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[1043] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[31],
                 datout[1044] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[21]^ip[22]^ip[27]^ip[30],
                 datout[1045] = ip[0]^ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[29]^ip[31],
                 datout[1046] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1047] = ip[1]^ip[2]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1048] = ip[0]^ip[1]^ip[4]^ip[6]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1049] = ip[0]^ip[3]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1050] = ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1051] = ip[1]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1052] = ip[0]^ip[2]^ip[3]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[1053] = ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[31],
                 datout[1054] = ip[0]^ip[1]^ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^
                         ip[30],
                 datout[1055] = ip[0]^ip[1]^ip[4]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[1056] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1057] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1058] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1059] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1060] = ip[2]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[1061] = ip[1]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[1062] = ip[0]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[29],
                 datout[1063] = ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[1064] = ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[1065] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[1066] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[1067] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[1068] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[1069] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[1070] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[1071] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1072] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1073] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1074] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1075] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1076] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1077] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[1078] = ip[4]^ip[5]^ip[9]^ip[11]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1079] = ip[3]^ip[4]^ip[8]^ip[10]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1080] = ip[2]^ip[3]^ip[7]^ip[9]^ip[15]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[1081] = ip[1]^ip[2]^ip[6]^ip[8]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[1082] = ip[0]^ip[1]^ip[5]^ip[7]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[1083] = ip[0]^ip[4]^ip[9]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[1084] = ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[1085] = ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[1086] = ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[1087] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[1088] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[1089] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[1090] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[1091] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[1092] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[27]^ip[30],
                 datout[1093] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[29]^ip[31],
                 datout[1094] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1095] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1096] = ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[20]^ip[21]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1097] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1098] = ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1099] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1100] = ip[1]^ip[3]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[1101] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[11]^ip[16]^ip[20]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[1102] = ip[1]^ip[5]^ip[8]^ip[9]^ip[10]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1103] = ip[0]^ip[4]^ip[7]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[1104] = ip[3]^ip[7]^ip[8]^ip[9]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1105] = ip[2]^ip[6]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[1106] = ip[1]^ip[5]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[1107] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[1108] = ip[3]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1109] = ip[2]^ip[3]^ip[4]^ip[5]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1110] = ip[1]^ip[2]^ip[3]^ip[4]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[1111] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[1112] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1113] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[21]^ip[22]^ip[25]^ip[30]^ip[31],
                 datout[1114] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[21]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1115] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[18]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1116] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[17]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1117] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1118] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[1119] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[1120] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[13]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[1121] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[12]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[1122] = ip[0]^ip[1]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1123] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1124] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1125] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[15]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1126] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[14]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1127] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[10]^ip[12]^ip[13]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1128] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[1129] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[11]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[1130] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[10]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1131] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[15]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1132] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[14]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1133] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[13]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1134] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[12]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1135] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1136] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1137] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[1138] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[1139] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1140] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1141] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1142] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[1143] = ip[0]^ip[2]^ip[3]^ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[1144] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[1145] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[1146] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[1147] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[1148] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1149] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1150] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[17]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1151] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[1152] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[7]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[27]^ip[30]^ip[31],
                 datout[1153] = ip[0]^ip[1]^ip[3]^ip[4]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[29]^ip[30]^ip[31],
                 datout[1154] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1155] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[1156] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[1157] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[31],
                 datout[1158] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[1159] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^
                         ip[29]^ip[30],
                 datout[1160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[26]^
                         ip[28]^ip[29],
                 datout[1161] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[26]^
                         ip[27]^ip[28]^ip[31],
                 datout[1162] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1163] = ip[0]^ip[3]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[1164] = ip[2]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^
                         ip[30]^ip[31],
                 datout[1165] = ip[1]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^
                         ip[29]^ip[30],
                 datout[1166] = ip[0]^ip[1]^ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^
                         ip[28]^ip[29],
                 datout[1167] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[1168] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[1169] = ip[1]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[1170] = ip[0]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[1171] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1172] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[1173] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[1174] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[1175] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30],
                 datout[1176] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29],
                 datout[1177] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28],
                 datout[1178] = ip[1]^ip[3]^ip[4]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[1179] = ip[0]^ip[2]^ip[3]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[1180] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1181] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[1182] = ip[0]^ip[4]^ip[7]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[1183] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[1184] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[1185] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[1186] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[1187] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[31],
                 datout[1188] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[30],
                 datout[1189] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[29],
                 datout[1190] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[21]^ip[24]^ip[28],
                 datout[1191] = ip[1]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1192] = ip[0]^ip[1]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[1193] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1194] = ip[0]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1195] = ip[3]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1196] = ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1197] = ip[1]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1198] = ip[0]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1199] = ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[31],
                 datout[1200] = ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[30],
                 datout[1201] = ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[29],
                 datout[1202] = ip[0]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[28],
                 datout[1203] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[1204] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[1205] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[29],
                 datout[1206] = ip[0]^ip[1]^ip[5]^ip[6]^ip[12]^ip[14]^ip[16]^ip[17]^ip[23]^ip[24]^ip[26]^ip[28]^ip[31],
                 datout[1207] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[1208] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[29]^ip[30]^
                         ip[31],
                 datout[1209] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30],
                 datout[1210] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29],
                 datout[1211] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28],
                 datout[1212] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[25]^ip[27]^ip[31],
                 datout[1213] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[24]^ip[30]^ip[31],
                 datout[1214] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1215] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[1216] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^
                         ip[30],
                 datout[1217] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[1218] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1219] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1220] = ip[3]^ip[5]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[1221] = ip[2]^ip[4]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[20]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[1222] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[1223] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[18]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[1224] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[1225] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[1226] = ip[0]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1227] = ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1228] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[1229] = ip[1]^ip[2]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[1230] = ip[0]^ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[1231] = ip[0]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[27]^ip[29]^ip[31],
                 datout[1232] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[16]^ip[17]^ip[21]^ip[28]^ip[30]^ip[31],
                 datout[1233] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[15]^ip[16]^ip[20]^ip[27]^ip[29]^ip[30],
                 datout[1234] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[1235] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[1236] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[1237] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29],
                 datout[1238] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1239] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[1240] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[1241] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[1242] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[1243] = ip[0]^ip[3]^ip[4]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[1244] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[1245] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[1246] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[1247] = ip[0]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[1248] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[1249] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[18]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[1250] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[17]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[1251] = ip[0]^ip[4]^ip[7]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[1252] = ip[3]^ip[9]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[1253] = ip[2]^ip[8]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[1254] = ip[1]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[1255] = ip[0]^ip[6]^ip[7]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28],
                 datout[1256] = ip[5]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[31],
                 datout[1257] = ip[4]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[30],
                 datout[1258] = ip[3]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[29],
                 datout[1259] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[28],
                 datout[1260] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[27],
                 datout[1261] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[26],
                 datout[1262] = ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[31],
                 datout[1263] = ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[24]^ip[25]^ip[30],
                 datout[1264] = ip[1]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[29],
                 datout[1265] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[28],
                 datout[1266] = ip[1]^ip[2]^ip[3]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[31],
                 datout[1267] = ip[0]^ip[1]^ip[2]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[30],
                 datout[1268] = ip[0]^ip[1]^ip[8]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[1269] = ip[0]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[1270] = ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[1271] = ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[1272] = ip[3]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[1273] = ip[2]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[1274] = ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[1275] = ip[0]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26],
                 datout[1276] = ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[1277] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30],
                 datout[1278] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[29],
                 datout[1279] = ip[1]^ip[4]^ip[5]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[31];
        end // gen_1280_loop

  512: begin :gen_512_loop

          assign op[0] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31],
                 op[1] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 op[2] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 op[3] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 op[4] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 op[5] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 op[6] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 op[7] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 op[8] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 op[9] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 op[10] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 op[11] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 op[12] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 op[13] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 op[14] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 op[15] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[16] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 op[17] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 op[18] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 op[19] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 op[20] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 op[21] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 op[22] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 op[23] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 op[24] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 op[25] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 op[26] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 op[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 op[28] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 op[29] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 op[30] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 op[31] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31];

          assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                 datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                 datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                 datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                 datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                 datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                 datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                 datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                 datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                 datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                 datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                 datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                 datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                 datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                 datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                 datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                 datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                 datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                 datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                 datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                 datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                 datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                 datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                 datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                 datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                 datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                 datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                 datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                 datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                 datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                 datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                 datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                 datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                 datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                 datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                 datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                 datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                 datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                 datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                 datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                 datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                 datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                 datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                 datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                 datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                 datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                 datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                 datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                 datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                 datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                 datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                 datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                 datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                 datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                 datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                 datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                 datout[128] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[129] = ip[3]^ip[4]^ip[5]^ip[9]^ip[13]^ip[15]^ip[16]^ip[17]^ip[20]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[130] = ip[2]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[131] = ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[18]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[132] = ip[0]^ip[1]^ip[2]^ip[6]^ip[10]^ip[12]^ip[13]^ip[14]^ip[17]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[133] = ip[0]^ip[1]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[134] = ip[0]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[135] = ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[136] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[137] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[15]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[138] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[28],
                 datout[139] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[31],
                 datout[140] = ip[0]^ip[1]^ip[3]^ip[8]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[24]^ip[30]^ip[31],
                 datout[141] = ip[0]^ip[2]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[19]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[142] = ip[1]^ip[5]^ip[8]^ip[10]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[143] = ip[0]^ip[4]^ip[7]^ip[9]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[144] = ip[3]^ip[8]^ip[9]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[145] = ip[2]^ip[7]^ip[8]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[146] = ip[1]^ip[6]^ip[7]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[147] = ip[0]^ip[5]^ip[6]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[148] = ip[4]^ip[5]^ip[6]^ip[9]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[149] = ip[3]^ip[4]^ip[5]^ip[8]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[150] = ip[2]^ip[3]^ip[4]^ip[7]^ip[16]^ip[17]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29],
                 datout[151] = ip[1]^ip[2]^ip[3]^ip[6]^ip[15]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28],
                 datout[152] = ip[0]^ip[1]^ip[2]^ip[5]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27],
                 datout[153] = ip[0]^ip[1]^ip[4]^ip[6]^ip[9]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[31],
                 datout[154] = ip[0]^ip[3]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[21]^ip[26]^ip[30]^ip[31],
                 datout[155] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[18]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[156] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[17]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[157] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[16]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[158] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[15]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[159] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[160] = ip[0]^ip[1]^ip[2]^ip[3]^ip[9]^ip[13]^ip[16]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[161] = ip[0]^ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[162] = ip[0]^ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[163] = ip[0]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[164] = ip[3]^ip[4]^ip[7]^ip[8]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[165] = ip[2]^ip[3]^ip[6]^ip[7]^ip[11]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[166] = ip[1]^ip[2]^ip[5]^ip[6]^ip[10]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[167] = ip[0]^ip[1]^ip[4]^ip[5]^ip[9]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[168] = ip[0]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[169] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[170] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30],
                 datout[171] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29],
                 datout[172] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[173] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[174] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[175] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[176] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[177] = ip[0]^ip[3]^ip[4]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[178] = ip[2]^ip[3]^ip[6]^ip[9]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[179] = ip[1]^ip[2]^ip[5]^ip[8]^ip[10]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[180] = ip[0]^ip[1]^ip[4]^ip[7]^ip[9]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[181] = ip[0]^ip[3]^ip[8]^ip[9]^ip[12]^ip[13]^ip[16]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[182] = ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[15]^ip[17]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[183] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[23]^ip[26]^ip[29]^ip[30],
                 datout[184] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[22]^ip[25]^ip[28]^ip[29],
                 datout[185] = ip[3]^ip[4]^ip[5]^ip[8]^ip[12]^ip[14]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[186] = ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[187] = ip[1]^ip[2]^ip[3]^ip[6]^ip[10]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29],
                 datout[188] = ip[0]^ip[1]^ip[2]^ip[5]^ip[9]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28],
                 datout[189] = ip[0]^ip[1]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[190] = ip[0]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[30]^ip[31],
                 datout[191] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[192] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[193] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[194] = ip[1]^ip[2]^ip[4]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[195] = ip[0]^ip[1]^ip[3]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[196] = ip[0]^ip[2]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[197] = ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[198] = ip[0]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[18]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[199] = ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[200] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[201] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[202] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[203] = ip[0]^ip[2]^ip[4]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[204] = ip[1]^ip[3]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[205] = ip[0]^ip[2]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[206] = ip[1]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[207] = ip[0]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[208] = ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[19]^ip[21]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[209] = ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[18]^ip[20]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[210] = ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[17]^ip[19]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[211] = ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[16]^ip[18]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[212] = ip[2]^ip[3]^ip[4]^ip[7]^ip[10]^ip[15]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27],
                 datout[213] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[14]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26],
                 datout[214] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[13]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25],
                 datout[215] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[31],
                 datout[216] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[217] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[218] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[219] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[220] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[221] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[30],
                 datout[222] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[25]^ip[29]^ip[31],
                 datout[223] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[24]^ip[28]^ip[30],
                 datout[224] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[225] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[226] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[227] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[228] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[229] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[230] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[231] = ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[232] = ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[233] = ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[234] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[235] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[236] = ip[0]^ip[3]^ip[4]^ip[8]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[237] = ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[238] = ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[239] = ip[0]^ip[1]^ip[4]^ip[5]^ip[7]^ip[9]^ip[11]^ip[12]^ip[13]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                 datout[240] = ip[0]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                 datout[241] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[27]^ip[30]^ip[31],
                 datout[242] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[26]^ip[29]^ip[30],
                 datout[243] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[14]^ip[15]^ip[20]^ip[25]^ip[28]^ip[29],
                 datout[244] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[245] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[246] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[16]^ip[18]^ip[19]^ip[22]^ip[24]^ip[26]^ip[29]^ip[30],
                 datout[247] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29],
                 datout[248] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[10]^ip[14]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[249] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[250] = ip[0]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[251] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[252] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[253] = ip[0]^ip[2]^ip[3]^ip[4]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[254] = ip[1]^ip[2]^ip[3]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[19]^ip[23]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[255] = ip[0]^ip[1]^ip[2]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[18]^ip[22]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[256] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[257] = ip[0]^ip[5]^ip[7]^ip[10]^ip[11]^ip[16]^ip[17]^ip[18]^ip[19]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[258] = ip[4]^ip[10]^ip[15]^ip[16]^ip[17]^ip[20]^ip[23]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[259] = ip[3]^ip[9]^ip[14]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[260] = ip[2]^ip[8]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[261] = ip[1]^ip[7]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28],
                 datout[262] = ip[0]^ip[6]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27],
                 datout[263] = ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[22]^ip[24]^ip[25]^ip[31],
                 datout[264] = ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[21]^ip[23]^ip[24]^ip[30],
                 datout[265] = ip[3]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[20]^ip[22]^ip[23]^ip[29],
                 datout[266] = ip[2]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[19]^ip[21]^ip[22]^ip[28],
                 datout[267] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[11]^ip[18]^ip[20]^ip[21]^ip[27],
                 datout[268] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[17]^ip[19]^ip[20]^ip[26],
                 datout[269] = ip[0]^ip[3]^ip[4]^ip[5]^ip[16]^ip[19]^ip[20]^ip[25]^ip[26]^ip[31],
                 datout[270] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[15]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                 datout[271] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[14]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                 datout[272] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[13]^ip[17]^ip[18]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                 datout[273] = ip[0]^ip[1]^ip[3]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[274] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[275] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[276] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[277] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[278] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[279] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[280] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[281] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[282] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[283] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[284] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[285] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[286] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[16]^ip[17]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[287] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[15]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[288] = ip[0]^ip[3]^ip[4]^ip[5]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[289] = ip[2]^ip[3]^ip[4]^ip[6]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[290] = ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[291] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[292] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[293] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[30]^ip[31],
                 datout[294] = ip[1]^ip[5]^ip[7]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[29]^ip[30]^ip[31],
                 datout[295] = ip[0]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[30],
                 datout[296] = ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[21]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[297] = ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[298] = ip[1]^ip[3]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[299] = ip[0]^ip[2]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[14]^ip[16]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28],
                 datout[300] = ip[1]^ip[2]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[301] = ip[0]^ip[1]^ip[6]^ip[7]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[302] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[303] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[304] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[305] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29],
                 datout[306] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28],
                 datout[307] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27],
                 datout[308] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[25]^ip[31],
                 datout[309] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[24]^ip[30],
                 datout[310] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29],
                 datout[311] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[22]^ip[26]^ip[28]^ip[31],
                 datout[312] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[313] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[17]^ip[18]^ip[19]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[314] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[17]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[315] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^
                         ip[31],
                 datout[316] = ip[1]^ip[3]^ip[5]^ip[7]^ip[11]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[317] = ip[0]^ip[2]^ip[4]^ip[6]^ip[10]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[318] = ip[1]^ip[3]^ip[5]^ip[6]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[319] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[320] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[321] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[26]^ip[28]^ip[30],
                 datout[322] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[323] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[324] = ip[0]^ip[2]^ip[4]^ip[5]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[325] = ip[1]^ip[3]^ip[4]^ip[6]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[326] = ip[0]^ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[327] = ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[328] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[329] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[330] = ip[1]^ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[17]^ip[28]^ip[30]^ip[31],
                 datout[331] = ip[0]^ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[27]^ip[29]^ip[30],
                 datout[332] = ip[1]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[18]^ip[20]^ip[28]^ip[29]^ip[31],
                 datout[333] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[17]^ip[19]^ip[27]^ip[28]^ip[30],
                 datout[334] = ip[0]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[16]^ip[20]^ip[27]^ip[29]^ip[31],
                 datout[335] = ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[12]^ip[15]^ip[18]^ip[19]^ip[20]^ip[28]^ip[30]^ip[31],
                 datout[336] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[11]^ip[14]^ip[17]^ip[18]^ip[19]^ip[27]^ip[29]^ip[30],
                 datout[337] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[16]^ip[17]^ip[18]^ip[26]^ip[28]^ip[29],
                 datout[338] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[25]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[339] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[27]^ip[30]^ip[31],
                 datout[340] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[29]^ip[30]^ip[31],
                 datout[341] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30],
                 datout[342] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[343] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[344] = ip[0]^ip[2]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[19]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                 datout[345] = ip[1]^ip[4]^ip[10]^ip[11]^ip[12]^ip[14]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30]^ip[31],
                 datout[346] = ip[0]^ip[3]^ip[9]^ip[10]^ip[11]^ip[13]^ip[19]^ip[22]^ip[23]^ip[27]^ip[29]^ip[30],
                 datout[347] = ip[2]^ip[6]^ip[8]^ip[10]^ip[12]^ip[20]^ip[21]^ip[22]^ip[28]^ip[29]^ip[31],
                 datout[348] = ip[1]^ip[5]^ip[7]^ip[9]^ip[11]^ip[19]^ip[20]^ip[21]^ip[27]^ip[28]^ip[30],
                 datout[349] = ip[0]^ip[4]^ip[6]^ip[8]^ip[10]^ip[18]^ip[19]^ip[20]^ip[26]^ip[27]^ip[29],
                 datout[350] = ip[3]^ip[5]^ip[6]^ip[7]^ip[17]^ip[19]^ip[20]^ip[25]^ip[28]^ip[31],
                 datout[351] = ip[2]^ip[4]^ip[5]^ip[6]^ip[16]^ip[18]^ip[19]^ip[24]^ip[27]^ip[30],
                 datout[352] = ip[1]^ip[3]^ip[4]^ip[5]^ip[15]^ip[17]^ip[18]^ip[23]^ip[26]^ip[29],
                 datout[353] = ip[0]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[22]^ip[25]^ip[28],
                 datout[354] = ip[1]^ip[2]^ip[3]^ip[6]^ip[9]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[31],
                 datout[355] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[30],
                 datout[356] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[357] = ip[0]^ip[3]^ip[5]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[358] = ip[2]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[14]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[359] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[10]^ip[11]^ip[13]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[360] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29],
                 datout[361] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[31],
                 datout[362] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[30],
                 datout[363] = ip[1]^ip[2]^ip[3]^ip[4]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[29]^ip[31],
                 datout[364] = ip[0]^ip[1]^ip[2]^ip[3]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[24]^ip[28]^ip[30],
                 datout[365] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[366] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[367] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[368] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[19]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[369] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[370] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[371] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[372] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[31],
                 datout[373] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[23]^ip[24]^ip[30]^ip[31],
                 datout[374] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[16]^ip[20]^ip[22]^ip[23]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[375] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[15]^ip[19]^ip[21]^ip[22]^ip[25]^ip[28]^ip[29]^ip[30],
                 datout[376] = ip[0]^ip[2]^ip[6]^ip[11]^ip[14]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[377] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[13]^ip[18]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[378] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[12]^ip[17]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                 datout[379] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[16]^ip[18]^ip[20]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                 datout[380] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[15]^ip[17]^ip[19]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                 datout[381] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                 datout[382] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                 datout[383] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[384] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[385] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[10]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[386] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[387] = ip[0]^ip[1]^ip[2]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[388] = ip[0]^ip[1]^ip[6]^ip[8]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[389] = ip[0]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[18]^ip[23]^ip[24]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[390] = ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[391] = ip[3]^ip[4]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[392] = ip[2]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[393] = ip[1]^ip[2]^ip[5]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[394] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[395] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[396] = ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[30]^ip[31],
                 datout[397] = ip[1]^ip[3]^ip[5]^ip[6]^ip[10]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[30],
                 datout[398] = ip[0]^ip[2]^ip[4]^ip[5]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[29],
                 datout[399] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[28]^ip[31],
                 datout[400] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[12]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[27]^ip[30],
                 datout[401] = ip[1]^ip[2]^ip[4]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[29]^ip[31],
                 datout[402] = ip[0]^ip[1]^ip[3]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[28]^ip[30],
                 datout[403] = ip[0]^ip[2]^ip[6]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[404] = ip[1]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[405] = ip[0]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[406] = ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[12]^ip[13]^ip[14]^ip[17]^ip[19]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[407] = ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[11]^ip[12]^ip[13]^ip[16]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[408] = ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[17]^ip[21]^ip[26]^ip[27]^ip[29],
                 datout[409] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[16]^ip[20]^ip[25]^ip[26]^ip[28],
                 datout[410] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[411] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[7]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[412] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[11]^ip[13]^ip[16]^ip[18]^ip[19]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                 datout[413] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[10]^ip[12]^ip[15]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[414] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[11]^ip[14]^ip[16]^ip[18]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30]^ip[31],
                 datout[415] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[15]^ip[17]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[416] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[14]^ip[16]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30],
                 datout[417] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^
                         ip[28]^ip[29]^ip[31],
                 datout[418] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[27]^ip[28]^
                         ip[30]^ip[31],
                 datout[419] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[8]^ip[11]^ip[13]^ip[16]^ip[19]^ip[21]^ip[23]^ip[24]^ip[27]^ip[29]^ip[30]^ip[31],
                 datout[420] = ip[0]^ip[1]^ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[15]^ip[22]^ip[23]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[421] = ip[0]^ip[1]^ip[2]^ip[8]^ip[11]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[422] = ip[0]^ip[1]^ip[6]^ip[7]^ip[9]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[423] = ip[0]^ip[5]^ip[8]^ip[12]^ip[16]^ip[17]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[424] = ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[23]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[425] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[17]^ip[19]^ip[22]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[426] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[13]^ip[14]^ip[16]^ip[18]^ip[21]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[427] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[12]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28],
                 datout[428] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[11]^ip[12]^ip[14]^ip[16]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27],
                 datout[429] = ip[1]^ip[2]^ip[4]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[31],
                 datout[430] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[30],
                 datout[431] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[11]^ip[13]^ip[21]^ip[22]^ip[23]^ip[26]^ip[29]^ip[31],
                 datout[432] = ip[1]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[18]^ip[21]^ip[22]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                 datout[433] = ip[0]^ip[4]^ip[6]^ip[8]^ip[9]^ip[11]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                 datout[434] = ip[3]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[16]^ip[18]^ip[19]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                 datout[435] = ip[2]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[15]^ip[17]^ip[18]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                 datout[436] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[14]^ip[16]^ip[17]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                 datout[437] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[25]^ip[26]^ip[28],
                 datout[438] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[12]^ip[14]^ip[15]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[439] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                 datout[440] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                 datout[441] = ip[0]^ip[1]^ip[2]^ip[5]^ip[8]^ip[11]^ip[12]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^
                         ip[30]^ip[31],
                 datout[442] = ip[0]^ip[1]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[29]^
                         ip[30]^ip[31],
                 datout[443] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[14]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[444] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[445] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[12]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[446] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[11]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[447] = ip[1]^ip[3]^ip[4]^ip[6]^ip[10]^ip[11]^ip[12]^ip[15]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[448] = ip[0]^ip[2]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[14]^ip[18]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30],
                 datout[449] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[29]^ip[31],
                 datout[450] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[9]^ip[12]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[28]^ip[30],
                 datout[451] = ip[0]^ip[2]^ip[4]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[452] = ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[16]^ip[22]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[453] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[13]^ip[14]^ip[15]^ip[21]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[454] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[18]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[455] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[17]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[456] = ip[2]^ip[3]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[457] = ip[1]^ip[2]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[17]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[458] = ip[0]^ip[1]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[25]^ip[27]^ip[29],
                 datout[459] = ip[0]^ip[2]^ip[4]^ip[7]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[24]^ip[28]^ip[31],
                 datout[460] = ip[1]^ip[3]^ip[7]^ip[9]^ip[12]^ip[14]^ip[16]^ip[18]^ip[19]^ip[20]^ip[23]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[461] = ip[0]^ip[2]^ip[6]^ip[8]^ip[11]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[462] = ip[1]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[16]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[463] = ip[0]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[11]^ip[13]^ip[15]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[464] = ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29]^ip[31],
                 datout[465] = ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28]^ip[30],
                 datout[466] = ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[25]^ip[27]^ip[29],
                 datout[467] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[24]^ip[26]^ip[28],
                 datout[468] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[19]^ip[23]^ip[25]^ip[26]^ip[27]^ip[31],
                 datout[469] = ip[0]^ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[14]^ip[15]^ip[20]^ip[22]^ip[24]^ip[25]^ip[30]^ip[31],
                 datout[470] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[13]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                 datout[471] = ip[0]^ip[1]^ip[2]^ip[4]^ip[9]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[472] = ip[0]^ip[1]^ip[3]^ip[6]^ip[8]^ip[9]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[473] = ip[0]^ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[474] = ip[1]^ip[4]^ip[5]^ip[7]^ip[8]^ip[10]^ip[14]^ip[17]^ip[22]^ip[23]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[475] = ip[0]^ip[3]^ip[4]^ip[6]^ip[7]^ip[9]^ip[13]^ip[16]^ip[21]^ip[22]^ip[23]^ip[26]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[476] = ip[2]^ip[3]^ip[5]^ip[8]^ip[9]^ip[12]^ip[15]^ip[18]^ip[21]^ip[22]^ip[25]^ip[27]^ip[28]^ip[29]^ip[31],
                 datout[477] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[11]^ip[14]^ip[17]^ip[20]^ip[21]^ip[24]^ip[26]^ip[27]^ip[28]^ip[30],
                 datout[478] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[10]^ip[13]^ip[16]^ip[19]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29],
                 datout[479] = ip[0]^ip[2]^ip[5]^ip[12]^ip[15]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[28]^ip[31],
                 datout[480] = ip[1]^ip[4]^ip[6]^ip[9]^ip[11]^ip[14]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[481] = ip[0]^ip[3]^ip[5]^ip[8]^ip[10]^ip[13]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30],
                 datout[482] = ip[2]^ip[4]^ip[6]^ip[7]^ip[12]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[31],
                 datout[483] = ip[1]^ip[3]^ip[5]^ip[6]^ip[11]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[27]^ip[28]^ip[30],
                 datout[484] = ip[0]^ip[2]^ip[4]^ip[5]^ip[10]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29],
                 datout[485] = ip[1]^ip[3]^ip[4]^ip[6]^ip[14]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[31],
                 datout[486] = ip[0]^ip[2]^ip[3]^ip[5]^ip[13]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[30],
                 datout[487] = ip[1]^ip[2]^ip[4]^ip[6]^ip[9]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[21]^ip[23]^ip[29]^ip[31],
                 datout[488] = ip[0]^ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[22]^ip[28]^ip[30],
                 datout[489] = ip[0]^ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[490] = ip[1]^ip[3]^ip[5]^ip[8]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[25]^ip[28]^ip[30]^ip[31],
                 datout[491] = ip[0]^ip[2]^ip[4]^ip[7]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[24]^ip[27]^ip[29]^ip[30],
                 datout[492] = ip[1]^ip[3]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[28]^ip[29]^ip[31],
                 datout[493] = ip[0]^ip[2]^ip[9]^ip[11]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[22]^ip[27]^ip[28]^ip[30],
                 datout[494] = ip[1]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[15]^ip[16]^ip[20]^ip[21]^ip[27]^ip[29]^ip[31],
                 datout[495] = ip[0]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[19]^ip[20]^ip[26]^ip[28]^ip[30],
                 datout[496] = ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[19]^ip[20]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                 datout[497] = ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[18]^ip[19]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30],
                 datout[498] = ip[2]^ip[5]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[17]^ip[18]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29],
                 datout[499] = ip[1]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[16]^ip[17]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28],
                 datout[500] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[15]^ip[16]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27],
                 datout[501] = ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[14]^ip[15]^ip[18]^ip[21]^ip[22]^ip[24]^ip[31],
                 datout[502] = ip[1]^ip[2]^ip[3]^ip[4]^ip[7]^ip[13]^ip[14]^ip[17]^ip[20]^ip[21]^ip[23]^ip[30],
                 datout[503] = ip[0]^ip[1]^ip[2]^ip[3]^ip[6]^ip[12]^ip[13]^ip[16]^ip[19]^ip[20]^ip[22]^ip[29],
                 datout[504] = ip[0]^ip[1]^ip[2]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[15]^ip[19]^ip[20]^ip[21]^ip[26]^ip[28]^ip[31],
                 datout[505] = ip[0]^ip[1]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[19]^ip[25]^ip[26]^ip[27]^ip[30]^ip[31],
                 datout[506] = ip[0]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[13]^ip[20]^ip[24]^ip[25]^ip[29]^ip[30]^ip[31],
                 datout[507] = ip[2]^ip[3]^ip[4]^ip[5]^ip[7]^ip[12]^ip[18]^ip[19]^ip[20]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[30]^ip[31],
                 datout[508] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[11]^ip[17]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[29]^ip[30],
                 datout[509] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[10]^ip[16]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29],
                 datout[510] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[15]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[27]^ip[28]^ip[31],
                 datout[511] = ip[0]^ip[1]^ip[3]^ip[5]^ip[6]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[27]^ip[30]^ip[31];


       end // gen_512_loop

  128: begin :gen_128_loop

         assign op[0] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31],
                op[1] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                op[2] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                op[3] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                op[4] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                op[5] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                op[6] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                op[7] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                op[8] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                op[9] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                op[10] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                op[11] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                op[12] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                op[13] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                op[14] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                op[15] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                op[16] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                op[17] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                op[18] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                op[19] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                op[20] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                op[21] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                op[22] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                op[23] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                op[24] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                op[25] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                op[26] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                op[27] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                op[28] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                op[29] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                op[30] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                op[31] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31];

         assign datout[0] = ip[6]^ip[9]^ip[18]^ip[20]^ip[26]^ip[31],
                datout[1] = ip[5]^ip[8]^ip[17]^ip[19]^ip[25]^ip[30],
                datout[2] = ip[4]^ip[7]^ip[16]^ip[18]^ip[24]^ip[29],
                datout[3] = ip[3]^ip[6]^ip[15]^ip[17]^ip[23]^ip[28],
                datout[4] = ip[2]^ip[5]^ip[14]^ip[16]^ip[22]^ip[27],
                datout[5] = ip[1]^ip[4]^ip[13]^ip[15]^ip[21]^ip[26],
                datout[6] = ip[0]^ip[3]^ip[12]^ip[14]^ip[20]^ip[25],
                datout[7] = ip[2]^ip[6]^ip[9]^ip[11]^ip[13]^ip[18]^ip[19]^ip[20]^ip[24]^ip[26]^ip[31],
                datout[8] = ip[1]^ip[5]^ip[8]^ip[10]^ip[12]^ip[17]^ip[18]^ip[19]^ip[23]^ip[25]^ip[30],
                datout[9] = ip[0]^ip[4]^ip[7]^ip[9]^ip[11]^ip[16]^ip[17]^ip[18]^ip[22]^ip[24]^ip[29],
                datout[10] = ip[3]^ip[8]^ip[9]^ip[10]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[31],
                datout[11] = ip[2]^ip[7]^ip[8]^ip[9]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[30],
                datout[12] = ip[1]^ip[6]^ip[7]^ip[8]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[29],
                datout[13] = ip[0]^ip[5]^ip[6]^ip[7]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[28],
                datout[14] = ip[4]^ip[5]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[26]^ip[27]^ip[31],
                datout[15] = ip[3]^ip[4]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[25]^ip[26]^ip[30],
                datout[16] = ip[2]^ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[24]^ip[25]^ip[29],
                datout[17] = ip[1]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[21]^ip[23]^ip[24]^ip[28],
                datout[18] = ip[0]^ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[20]^ip[22]^ip[23]^ip[27],
                datout[19] = ip[0]^ip[4]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[31],
                datout[20] = ip[3]^ip[7]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30]^ip[31],
                datout[21] = ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29]^ip[30],
                datout[22] = ip[1]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28]^ip[29],
                datout[23] = ip[0]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[16]^ip[18]^ip[23]^ip[27]^ip[28],
                datout[24] = ip[3]^ip[5]^ip[7]^ip[8]^ip[10]^ip[12]^ip[13]^ip[15]^ip[17]^ip[18]^ip[20]^ip[22]^ip[27]^ip[31],
                datout[25] = ip[2]^ip[4]^ip[6]^ip[7]^ip[9]^ip[11]^ip[12]^ip[14]^ip[16]^ip[17]^ip[19]^ip[21]^ip[26]^ip[30],
                datout[26] = ip[1]^ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[13]^ip[15]^ip[16]^ip[18]^ip[20]^ip[25]^ip[29],
                datout[27] = ip[0]^ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[12]^ip[14]^ip[15]^ip[17]^ip[19]^ip[24]^ip[28],
                datout[28] = ip[1]^ip[3]^ip[4]^ip[8]^ip[11]^ip[13]^ip[14]^ip[16]^ip[20]^ip[23]^ip[26]^ip[27]^ip[31],
                datout[29] = ip[0]^ip[2]^ip[3]^ip[7]^ip[10]^ip[12]^ip[13]^ip[15]^ip[19]^ip[22]^ip[25]^ip[26]^ip[30],
                datout[30] = ip[1]^ip[2]^ip[11]^ip[12]^ip[14]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[31] = ip[0]^ip[1]^ip[10]^ip[11]^ip[13]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                datout[32] = ip[0]^ip[6]^ip[10]^ip[12]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[31],
                datout[33] = ip[5]^ip[6]^ip[11]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[30]^ip[31],
                datout[34] = ip[4]^ip[5]^ip[10]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[29]^ip[30],
                datout[35] = ip[3]^ip[4]^ip[9]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[23]^ip[26]^ip[28]^ip[29],
                datout[36] = ip[2]^ip[3]^ip[8]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[25]^ip[27]^ip[28],
                datout[37] = ip[1]^ip[2]^ip[7]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[21]^ip[24]^ip[26]^ip[27],
                datout[38] = ip[0]^ip[1]^ip[6]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26],
                datout[39] = ip[0]^ip[5]^ip[6]^ip[9]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[22]^ip[24]^ip[25]^ip[26]^ip[31],
                datout[40] = ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                datout[41] = ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                datout[42] = ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29],
                datout[43] = ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28],
                datout[44] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27],
                datout[45] = ip[0]^ip[1]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[25]^ip[31],
                datout[46] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[24]^ip[26]^ip[30]^ip[31],
                datout[47] = ip[1]^ip[2]^ip[4]^ip[10]^ip[12]^ip[13]^ip[14]^ip[18]^ip[20]^ip[23]^ip[25]^ip[26]^ip[29]^ip[30]^ip[31],
                datout[48] = ip[0]^ip[1]^ip[3]^ip[9]^ip[11]^ip[12]^ip[13]^ip[17]^ip[19]^ip[22]^ip[24]^ip[25]^ip[28]^ip[29]^ip[30],
                datout[49] = ip[0]^ip[2]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[16]^ip[20]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[50] = ip[1]^ip[5]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[15]^ip[18]^ip[19]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30]^ip[31],
                datout[51] = ip[0]^ip[4]^ip[5]^ip[6]^ip[7]^ip[9]^ip[10]^ip[14]^ip[17]^ip[18]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30],
                datout[52] = ip[3]^ip[4]^ip[5]^ip[8]^ip[13]^ip[16]^ip[17]^ip[18]^ip[21]^ip[23]^ip[25]^ip[28]^ip[29]^ip[31],
                datout[53] = ip[2]^ip[3]^ip[4]^ip[7]^ip[12]^ip[15]^ip[16]^ip[17]^ip[20]^ip[22]^ip[24]^ip[27]^ip[28]^ip[30],
                datout[54] = ip[1]^ip[2]^ip[3]^ip[6]^ip[11]^ip[14]^ip[15]^ip[16]^ip[19]^ip[21]^ip[23]^ip[26]^ip[27]^ip[29],
                datout[55] = ip[0]^ip[1]^ip[2]^ip[5]^ip[10]^ip[13]^ip[14]^ip[15]^ip[18]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28],
                datout[56] = ip[0]^ip[1]^ip[4]^ip[6]^ip[12]^ip[13]^ip[14]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[57] = ip[0]^ip[3]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[16]^ip[17]^ip[19]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                datout[58] = ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[9]^ip[10]^ip[11]^ip[12]^ip[15]^ip[16]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[29]^ip[30]^ip[31],
                datout[59] = ip[1]^ip[3]^ip[4]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[11]^ip[14]^ip[15]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30],
                datout[60] = ip[0]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29],
                datout[61] = ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[17]^ip[18]^ip[19]^ip[21]^ip[23]^ip[27]^ip[28]^ip[31],
                datout[62] = ip[0]^ip[1]^ip[2]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[16]^ip[17]^ip[18]^ip[20]^ip[22]^ip[26]^ip[27]^ip[30],
                datout[63] = ip[0]^ip[1]^ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[25]^ip[29]^ip[31],
                datout[64] = ip[0]^ip[2]^ip[4]^ip[6]^ip[8]^ip[10]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[24]^ip[26]^ip[28]^ip[30]^ip[31],
                datout[65] = ip[1]^ip[3]^ip[5]^ip[6]^ip[7]^ip[13]^ip[14]^ip[15]^ip[16]^ip[20]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[66] = ip[0]^ip[2]^ip[4]^ip[5]^ip[6]^ip[12]^ip[13]^ip[14]^ip[15]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[28]^ip[29]^ip[30],
                datout[67] = ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[68] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[28]^ip[30],
                datout[69] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[7]^ip[10]^ip[11]^ip[12]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[31],
                datout[70] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[6]^ip[9]^ip[10]^ip[11]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[30],
                datout[71] = ip[0]^ip[1]^ip[2]^ip[4]^ip[5]^ip[6]^ip[8]^ip[10]^ip[17]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[26]^ip[27]^ip[29]^ip[31],
                datout[72] = ip[0]^ip[1]^ip[3]^ip[4]^ip[5]^ip[6]^ip[7]^ip[16]^ip[21]^ip[22]^ip[24]^ip[25]^ip[28]^ip[30]^ip[31],
                datout[73] = ip[0]^ip[2]^ip[3]^ip[4]^ip[5]^ip[9]^ip[15]^ip[18]^ip[21]^ip[23]^ip[24]^ip[26]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[74] = ip[1]^ip[2]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[14]^ip[17]^ip[18]^ip[22]^ip[23]^ip[25]^ip[28]^ip[29]^ip[30]^ip[31],
                datout[75] = ip[0]^ip[1]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[13]^ip[16]^ip[17]^ip[21]^ip[22]^ip[24]^ip[27]^ip[28]^ip[29]^ip[30],
                datout[76] = ip[0]^ip[1]^ip[2]^ip[4]^ip[7]^ip[9]^ip[12]^ip[15]^ip[16]^ip[18]^ip[21]^ip[23]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[77] = ip[0]^ip[1]^ip[3]^ip[8]^ip[9]^ip[11]^ip[14]^ip[15]^ip[17]^ip[18]^ip[22]^ip[27]^ip[28]^ip[30]^ip[31],
                datout[78] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[9]^ip[10]^ip[13]^ip[14]^ip[16]^ip[17]^ip[18]^ip[20]^ip[21]^ip[27]^ip[29]^ip[30]^ip[31],
                datout[79] = ip[1]^ip[5]^ip[7]^ip[8]^ip[12]^ip[13]^ip[15]^ip[16]^ip[17]^ip[18]^ip[19]^ip[28]^ip[29]^ip[30]^ip[31],
                datout[80] = ip[0]^ip[4]^ip[6]^ip[7]^ip[11]^ip[12]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[27]^ip[28]^ip[29]^ip[30],
                datout[81] = ip[3]^ip[5]^ip[9]^ip[10]^ip[11]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[18]^ip[20]^ip[27]^ip[28]^ip[29]^ip[31],
                datout[82] = ip[2]^ip[4]^ip[8]^ip[9]^ip[10]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[17]^ip[19]^ip[26]^ip[27]^ip[28]^ip[30],
                datout[83] = ip[1]^ip[3]^ip[7]^ip[8]^ip[9]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[16]^ip[18]^ip[25]^ip[26]^ip[27]^ip[29],
                datout[84] = ip[0]^ip[2]^ip[6]^ip[7]^ip[8]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[15]^ip[17]^ip[24]^ip[25]^ip[26]^ip[28],
                datout[85] = ip[1]^ip[5]^ip[7]^ip[10]^ip[11]^ip[12]^ip[13]^ip[14]^ip[16]^ip[18]^ip[20]^ip[23]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[86] = ip[0]^ip[4]^ip[6]^ip[9]^ip[10]^ip[11]^ip[12]^ip[13]^ip[15]^ip[17]^ip[19]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[30],
                datout[87] = ip[3]^ip[5]^ip[6]^ip[8]^ip[10]^ip[11]^ip[12]^ip[14]^ip[16]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[88] = ip[2]^ip[4]^ip[5]^ip[7]^ip[9]^ip[10]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[28]^ip[30],
                datout[89] = ip[1]^ip[3]^ip[4]^ip[6]^ip[8]^ip[9]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[24]^ip[27]^ip[29],
                datout[90] = ip[0]^ip[2]^ip[3]^ip[5]^ip[7]^ip[8]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[19]^ip[20]^ip[21]^ip[22]^ip[23]^ip[26]^ip[28],
                datout[91] = ip[1]^ip[2]^ip[4]^ip[7]^ip[8]^ip[9]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[21]^ip[22]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[92] = ip[0]^ip[1]^ip[3]^ip[6]^ip[7]^ip[8]^ip[9]^ip[11]^ip[15]^ip[16]^ip[18]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30],
                datout[93] = ip[0]^ip[2]^ip[5]^ip[7]^ip[8]^ip[9]^ip[10]^ip[14]^ip[15]^ip[17]^ip[18]^ip[19]^ip[23]^ip[24]^ip[25]^ip[26]^ip[29]^ip[31],
                datout[94] = ip[1]^ip[4]^ip[7]^ip[8]^ip[13]^ip[14]^ip[16]^ip[17]^ip[20]^ip[22]^ip[23]^ip[24]^ip[25]^ip[26]^ip[28]^ip[30]^ip[31],
                datout[95] = ip[0]^ip[3]^ip[6]^ip[7]^ip[12]^ip[13]^ip[15]^ip[16]^ip[19]^ip[21]^ip[22]^ip[23]^ip[24]^ip[25]^ip[27]^ip[29]^ip[30],
                datout[96] = ip[2]^ip[5]^ip[9]^ip[11]^ip[12]^ip[14]^ip[15]^ip[21]^ip[22]^ip[23]^ip[24]^ip[28]^ip[29]^ip[31],
                datout[97] = ip[1]^ip[4]^ip[8]^ip[10]^ip[11]^ip[13]^ip[14]^ip[20]^ip[21]^ip[22]^ip[23]^ip[27]^ip[28]^ip[30],
                datout[98] = ip[0]^ip[3]^ip[7]^ip[9]^ip[10]^ip[12]^ip[13]^ip[19]^ip[20]^ip[21]^ip[22]^ip[26]^ip[27]^ip[29],
                datout[99] = ip[2]^ip[8]^ip[11]^ip[12]^ip[19]^ip[21]^ip[25]^ip[28]^ip[31],
                datout[100] = ip[1]^ip[7]^ip[10]^ip[11]^ip[18]^ip[20]^ip[24]^ip[27]^ip[30],
                datout[101] = ip[0]^ip[6]^ip[9]^ip[10]^ip[17]^ip[19]^ip[23]^ip[26]^ip[29],
                datout[102] = ip[5]^ip[6]^ip[8]^ip[16]^ip[20]^ip[22]^ip[25]^ip[26]^ip[28]^ip[31],
                datout[103] = ip[4]^ip[5]^ip[7]^ip[15]^ip[19]^ip[21]^ip[24]^ip[25]^ip[27]^ip[30],
                datout[104] = ip[3]^ip[4]^ip[6]^ip[14]^ip[18]^ip[20]^ip[23]^ip[24]^ip[26]^ip[29],
                datout[105] = ip[2]^ip[3]^ip[5]^ip[13]^ip[17]^ip[19]^ip[22]^ip[23]^ip[25]^ip[28],
                datout[106] = ip[1]^ip[2]^ip[4]^ip[12]^ip[16]^ip[18]^ip[21]^ip[22]^ip[24]^ip[27],
                datout[107] = ip[0]^ip[1]^ip[3]^ip[11]^ip[15]^ip[17]^ip[20]^ip[21]^ip[23]^ip[26],
                datout[108] = ip[0]^ip[2]^ip[6]^ip[9]^ip[10]^ip[14]^ip[16]^ip[18]^ip[19]^ip[22]^ip[25]^ip[26]^ip[31],
                datout[109] = ip[1]^ip[5]^ip[6]^ip[8]^ip[13]^ip[15]^ip[17]^ip[20]^ip[21]^ip[24]^ip[25]^ip[26]^ip[30]^ip[31],
                datout[110] = ip[0]^ip[4]^ip[5]^ip[7]^ip[12]^ip[14]^ip[16]^ip[19]^ip[20]^ip[23]^ip[24]^ip[25]^ip[29]^ip[30],
                datout[111] = ip[3]^ip[4]^ip[9]^ip[11]^ip[13]^ip[15]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[26]^ip[28]^ip[29]^ip[31],
                datout[112] = ip[2]^ip[3]^ip[8]^ip[10]^ip[12]^ip[14]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[25]^ip[27]^ip[28]^ip[30],
                datout[113] = ip[1]^ip[2]^ip[7]^ip[9]^ip[11]^ip[13]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[24]^ip[26]^ip[27]^ip[29],
                datout[114] = ip[0]^ip[1]^ip[6]^ip[8]^ip[10]^ip[12]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[23]^ip[25]^ip[26]^ip[28],
                datout[115] = ip[0]^ip[5]^ip[6]^ip[7]^ip[11]^ip[15]^ip[16]^ip[19]^ip[22]^ip[24]^ip[25]^ip[26]^ip[27]^ip[31],
                datout[116] = ip[4]^ip[5]^ip[9]^ip[10]^ip[14]^ip[15]^ip[20]^ip[21]^ip[23]^ip[24]^ip[25]^ip[30]^ip[31],
                datout[117] = ip[3]^ip[4]^ip[8]^ip[9]^ip[13]^ip[14]^ip[19]^ip[20]^ip[22]^ip[23]^ip[24]^ip[29]^ip[30],
                datout[118] = ip[2]^ip[3]^ip[7]^ip[8]^ip[12]^ip[13]^ip[18]^ip[19]^ip[21]^ip[22]^ip[23]^ip[28]^ip[29],
                datout[119] = ip[1]^ip[2]^ip[6]^ip[7]^ip[11]^ip[12]^ip[17]^ip[18]^ip[20]^ip[21]^ip[22]^ip[27]^ip[28],
                datout[120] = ip[0]^ip[1]^ip[5]^ip[6]^ip[10]^ip[11]^ip[16]^ip[17]^ip[19]^ip[20]^ip[21]^ip[26]^ip[27],
                datout[121] = ip[0]^ip[4]^ip[5]^ip[6]^ip[10]^ip[15]^ip[16]^ip[19]^ip[25]^ip[31],
                datout[122] = ip[3]^ip[4]^ip[5]^ip[6]^ip[14]^ip[15]^ip[20]^ip[24]^ip[26]^ip[30]^ip[31],
                datout[123] = ip[2]^ip[3]^ip[4]^ip[5]^ip[13]^ip[14]^ip[19]^ip[23]^ip[25]^ip[29]^ip[30],
                datout[124] = ip[1]^ip[2]^ip[3]^ip[4]^ip[12]^ip[13]^ip[18]^ip[22]^ip[24]^ip[28]^ip[29],
                datout[125] = ip[0]^ip[1]^ip[2]^ip[3]^ip[11]^ip[12]^ip[17]^ip[21]^ip[23]^ip[27]^ip[28],
                datout[126] = ip[0]^ip[1]^ip[2]^ip[6]^ip[9]^ip[10]^ip[11]^ip[16]^ip[18]^ip[22]^ip[27]^ip[31],
                datout[127] = ip[0]^ip[1]^ip[5]^ip[6]^ip[8]^ip[10]^ip[15]^ip[17]^ip[18]^ip[20]^ip[21]^ip[30]^ip[31];

       end // gen_128_loop

       default: begin :gen_rtl_loop

                  reg [(BIT_COUNT-1):0] mdat;
                  reg [REMAINDER_SIZE:0] md, nCRC [0:(BIT_COUNT-1)];                       // temp vaiables used in CRC calculation

                  always @(ip) begin :crc_loop
                    integer i;
                    nCRC[0] = {ip,^(CRC_POLYNOMIAL & {ip,1'b0})};
                    for(i=1;i<BIT_COUNT;i=i+1) begin                     // Calculate remaining CRC for all other data bits in parallel
                      md = nCRC[i-1];
                      mdat[i-1] = md[0];
                      nCRC[i] = {md,^(CRC_POLYNOMIAL & {md[(REMAINDER_SIZE-1):0],1'b0})};
                    end
                    md = nCRC[(BIT_COUNT-1)];
                    mdat[(BIT_COUNT-1)] = md[0];
                  end

                  assign op = md;                          // The output polynomial is the very last entry in the array
                  assign datout  = mdat;

                end             // gen_rtl_loop

endcase

endgenerate

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


