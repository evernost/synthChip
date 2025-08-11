-- ============================================================================
-- Project        : synthChip
-- Module name    : uart
-- File name      : uart.vhd
-- File type      : VHDL 2008
-- Purpose        : simple UART module
-- Author         : QuBi (nitrogenium@outlook.fr)
-- Creation date  : August 10th, 2025
-- ----------------------------------------------------------------------------
-- Best viewed with space indentation (2 spaces)
-- ============================================================================

-- ============================================================================
-- DESCRIPTION
-- ============================================================================
-- Simple UART PHY module.
-- This module handles the very low level of the UART link to retrieve the data byte and
-- send it.
-- There is a consistency check that is made in the UART read transaction to make sure
-- that the baudrate is correct.



-- ============================================================================
-- LIBRARIES
-- ============================================================================
-- Standard libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Project libraries
-- None.



-- ============================================================================
-- I/O DESCRIPTION
-- ============================================================================
entity uart is
  generic
  (
    G_SYNC_RESET      : STD_LOGIC := '1';
    G_RESET_POL       : STD_LOGIC := '1'; -- Defines the reset active state
    G_CLOCK_FREQ      : REAL := 100.0;    -- Master clock frequency in MHz
    G_BAUDRATE        : REAL := 115200.0; -- UART transmission baudrate
    G_MSB_FIRST       : STD_LOGIC := '0'; -- bit ordering in the UART frame: '0' = LSB first, '1' = MSB first
    G_PHY_IDLE_STATE  : STD_LOGIC := '1'  -- UART physical link idle state (i.e. define here if polariy is reversed)
  );
  port
  ( 
    -- Main signals
    Clock           : in STD_LOGIC;
    Reset           : in STD_LOGIC;
    
    -- UART physical link
    UART_in         : in STD_LOGIC;
    UART_out        : out STD_LOGIC;
    
    -- Data interface
    RX_data         : out STD_LOGIC_VECTOR(7 downto 0);
    RX_data_valid   : out STD_LOGIC;
    
    TX_data         : in STD_LOGIC_VECTOR(7 downto 0);
    TX_data_valid   : in STD_LOGIC;
    TX_ready        : out STD_LOGIC;
    
    -- Flags
    RX_frame_error  : out STD_LOGIC
  );
end uart;



-- ============================================================================
-- ARCHITECTURE
-- ============================================================================
architecture archDefault of uart is

  -- -----
  -- Types 
  -- -----
  type RX_STATE_TYPE            is (RX_INIT, RX_BIT_SAMPLING, RX_SAMPLING_DONE);
  type TX_STATE_TYPE            is (TX_INIT, TX_TRANSMIT);

  -- ---------
  -- Constants
  -- ---------
  constant SAMPLE_TIMER_THRESH  : STD_LOGIC_VECTOR(31 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(INTEGER((10.0**6)*(G_CLOCK_FREQ/(4.0*G_BAUDRATE)))-1,32));
  constant N_BITS               : NATURAL                       := 10;  -- start bit + 1 byte + stop bit
  constant BIT_INDEX_THRESH     : STD_LOGIC_VECTOR(3 downto 0)  := STD_LOGIC_VECTOR(TO_UNSIGNED(N_BITS-1,4));
  constant RX_BUFFER_SIZE       : NATURAL                       := 3*N_BITS;
  constant TX_BIT_TIMER_THRESH  : STD_LOGIC_VECTOR(31 downto 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(INTEGER((10.0**6)*(G_CLOCK_FREQ/G_BAUDRATE))-1,32));

  -- ---------
  -- Functions
  -- ---------
  function mirror(input_vect  : STD_LOGIC_VECTOR)
  return STD_LOGIC_VECTOR is
  variable tmp : STD_LOGIC_VECTOR((input_vect'LENGTH-1) downto 0) := (others => '0');
  begin
    for k in 0 to (input_vect'LENGTH-1) loop
      tmp((input_vect'LENGTH-1) - k) := input_vect(k);
    end loop;
    return tmp;
  end mirror;

  -- ----------------
  -- Internal signals
  -- ----------------
  signal UART_in_R              : STD_LOGIC;
  signal UART_in_R_R            : STD_LOGIC;
  signal UART_in_R_R_R          : STD_LOGIC;

  -- RX FSM signals
  signal RX_state               : RX_STATE_TYPE;
  signal sample_timer           : STD_LOGIC_VECTOR(31 downto 0);
  signal sample_count           : STD_LOGIC_VECTOR(1 downto 0);
  signal RX_buffer              : STD_LOGIC_VECTOR((RX_BUFFER_SIZE-1) downto 0);
  signal bit_index              : STD_LOGIC_VECTOR(3 downto 0);
  signal sampling_done          : STD_LOGIC;

  signal framing_err_vector     : STD_LOGIC_VECTOR((N_BITS-1) downto 0);
  signal RX_buffer_proc         : STD_LOGIC_VECTOR((N_BITS-1) downto 0);

  -- TX FSM signals 
  signal TX_state               : TX_STATE_TYPE;
  signal TX_buffer              : STD_LOGIC_VECTOR((N_BITS-1) downto 0);
  signal TX_bit_count           : STD_LOGIC_VECTOR((N_BITS-1) downto 0);
  signal TX_bit_timer           : STD_LOGIC_VECTOR(31 downto 0);
  signal UART_out_buffer        : STD_LOGIC; 

begin

  
  UART_out <= UART_out_buffer;
  
  
  -- --------------------------------------------------------------------------
  -- UART input resynchronisation
  -- --------------------------------------------------------------------------
  UART_in_resync_proc : process(Clock, Reset)
  procedure reset_proc is
  begin
    UART_in_R     <= G_PHY_IDLE_STATE;
    UART_in_R_R   <= G_PHY_IDLE_STATE;
    UART_in_R_R_R <= G_PHY_IDLE_STATE;
  end procedure;
  
	begin
		if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '0')) then
      reset_proc;
		elsif(Clock'event and Clock = '1') then
			if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '1')) then
        reset_proc;
      else
        UART_in_R     <= UART_in;
        UART_in_R_R   <= UART_in_R;
        UART_in_R_R_R <= UART_in_R_R;
      end if;
		end if;
	end process UART_in_resync_proc;
  
  
  
  -- --------------------------------------------------------------------------
  -- UART receiver sampling machine
  -- --------------------------------------------------------------------------
  UART_RX_FSM_proc : process(Clock, Reset)
  procedure reset_proc is
  begin
    RX_state      <= RX_INIT;
    sample_count  <= "00";
    sample_timer  <= SAMPLE_TIMER_THRESH;
    bit_index     <= (others => '0');
    RX_buffer     <= (others => '0');
    sampling_done <= '0';
  end procedure;
  
	begin
		if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '0')) then
      reset_proc;
		elsif(Clock'event and Clock = '1') then
			if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '1')) then
        reset_proc;
      else
        case(RX_state) is 
          -- ------------------------------------------------------------------
          when RX_INIT =>
            if ((UART_in_R_R = not(G_PHY_IDLE_STATE)) and (UART_in_R_R_R = G_PHY_IDLE_STATE)) then
              -- UART state just changed, start sampling procedure.
              RX_state      <= RX_BIT_SAMPLING;
              sample_count  <= "00";
              sample_timer  <= SAMPLE_TIMER_THRESH - 1;
              bit_index     <= (others => '0');
              RX_buffer     <= RX_buffer;
              sampling_done <= '0';
            else
              -- No activity detected on UART.
              RX_state      <= RX_INIT;
              sample_count  <= "00";
              sample_timer  <= SAMPLE_TIMER_THRESH;
              bit_index     <= (others => '0');
              RX_buffer     <= RX_buffer;
              sampling_done <= '0';
            end if;
          -- ------------------------------------------------------------------
          when RX_BIT_SAMPLING =>
            if (sample_timer = 0) then
              -- It's time for sampling the bit status
              if (bit_index = BIT_INDEX_THRESH) then
                -- The bit we are about to sample is the last
                if (sample_count = "10") then             -- stop at the last sampling point
                  RX_state      <= RX_SAMPLING_DONE;      -- to avoid missing the next falling edge.
                  sample_count  <= "00";
                  sample_timer  <= SAMPLE_TIMER_THRESH;
                  bit_index     <= (others => '0');
                  
                  if (G_MSB_FIRST = '0') then
                    RX_buffer <= (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE))) & RX_buffer((RX_BUFFER_SIZE-1) downto 1);
                  else
                    RX_buffer <= RX_buffer((RX_BUFFER_SIZE-2) downto 0) & (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE)));
                  end if;
                  
                  sampling_done <= '0';
                else
                  RX_state      <= RX_BIT_SAMPLING;
                  sample_count  <= sample_count + 1;
                  sample_timer  <= SAMPLE_TIMER_THRESH;
                  bit_index     <= bit_index;
                  
                  if (G_MSB_FIRST = '0') then
                    RX_buffer <= (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE))) & RX_buffer((RX_BUFFER_SIZE-1) downto 1);
                  else
                    RX_buffer <= RX_buffer((RX_BUFFER_SIZE-2) downto 0) & (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE)));
                  end if;
                  
                  sampling_done <= '0';
                end if;
              else
                -- Regular bit sampling
                if (sample_count = "11") then
                  -- 3 samples points were already taken.
                  -- Now, we don't sample, we move to the next bit.
                  RX_state      <= RX_BIT_SAMPLING;
                  sample_count  <= (others => '0');
                  sample_timer  <= SAMPLE_TIMER_THRESH;
                  bit_index     <= bit_index + 1;
                  RX_buffer     <= RX_buffer;
                  sampling_done <= '0';
                else
                  RX_state      <= RX_BIT_SAMPLING;
                  sample_count  <= sample_count + 1;
                  sample_timer  <= SAMPLE_TIMER_THRESH;
                  
                  -- Sampling point was reached. Push the UART value in the stack
                  if (G_MSB_FIRST = '0') then
                    RX_buffer <= (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE))) & RX_buffer((RX_BUFFER_SIZE-1) downto 1);
                  else
                    RX_buffer <= RX_buffer((RX_BUFFER_SIZE-2) downto 0) & (UART_in_R_R_R xor (not(G_PHY_IDLE_STATE)));
                  end if;
                  
                  sampling_done <= '0';
                end if;
              end if;
            else
              -- Keep increasing the counter until we reach the sampling point.
              RX_state      <= RX_BIT_SAMPLING;
              sample_count  <= sample_count;
              sample_timer  <= sample_timer - 1;
              bit_index     <= bit_index;
              RX_buffer     <= RX_buffer;
              sampling_done <= '0';
            end if;
          -- ------------------------------------------------------------------
          when RX_SAMPLING_DONE =>
            RX_state      <= RX_INIT;
            sample_count  <= "00";
            sample_timer  <= SAMPLE_TIMER_THRESH;
            bit_index     <= (others => '0');
            RX_buffer     <= RX_buffer;
            sampling_done <= '1';
          -- ------------------------------------------------------------------
          when others =>
            RX_state      <= RX_INIT;
            sample_count  <= "00";
            sample_timer  <= SAMPLE_TIMER_THRESH;
            bit_index     <= (others => '0');
            RX_buffer     <= (others => '0');
            sampling_done <= '0';
          -- ------------------------------------------------------------------
        end case;
      end if;
		end if;
	end process UART_RX_FSM_proc;

  RX_outputs_gen : for i in 0 to (N_BITS-1) generate
    -- Declare that there is no framing error when the 3 samples of each bit agree on the value.
    framing_err_vector(i) <=  '0' when ((RX_buffer((3*i)+0) = '1') and (RX_buffer((3*i)+1) = '1') and (RX_buffer((3*i)+2) = '1')) else
                              '0' when ((RX_buffer((3*i)+0) = '0') and (RX_buffer((3*i)+1) = '0') and (RX_buffer((3*i)+2) = '0')) else
                              '1';
    RX_buffer_proc(i) <= RX_buffer((3*i)+1);  -- keep the middle sample
  end generate RX_outputs_gen;
  
  RX_output_proc : process(Clock, Reset)
  procedure reset_proc is
  begin
    RX_frame_error  <= '0';
    RX_data         <= (others => '0');
    RX_data_valid   <= '0';
  end procedure;
  
	begin
		if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '0')) then
      reset_proc;
		elsif(Clock'event and Clock = '1') then
			if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '1')) then
        reset_proc;
      else
        if (sampling_done = '1') then
          if (UNSIGNED(framing_err_vector) > 0) then
            RX_frame_error <= '1';
          end if;
          
          -- Drop the start & stop bits
          if (G_MSB_FIRST = '0') then
            RX_data <= RX_buffer_proc(8 downto 1);
          else
            RX_data <= RX_buffer_proc((N_BITS-2) downto (N_BITS-9));
          end if;
        end if;
        
        RX_data_valid <= sampling_done;
      end if;
		end if;
	end process RX_output_proc;
  
  -- ------------------------------
  -- UART transmitter state machine
  -- ------------------------------
  UART_TX_FSM_proc : process(Clock, Reset)
  procedure reset_proc is
  begin
    TX_state        <= TX_INIT;
    TX_buffer       <= (others => '0');
    TX_ready        <= '0';
    TX_bit_timer    <= (others => '0');
    TX_bit_count    <= (others => '0');
    UART_out_buffer <= G_PHY_IDLE_STATE;
  end procedure;
  
	begin
		if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '0')) then
      reset_proc;
		elsif(Clock'event and Clock = '1') then
			if ((Reset = G_RESET_POL) and (G_SYNC_RESET = '1')) then
        reset_proc;
      else
        case(TX_state) is 
          -- ------------------------------------------------------------------
          when TX_INIT =>
            if (TX_data_valid = '1') then 
              TX_state  <= TX_TRANSMIT;
              
              -- Fetch the data buffer and add the start and stop bits
              if (G_MSB_FIRST = '0') then
                TX_buffer <= '1' & TX_data & '0';
              else
                TX_buffer <= '1' & mirror(TX_data) & '0';
              end if;
              
              TX_ready        <= '0';               -- Transmitter is not ready any more
              TX_bit_timer    <= (others => '0');
              TX_bit_count    <= (others => '0');
              UART_out_buffer <= not(G_PHY_IDLE_STATE);
            else
              TX_state        <= TX_INIT;
              TX_buffer       <= (others => '0');
              TX_ready        <= '1';
              TX_bit_timer    <= (others => '0');
              TX_bit_count    <= (others => '0');
              UART_out_buffer <= G_PHY_IDLE_STATE;
            end if;
          -- ------------------------------------------------------------------
          when TX_TRANSMIT =>
            if (TX_bit_timer = TX_BIT_TIMER_THRESH) then
              if (TX_bit_count = (N_BITS-1)) then 
                TX_state        <= TX_INIT;
                TX_buffer       <= (others => '0');
                TX_ready        <= '1';             -- Transmission done, TX ready for a new data.
                TX_bit_timer    <= (others => '0');
                TX_bit_count    <= (others => '0');
                UART_out_buffer <= G_PHY_IDLE_STATE;
              else
                TX_state        <= TX_TRANSMIT;
                TX_buffer       <= '0' & TX_buffer(TX_buffer'left downto 1);
                TX_ready        <= '0';
                TX_bit_timer    <= (others => '0');
                TX_bit_count    <= TX_bit_count + 1;
                
                if (G_PHY_IDLE_STATE = '1') then
                  UART_out_buffer <= TX_buffer(1);
                else
                  UART_out_buffer <= not(TX_buffer(1));
                end if;
              end if;
            else
              TX_state        <= TX_TRANSMIT;
              TX_buffer       <= TX_buffer;
              TX_ready        <= '0';
              TX_bit_timer    <= TX_bit_timer + 1;
              TX_bit_count    <= TX_bit_count;
              
              if (G_PHY_IDLE_STATE = '1') then
                UART_out_buffer <= TX_buffer(0);
              else
                UART_out_buffer <= not(TX_buffer(0));
              end if;
            end if;
          -- ------------------------------------------------------------------
          when others =>
            TX_state        <= TX_INIT;
            TX_buffer       <= (others => '0');
            TX_ready        <= '1';
            TX_bit_timer    <= (others => '0');
            TX_bit_count    <= (others => '0');
            UART_out_buffer <= G_PHY_IDLE_STATE;
          -- ------------------------------------------------------------------
        end case;
      end if;
		end if;
	end process UART_TX_FSM_proc;

end archDefault;
