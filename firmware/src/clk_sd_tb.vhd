--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:49:07 02/18/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Code/lanemate/firmware/src/clk_sd_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: clk_sd
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
 
ENTITY clk_sd_tb IS
END clk_sd_tb;
 
ARCHITECTURE behavior OF clk_sd_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT clk_sd
    PORT(
         CLK100 : IN  std_logic;
         CLK27 : OUT  std_logic;
         CLK54 : OUT  std_logic;
         RST : IN  std_logic;
         LOCKED : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK100 : std_logic := '0';
   signal RST : std_logic := '0';

 	--Outputs
   signal CLK27 : std_logic;
   signal CLK54 : std_logic;
   signal LOCKED : std_logic;

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: clk_sd PORT MAP (
          CLK100 => CLK100,
          CLK27 => CLK27,
          CLK54 => CLK54,
          RST => RST,
          LOCKED => LOCKED
        );

	CLK100 <= not CLK100 after 5 ns;

END;
