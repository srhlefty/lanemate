--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:40:25 02/17/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Code/lanemate/firmware/src/timing_gen_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: timing_gen
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
 
ENTITY timing_gen_tb IS
END timing_gen_tb;
 
ARCHITECTURE behavior OF timing_gen_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT timing_gen
    PORT(
         CLK : IN  std_logic;
			RST : in std_logic;
         VIC : IN  std_logic_vector(7 downto 0);
         VS : OUT  std_logic;
         HS : OUT  std_logic;
         DE : OUT  std_logic;
         D : OUT  std_logic_vector(23 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RST : std_logic := '1';
   signal VIC : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal VS : std_logic;
   signal HS : std_logic;
   signal DE : std_logic;
   signal D : std_logic_vector(23 downto 0);


	signal count : natural := 0;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: timing_gen PORT MAP (
          CLK => CLK,
          RST => RST,
          VIC => VIC,
          VS => VS,
          HS => HS,
          DE => DE,
          D => D
        );

	CLK <= not CLK after 6.734 ns; -- 74.25MHz

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		
		if(count = 5) then
			RST <= '0';
		end if;
		count <= count + 1;
		
	end if;
	end process;
	

END;
