:: ============================================================================
:: Project       : synthChip
:: Module name   : -
:: File name     : makeFpga.bat
:: File type     : Batch script for Windows
:: Purpose       : 
:: Author        : QuBi (nitrogenium@outlook.fr)
:: Creation date : August 10th, 2025
:: ----------------------------------------------------------------------------
:: Best viewed with space indentation (2 spaces)
:: ============================================================================

@echo off
echo Generating the synthChip FPGA...

set VIVADO_PATH="D:\Xilinx\Vivado\2019.2\bin\vivado.bat"
set TARGET_DIR=".\vivado\fpga_synthChip"
set TCL_SCRIPT=".\tcl\makeFpga.tcl"

if exist "%TARGET_DIR%" (
  echo [WARNING] A Vivado project already exists and will be deleted.
  rmdir /s /q "%TARGET_DIR%"
)

%VIVADO_PATH% -mode batch -source %TCL_SCRIPT% -notrace -log makeFpga.log -journal makeFpga.jou

echo Batch execution finished.
pause

