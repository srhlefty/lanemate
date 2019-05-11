--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:53:06 05/10/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/input_fifo_control_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: input_fifo_control
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
 
ENTITY input_fifo_control_tb IS
END input_fifo_control_tb;
 
ARCHITECTURE behavior OF input_fifo_control_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT input_fifo_control
    PORT(
			SYSCLK : in  STD_LOGIC;
			LOCKED : in  STD_LOGIC;
			RCLK : in std_logic;		
			RST : out  STD_LOGIC;
         RD_EN : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal SYSCLK : std_logic := '0';
   signal RCLK : std_logic := '0';
   signal LOCKED : std_logic := '1';

 	--Outputs
   signal RST : std_logic;
   signal RD_EN : std_logic;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: input_fifo_control PORT MAP (
          SYSCLK => SYSCLK,
          LOCKED => LOCKED,
			 RCLK => RCLK,
          RST => RST,
          RD_EN => RD_EN
        );

	SYSCLK <= not SYSCLK after 5 ns;
--	RCLK <= (not RCLK and LOCKED) after 18.519 ns; -- 27MHz
	RCLK <= (not RCLK and LOCKED) after 3.367 ns;
	
	process is
	begin
		wait for 400 ns;
		LOCKED <= '0';
		wait for 1 ms;
		LOCKED <= '1';
		wait for 1 ms;
	end process;

END;
