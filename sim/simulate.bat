:: ============================================================================
:: Project       : synthChip
:: Module name   : -
:: File name     : simulate.bat
:: File type     : Batch script for Windows
:: Purpose       : runs a VHDL simulation
:: Author        : QuBi (nitrogenium@outlook.fr)
:: Creation date : August 10th, 2025
:: ----------------------------------------------------------------------------
:: Best viewed with space indentation (2 spaces)
:: ============================================================================

@echo off
REM Usage: simulate.bat path\to\simulate.tcl

set VIVADO_PATH="D:\Xilinx\Vivado\2019.2"

if "%~1"=="" (
    echo Usage: %~nx0 path\to\simulate.tcl
    exit /b 1
)

echo Setting environment (settings64)...
call "%VIVADO_PATH%\settings64.bat"

echo Syntax check...
xvhdl ../src/uart/uart.vhd
::xvhdl ../src/uart/uart.vhd tb_my_design.v

echo Elaborating...
xelab tb_my_design -s tb_sim

echo Run simulation...
::xsim tb_sim -runall
xsim tb_sim -t 1ms




::vivado -mode batch -source "%~1" -notrace -log sim.log -journal sim.jou


echo Batch execution finished.
pause