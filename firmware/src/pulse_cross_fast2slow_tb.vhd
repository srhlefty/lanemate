--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:54:49 10/25/2017
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Byron STTW/byron_sttw/firmware/adc_driver/src/pulse_cross_fast2slow_tb.vhd
-- Project Name:  adc_driver
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pulse_cross_fast2slow
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY pulse_cross_fast2slow_tb IS
END pulse_cross_fast2slow_tb;
 
ARCHITECTURE behavior OF pulse_cross_fast2slow_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pulse_cross_fast2slow
    PORT(
         CLKFAST : IN  std_logic;
         TRIGIN : IN  std_logic;
         CLKSLOW : IN  std_logic;
         TRIGOUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLKFAST : std_logic := '0';
   signal TRIGIN : std_logic := '0';
   signal CLKSLOW : std_logic := '0';

 	--Outputs
   signal TRIGOUT : std_logic;

	signal count : natural := 0;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pulse_cross_fast2slow PORT MAP (
          CLKFAST => CLKFAST,
          TRIGIN => TRIGIN,
          CLKSLOW => CLKSLOW,
          TRIGOUT => TRIGOUT
        );

	CLKFAST <= not CLKFAST after 4 ns;
	CLKSLOW <= not CLKSLOW after 16 ns;

	process(CLKFAST) is
	begin
	if(rising_edge(CLKFAST)) then
		count <= count + 1;
		if(count = 10) then
			TRIGIN <= '1';
		else
			TRIGIN <= '0';
		end if;
	end if;
	end process;

END;
