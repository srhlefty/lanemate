--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:20:56 03/22/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/pulse_delay_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pulse_delay
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
 
ENTITY pulse_delay_tb IS
END pulse_delay_tb;
 
ARCHITECTURE behavior OF pulse_delay_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pulse_delay
    PORT(
         CLK : IN  std_logic;
         D : IN  std_logic_vector(2 downto 0);
         RST : IN  std_logic;
         DELAY : IN  std_logic_vector(15 downto 0);
         DOUT : OUT  std_logic_vector(2 downto 0);
         OVERFLOW : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal D : std_logic_vector(2 downto 0) := (others => '0');
   signal RST : std_logic := '0';
   signal DELAY : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(30, 16));

 	--Outputs
   signal DOUT : std_logic_vector(2 downto 0);
   signal OVERFLOW : std_logic;

	signal count : natural := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pulse_delay PORT MAP (
          CLK => CLK,
          D => D,
          RST => RST,
          DELAY => DELAY,
          DOUT => DOUT,
          OVERFLOW => OVERFLOW
        );

	CLK <= not CLK after 5 ns;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		
		if(count = 10 or count = 15) then
			D <= "111";
		else
			D <= "000";
		end if;
	end if;
	end process;
END;
