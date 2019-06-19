----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:13:56 03/22/2019 
-- Design Name: 
-- Module Name:    pulse_delay_shiftreg - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-- This module is designed to delay an arbitrary pulse train (on each of 3 lines)
-- by up to 1024 clocks. It does this by creating a long shift register / memory
-- hybrid so that the output point is selectable. The actual delay is 2 more than requested.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_delay_shiftreg is
	Port ( 
		CLK : in  STD_LOGIC;
		D : in  STD_LOGIC_VECTOR(2 downto 0);
		DELAY : in  STD_LOGIC_VECTOR (10 downto 0);
		DOUT : out  STD_LOGIC_VECTOR(2 downto 0)
	);
end pulse_delay_shiftreg;

architecture Behavioral of pulse_delay_shiftreg is

	type shifter_t is array(0 to 2047) of std_logic_vector(2 downto 0);
	signal shifter : shifter_t := (others => (others => '0'));
		
begin
	
	process(CLK) is
		variable addr : natural;
	begin
	if(rising_edge(CLK)) then
		shifter(0) <= D;
		for i in 1 to shifter'high loop
			shifter(i) <= shifter(i-1);
		end loop;
		
		addr := to_integer(unsigned(DELAY));
		DOUT <= shifter(addr);
	end if;
	end process;
	
end Behavioral;

