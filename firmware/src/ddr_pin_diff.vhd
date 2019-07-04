----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:12:29 07/02/2019 
-- Design Name: 
-- Module Name:    ddr_pin_diff - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ddr_pin_diff is
	Generic ( 
		IDELAY_VALUE : natural range 0 to 255 := 0;
		ODELAY_VALUE : natural range 0 to 255 := 0
	);
	Port ( 
		CLK : in  STD_LOGIC;
		IOCLK : in std_logic;
		STROBE : in std_logic;
		READING : in std_logic;
		
		BITSLIP : in std_logic;
		
		TXD : in std_logic_vector(3 downto 0);
		RXD : out std_logic_vector(3 downto 0);
		PIN_P : inout std_logic;
		PIN_N : inout std_logic
	);
end ddr_pin_diff;

architecture Behavioral of ddr_pin_diff is

	signal oserdes_to_delay : std_logic;
	signal oserdes_to_delay_t : std_logic;
	signal delay_to_iserdes : std_logic;
	signal delay_to_pin : std_logic;
	signal delay_to_pin_t : std_logic;
	signal pin_to_delay : std_logic;
	
begin

   OSERDES2_inst : OSERDES2
   generic map (
      BYPASS_GCLK_FF => FALSE,       -- Bypass CLKDIV syncronization registers (TRUE/FALSE)
      DATA_RATE_OQ => "SDR",         -- Output Data Rate ("SDR" or "DDR")
      DATA_RATE_OT => "SDR",         -- 3-state Data Rate ("SDR" or "DDR")
      DATA_WIDTH => 4,               -- Parallel data width (2-8)
      OUTPUT_MODE => "SINGLE_ENDED", -- "SINGLE_ENDED" or "DIFFERENTIAL" 
      SERDES_MODE => "NONE",         -- "NONE", "MASTER" or "SLAVE" 
      TRAIN_PATTERN => 0             -- Training Pattern (0-15)
   )
   port map (
      OQ => oserdes_to_delay,               -- 1-bit output: Data output to pad or IODELAY2
      SHIFTOUT1 => open, -- 1-bit output: Cascade data output
      SHIFTOUT2 => open, -- 1-bit output: Cascade 3-state output
      SHIFTOUT3 => open, -- 1-bit output: Cascade differential data output
      SHIFTOUT4 => open, -- 1-bit output: Cascade differential 3-state output
      TQ => oserdes_to_delay_t,               -- 1-bit output: 3-state output to pad or IODELAY2
      CLK0 => IOCLK,           -- 1-bit input: I/O clock input
      CLK1 => '0',           -- 1-bit input: Secondary I/O clock input
      CLKDIV => CLK,       -- 1-bit input: Logic domain clock input
      -- D1 - D4: 1-bit (each) input: Parallel data inputs
      D1 => TXD(3),
      D2 => TXD(2),
      D3 => TXD(1),
      D4 => TXD(0),
      IOCE => STROBE,           -- 1-bit input: Data strobe input
      OCE => '1',             -- 1-bit input: Clock enable input
      RST => '0',             -- 1-bit input: Asynchrnous reset input
      SHIFTIN1 => '0',   -- 1-bit input: Cascade data input
      SHIFTIN2 => '0',   -- 1-bit input: Cascade 3-state input
      SHIFTIN3 => '0',   -- 1-bit input: Cascade differential data input
      SHIFTIN4 => '0',   -- 1-bit input: Cascade differential 3-state input
      -- T1 - T4: 1-bit (each) input: 3-state control inputs
      T1 => READING,
      T2 => READING,
      T3 => READING,
      T4 => READING,
      TCE => '1',             -- 1-bit input: 3-state clock enable input
      TRAIN => '0'          -- 1-bit input: Training pattern enable input
   );
	
	


   IODELAY2_inst : IODELAY2
   generic map (
      COUNTER_WRAPAROUND => "WRAPAROUND", -- "STAY_AT_LIMIT" or "WRAPAROUND" 
      DATA_RATE => "SDR",                 -- "SDR" or "DDR" 
      DELAY_SRC => "IO",                  -- "IO", "ODATAIN" or "IDATAIN" 
      IDELAY2_VALUE => 0,                 -- Delay value when IDELAY_MODE="PCI" (0-255)
      IDELAY_MODE => "NORMAL",            -- "NORMAL" or "PCI" 
      IDELAY_TYPE => "FIXED",           -- "FIXED", "DEFAULT", "VARIABLE_FROM_ZERO", "VARIABLE_FROM_HALF_MAX" 
                                          -- or "DIFF_PHASE_DETECTOR" 
      IDELAY_VALUE => IDELAY_VALUE,                  -- Amount of taps for fixed input delay (0-255)
      ODELAY_VALUE => ODELAY_VALUE,                  -- Amount of taps fixed output delay (0-255)
      SERDES_MODE => "NONE",              -- "NONE", "MASTER" or "SLAVE" 
      SIM_TAPDELAY_VALUE => 75            -- Per tap delay used for simulation in ps
   )
   port map (
      BUSY => open,         -- 1-bit output: Busy output after CAL
      DATAOUT => delay_to_iserdes,   -- 1-bit output: Delayed data output to ISERDES/input register
      DATAOUT2 => open, -- 1-bit output: Delayed data output to general FPGA fabric
      DOUT => delay_to_pin,         -- 1-bit output: Delayed data output
      TOUT => delay_to_pin_t,         -- 1-bit output: Delayed 3-state output
      CAL => '0',           -- 1-bit input: Initiate calibration input
      CE => '0',             -- 1-bit input: Enable INC input
      CLK => '0',           -- 1-bit input: Clock input
      IDATAIN => pin_to_delay,   -- 1-bit input: Data input (connect to top-level port or I/O buffer)
      INC => '0',           -- 1-bit input: Increment / decrement input
      IOCLK0 => '0',     -- 1-bit input: Input from the I/O clock network
      IOCLK1 => '0',     -- 1-bit input: Input from the I/O clock network
      ODATAIN => oserdes_to_delay,   -- 1-bit input: Output data input from output register or OSERDES2.
      RST => '0',           -- 1-bit input: Reset to zero or 1/2 of total delay period
      T => oserdes_to_delay_t                -- 1-bit input: 3-state input signal
   );




   ISERDES2_inst : ISERDES2
   generic map (
      BITSLIP_ENABLE => TRUE,        -- Enable Bitslip Functionality (TRUE/FALSE)
      DATA_RATE => "SDR",             -- Data-rate ("SDR" or "DDR")
      DATA_WIDTH => 4,                -- Parallel data width selection (2-8)
      INTERFACE_TYPE => "RETIMED", -- "NETWORKING", "NETWORKING_PIPELINED" or "RETIMED" 
      SERDES_MODE => "NONE"           -- "NONE", "MASTER" or "SLAVE" 
   )
   port map (
      CFB0 => open,           -- 1-bit output: Clock feed-through route output
      CFB1 => open,           -- 1-bit output: Clock feed-through route output
      DFB => open,             -- 1-bit output: Feed-through clock output
      FABRICOUT => open, -- 1-bit output: Unsynchrnonized data output
      INCDEC => open,       -- 1-bit output: Phase detector output
      -- Q1 - Q4: 1-bit (each) output: Registered outputs to FPGA logic
      Q1 => RXD(3),
      Q2 => RXD(2),
      Q3 => RXD(1),
      Q4 => RXD(0),
      SHIFTOUT => open,   -- 1-bit output: Cascade output signal for master/slave I/O
      VALID => open,         -- 1-bit output: Output status of the phase detector
      BITSLIP => BITSLIP,     -- 1-bit input: Bitslip enable input
      CE0 => '1',             -- 1-bit input: Clock enable input
      CLK0 => IOCLK,           -- 1-bit input: I/O clock network input
      CLK1 => '0',           -- 1-bit input: Secondary I/O clock network input
      CLKDIV => CLK,       -- 1-bit input: FPGA logic domain clock input
      D => delay_to_iserdes,                 -- 1-bit input: Input data
      IOCE => STROBE,           -- 1-bit input: Data strobe input
      RST => '0',             -- 1-bit input: Asynchronous reset input
      SHIFTIN => '0'      -- 1-bit input: Cascade input signal for master/slave I/O
   );




   IOBUF_inst : IOBUFDS
   generic map (
      IOSTANDARD => "DIFF_HSTL_III" -- TODO is this right?
	)
   port map (
      O => pin_to_delay,     -- Buffer output
      IO => PIN_P,   -- Buffer inout port (connect directly to top-level port)
      IOB => PIN_N,   -- Buffer inout port (connect directly to top-level port)
      I => delay_to_pin,     -- Buffer input
      T => delay_to_pin_t      -- 3-state enable input, high=input, low=output 
   );

end Behavioral;

