# =============================================================================
# Project       : synthChip
# Module name   : makeFpga
# File name     : makeFpga.tcl
# File type     : TCL script (Vivado 2019.2)
# Purpose       : full Vivado project generation script
# Author        : QuBi (nitrogenium@outlook.fr)
# Creation date : August 11th, 2025
# -----------------------------------------------------------------------------
# Best viewed with space indentation (2 spaces)
# =============================================================================

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
set targetBoard "em.avnet.com:zed:part0:1.4"

# Directories
set projectDir "./vivado"
set sourceDir "../src"
set ipDir "./ip"

# Number of parallel processes running for implementation
set nImplemJobs 8

# Bypass bitstream generation to save some time
set makeBitstream 1



# =============================================================================
# MAIN SCRIPT
# =============================================================================

log "Cleaning output products"
#exec rm -rf "${projectDir}/${projectName}"



log "Creating project"
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
addFileToLib "${sourceDir}/uart/uart.vhd" "uart_lib"



log "Adding IPs"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
create_bd_cell -type ip -vlnv xilinx.com:ip:i2s_transmitter:1.0 i2s_transmitter_0
create_bd_cell -type module -reference uart uart_0
save_bd_design



log "I/O constraints"
create_fileset -constrset "constraintsDefault"
add_files -fileset "constraintsDefault" -norecurse "./constraints/io.xdc"

set_property constrset constraintsDefault [get_runs synth_1]
set_property constrset constraintsDefault [get_runs impl_1]
save_bd_design



puts "# ###################################################################"
puts "# Block design wrapper creation"
puts "# ###################################################################"

make_wrapper -files [get_files "./${projectName}/${projectName}.srcs/sources_1/bd/${blockDesignName}/${blockDesignName}.bd"] -top
add_files -norecurse "./${projectName}/${projectName}.srcs/sources_1/bd/${blockDesignName}/hdl/${blockDesignName}_wrapper.vhd"



if {[string equal $synth 1]} {
  puts "Synthesis is enabled."
  set_property STEPS.SYNTH_DESIGN.ARGS.ASSERT true [get_runs synth_1]
  launch_runs synth_1 -jobs $nSynthJobs
  wait_on_run -timeout 60 synth_1
} else {
  puts "Synthesis is disabled."
}

if ([string equal $makeBitstream 1]) {
  puts "# ###################################################################"
  puts "# Output products, synthesis, implementation, and bistream generation"
  puts "# ###################################################################"

  launch_runs impl_1 -to_step write_bitstream -jobs ${nImplemJobs}
  wait_on_run -timeout 60 impl_1

  # puts "Generation of RBT, MSD and logic location files is enabled."
  # set_property STEPS.WRITE_BITSTREAM.ARGS.RAW_BITFILE true [get_runs impl_1]
  # set_property STEPS.WRITE_BITSTREAM.ARGS.READBACK_FILE true [get_runs impl_1]
  # set_property STEPS.WRITE_BITSTREAM.ARGS.LOGIC_LOCATION_FILE true [get_runs impl_1]
  # puts "Output products, synthesis, implementation, and bistream generation is enabled."
  # launch_runs impl_1 -to_step write_bitstream -jobs $nImplemJobs
  # wait_on_run -timeout 60 impl_1
} else {
  puts "Output products, synthesis, implementation, and bistream generation is disabled."
}

save_bd_design



