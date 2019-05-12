----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:53:34 05/10/2019 
-- Design Name: 
-- Module Name:    programmable_clock - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity programmable_clock is
	Port ( 
		CLK : in std_logic;
		SEL : in std_logic_vector(1 downto 0); -- 00=27M, 01=74.25M, 10=148.5M
		DCM1_LOCKED : out std_logic;
		DCM2_LOCKED : out std_logic;
		CLKOUT : out std_logic
);
end programmable_clock;

architecture Behavioral of programmable_clock is

	signal locked1 : std_logic;
	signal locked2 : std_logic;
	signal clktmp : std_logic;
	
	signal clk_1080p : std_logic;
	signal clk_720p : std_logic;
	signal clk_480i : std_logic;
	
	type rom_t is array(0 to 3) of natural;
	signal mvalues : rom_t := (2,  27, 124, 248);
	signal dvalues : rom_t := (2, 100, 167, 167);

begin

   hd_dcm : DCM_CLKGEN
   generic map (
      CLKFXDV_DIVIDE => 2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
      CLKFX_DIVIDE => 167,         -- Divide value - D - (1-256)
      CLKFX_MD_MAX => 1.5,       -- Specify maximum M/D ratio for timing anlysis
      CLKFX_MULTIPLY => 248,       -- Multiply value - M - (2-256)
      CLKIN_PERIOD => 10.0,       -- Input clock period specified in nS
      SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
                                 -- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
      STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
   )
   port map (
      CLKFX => clk_1080p,         -- 1-bit output: Generated clock output
      CLKFX180 => open,   -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
      CLKFXDV => clk_720p,     -- 1-bit output: Divided clock output
      LOCKED => DCM1_LOCKED,       -- 1-bit output: Locked output
      PROGDONE => open,   -- 1-bit output: Active high output to indicate the successful re-programming
      STATUS => open,       -- 2-bit output: DCM_CLKGEN status
      CLKIN => CLK,         -- 1-bit input: Input clock
      FREEZEDCM => '0', -- 1-bit input: Prevents frequency adjustments to input clock
      PROGCLK => '0',     -- 1-bit input: Clock input for M/D reconfiguration
      PROGDATA => '0',   -- 1-bit input: Serial data input for M/D reconfiguration
      PROGEN => '0',       -- 1-bit input: Active high program enable
      RST => '0'              -- 1-bit input: Reset input pin
   );
	
	
   sd_dcm : DCM_CLKGEN
   generic map (
      CLKFXDV_DIVIDE => 2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
      CLKFX_DIVIDE => 100,         -- Divide value - D - (1-256)
      CLKFX_MD_MAX => 1.5,       -- Specify maximum M/D ratio for timing anlysis
      CLKFX_MULTIPLY => 27,       -- Multiply value - M - (2-256)
      CLKIN_PERIOD => 10.0,       -- Input clock period specified in nS
      SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
                                 -- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
      STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
   )
   port map (
      CLKFX => clk_480i,         -- 1-bit output: Generated clock output
      CLKFX180 => open,   -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
      CLKFXDV => open,     -- 1-bit output: Divided clock output
      LOCKED => DCM2_LOCKED,       -- 1-bit output: Locked output
      PROGDONE => open,   -- 1-bit output: Active high output to indicate the successful re-programming
      STATUS => open,       -- 2-bit output: DCM_CLKGEN status
      CLKIN => CLK,         -- 1-bit input: Input clock
      FREEZEDCM => '0', -- 1-bit input: Prevents frequency adjustments to input clock
      PROGCLK => '0',     -- 1-bit input: Clock input for M/D reconfiguration
      PROGDATA => '0',   -- 1-bit input: Serial data input for M/D reconfiguration
      PROGEN => '0',       -- 1-bit input: Active high program enable
      RST => '0'              -- 1-bit input: Reset input pin
   );

   clkmux1 : BUFGMUX
   generic map (
      CLK_SEL_TYPE => "SYNC"  -- Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   port map (
      O => clktmp,   -- 1-bit output: Clock buffer output
      I0 => clk_480i, -- 1-bit input: Clock buffer input (S=0)
      I1 => clk_720p, -- 1-bit input: Clock buffer input (S=1)
      S => SEL(0)    -- 1-bit input: Clock buffer select
   );
	
   clkmux2 : BUFGMUX
   generic map (
      CLK_SEL_TYPE => "SYNC"  -- Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   port map (
      O => CLKOUT,   -- 1-bit output: Clock buffer output
      I0 => clktmp, -- 1-bit input: Clock buffer input (S=0)
      I1 => clk_1080p, -- 1-bit input: Clock buffer input (S=1)
      S => SEL(1)    -- 1-bit input: Clock buffer select
   );

end Behavioral;

