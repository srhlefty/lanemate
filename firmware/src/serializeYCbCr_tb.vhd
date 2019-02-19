--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:53:13 02/19/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Code/lanemate/firmware/src/serializeYCbCr_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: serializeYCbCr
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
 
ENTITY serializeYCbCr_tb IS
END serializeYCbCr_tb;
 
ARCHITECTURE behavior OF serializeYCbCr_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT serializeYCbCr
    PORT(
         DE : IN  std_logic;
         YCbCr1 : IN  std_logic_vector(23 downto 0);
         Y2 : IN  std_logic_vector(7 downto 0);
         D : OUT  std_logic_vector(7 downto 0);
         DEout : OUT  std_logic;
         CLK : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal DE : std_logic := '0';
   signal YCbCr1 : std_logic_vector(23 downto 0) := x"221133";
   signal Y2 : std_logic_vector(7 downto 0) := x"44";
   signal CLK : std_logic := '0';

 	--Outputs
   signal D : std_logic_vector(7 downto 0);
   signal DEout : std_logic;

	signal count : natural := 0;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: serializeYCbCr PORT MAP (
          DE => DE,
          YCbCr1 => YCbCr1,
          Y2 => Y2,
          D => D,
          DEout => DEout,
          CLK => CLK
        );

	CLK <= not CLK after 5 ns;

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		if(count >= 11 and count <= 110) then
			DE <= '1';
		else
			DE <= '0';
		end if;
	end if;
	end process;

END;
