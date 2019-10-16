----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    07:47:05 10/16/2019 
-- Design Name: 
-- Module Name:    debounce - Behavioral 
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

entity debounce is
	generic ( TIMESCALE : natural := 100 );
	Port ( 
		CLK : in  STD_LOGIC;
		DIN : in  STD_LOGIC;
		DOUT : out  STD_LOGIC
	);
end debounce;

architecture Behavioral of debounce is

	signal count : natural range 0 to TIMESCALE := 0;
	signal state : std_logic := '0';
	
begin

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		if(DIN = '1') then
			if(count = TIMESCALE) then
				state <= '1';
			else
				count <= count + 1;
			end if;
		else
			if(count = 0) then
				state <= '0';
			else
				count <= count - 1;
			end if;
		end if;
	end if;
	end process;
	
	DOUT <= state;

end Behavioral;

