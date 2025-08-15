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


:: ============================================================================
:: SETTINGS
:: ============================================================================
set VIVADO_BIN="D:\Xilinx\Vivado\2024.1\bin"
set WCFG_FILE="tb_sim.wcfg"



:: ============================================================================
:: SYNTAX CHECK AND COMPILE
:: ============================================================================
echo [INFO] Syntax check...
call %VIVADO_BIN%\xvhdl --work debouncer_lib ../../src/debouncer/debouncer_pkg.vhd
call %VIVADO_BIN%\xvhdl --work debouncer_lib ../../src/debouncer/debouncer.vhd
echo [DEBUG] 'xvhdl' command return code: %ERRORLEVEL%

call %VIVADO_BIN%\xvhdl --work work tb_debouncer.vhd
echo [DEBUG] 'xvhdl' command return code: %ERRORLEVEL%


:: ============================================================================
:: TESTBENCH ELABORATION
:: ============================================================================
echo [INFO] Elaborating...
call %VIVADO_BIN%\xelab tb_debouncer -L debouncer_lib -generic_top "IRQ_DURATION=3" -s tb_sim -debug all



:: ============================================================================
:: RUN SIMULATION
:: ============================================================================
if "%~1"=="nogui" (
  echo [INFO] GUI is disabled. Running simulation silently...
  %VIVADO_BIN%\xsim tb_sim -runall
) else (
  echo [INFO] GUI mode
	
  if exist "%WCFG_FILE%" (
    %VIVADO_BIN%\xsim tb_sim --gui -view "%WCFG_FILE%"
  ) else (
    echo [WARNING] Wave file directive not found. Using defaults...
    %VIVADO_BIN%\xsim tb_sim --gui
  )
)

endlocal