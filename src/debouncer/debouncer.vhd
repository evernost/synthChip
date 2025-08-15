-- ============================================================================
-- Project        : synthChip
-- Module name    : debouncer
-- File name      : debouncer.vhd
-- File type      : VHDL 2008
-- Purpose        : debounce module for push buttons
-- Author         : QuBi (nitrogenium@outlook.fr)
-- Creation date  : August 13th, 2025
-- ----------------------------------------------------------------------------
-- Best viewed with space indentation (2 spaces)
-- ============================================================================

-- ============================================================================
-- DESCRIPTION
-- ============================================================================
-- Simple debouncing module for push buttons, switches etc.
-- The module includes the synchronizing input DFFs.
--
-- It provides various types of outputs:
-- * state output : current state of the push button 
-- * toggle output: state changes on every button press
-- * irq output   : pulse every time an event is detected on the button.
--
-- Known limitations: 
-- None.



-- ============================================================================
-- LIBRARIES
-- ============================================================================
-- Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Project libraries
-- None.



-- ============================================================================
-- I/O DESCRIPTION
-- ============================================================================
entity debouncer is
generic
(
  RESET_POL       : STD_LOGIC;                  -- Reset active state
  RESET_SYNC      : BOOLEAN;                    -- Use synchronous reset?
  CLOCK_FREQ_MHZ  : REAL;                       -- Clock frequency in MHz
  BLIND_TIME_MS   : REAL := 1.0;                -- Time period (in ms) during which the state of the input is ignored
  IRQ_TRIG_POL    : INTEGER range 0 to 2 := 1;  -- IRQ trigger event: rising edge (0), falling edge (1) or both (2)
  IRQ_DURATION    : INTEGER range 1 to 15 := 1  -- IRQ notification time (in clock cycles)
);
port
( 
  clock     : in STD_LOGIC;
  reset     : in STD_LOGIC; 
  
  button_in : in STD_LOGIC;
  
  state     : out STD_LOGIC;
  state_n   : out STD_LOGIC;
  toggle    : out STD_LOGIC;

  irq       : out STD_LOGIC
);
end debouncer;



-- ============================================================================
-- ARCHITECTURE
-- ============================================================================
architecture archDefault of debouncer is

  type FSM_STATE_TYPE is (FREEZE, WAIT_EVENT);

  signal button_R    : STD_LOGIC;
  signal button_RR   : STD_LOGIC;
  signal button_sync : STD_LOGIC;

  constant TIMER_INIT_VAL : UNSIGNED(31 downto 0) := TO_UNSIGNED(INTEGER(CLOCK_FREQ_MHZ*1000.0*BLIND_TIME_MS)-1, 32);
  signal timer            : STD_LOGIC_VECTOR(31 downto 0);

  signal fsm_state  : FSM_STATE_TYPE;
  signal out_tmp    : STD_LOGIC;

  signal event            : STD_LOGIC;
  signal event_trig       : STD_LOGIC;
  signal event_en         : STD_LOGIC;
  signal event_cycle_cnt  : STD_LOGIC_VECTOR(3 downto 0);
  
begin

  -- --------------------------------------------------------------------------
  -- PROCESS NAME: resynchronizer
  -- DESCRIPTION: 
  -- Bring back the asynchronous input to the synchronous domain.
  -- (3 stages resynchronizer, should be enough for most architectures)
  -- --------------------------------------------------------------------------
  p_sync : process(clock, reset)
  procedure reset_procedure is 
  begin
    button_R    <= '0';
    button_RR   <= '0';
    button_sync <= '0';
  end reset_procedure;
  begin
    if (reset = RESET_POL) and (RESET_SYNC = false) then
      reset_procedure;
    elsif (clock'event and clock = '1') then
      if (reset = RESET_POL) and (RESET_SYNC = true) then
        reset_procedure;
      else
        button_R    <= button_in;
        button_RR   <= button_R;
        button_sync <= button_RR;
      end if;
    end if;
  end process p_sync;



  -- --------------------------------------------------------------------------
  -- Debouncing process
  -- --------------------------------------------------------------------------
  p_debounce : process(clock, reset)
  procedure reset_procedure is 
  begin
    fsm_state   <= WAIT_EVENT;
    timer       <= (others => '0');
    event_trig  <= '0';
    out_tmp     <= '0';
    state       <= '0';
    state_n     <= '0';
  end reset_procedure;
  begin
    if (reset = RESET_POL) and (RESET_SYNC = false) then
      reset_procedure;
    elsif (clock'event and clock = '1') then
      if (reset = RESET_POL) and (RESET_SYNC = true) then
        reset_procedure;
      else
        case fsm_state is 
          
          -- ------------------------------------------------------------------
          -- WAIT_EVENT State
          -- ------------------------------------------------------------------
          when WAIT_EVENT => 
            if (button_sync /= out_tmp) then
              fsm_state <= FREEZE;
              timer <= STD_LOGIC_VECTOR(TIMER_INIT_VAL);
              
              if (IRQ_TRIG_POL = 1) then
                if (out_tmp = '1') and (button_sync = '0') then
                  event_trig <= '1';
                else 
                  event_trig <= '0';
                end if;
              elsif (IRQ_TRIG_POL = 0) then
                if (out_tmp = '0') and (button_sync = '1') then
                  event_trig <= '1';
                else 
                  event_trig <= '0';
                end if;
              else
                event_trig <= '1';
              end if;
            end if;

          -- ------------------------------------------------------------------
          -- FREEZE State
          -- ------------------------------------------------------------------
          when FREEZE => 
            if (timer = STD_LOGIC_VECTOR(to_unsigned(0, timer'length))) then
              fsm_state <= WAIT_EVENT;
              timer <= (others => '0');
              out_tmp <= button_sync;
              event_trig <= '0';
            else
              timer <= STD_LOGIC_VECTOR(UNSIGNED(timer) - 1);
              event_trig <= '0';
            end if;

          -- ------------------------------------------------------------------
          -- Exceptions
          -- ------------------------------------------------------------------
          when others =>
            fsm_state   <= WAIT_EVENT;
            timer       <= (others => '0');
            event_trig  <= '0';
            out_tmp     <= '0';

        end case;

        -- Assign outputs
        state_n <= not(out_tmp);
        state   <= out_tmp;
      end if;
    end if;
  end process p_debounce;



  -- --------------------------------------------------------------------------
  -- Process name: Event handler
  -- Description: 
  -- TODO
  -- --------------------------------------------------------------------------
  p_event : process(clock, reset)
  procedure reset_procedure is 
  begin
    event           <= '0';
    event_en        <= '0';
    event_cycle_cnt <= (others => '0');
  end reset_procedure;
  begin
    if (reset = RESET_POL) and (RESET_SYNC = false) then
      reset_procedure;
    elsif (clock'event and clock = '1') then
      if (reset = RESET_POL) and (RESET_SYNC = true) then
        reset_procedure;
      else
        if (event_en = '0') then
          if (event_trig = '1') then
            event <= '1';
            event_en <= '1';
            event_cycle_cnt <= STD_LOGIC_VECTOR(UNSIGNED(event_cycle_cnt) + 1);
          end if;
        else
          if (event_cycle_cnt = STD_LOGIC_VECTOR(to_unsigned(IRQ_DURATION, event_cycle_cnt'length))) then
            event <= '0';
            event_en <= '0';
            event_cycle_cnt <= (others => '0');
          else
            event_cycle_cnt <= STD_LOGIC_VECTOR(UNSIGNED(event_cycle_cnt) + 1);
          end if;
        end if;
      end if;
    end if;
  end process p_event;

end archDefault;
