----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:46:37 02/19/2019 
-- Design Name: 
-- Module Name:    serializeYCbCr - Behavioral 
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

entity serializeYCbCr is
    Port ( DE : in  STD_LOGIC;
           YCbCr1 : in  STD_LOGIC_VECTOR (23 downto 0);
           Y2 : in  STD_LOGIC_VECTOR (7 downto 0);
           D : out  STD_LOGIC_VECTOR (7 downto 0);
			  DEout : out std_logic;
           CLK : in  STD_LOGIC);
end serializeYCbCr;

architecture Behavioral of serializeYCbCr is
	signal count : natural range 0 to 3 := 0;
	signal de_old : std_logic := '0';
begin

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		if(count = 3 or (DE = '1' and de_old = '0')) then
			count <= 0;
		else
			count <= count + 1;
		end if;
		DEout <= DE;
		de_old <= DE;
	end if;
	end process;
	
	with count select D <=
		YCbCr1(15 downto  8) when 0, -- Cb1
		YCbCr1(23 downto 16) when 1, -- Y1
		YCbCr1( 7 downto  0) when 2, -- Cr1
		Y2                  when 3,
		x"00"               when others;

end Behavioral;

