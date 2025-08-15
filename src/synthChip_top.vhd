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
library debouncer_lib; use debouncer_lib.debouncer_pkg.all;
library blinky_lib; use blinky_lib.blinky_pkg.all;
--library work; use work.synthChip_pkg.all;



-- ============================================================================
-- I/O DESCRIPTION
-- ============================================================================
entity synthChip_top is
generic
(
  RESET_POL       : STD_LOGIC := '0';
  RESET_SYNC      : BOOLEAN := TRUE;
  CLOCK_FREQ_MHZ  : REAL
);
port
( 
  clock         : in STD_LOGIC;
  reset         : in STD_LOGIC;

  -- User
  leds          : out STD_LOGIC_VECTOR(7 downto 0);
  push_button_C : in STD_LOGIC;
  push_button_L : in STD_LOGIC;
  push_button_R : in STD_LOGIC;
  push_button_U : in STD_LOGIC;
  push_button_D : in STD_LOGIC;

  -- UART link
  uart_rxd : in STD_LOGIC;
  uart_txd : out STD_LOGIC
);
end synthChip_top;



-- ============================================================================
-- ARCHITECTURE
-- ============================================================================
architecture archDefault of synthChip_top is

  signal heartbeat      : STD_LOGIC;
  signal isResetActive  : STD_LOGIC;
  
begin

  user_leds(0)  <= isResetActive;                   -- Indicates if the module is under reset
  user_leds(1)  <= heartbeat;                       -- Indicates if the FPGA is active (clock OK, reset OK)
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
    CLOCK_FREQ_MHZ  => CLOCK_FREQ_MHZ,
    BLINK_FREQ_HZ   => 1.0
  )
  port map
  ( 
    clock     => clock,
    reset     => reset,
    
    blink_out => heartbeat
  );



  -- --------------------------------------------------------------------------
  -- Debouncer
  -- --------------------------------------------------------------------------
  debouncer_0 : entity misc_lib.debouncer(archDefault)
  generic map
  (
    RESET_POL       => RESET_POL,
    RESET_SYNC      => RESET_SYNC,
    CLOCK_FREQ_MHZ  => CLOCK_FREQ_MHZ,
    BLIND_TIME_MS   => 25.0,
    IRQ_TRIG_POL    => IRQ_TRIGGER_POL_RISING,
    IRQ_DURATION    => 1
  )
  port map
  ( 
    clock     => clock,
    reset     => reset,
    
    button_in => push_button_C,
    
    state     => 
    state_n   => open,
    toggle    => open,

    irq       => open
  );



  isResetActive <= '1' when (reset = RESET_POL) else
                   '0';


  
end archDefault;
