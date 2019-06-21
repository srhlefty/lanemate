----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:59:34 05/16/2019 
-- Design Name: 
-- Module Name:    test_pattern - Behavioral 
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

entity test_pattern is
	Port ( 
		PCLK : in  STD_LOGIC;
		VS : in  STD_LOGIC;
		HS : in  STD_LOGIC;
		DE : in  STD_LOGIC;
		CE : in  STD_LOGIC;
		IS422 : in std_logic;
		D : in  STD_LOGIC_VECTOR (23 downto 0);
		VSOUT : out  STD_LOGIC;
		HSOUT : out  STD_LOGIC;
		DEOUT : out  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0)
	);
end test_pattern;

architecture Behavioral of test_pattern is

	component serializeYCbCr is
    Port ( DE : in  STD_LOGIC;
           YCbCr1 : in  STD_LOGIC_VECTOR (23 downto 0);
           Y2 : in  STD_LOGIC_VECTOR (7 downto 0);
           D : out  STD_LOGIC_VECTOR (7 downto 0);
			  DEout : out std_logic;
           CLK : in  STD_LOGIC);
	end component;

	signal hcount : natural range 0 to 2047 := 0;
	signal vcount : natural range 0 to 2047 := 0;
	signal de_old : std_logic := '0';
	signal hs_old : std_logic := '0';
	
	signal vs1 : std_logic := '0';
	signal hs1 : std_logic := '0';
	signal vs2 : std_logic := '0';
	signal hs2 : std_logic := '0';
	signal de1 : std_logic := '0';
	
	signal de444 : std_logic := '0';
	signal de422 : std_logic := '0';
	
	signal d444 : std_logic_vector(23 downto 0) := (others => '0');
	signal d422 : std_logic_vector(23 downto 0) := (others => '0');
	
	type rom_t is array(0 to 3) of std_logic_vector(23 downto 0);
	signal romRGB : rom_t := (
		x"FF0000",
		x"00FF00",
		x"0000FF",
		x"FFFFFF"
	);
	
	signal romYCbCr : rom_t := (
		x"4C54FF", 
		x"952B15",
		x"1DFF6B",
		x"FF8080"
	);
	
	signal srcYCbCr1 : std_logic_vector(23 downto 0) := (others => '0');
	signal srcY2 : std_logic_vector(7 downto 0) := (others => '0');
	
begin

		
		

	Inst_serializeYCbCr: serializeYCbCr PORT MAP(
		DE => de_old,
		YCbCr1 => srcYCbCr1,
		Y2 => srcY2,
		D => d422(7 downto 0),
		DEout => de422,
		CLK => PCLK
	);

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
		variable hcountv : std_logic_vector(10 downto 0);
		variable vcountv : std_logic_vector(10 downto 0);
		variable sample : std_logic_vector(23 downto 0);
	begin
	if(rising_edge(PCLK)) then
		if(CE = '1') then
			de1 <= DE;
			de444 <= de1;
			hcountv := std_logic_vector(to_unsigned(hcount, hcountv'length));
			vcountv := std_logic_vector(to_unsigned(vcount, vcountv'length));
			--d444 <= romRGB(to_integer(unsigned(hcountv(8 downto 7))));
			d444(23 downto 16) <= hcountv(7 downto 0);
			d444(15 downto 8)  <= vcountv(7 downto 0);
			d444(7 downto 0) <= x"00";
			
			sample := romYCbCr(to_integer(unsigned(hcountv(8 downto 7))));
			srcYCbCr1 <= sample;
			srcY2 <= sample(23 downto 16);
			
		else
			de444 <= DE;
			d444  <= D;
		end if;
	end if;
	end process;
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		if(CE = '1') then
			vs1 <= VS;
			hs1 <= HS;
			vs2 <= vs1;
			hs2 <= hs1;
			VSOUT <= vs2;
			HSOUT <= hs2;
			if(IS422 = '1') then
				DEOUT <= de422;
				DOUT <= d422;
			else
				DEOUT <= de444;
				DOUT <= d444;
			end if;
		else
			VSOUT <= VS;
			HSOUT <= HS;
			DEOUT <= DE;
			DOUT <= D;
		end if;
	end if;
	end process;

end Behavioral;

