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
	signal bufio_to_pll : std_logic;
	signal pll_fb : std_logic;
	signal pll_locked : std_logic;
	signal ioclk : std_logic;
	signal ioclk180 : std_logic;
	signal clkout2 : std_logic;
	
	
	signal clk : std_logic;
	
	-- 125MHz system, 500MHz data
	constant PLL_M : natural := 5;
	constant IOCLK_D : natural := 1;
	constant SYSCLK_D : natural := 4;

	-- 100MHz system, 400MHz data
--	constant PLL_M : natural := 8;
--	constant IOCLK_D : natural := 2;
--	constant SYSCLK_D : natural := 8;
	
	-- 50MHz system, 200MHz data
--	constant PLL_M : natural := 8;
--	constant IOCLK_D : natural := 4;
--	constant SYSCLK_D : natural := 16;
begin

	LOCKED <= pll_locked;

   sysclk_ibufg : IBUFG generic map (IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
		port map (
			I => SYSCLK100,
			O => ibufg_to_bufio
		);



   sys_bufio2 : BUFIO2
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

   the_pll : PLL_BASE
   generic map (
      BANDWIDTH => "OPTIMIZED",             -- "HIGH", "LOW" or "OPTIMIZED" 
      CLKFBOUT_MULT => PLL_M,                   -- Multiply value for all CLKOUT clock outputs (1-64)
      CLKFBOUT_PHASE => 0.0,                -- Phase offset in degrees of the clock feedback output
                                            -- (0.0-360.0).
      CLKIN_PERIOD => 10.0,                  -- Input clock period in ns to ps resolution (i.e. 33.333 is 30
                                            -- MHz).
      -- CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for CLKOUT# clock output (1-128)
      CLKOUT0_DIVIDE => IOCLK_D, -- serdes clock
      CLKOUT1_DIVIDE => IOCLK_D, -- serdes clock (180deg)
      CLKOUT2_DIVIDE => SYSCLK_D, -- system clock
      CLKOUT3_DIVIDE => 1, -- forwarded clock to second pll
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
      CLKFBOUT => pll_fb, -- 1-bit output: PLL_BASE feedback output
      -- CLKOUT0 - CLKOUT5: 1-bit (each) output: Clock outputs
      CLKOUT0 => ioclk,
      CLKOUT1 => ioclk180,
      CLKOUT2 => clkout2,
      CLKOUT3 => open,
      CLKOUT4 => open,
      CLKOUT5 => open,
      LOCKED => pll_locked,     -- 1-bit output: PLL_BASE lock status output
      CLKFBIN => pll_fb,   -- 1-bit input: Feedback clock input
      CLKIN => bufio_to_pll,       -- 1-bit input: Clock input
      RST => '0'            -- 1-bit input: Reset input
   );

   sys_bufg : BUFG
   port map (
      O => clk, -- 1-bit output: Clock buffer output
      I => clkout2  -- 1-bit input: Clock buffer input
   );
	
	CLK200 <= clk;
	
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk                -- 1-bit input: Clock input from PLL
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk180                -- 1-bit input: Clock input from PLL
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk                -- 1-bit input: Clock input from PLL
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk180                -- 1-bit input: Clock input from PLL
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk                -- 1-bit input: Clock input from PLL
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
      LOCKED => pll_locked,             -- 1-bit input: LOCKED input from PLL
      PLLIN => ioclk180                -- 1-bit input: Clock input from PLL
   );
	

end Behavioral;

