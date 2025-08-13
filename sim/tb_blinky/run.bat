:: ============================================================================
:: Project       : synthChip
:: Module name   : -
:: File name     : run.bat
:: File type     : Batch script for Windows
:: Purpose       : check, compile and simulation script
:: Author        : QuBi (nitrogenium@outlook.fr)
:: Creation date : August 10th, 2025
:: ----------------------------------------------------------------------------
:: Best viewed with space indentation (2 spaces)
:: ============================================================================

@echo off
setlocal

set VIVADO_BIN="C:\Xilinx\Vivado\2024.1\bin"

:: ============================================================================
:: Syntax check & compile
:: ============================================================================
%VIVADO_BIN%\xvhdl --work misc_lib ../../src/misc/blinky.vhd
%VIVADO_BIN%\xvhdl --work misc_lib ../../src/misc/blinky_pkg.vhd
%VIVADO_BIN%\xvhdl --work misc_lib tb_blinky.vhd



:: ============================================================================
:: Elaborate the testbench
:: ============================================================================
%VIVADO_BIN%\xelab tb_blinky -L misc_lib -s tb_sim -generic_top GENERIC_NAME=VALUE



:: ============================================================================
:: Run simulation
:: ============================================================================
%VIVADO_BIN%\xsim tb_sim --gui

if "%~1"=="gui" (
    %VIVADO_BIN%\xsim tb_sim --gui
) else (
    %VIVADO_BIN%\xsim tb_sim -runall
)


endlocal