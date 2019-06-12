--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:37:30 06/11/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/gearbox8to24_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gearbox8to24
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
 
ENTITY gearbox8to24_tb IS
END gearbox8to24_tb;
 
ARCHITECTURE behavior OF gearbox8to24_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT gearbox8to24
    PORT(
         PCLK : IN  std_logic;
         CE : IN  std_logic;
         DIN : IN  std_logic_vector(23 downto 0);
         DE : IN  std_logic;
         DOUT : OUT  std_logic_vector(23 downto 0);
         DEOUT : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal PCLK : std_logic := '0';
   signal CE : std_logic := '1';
   signal DIN : std_logic_vector(23 downto 0) := (others => '0');
   signal DE : std_logic := '0';

 	--Outputs
   signal DOUT : std_logic_vector(23 downto 0);
   signal DEOUT : std_logic;

	signal count : natural := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: gearbox8to24 PORT MAP (
          PCLK => PCLK,
          CE => CE,
          DIN => DIN,
          DE => DE,
          DOUT => DOUT,
          DEOUT => DEOUT
        );

	PCLK <= not PCLK after 5 ns;
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
		DIN <= x"0000" & std_logic_vector(to_unsigned(count, 8));
		
		if(count >= 10 and count < 10+10*3) then
			DE <= '1';
		elsif(count >= 50 and count < 50+10*3+1) then -- intentionally bad
			DE <= '1';
		elsif(count >= 90 and count < 90+10*3) then -- should be ok
			DE <= '1';
		else
			DE <= '0';
		end if;
	end if;
	end process;

END;
