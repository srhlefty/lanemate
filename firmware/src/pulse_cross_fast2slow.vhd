----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:31:38 10/25/2017 
-- Design Name: 
-- Module Name:    pulse_cross_fast2slow - Behavioral 
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
-- This module is designed to pass a 1-clock pulse in the fast domain to a 
-- 1-clock pulse in the slow domain. (It still works if you go from slow to fast)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_cross_fast2slow is
    Port ( CLKFAST : in  STD_LOGIC;
           TRIGIN : in  STD_LOGIC;
           CLKSLOW : in  STD_LOGIC;
           TRIGOUT : out  STD_LOGIC);
end pulse_cross_fast2slow;

architecture Behavioral of pulse_cross_fast2slow is

	signal level : std_logic := '0';
	signal reg1, reg2, reg3 : std_logic := '0';
	attribute ASYNC_REG : string;
	attribute ASYNC_REG of reg1 : signal is "TRUE";
	attribute ASYNC_REG of reg2 : signal is "TRUE";

begin

	process(CLKFAST) is
	begin
	if(rising_edge(CLKFAST)) then
		if(TRIGIN = '1') then
			level <= not level;
		end if;
	end if;
	end process;

	process(CLKSLOW) is
	begin
	if(rising_edge(CLKSLOW)) then
		reg1 <= level;
		reg2 <= reg1;
		reg3 <= reg2;
	end if;
	end process;
	
	TRIGOUT <= reg3 xor reg2;

end Behavioral;

