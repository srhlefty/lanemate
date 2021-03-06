----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:23:44 06/11/2019 
-- Design Name: 
-- Module Name:    gearbox8to24 - Behavioral 
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

entity gearbox8to24 is
	Port ( 
		PCLK : in  STD_LOGIC;
		PRST : in std_logic;
		CE : in  STD_LOGIC;
		DIN : in  STD_LOGIC_VECTOR (23 downto 0);
		DE : in  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0);
		DEOUT : out  STD_LOGIC
	);
end gearbox8to24;

architecture Behavioral of gearbox8to24 is

	type shift_t is array(integer range <>) of std_logic_vector(7 downto 0);
	signal shifter : shift_t(0 to 2) := (others => (others => '0'));
	signal count : natural range 0 to 3 := 3;
	
	signal dout_i : std_logic_vector(23 downto 0) := (others => '0');
	signal deout_i : std_logic := '0';
begin

	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		if(PRST = '1') then
			shifter <= (others => (others => '0'));
			count <= 3;
			dout_i <= (others => '0');
			deout_i <= '0';
		else
			if(CE = '1') then
				if(DE = '1') then
					shifter(2) <= DIN(7 downto 0);
					for i in 0 to 1 loop
						shifter(i) <= shifter(i+1);
					end loop;
					
					if(count = 2) then
						count <= 0;
					elsif(count = 3) then
						count <= 1;
					else
						count <= count + 1;
					end if;
				else
					count <= 3;
				end if;
				
				if(count = 0) then
					dout_i <= shifter(2) & shifter(1) & shifter(0);
					deout_i <= '1';
				else
					deout_i <= '0';
				end if;
				
			else
				count <= 3;
				dout_i <= DIN;
				deout_i <= DE;
			end if;
		end if;
	end if;
	end process;
	
	DOUT <= dout_i;
	DEOUT <= deout_i;
	
end Behavioral;

