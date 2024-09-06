#------------------------------------------------------------------------------
#  (c) Copyright 2020-2021 Advanced Micro Devices, Inc. All rights reserved.
#
#  This file contains confidential and proprietary information
#  of Advanced Micro Devices, Inc. and is protected under U.S. and
#  international copyright and other intellectual property
#  laws.
#
#  DISCLAIMER
#  This disclaimer is not a license and does not grant any
#  rights to the materials distributed herewith. Except as
#  otherwise provided in a valid license issued to you by
#  AMD, and to the maximum extent permitted by applicable
#  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
#  WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
#  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
#  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
#  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
#  (2) AMD shall not be liable (whether in contract or tort,
#  including negligence, or under any other theory of
#  liability) for any loss or damage of any kind or nature
#  related to, arising under or in connection with these
#  materials, including for any direct, or any indirect,
#  special, incidental, or consequential loss or damage
#  (including loss of data, profits, goodwill, or any type of
#  loss or damage suffered as a result of any action brought
#  by a third party) even if such damage or loss was
#  reasonably foreseeable or AMD had been advised of the
#  possibility of the same.
#
#  CRITICAL APPLICATIONS
#  AMD products are not designed or intended to be fail-
#  safe, or for use in any application requiring fail-safe
#  performance, such as life-support or safety devices or
#  systems, Class III medical devices, nuclear facilities,
#  applications related to the deployment of airbags, or any
#  other applications that could lead to death, personal
#  injury, or severe property or environmental damage
#  (individually and collectively, "Critical
#  Applications"). Customer assumes the sole risk and
#  liability of any use of AMD products in Critical
#  Applications, subject only to applicable laws and
#  regulations governing limitations on product liability.
#
#  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
#  PART OF THIS FILE AT ALL TIMES.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# L_ETHERNET example design-level XDC file
# ----------------------------------------------------------------------------------------------------------------------
### init_clk should be lesser or equal to reference clock.

create_clock -period 8.000 [get_ports dclk]
set_property IOSTANDARD LVCMOS18 [get_ports dclk]
create_clock -period 6.206 [get_ports gt_refclk_p]

### Transceiver Reference Clock Placement
### Transceivers should be adjacent to allow timing constraints to be met easily.
### Full details of available transceiver locations can be found
### in the appropriate transceiver User Guide, or use the Transceiver Wizard.

### These are sample constraints, please use correct constraints for your device
### update the gt_refclk pin location accordingly and un-comment the below two lines
##set_property PACKAGE_PIN AK38 [get_ports gt_refclk_p]
##set_property PACKAGE_PIN AK39 [get_ports gt_refclk_n]

###Board constraints to be added here
### Below XDC constraints are for VCU108 board with xcvu095-ffva2104-2-e-es2 device
### Change these constraints as per your board and device
### Push Buttons
#set_property PACKAGE_PIN D9 [get_ports sys_reset]
set_property IOSTANDARD LVCMOS18 [get_ports sys_reset]

#set_property LOC A10 [get_ports restart_tx_rx]
set_property IOSTANDARD LVCMOS18 [get_ports restart_tx_rx]

### LEDs
#set_property PACKAGE_PIN AT32 [get_ports rx_gt_locked_led]
set_property IOSTANDARD LVCMOS18 [get_ports rx_gt_locked_led]
##
#set_property PACKAGE_PIN AV34 [get_ports rx_aligned_led]
set_property IOSTANDARD LVCMOS18 [get_ports rx_aligned_led]
##
#set_property PACKAGE_PIN AY30 [get_ports completion_status[0]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[0]]
##
#set_property PACKAGE_PIN BB32 [get_ports completion_status[1]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[1]]
##
#set_property PACKAGE_PIN BF32 [get_ports completion_status[2]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[2]]
##
#set_property PACKAGE_PIN AV36 [get_ports completion_status[3]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[3]]
##
#set_property PACKAGE_PIN AY35 [get_ports completion_status[4]]
set_property IOSTANDARD LVCMOS18 [get_ports completion_status[4]]




### Any other Constraints
###set_power_opt -exclude_cells [get_cells -hierarchical -filter {NAME =~ */*HSEC_CORES*/i_RX_TOP/i_RX_CORE/i_RX_LANE*/i_BUFF_*/i_RAM/i_RAM_* }]

####set_power_opt -exclude_cells [get_cells {DUT/inst/i_my_ip_top_0/i_my_ip_HSEC_CORES/i_RX_TOP/i_RX_CORE/i_RX_LANE0/i_BUFF_1/i_RAM/i_RAM_0}]











set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */pktgen_enable_int_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter { name =~ */*_syncer/meta_reg*}] -filter { name =~ *D }] 8.000 -quiet



set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */i_SYNCER_BUS/busout_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter { name =~ */*_stat_*x_*_syncer/meta_reg*}] -filter { name =~ *D }] 8.000 -quiet


set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */stat_rx_status_int_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter { name =~ */*_stat_rx_status_syncer/meta_reg*}] -filter { name =~ *D }] 8.000 -quiet

set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */i_RX_LANE_ALIGNER/aligned_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter { name =~ */*_syncer/meta_reg[*]}] -filter { name =~ *D }] 8.000 -quiet







set_max_delay -datapath_only -from [get_pins -of [get_cells -hier -filter { name =~ */*_cdc_sync_*x*reset*/s_out_d4_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter { name =~ */*_cdc_sync_*x_*/s_out_d2_cdc_to_reg*}] -filter { name =~ *D }] 8.000 -quiet

create_waiver -type CDC -id {CDC-1} -user "l_ethernet" -desc "The CDC-1 warning is waived as it is a level signal in reset path. This is safe to ignore" -tags "11999" -from [get_pins -of [get_cells -hier -filter {name =~ */i_RX_LANE_ALIGNER/*_reg*}] -filter { name =~ *C }] -to [get_pins -of [get_cells -hier -filter {name =~ */stat_rx_status_int_reg*}] -filter { name =~ *D }] -timestamp "Thu Sep  5 07:47:54 GMT 2024"














