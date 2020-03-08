----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:31:06 03/07/2020 
-- Design Name: 
-- Module Name:    video_mask - Behavioral 
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

entity video_mask is
    Port ( 
		CE : in std_logic;
		PCLK : in  STD_LOGIC;
		VS : in  STD_LOGIC;
		HS : in  STD_LOGIC;
		DE : in  STD_LOGIC;
		D : in  STD_LOGIC_VECTOR (23 downto 0);
		VALUE : in std_logic_vector(15 downto 0);
		HIDE_BKND : in std_logic;
		FULL_MODE : in std_logic;
		VSOUT : out  STD_LOGIC;
		HSOUT : out  STD_LOGIC;
		DEOUT : out  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0)
	 );
end video_mask;

architecture Behavioral of video_mask is
	signal hcount : natural range 0 to 2047 := 0;
	signal vcount : natural range 0 to 2047 := 0;
	signal de_old : std_logic := '0';
	signal hs_old : std_logic := '0';
	signal vs_old : std_logic := '0';

	signal de_tmp : std_logic := '0';
	signal hs_tmp : std_logic := '0';
	signal vs_tmp : std_logic := '0';
	signal d_tmp : std_logic_vector(23 downto 0) := (others => '0');
	
	constant filling_bar_color : std_logic_vector(23 downto 0) := x"AA0000";
	constant filling_bknd_color: std_logic_vector(23 downto 0) := x"000000";

	constant full_bar_color : std_logic_vector(23 downto 0) := x"00AA00";

	constant indicator_color : std_logic_vector(23 downto 0) := x"FFFFFF";
begin

	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		de_old <= DE;
		if(DE = '1') then
			if(de_old = '0') then
				hcount <= 0;
			else
				hcount <= hcount + 1;
			end if;
		end if;
		if(VS = '0') then
			vcount <= 0;
		else
			if(de_old = '1' and DE = '0') then
				vcount <= vcount + 1;
			end if;
		end if;
			
	end if;
	end process;

	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		if(CE = '0') then
			VSOUT <= VS;
			HSOUT <= HS;
			DEOUT <= DE;
			DOUT  <= D;
		else
			vs_tmp <= VS;
			hs_tmp <= HS;
			de_tmp <= DE;
			d_tmp <= D;
			VSOUT <= vs_tmp;
			HSOUT <= hs_tmp;
			DEOUT <= de_tmp;
			-- top and bottom black outline
			if(vcount = 0 or vcount = 15) then
				DOUT <= (others => '0');
			-- left black outline
			elsif(vcount <= 15 and hcount = 0) then
				DOUT <= (others => '0');
			-- top and bottom white outline
			elsif((vcount = 1 or vcount = 14) and hcount >= 1) then
				DOUT <= (others => '1');
			-- left white outline
			elsif(vcount >= 1 and vcount <= 14 and hcount = 1) then
				DOUT <= (others => '1');
			-- Progress bar
			elsif(vcount >= 2 and vcount <=13) then
				if(FULL_MODE = '0') then
					if(hcount >= 2 and hcount < to_integer(unsigned(VALUE))-16) then
						DOUT <= filling_bar_color;
					elsif(hcount >= to_integer(unsigned(VALUE))-16 and hcount <= to_integer(unsigned(VALUE))) then
						DOUT <= indicator_color;
					else
						DOUT <= filling_bknd_color;
					end if;
				else
					if(hcount >= to_integer(unsigned(VALUE))-16 and hcount <= to_integer(unsigned(VALUE))) then
						DOUT <= indicator_color;
					else
						DOUT <= full_bar_color;
					end if;
				end if;
			else
				if(HIDE_BKND = '1') then
					DOUT <= (others => '0');
				else
					DOUT <= d_tmp;
				end if;
			end if;
		end if;
	end if;
	end process;

end Behavioral;

