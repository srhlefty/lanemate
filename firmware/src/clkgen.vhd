----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:41:37 07/02/2019 
-- Design Name: 
-- Module Name:    clkgen - Behavioral 
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

entity clkgen is
	Port ( 
		SYSCLK100 : in STD_LOGIC;
		
		CLK200 : out STD_LOGIC;
		
		B0_CLK800 : out std_logic;
		B0_STROBE800 : out std_logic;
		B0_CLK800_180 : out std_logic;
		B0_STROBE800_180 : out std_logic;

		B1_CLK800 : out std_logic;
		B1_STROBE800 : out std_logic;
		B1_CLK800_180 : out std_logic;
		B1_STROBE800_180 : out std_logic;

		B3_CLK800 : out std_logic;
		B3_STROBE800 : out std_logic;
		B3_CLK800_180 : out std_logic;
		B3_STROBE800_180 : out std_logic;
		
		LOCKED : out std_logic
	);
end clkgen;

architecture Behavioral of clkgen is

	signal ibufg_to_bufio : std_logic;
	
	signal b0_bufio_to_pll : std_logic;
	signal b0_pll_fb : std_logic;
	signal b0_pll_locked : std_logic;
	signal b0_pll_to_bufg : std_logic;
	signal b0_pll_to_bufg2 : std_logic;
	signal b0_pll_to_buf1 : std_logic;
	signal b0_pll_to_buf2 : std_logic;
	
	signal b1_bufio_to_pll : std_logic;
	signal b1_pll_fb : std_logic;
	signal b1_pll_locked : std_logic;
	signal b1_pll_to_buf1 : std_logic;
	signal b1_pll_to_buf2 : std_logic;
	
	signal b3_bufio_to_pll : std_logic;
	signal b3_pll_fb : std_logic;
	signal b3_pll_locked : std_logic;
	signal b3_pll_to_bufg : std_logic;
	signal b3_pll_to_buf1 : std_logic;
	signal b3_pll_to_buf2 : std_logic;
	
	signal clk : std_logic;
	signal b0_pll_to_b1_pll : std_logic;
	
begin

	LOCKED <= b0_pll_locked and b1_pll_locked and b3_pll_locked;

   sysclk_ibufg : IBUFG generic map (IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
		port map (
			I => SYSCLK100,
			O => ibufg_to_bufio
		);





   bank0_BUFIO2 : BUFIO2
   generic map (
      DIVIDE => 1,           -- DIVCLK divider (1,3-8)
      DIVIDE_BYPASS => TRUE, -- Bypass the divider circuitry (TRUE/FALSE)
      I_INVERT => FALSE,     -- Invert clock (TRUE/FALSE)
      USE_DOUBLER => FALSE   -- Use doubler circuitry (TRUE/FALSE)
   )
   port map (
      DIVCLK => b0_bufio_to_pll,             -- 1-bit output: Divided clock output
      IOCLK => open,               -- 1-bit output: I/O output clock
      SERDESSTROBE => open, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      I => ibufg_to_bufio                        -- 1-bit input: Clock input (connect to IBUFG)
   );

   bank0_PLL_BASE : PLL_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",             -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT => 8,                   -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output
                                            -- (0.0-360.0).
      CLKIN_PERIOD => 10.0,                  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                            -- MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => 1,
      CLKOUT1_DIVIDE => 1,
      CLKOUT2_DIVIDE => 4,
      CLKOUT3_DIVIDE => 8,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 180.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLK_FEEDBACK => "CLKFBOUT",           -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      COMPENSATION => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
      DIVCLK_DIVIDE => 1,                   -- Division value for all output clocks (1-52)
      REF_JITTER => 0.1,                    -- Reference Clock Jitter in UI (0.000-0.999).
      RESET_ON_LOSS_OF_LOCK => FALSE        -- Must be set to FALSE
   )
   port map (
      CLKFBOUT => b0_pll_fb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => b0_pll_to_buf1,
      CLKOUT1 => b0_pll_to_buf2,
      CLKOUT2 => b0_pll_to_bufg,
      CLKOUT3 => b0_pll_to_bufg2,
      CLKOUT4 => open,
      CLKOUT5 => open,
      LOCKED => b0_pll_locked,     -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => b0_pll_fb,   -- 1-bit input: Feedback clock input
      CLKIN => b0_bufio_to_pll,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Reset input
   );

   bank0_BUFG1 : BUFG
   port map (
      O => clk, -- 1-bit output: Clock buffer output
      I => b0_pll_to_bufg  -- 1-bit input: Clock buffer input
   );
	
	CLK200 <= clk;
	
   bank0_BUFG2 : BUFG
   port map (
      O => b0_pll_to_b1_pll, -- 1-bit output: Clock buffer output
      I => b0_pll_to_bufg2  -- 1-bit input: Clock buffer input
   );
	
	
   bank0_bufpll1 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B0_CLK800,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B0_STROBE800, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b0_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b0_pll_to_buf1                -- 1-bit input: Clock input from PLL
   );
	
   bank0_bufpll2 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B0_CLK800_180,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B0_STROBE800_180, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b0_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b0_pll_to_buf2                -- 1-bit input: Clock input from PLL
   );
	




	-- The way the BUFGMUX's work out, I can directly feed SYSCLK into the bank 0 and bank 3 PLLs.
	-- But there isn't a way to also route directly into the bank 1 PLL.
	-- To get around this, I essentially transfer SYSCLK to another BUFGMUX area by feeding it
	-- through bank 0's PLL with a M/D of 1. Clearly in that situation a BUFIO2 is not needed.

   bank1_PLL_BASE : PLL_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",             -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT => 8,                   -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output
                                            -- (0.0-360.0).
      CLKIN_PERIOD => 10.0,                  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                            -- MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => 1,
      CLKOUT1_DIVIDE => 1,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 180.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLK_FEEDBACK => "CLKFBOUT",           -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      COMPENSATION => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
      DIVCLK_DIVIDE => 1,                   -- Division value for all output clocks (1-52)
      REF_JITTER => 0.1,                    -- Reference Clock Jitter in UI (0.000-0.999).
      RESET_ON_LOSS_OF_LOCK => FALSE        -- Must be set to FALSE
   )
   port map (
      CLKFBOUT => b1_pll_fb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => b1_pll_to_buf1,
      CLKOUT1 => b1_pll_to_buf2,
      CLKOUT2 => open,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      LOCKED => b1_pll_locked,     -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => b1_pll_fb,   -- 1-bit input: Feedback clock input
      CLKIN => b0_pll_to_b1_pll,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Reset input
   );


   bank1_bufpll1 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B1_CLK800,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B1_STROBE800, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b1_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b1_pll_to_buf1                -- 1-bit input: Clock input from PLL
   );
	
   bank1_bufpll2 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B1_CLK800_180,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B1_STROBE800_180, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b1_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b1_pll_to_buf2                -- 1-bit input: Clock input from PLL
   );
	





   bank3_BUFIO2 : BUFIO2
   generic map (
      DIVIDE => 1,           -- DIVCLK divider (1,3-8)
      DIVIDE_BYPASS => TRUE, -- Bypass the divider circuitry (TRUE/FALSE)
      I_INVERT => FALSE,     -- Invert clock (TRUE/FALSE)
      USE_DOUBLER => FALSE   -- Use doubler circuitry (TRUE/FALSE)
   )
   port map (
      DIVCLK => b3_bufio_to_pll,             -- 1-bit output: Divided clock output
      IOCLK => open,               -- 1-bit output: I/O output clock
      SERDESSTROBE => open, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      I => ibufg_to_bufio                        -- 1-bit input: Clock input (connect to IBUFG)
   );

   bank3_PLL_BASE : PLL_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",             -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT => 8,                   -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output
                                            -- (0.0-360.0).
      CLKIN_PERIOD => 10.0,                  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                            -- MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => 1,
      CLKOUT1_DIVIDE => 1,
      CLKOUT2_DIVIDE => 1,
      CLKOUT3_DIVIDE => 1,
      CLKOUT4_DIVIDE => 1,
      CLKOUT5_DIVIDE => 1,
      -- CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for CLKOUT# clock output (0.01-0.99).
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      -- CLKOUT0_PHASE - CLKOUT5_PHASE: Output phase relationship for CLKOUT# clock output (-360.0-360.0).
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 180.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLK_FEEDBACK => "CLKFBOUT",           -- Clock source to drive CLKFBIN ("CLKFBOUT" or "CLKOUT0")
      COMPENSATION => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRONOUS", "SOURCE_SYNCHRONOUS", "EXTERNAL" 
      DIVCLK_DIVIDE => 1,                   -- Division value for all output clocks (1-52)
      REF_JITTER => 0.1,                    -- Reference Clock Jitter in UI (0.000-0.999).
      RESET_ON_LOSS_OF_LOCK => FALSE        -- Must be set to FALSE
   )
   port map (
      CLKFBOUT => b3_pll_fb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => b3_pll_to_buf1,
      CLKOUT1 => b3_pll_to_buf2,
      CLKOUT2 => open,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      LOCKED => b3_pll_locked,     -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => b3_pll_fb,   -- 1-bit input: Feedback clock input
      CLKIN => b3_bufio_to_pll,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Reset input
   );

   bank3_bufpll1 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B3_CLK800,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B3_STROBE800, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b3_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b3_pll_to_buf1                -- 1-bit input: Clock input from PLL
   );
	
   bank3_bufpll2 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => B3_CLK800_180,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => B3_STROBE800_180, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => b3_pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => b3_pll_to_buf2                -- 1-bit input: Clock input from PLL
   );
	

end Behavioral;

