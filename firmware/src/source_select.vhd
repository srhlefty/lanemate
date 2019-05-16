----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:25:37 05/11/2019 
-- Design Name: 
-- Module Name:    source_select - Behavioral 
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

entity source_select is
	Port ( 
		SYSCLK : in  STD_LOGIC;
		
		PIXEL_CLK : in std_logic;
		PIXEL_CLK_LOCKED : in std_logic; -- on SYSCLK domain
		
		-- clk is PIXEL_CLK
		INT_VS : in std_logic;
		INT_HS : in std_logic;
		INT_DE : in std_logic;
		INT_D  : in std_logic_vector(23 downto 0);
		
		HD_PCLK : in std_logic;
		HD_VS : in std_logic;
		HD_HS : in std_logic;
		HD_DE : in std_logic;
		HD_D  : in std_logic_vector(23 downto 0);
		
		-- BT.656 (YCbCr 4:2:2, embedded syncs)
		SD_PCLK : in std_logic;
		SD_D : in std_logic_vector(7 downto 0);
		
		SEL : in std_logic_vector(1 downto 0);
		
		-- clk is PIXEL_CLK
		OUT_VS : out std_logic;
		OUT_HS : out std_logic;
		OUT_DE : out std_logic;
		OUT_D  : out std_logic_vector(23 downto 0)
	);
end source_select;

architecture Behavioral of source_select is

	signal decoded_vs : std_logic;
	signal decoded_hs : std_logic;
	signal decoded_de : std_logic;
	signal decoded_d : std_logic_vector(7 downto 0);

		
	COMPONENT bt656_decode
	PORT(
		D : IN std_logic_vector(7 downto 0);
		CLK : IN std_logic;          
		VS : OUT std_logic;
		HS : OUT std_logic;
		DE : OUT std_logic;
		DOUT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

begin

		process(PIXEL_CLK) is
		begin
		if(rising_edge(PIXEL_CLK)) then
			if(SEL = "00") then
				OUT_VS <= int_input(26);
				OUT_HS <= int_input(25);
				OUT_DE <= int_input(24);
				OUT_D  <= int_input(23 downto 0);
			elsif(SEL(1 downto 0) = "01") then
				OUT_VS <= hd_input(26);
				OUT_HS <= hd_input(25);
				OUT_DE <= hd_input(24);
				OUT_D  <= hd_input(23 downto 0);
			else --elsif(SEL = "10") then
				OUT_VS <= sd_input(26);
				OUT_HS <= sd_input(25);
				OUT_DE <= sd_input(24);
				OUT_D  <= sd_input(23 downto 0);
			end if;
		end if;
		end process;

		-------------------------------------------------------------------------
		
		intbus(26) <= INT_VS;
		intbus(25) <= INT_HS;
		intbus(24) <= INT_DE;
		intbus(23 downto 0) <= INT_D;
	
		-------------------------------------------------------------------------
		
		hdbus(26) <= HD_VS;
		hdbus(25) <= HD_HS;
		hdbus(24) <= HD_DE;
		hdbus(23 downto 0) <= HD_D;
	
		-------------------------------------------------------------------------
		
		Inst_bt656_decode: bt656_decode PORT MAP(
			D => SD_D,
			CLK => SD_PCLK,
			VS => decoded_vs,
			HS => decoded_hs,
			DE => decoded_de,
			DOUT => decoded_d
		);
	
		sdbus(26) <= decoded_vs;
		sdbus(25) <= decoded_hs;
		sdbus(24) <= decoded_de;
		sdbus(23 downto 8) <= (others => '0');
		sdbus(7 downto 0) <= decoded_d;
	

end Behavioral;

