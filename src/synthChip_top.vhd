-- ============================================================================
-- Project        : synthChip
-- Module name    : synthChip_top
-- File name      : synthChip_top.vhd
-- File type      : VHDL 2008
-- Purpose        : top level for the 'synthChip' FPGA
-- Author         : QuBi (nitrogenium@outlook.fr)
-- Creation date  : August 10th, 2025
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
library uart_lib; use uart_lib.uart_pkg.all;
library misc_lib;
--library work; use work.synthChip_pkg.all;



-- ============================================================================
-- I/O DESCRIPTION
-- ============================================================================
entity synthChip_top is
generic
(
  RESET_POL   : STD_LOGIC := '0';
  RESET_SYNC  : BOOLEAN := TRUE
);
port
( 
  clock       : in STD_LOGIC;
  reset       : in STD_LOGIC;

  user_leds   : out STD_LOGIC_VECTOR(7 downto 0);

  -- UART link
  uart_rxd : in STD_LOGIC;
  uart_txd : out STD_LOGIC
);
end synthChip_top;



-- ============================================================================
-- ARCHITECTURE
-- ============================================================================
architecture archDefault of synthChip_top is

  signal heartbeat  : STD_LOGIC;
  
begin

  user_leds(0)  <= heartbeat;                       -- FPGA is active
  user_leds(1)  <= '0';                             -- No function yet
  user_leds(2)  <= '0';                             -- No function yet
  user_leds(3)  <= '0';                             -- No function yet
  user_leds(4)  <= '0';                             -- No function yet
  user_leds(5)  <= '0';                             -- No function yet
  user_leds(6)  <= '0';                             -- No function yet
  user_leds(7)  <= '0';                             -- No function yet



  -- --------------------------------------------------------------------------
  -- Blinky (heartbeat)
  -- --------------------------------------------------------------------------
  blinky_0 : entity misc_lib.blinky(archDefault)
  generic map
  (
    RESET_POL       => RESET_POL,
    RESET_SYNC      => RESET_SYNC,
    CLOCK_FREQ_MHZ  => 100.0,
    BLINK_FREQ_HZ   => 2.0
  )
  port map
  ( 
    clock     => clock,
    reset     => reset,
    
    blink_out => heartbeat
  );



  


  
end archDefault;
