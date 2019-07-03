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
		
		CLK800 : out std_logic;
		STROBE800 : out std_logic;
		
		CLK800_180 : out std_logic;
		STROBE800_180 : out std_logic
	);
end clkgen;

architecture Behavioral of clkgen is

	signal ibufg_to_bufio : std_logic;
	signal bufio_to_pll : std_logic;
	signal pll_fb : std_logic;
	signal pll_locked : std_logic;
	signal pll_to_bufg : std_logic;
	signal pll_to_buf1 : std_logic;
	signal pll_to_buf2 : std_logic;
	signal clk : std_logic;
	
begin

   sysclk_ibufg : IBUFG generic map (IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
		port map (
			I => SYSCLK100,
			O => ibufg_to_bufio
		);

   BUFIO2_inst : BUFIO2
   generic map (
      DIVIDE => 1,           -- DIVCLK divider (1,3-8)
      DIVIDE_BYPASS => TRUE, -- Bypass the divider circuitry (TRUE/FALSE)
      I_INVERT => FALSE,     -- Invert clock (TRUE/FALSE)
      USE_DOUBLER => FALSE   -- Use doubler circuitry (TRUE/FALSE)
   )
   port map (
      DIVCLK => bufio_to_pll,             -- 1-bit output: Divided clock output
      IOCLK => open,               -- 1-bit output: I/O output clock
      SERDESSTROBE => open, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      I => ibufg_to_bufio                        -- 1-bit input: Clock input (connect to IBUFG)
   );

   PLL_BASE_inst : PLL_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",             -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT => 8,                   -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output
                                            -- (0.0-360.0).
      CLKIN_PERIOD => 10.0,                  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                            -- MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => 4,
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
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 180.0,
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
      CLKFBOUT => pll_fb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => pll_to_bufg,
      CLKOUT1 => pll_to_buf1,
      CLKOUT2 => pll_to_buf2,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      LOCKED => pll_locked,     -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => pll_fb,   -- 1-bit input: Feedback clock input
      CLKIN => bufio_to_pll,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Reset input
   );

   BUFG_inst : BUFG
   port map (
      O => clk, -- 1-bit output: Clock buffer output
      I => pll_to_bufg  -- 1-bit input: Clock buffer input
   );
	
	CLK200 <= clk;
	
   bufpll1 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => CLK800,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => STROBE800, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => pll_to_buf1                -- 1-bit input: Clock input from PLL
   );
	
   bufpll2 : BUFPLL
   generic map (
      DIVIDE => 4,         -- DIVCLK divider (1-8)
      ENABLE_SYNC => TRUE  -- Enable synchrnonization between PLL and GCLK (TRUE/FALSE)
   )
   port map (
      IOCLK => CLK800_180,               -- 1-bit output: Output I/O clock
      LOCK => open,                 -- 1-bit output: Synchronized LOCK output
      SERDESSTROBE => STROBE800_180, -- 1-bit output: Output SERDES strobe (connect to ISERDES2/OSERDES2)
      GCLK => clk,                 -- 1-bit input: BUFG clock input
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => pll_to_buf2                -- 1-bit input: Clock input from PLL
   );
	

end Behavioral;

