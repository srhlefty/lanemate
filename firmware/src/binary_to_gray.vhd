----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:30:24 11/03/2017 
-- Design Name: 
-- Module Name:    binary_to_gray - Behavioral 
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

entity binary_to_gray is
	generic ( DATA_WIDTH : natural );
	Port ( 
		DIN : in std_logic_vector(DATA_WIDTH-1 downto 0);
		DOUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end binary_to_gray;

architecture Behavioral of binary_to_gray is

begin

	process(DIN) is
	begin
		for i in 0 to DATA_WIDTH-2 loop
			DOUT(i) <= DIN(i) xor DIN(i+1);
		end loop;
		DOUT(DATA_WIDTH-1) <= DIN(DATA_WIDTH-1);
	end process;

end Behavioral;

