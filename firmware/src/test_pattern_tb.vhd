--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:50:55 05/19/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/test_pattern_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: test_pattern
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
USE ieee.numeric_std.ALL;
 
ENTITY test_pattern_tb IS
END test_pattern_tb;
 
ARCHITECTURE behavior OF test_pattern_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT test_pattern
    PORT(
         PCLK : IN  std_logic;
         VS : IN  std_logic;
         HS : IN  std_logic;
         DE : IN  std_logic;
         CE : IN  std_logic;
         IS422 : IN  std_logic;
         D : IN  std_logic_vector(23 downto 0);
         VSOUT : OUT  std_logic;
         HSOUT : OUT  std_logic;
         DEOUT : OUT  std_logic;
         DOUT : OUT  std_logic_vector(23 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal PCLK : std_logic := '0';
   signal VS : std_logic := '0';
   signal HS : std_logic := '0';
   signal DE : std_logic := '0';
   signal CE : std_logic := '1';
   signal IS422 : std_logic := '1';
   signal D : std_logic_vector(23 downto 0) := (others => '0');

 	--Outputs
   signal VSOUT : std_logic;
   signal HSOUT : std_logic;
   signal DEOUT : std_logic;
   signal DOUT : std_logic_vector(23 downto 0);

	signal count : natural := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: test_pattern PORT MAP (
          PCLK => PCLK,
          VS => VS,
          HS => HS,
          DE => DE,
          CE => CE,
          IS422 => IS422,
          D => D,
          VSOUT => VSOUT,
          HSOUT => HSOUT,
          DEOUT => DEOUT,
          DOUT => DOUT
        );

	PCLK <= not PCLK after 5 ns;
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
		
		if(count = 2) then
			VS <= '1';
		else
			VS <= '0';
		end if;
		
		if(count = 4) then
			HS <= '1';
		else
			HS <= '0';
		end if;
		
		if(count > 10) then
			DE <= '1';
			D <= std_logic_vector(to_unsigned(count-10, D'length)); -- note data starts from 1
		else
			DE <= '0';
			D <= (others => '0');
		end if;
	end if;
	end process;

END;
