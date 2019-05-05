--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:47:55 04/10/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/i2c_debounce_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: i2c_debounce
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
 
ENTITY i2c_debounce_tb IS
END i2c_debounce_tb;
 
ARCHITECTURE behavior OF i2c_debounce_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT i2c_debounce
	Generic (
		DEPTH : natural := 5
	);
    PORT(
         CLK : IN  std_logic;
         DIN : IN  std_logic;
         DOUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal DIN : std_logic := '1';

 	--Outputs
   signal DOUT : std_logic;

	signal count : natural := 0;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: i2c_debounce PORT MAP (
          CLK => CLK,
          DIN => DIN,
          DOUT => DOUT
        );

	CLK <= not CLK after 5 ns;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		
		if(count = 10) then
			DIN <= '0';
		elsif(count >= 20 and count <= 30) then
			DIN <= '0';
		else
			DIN <= '1';
		end if;
		
	end if;
	end process;

END;
