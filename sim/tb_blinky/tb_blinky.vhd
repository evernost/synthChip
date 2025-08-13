-- ============================================================================
-- Project        : synthChip
-- Module name    : tb_blinky
-- File name      : tb_blinky.vhd
-- File type      : VHDL 2008
-- Purpose        : testbench for the blinky
-- Author         : QuBi (nitrogenium@outlook.fr)
-- Creation date  : August 13th, 2025
-- ----------------------------------------------------------------------------
-- Best viewed with space indentation (2 spaces)
-- ============================================================================

-- ============================================================================
-- LIBRARIES
-- ============================================================================
-- Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Project libraries
library misc_lib;



-- ============================================================================
-- I/O DESCRIPTION
-- ============================================================================
entity tb_blinky is
generic
(
  RESET_POL       : STD_LOGIC := '0';
  RESET_SYNC      : BOOLEAN := TRUE;
  CLOCK_FREQ_MHZ  : REAL := 100.0;
  BLINK_FREQ_HZ   : REAL := 10.0
);
end tb_blinky;



-- ============================================================================
-- ARCHITECTURE
-- ============================================================================
architecture archDefault of tb_blinky is

  signal clock  : STD_LOGIC := '0';
  signal reset  : STD_LOGIC := '0';

  signal blink  : STD_LOGIC;

begin
  
  -- --------------------------------------------------------------------------
  -- DUT (blinky)
  -- --------------------------------------------------------------------------
  dut_blinky_0 : entity misc_lib.blinky(archDefault)
  generic map
  (
    RESET_POL       => RESET_POL,
    RESET_SYNC      => RESET_SYNC,
    CLOCK_FREQ_MHZ  => CLOCK_FREQ_MHZ,
    BLINK_FREQ_HZ   => BLINK_FREQ_HZ
  )
  port map
  ( 
    clock     => clock,
    reset     => reset,
    
    blink_out => blink
  );



  -- Resets 
  reset <= '1', '0' after 111.0 ns;
  
  -- Clocks
  clock <= not(clock) after (CLOCK_PERIOD/2);
  
end archDefault;
