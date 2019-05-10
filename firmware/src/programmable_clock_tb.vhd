--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:21:44 05/10/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/programmable_clock_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: programmable_clock
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
 
ENTITY programmable_clock_tb IS
END programmable_clock_tb;
 
ARCHITECTURE behavior OF programmable_clock_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT programmable_clock
    PORT(
         CLK : IN  std_logic;
         SEL : IN  std_logic_vector(1 downto 0);
         CLKOUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal SEL : std_logic_vector(1 downto 0) := "00";

 	--Outputs
   signal CLKOUT : std_logic;

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: programmable_clock PORT MAP (
          CLK => CLK,
          SEL => SEL,
          CLKOUT => CLKOUT
        );

	CLK <= not CLK after 5 ns;
	
	process is
	begin
		SEL <= "00";
		wait for 600 ns;
		SEL <= "01";
		wait for 600 ns;
		SEL <= "10";
		wait for 600 ns;
		SEL <= "11";
		wait;
	end process;

END;
