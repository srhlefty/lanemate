----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    06:50:43 10/16/2019 
-- Design Name: 
-- Module Name:    quadrature_decoder - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity quadrature_decoder is
    Port ( CLK : in  STD_LOGIC;
           A : in  STD_LOGIC;
           B : in  STD_LOGIC;
           COUNT : out  STD_LOGIC_VECTOR (7 downto 0));
end quadrature_decoder;

architecture Behavioral of quadrature_decoder is

	signal counter : natural range 0 to 255 := 0;
	signal prevA : std_logic := '0';
	signal prevB : std_logic := '0';
	signal item : std_logic_vector(1 downto 0) := "00";

	type item_t is array(natural range <>) of std_logic_vector(1 downto 0);
	signal rom : item_t(15 downto 0) := 
	(
							-- previous   current      CE    add
		2	=> "11",		--	"00"     &   "10"   =>  '1' & '1',
		11	=> "11",		--	"10"     &   "11"   =>  '1' & '1',
		13	=> "11",		--	"11"     &   "01"   =>  '1' & '1',
		4	=> "11",		--	"01"     &   "00"   =>  '1' & '1',
								
		1	=> "10",		--	"00"     &   "01"   =>  '1' & '0',
		7	=> "10",		--	"01"     &   "11"   =>  '1' & '0',
		14	=> "10",		--	"11"     &   "10"   =>  '1' & '0',
		8	=> "10",		--	"10"     &   "00"   =>  '1' & '0',
		
	   others => "00"
	);

begin

	process(CLK) is
		variable addr : std_logic_vector(3 downto 0);
	begin
	if(rising_edge(CLK)) then
		prevA <= A;
		prevB <= B;

		addr := prevA & prevB & A & B;
		item <= rom(to_integer(unsigned(addr)));
		
		if(item(1) = '1') then
			if(item(0) = '1') then
				if(counter = 255) then
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
			else
				if(counter = 0) then
					counter <= 255;
				else
					counter <= counter - 1;
				end if;
			end if;
		end if;
	end if;
	end process;
	
	COUNT <= std_logic_vector(to_unsigned(counter, COUNT'length));

end Behavioral;

