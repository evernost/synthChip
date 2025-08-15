# =============================================================================
# Project       : synthChip
# Module name   : makeFpga
# File name     : makeFpga.tcl
# File type     : TCL script (Vivado 2024.1)
# Purpose       : full Vivado project generation script
# Author        : QuBi (nitrogenium@outlook.fr)
# Creation date : August 11th, 2025
# -----------------------------------------------------------------------------
# Best viewed with space indentation (2 spaces)
# =============================================================================

# =============================================================================
# NOTES
# =============================================================================
# The "zedboard" might require an update of the board repository to be 
# available in Vivado:
# xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
# xhub::uninstall [xhub::get_xitems avnet.com:xilinx_board_store:zedboard:1.4]
# xhub::install [xhub::get_xitems avnet.com:xilinx_board_store:zedboard:1.4]
# xhub::update [xhub::get_xitems avnet.com:xilinx_board_store:zedboard:1.4]



# =============================================================================
# FUNCTIONS
# =============================================================================
proc addFileToLib {fileName libName} {
  add_file -norecurse $fileName
  set_property library $libName [get_files $fileName]
}

proc log {msg} {
    puts "\[VIVADO\] $msg"
}



# =============================================================================
# SETTINGS
# =============================================================================
set topName "synthChip"
set projectName "fpga_${topName}"
set blockDesignName "${topName}"

# FPGA settings
set targetFpga "7z020"
set targetPart "xc7z020clg484-1"
set targetBoard "avnet.com:zedboard:part0:1.4"
#set targetBoard "em.avnet.com:zed:part0:1.4"

# Directories
set projectDir "./vivado"
set sourceDir "../src"
set ipDir "./ip"

# Number of parallel processes running for implementation
set nImplemJobs 8

# Bypass bitstream generation to save some time
set makeBitstream 1



# =============================================================================
# PROJECT GENERATION
# =============================================================================
log "Cleaning output products"
#exec rm -rf "${projectDir}/${projectName}"




log "Creating project"
# NOTE: workaround in 2024.1 to force Vivado detect the installed boards
# See 'https://adaptivesupport.amd.com/s/question/0D52E00006hpfIzSAI/set-board-repo-path?language=en_US'
set_param board.repoPaths [file join $::env(APPDATA) Xilinx Vivado 2024.1 xhub board_store xilinx_board_store]

create_project ${projectName} "${projectDir}/${projectName}" -part ${targetPart}
set_property board_part ${targetBoard} [current_project]
set_property target_language VHDL [current_project]



log "Including custom IP repository"
set_property  ip_repo_paths ./${ipDir} [current_project]
update_ip_catalog



log "Creating block design"
create_bd_design ${blockDesignName}
save_bd_design



log "Adding VHDL files"
addFileToLib "${sourceDir}/blinky/blinky_pkg.vhd" "blinky_lib"
addFileToLib "${sourceDir}/blinky/blinky.vhd"     "blinky_lib"

addFileToLib "${sourceDir}/debouncer/debouncer_pkg.vhd" "debouncer_lib"
addFileToLib "${sourceDir}/debouncer/debouncer.vhd"     "debouncer_lib"

addFileToLib "${sourceDir}/uart/uart.vhd" "uart_lib"

addFileToLib "${sourceDir}/synthChip_top.vhd" "work"


log "Adding IPs"
# ------------------
# Processor instance
# ------------------
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation \
  -rule xilinx.com:bd_rule:processing_system7 \
  -config {
    make_external "FIXED_IO, DDR" \
    apply_board_preset "1" \
    Master "Disable" \
    Slave "Disable" \
} [get_bd_cells processing_system7_0]

set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.0}] [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {0}]                [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {0}]                [get_bd_cells processing_system7_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M



# --------------
# FPGA top level
# --------------
create_bd_cell -type module -reference synthChip_top synthChip_top_0
#set_property CONFIG.CLOCK_FREQ_MHZ {100.0}  [get_bd_cells synthChip_top_0]
set_property CONFIG.RESET_POL {"1"}         [get_bd_cells synthChip_top_0]

# ---------------
# I2S transmitter
# ---------------
# create_bd_cell -type ip -vlnv xilinx.com:ip:i2s_transmitter:1.0 i2s_transmitter_0

# --------------
# UART interface
# --------------
# create_bd_cell -type module -reference uart uart_0



# --------------------
# Creating connections
# --------------------
create_bd_port -dir O leds
create_bd_port -dir I push_button_L
create_bd_port -dir I push_button_R
create_bd_port -dir I push_button_U
create_bd_port -dir I push_button_D
create_bd_port -dir I push_button_C


connect_bd_net [get_bd_pins synthChip_top_0/leds]           [get_bd_ports leds]
connect_bd_net [get_bd_pins synthChip_top_0/push_button_L]  [get_bd_ports push_button_L]
connect_bd_net [get_bd_pins synthChip_top_0/push_button_R]  [get_bd_ports push_button_R]
connect_bd_net [get_bd_pins synthChip_top_0/push_button_U]  [get_bd_ports push_button_U]
connect_bd_net [get_bd_pins synthChip_top_0/push_button_D]  [get_bd_ports push_button_D]
connect_bd_net [get_bd_pins synthChip_top_0/push_button_C]  [get_bd_ports push_button_C]


# make_bd_intf_pins_external  [get_bd_intf_pins processing_system7_0/DDR]
# make_bd_intf_pins_external  [get_bd_intf_pins processing_system7_0/FIXED_IO]
# connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR]            [get_bd_intf_pins processing_system7_0/DDR]
# connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO]  [get_bd_intf_pins processing_system7_0/FIXED_IO]

connect_bd_net -net processing_system7_0_FCLK_CLK0      [get_bd_pins processing_system7_0/FCLK_CLK0]      [get_bd_pins synthChip_top_0/clock] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
connect_bd_net -net processing_system7_0_FCLK_RESET0_N  [get_bd_pins processing_system7_0/FCLK_RESET0_N]  [get_bd_pins rst_ps7_0_100M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_reset] [get_bd_pins synthChip_top_0/reset]
save_bd_design


log "I/O constraints"
create_fileset -constrset "constraintsDefault"
add_files -fileset "constraintsDefault" -norecurse "./constraints/io.xdc"

set_property constrset constraintsDefault [get_runs synth_1]
set_property constrset constraintsDefault [get_runs impl_1]



puts "# ###################################################################"
puts "# Block design wrapper creation"
puts "# ###################################################################"

make_wrapper -files [get_files "./vivado/${projectName}/${projectName}.srcs/sources_1/bd/${blockDesignName}/${blockDesignName}.bd"] -top
add_files -norecurse "./vivado/${projectName}/${projectName}.gen/sources_1/bd/${blockDesignName}/hdl/${blockDesignName}_wrapper.vhd"




log "Run synthesis"
launch_runs synth_1 -jobs 8
wait_on_run -timeout 60 synth_1



log "Run implementation"
launch_runs impl_1 -to_step write_bitstream -jobs ${nImplemJobs}
wait_on_run -timeout 60 impl_1

#   launch_runs impl_1 -to_step write_bitstream -jobs ${nImplemJobs}
#   wait_on_run -timeout 60 impl_1

# if {[string equal $synth 1]} {
#   puts "Synthesis is enabled."
#   set_property STEPS.SYNTH_DESIGN.ARGS.ASSERT true [get_runs synth_1]
#   launch_runs synth_1 -jobs $nSynthJobs
#   wait_on_run -timeout 60 synth_1
# } else {
#   puts "Synthesis is disabled."
# }

# if ([string equal $makeBitstream 1]) {
#   puts "# ###################################################################"
#   puts "# Output products, synthesis, implementation, and bistream generation"
#   puts "# ###################################################################"

#   launch_runs impl_1 -to_step write_bitstream -jobs ${nImplemJobs}
#   wait_on_run -timeout 60 impl_1

#   # puts "Generation of RBT, MSD and logic location files is enabled."
#   # set_property STEPS.WRITE_BITSTREAM.ARGS.RAW_BITFILE true [get_runs impl_1]
#   # set_property STEPS.WRITE_BITSTREAM.ARGS.READBACK_FILE true [get_runs impl_1]
#   # set_property STEPS.WRITE_BITSTREAM.ARGS.LOGIC_LOCATION_FILE true [get_runs impl_1]
#   # puts "Output products, synthesis, implementation, and bistream generation is enabled."
#   # launch_runs impl_1 -to_step write_bitstream -jobs $nImplemJobs
#   # wait_on_run -timeout 60 impl_1
# } else {
#   puts "Output products, synthesis, implementation, and bistream generation is disabled."
# }

# save_bd_design



