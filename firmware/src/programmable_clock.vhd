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
		PROGCLK : in std_logic;
		SEL : in std_logic_vector(1 downto 0); -- 00=100M, 01=27M, 10=74.25M, 11=148.5M
		CLKOUT : out std_logic
);
end programmable_clock;

architecture Behavioral of programmable_clock is

	COMPONENT dcmspi
	PORT(
		RST : IN std_logic;
		PROGCLK : IN std_logic;
		PROGDONE : IN std_logic;
		DFSLCKD : IN std_logic;
		M : IN std_logic_vector(7 downto 0);
		D : IN std_logic_vector(7 downto 0);
		GO : IN std_logic;          
		BUSY : OUT std_logic;
		PROGEN : OUT std_logic;
		PROGDATA : OUT std_logic
		);
	END COMPONENT;

	signal locked : std_logic;
	signal progdone : std_logic;
	signal progdata : std_logic;
	signal progen : std_logic;
	
	signal clkfx : std_logic;
	
	signal rst : std_logic := '0';
	signal go : std_logic := '0';
	signal busy : std_logic;
	
	type rom_t is array(0 to 3) of natural;
	signal mvalues : rom_t := (2,  27, 124, 248);
	signal dvalues : rom_t := (2, 100, 167, 167);
	signal m : std_logic_vector(7 downto 0);
	signal d : std_logic_vector(7 downto 0);
	signal sel_old : std_logic_vector(1 downto 0) := "11";
begin

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		sel_old <= SEL;
		if(to_integer(unsigned(SEL)) /= to_integer(unsigned(sel_old))) then
			go <= '1';
		else
			go <= '0';
		end if;
	end if;
	end process;
	
	with SEL select m <=
		std_logic_vector(to_unsigned(mvalues(0),8)) when "00",
		std_logic_vector(to_unsigned(mvalues(1),8)) when "01",
		std_logic_vector(to_unsigned(mvalues(2),8)) when "10",
		std_logic_vector(to_unsigned(mvalues(3),8)) when "11",
		std_logic_vector(to_unsigned(mvalues(0),8)) when others;
		
	with SEL select d <=
		std_logic_vector(to_unsigned(dvalues(0),8)) when "00",
		std_logic_vector(to_unsigned(dvalues(1),8)) when "01",
		std_logic_vector(to_unsigned(dvalues(2),8)) when "10",
		std_logic_vector(to_unsigned(dvalues(3),8)) when "11",
		std_logic_vector(to_unsigned(dvalues(0),8)) when others;
		

	Inst_dcmspi: dcmspi PORT MAP(
		RST => rst,
		PROGCLK => PROGCLK,
		PROGDONE => progdone,
		DFSLCKD => locked,
		M => m,
		D => d,
		GO => go,
		BUSY => busy,
		PROGEN => progen,
		PROGDATA => progdata
	);
	
   DCM_CLKGEN_inst : DCM_CLKGEN
   generic map (
      CLKFXDV_DIVIDE => 2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
      CLKFX_DIVIDE => 21,         -- Divide value - D - (1-256)
      CLKFX_MD_MAX => 1.5,       -- Specify maximum M/D ratio for timing anlysis
      CLKFX_MULTIPLY => 31,       -- Multiply value - M - (2-256)
      CLKIN_PERIOD => 10.0,       -- Input clock period specified in nS
      SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
                                 -- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
      STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
   )
   port map (
      CLKFX => clkfx,         -- 1-bit output: Generated clock output
      CLKFX180 => open,   -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
      CLKFXDV => open,     -- 1-bit output: Divided clock output
      LOCKED => locked,       -- 1-bit output: Locked output
      PROGDONE => progdone,   -- 1-bit output: Active high output to indicate the successful re-programming
      STATUS => open,       -- 2-bit output: DCM_CLKGEN status
      CLKIN => CLK,         -- 1-bit input: Input clock
      FREEZEDCM => '0', -- 1-bit input: Prevents frequency adjustments to input clock
      PROGCLK => PROGCLK,     -- 1-bit input: Clock input for M/D reconfiguration
      PROGDATA => progdata,   -- 1-bit input: Serial data input for M/D reconfiguration
      PROGEN => PROGEN,       -- 1-bit input: Active high program enable
      RST => '0'              -- 1-bit input: Reset input pin
   );
	
   BUFG_inst : BUFG
   port map (
      O => CLKOUT, -- 1-bit output: Clock buffer output
      I => clkfx  -- 1-bit input: Clock buffer input
   );


end Behavioral;

