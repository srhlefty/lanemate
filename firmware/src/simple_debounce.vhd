----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:51:22 04/10/2019 
-- Design Name: 
-- Module Name:    simple_debounce - Behavioral 
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

entity simple_debounce is
	Generic (
		DEPTH : natural := 5
	);
	Port ( 
		CLK : in  STD_LOGIC;
		DIN : in  STD_LOGIC;
		DOUT : out  STD_LOGIC);
end simple_debounce;

architecture Behavioral of simple_debounce is

	signal reg : std_logic_vector(DEPTH-1 downto 0) := (others => '0');
	signal reg2 : std_logic_vector(DEPTH-1 downto 0) := (others => '0');

begin

	process(CLK) is
		variable tmp : std_logic := '0';
	begin
	if(rising_edge(CLK)) then
		-- shift in new data into slot 0
		for i in 1 to reg'high loop
			reg(i) <= reg(i-1);
		end loop;
		reg(0) <= DIN;
		
		-- copy reg to reg2 to ease timing requirements
		reg2 <= reg;

		-- OR all bits together to generate the output.
		-- This is because I2C's "off" state is 1, so
		-- glitches will be 0's not 1's. Thus, only let
		-- a 0 through if they really meant it, which
		-- implies several 0's in a row
		tmp := '0';
		for i in 0 to reg2'high loop
			tmp := tmp or reg2(i);
		end loop;
		DOUT <= tmp;
		
	end if;
	end process;

end Behavioral;

