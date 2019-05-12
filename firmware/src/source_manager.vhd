----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:55:19 05/11/2019 
-- Design Name: 
-- Module Name:    source_manager - Behavioral 
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

entity source_manager is
    Port ( CLK : in  STD_LOGIC;
           SOURCE : in  STD_LOGIC_VECTOR (2 downto 0);   -- 00=720p test pat, 01=1080p test pat, 10=hd in 720p, 11=hd in 1080p, 100=sd in
           CLK_SEL : out  STD_LOGIC_VECTOR (1 downto 0);
           SRC_SEL : out  STD_LOGIC_VECTOR (1 downto 0);
           SRC_ENABLE : out  STD_LOGIC);
end source_manager;

architecture Behavioral of source_manager is
	signal source_old : std_logic_vector(2 downto 0) := "111";
	signal enable : std_logic := '1';
	signal clksel : std_logic_vector(1 downto 0) := "00";
	signal srcsel : std_logic_vector(1 downto 0) := "00";
	
	type state_t is (NORMAL, PICK, W1, W2, W3);
	signal state : state_t := NORMAL;
	
begin
	
	CLK_SEL <= clksel;
	SRC_SEL <= srcsel;
	SRC_ENABLE <= enable;

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		source_old <= SOURCE;
		case state is
			when NORMAL =>
				if(SOURCE /= source_old) then
					enable <= '0';
					state <= PICK;
				else
					enable <= '1';
				end if;
			
			when PICK =>
				if(SOURCE = "000") then
					clksel <= "01";
					srcsel <= "00";
				elsif(SOURCE = "001") then
					clksel <= "10";
					srcsel <= "00";
				elsif(SOURCE = "010") then
					clksel <= "01";
					srcsel <= "01";
				elsif(SOURCE = "011") then
					clksel <= "10";
					srcsel <= "01";
				else
					clksel <= "00";
					srcsel <= "10";
				end if;
				state <= W1;
			
			when W1 =>
				state <= W2;
			when W2 =>
				state <= W3;
			when W3 =>
				state <= NORMAL;
			
		end case;
	end if;
	end process;

end Behavioral;

