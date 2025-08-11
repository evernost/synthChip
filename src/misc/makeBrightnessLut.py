# -*- coding: utf-8 -*-
# =============================================================================
# Project       : Blinky
# Module name   : makeBrightnessLut
# File name     : makeBrightnessLut.py
# File type     : Python script (Python 3)
# Purpose       : LUT generation table (gamma correction)
# Author        : QuBi (nitrogenium@outlook.fr)
# Creation date : July 16th, 2025
# -----------------------------------------------------------------------------
# Best viewed with space indentation (2 spaces)
# =============================================================================

import math
from datetime import datetime

# PWM resolution (in bits)
# Number of PWM steps = 2^PWM_RESOL
PWM_RESOL_NBITS = 9
pwmSteps = int(2**PWM_RESOL_NBITS)

# Number of desired steps in brightness.
# NOTES:
# - A value higher than 'pwmSteps' won't make much sense since 
#   there aren't enough PWM steps to satisfy the resolution.
# - Use a power of 2 for more optimal synthesis.
BRIGHTNESS_STEPS = 128



with open("blinky_pkg.vhd", "w") as file :

  now = datetime.now()
  timestamp = now.strftime(f"%B {now.day}, %Y at %H:%M")

  file.write("-- ============================================================================\n")
  file.write("-- Project        : Blinky\n")
  file.write("-- Module name    : blinky\n")
  file.write("-- File name      : blinky.vhd\n")
  file.write("-- File type      : VHDL 2008\n")
  file.write("-- Purpose        : package definition for the Blinky module\n")
  file.write("-- Author         : QuBi (nitrogenium@outlook.fr)\n")
  file.write(f"-- Creation date  : {timestamp}\n")
  file.write("-- ----------------------------------------------------------------------------\n")
  file.write("-- Best viewed with space indentation (2 spaces)\n")
  file.write("-- ============================================================================\n")
  file.write("\n")
  file.write("-- ============================================================================\n")
  file.write("-- CONTENT IS GENERATED AUTOMATICALLY USING 'makeBrightnessLut.py'.\n")
  file.write("-- ! DO NOT MODIFY IT !\n")
  file.write("-- ============================================================================\n")
  file.write("\n")
  file.write("-- ============================================================================\n")
  file.write("-- LIBRARIES\n")
  file.write("-- ============================================================================\n")
  file.write("-- Standard libraries\n")
  file.write("library IEEE;\n")
  file.write("use IEEE.STD_LOGIC_1164.all;\n")
  file.write("use IEEE.NUMERIC_STD.all;\n")
  file.write("\n")
  file.write("\n")
  file.write("\n")
  file.write("-- ============================================================================\n")
  file.write("-- PACKAGE DESCRIPTION\n")
  file.write("-- ============================================================================\n")
  file.write("package blinky_pkg is\n")
  file.write("  \n")
  file.write("  -- --------------------------------------------------------------------------\n")
  file.write("  -- Constants / Types\n")
  file.write("  -- --------------------------------------------------------------------------\n")
  file.write(f"  constant PWM_RESOL_NBITS  : INTEGER := {PWM_RESOL_NBITS};\n")
  file.write(f"  constant BRIGHTNESS_STEPS : INTEGER := {BRIGHTNESS_STEPS};\n")
  file.write("  \n")
  file.write("  type ROM_TYPE is array (0 to (BRIGHTNESS_STEPS-1)) of STD_LOGIC_VECTOR((PWM_RESOL_NBITS-1) downto 0);\n")
  file.write(" \n")
  file.write("  constant BRIGHTNESS_ROM : ROM_TYPE := \n")
  file.write("  (\n")
  for i in range(BRIGHTNESS_STEPS) :
    
    # TODO: with the rounding, is there a risk that 'val' exceeds the number
    # of bits available for the PWM (i.e. PWM_RESOL_NBITS)?
    val = int(round(10**((i/BRIGHTNESS_STEPS)*math.log10(pwmSteps))))-1
    
    if (i == (BRIGHTNESS_STEPS-1)) :
      file.write(f"    {i} => \"{val:0{PWM_RESOL_NBITS}b}\"     -- PWM({i}) = {val}/{pwmSteps}\n")
    else :
      file.write(f"    {i} => \"{val:0{PWM_RESOL_NBITS}b}\",    -- PWM({i}) = {val}/{pwmSteps}\n")
    
  file.write("  );\n")
  file.write("  \n")
  file.write("  -- --------------------------------------------------------------------------\n")
  file.write("  -- Components\n")
  file.write("  -- --------------------------------------------------------------------------\n")
  file.write("  -- None.\n")
  file.write("  \n")
  file.write("end package blinky_pkg;\n")
  file.write("  \n")
  file.write("  \n")
  file.write("  \n")
  file.write("-- ============================================================================\n")
  file.write("-- PACKAGE DESCRIPTION\n")
  file.write("-- ============================================================================\n")
  file.write("package body blinky_pkg is \n")
  file.write("  \n")
  file.write("  -- None.\n")
  file.write("  \n")
  file.write("end package body;\n")

print("[NOTE] Output generated to './blinky_pkg.vhd'.")
 