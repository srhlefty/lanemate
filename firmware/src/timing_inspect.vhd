----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:02:51 02/18/2019 
-- Design Name: 
-- Module Name:    timing_inspect - Behavioral 
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


entity timing_inspect is
    Port ( PCLK : in  STD_LOGIC;
           VS : in  STD_LOGIC;
           HS : in  STD_LOGIC;
           HCOUNT : out natural;
			  HSYNC_WIDTH : out natural;
			  VCOUNT : out natural;
			  VSYNC_WIDTH : out natural);
end timing_inspect;

architecture Behavioral of timing_inspect is

	
begin

	line_length : block is
		signal old : std_logic := '1';
		signal count : natural range 0 to 65535 := 0;
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			old <= HS;
			if(HS = '0' and old = '1') then
				HCOUNT <= count;
				count <= 1;
			else
				count <= count + 1;
			end if;
		end if;
		end process;
	end block;
	
	num_lines : block is
		signal oldH : std_logic := '1';
		signal oldV : std_logic := '1';
		signal count : natural range 0 to 65535 := 0;
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			oldV <= VS;
			oldH <= HS;
			if(VS = '0' and oldV = '1') then
				VCOUNT <= count;
				count <= 1;
			else
				if(HS = '0' and oldH = '1') then
					count <= count + 1;
				end if;
			end if;
		end if;
		end process;
	end block;
	
end Behavioral;

