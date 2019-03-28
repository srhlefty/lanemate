----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:39:32 11/03/2017 
-- Design Name: 
-- Module Name:    gray_to_binary - Behavioral 
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

entity gray_to_binary is
	generic ( DATA_WIDTH : natural := 4);
	Port ( 
		DIN : in std_logic_vector(DATA_WIDTH-1 downto 0);
		DOUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end gray_to_binary;

architecture Behavioral of gray_to_binary is
	
begin

	-- Don't be alarmed by the deep layers of logic implied by this structure.
	-- When synthesized, it collapses to a collection of LUTs in parallel.
	-- Even with a 14-bit bus it's only 2 levels of logic.

	process(DIN) is
		variable d : std_logic_vector(DATA_WIDTH-1 downto 0);
	begin
		d(DATA_WIDTH-1) := DIN(DATA_WIDTH-1);
		for i in DATA_WIDTH-2 downto 0 loop
			d(i) := d(i+1) xor DIN(i);
		end loop;
		DOUT <= d;
	end process;
	
	
end Behavioral;

