--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:59:04 07/02/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/clkgen_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: clkgen
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
 
ENTITY clkgen_tb IS
END clkgen_tb;
 
ARCHITECTURE behavior OF clkgen_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT clkgen
    PORT(
         SYSCLK100 : IN  std_logic;
         CLK200 : OUT  std_logic;
         CLK800 : OUT  std_logic;
         STROBE800 : OUT  std_logic;
         CLK800_180 : OUT  std_logic;
         STROBE800_180 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal SYSCLK100 : std_logic := '0';

 	--Outputs
   signal CLK200 : std_logic;
   signal CLK800 : std_logic;
   signal STROBE800 : std_logic;
   signal CLK800_180 : std_logic;
   signal STROBE800_180 : std_logic;

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: clkgen PORT MAP (
          SYSCLK100 => SYSCLK100,
          CLK200 => CLK200,
          CLK800 => CLK800,
          STROBE800 => STROBE800,
          CLK800_180 => CLK800_180,
          STROBE800_180 => STROBE800_180
        );

	SYSCLK100 <= not SYSCLK100 after 5 ns;

END;
