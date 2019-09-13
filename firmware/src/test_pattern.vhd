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
		PATTERN : in std_logic_vector(7 downto 0);
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
	signal vs_old : std_logic := '0';
	
	signal vs1 : std_logic := '0';
	signal hs1 : std_logic := '0';
	signal vs2 : std_logic := '0';
	signal hs2 : std_logic := '0';
	signal de1 : std_logic := '0';
	signal d1 : std_logic_vector(23 downto 0) := (others => '0');
	
	signal de444 : std_logic := '0';
	signal de422 : std_logic := '0';
	
	signal d444 : std_logic_vector(23 downto 0) := (others => '0');
	signal d422 : std_logic_vector(23 downto 0) := (others => '0');
	
	type rom_t is array(integer range <>) of std_logic_vector(23 downto 0);
	signal romRGB : rom_t(0 to 3) := (
		x"FF0000",
		x"00FF00",
		x"0000FF",
		x"FFFFFF"
	);
	
	signal romYCbCr : rom_t(0 to 3) := (
		x"4C54FF", 
		x"952B15",
		x"1DFF6B",
		x"FF8080"
	);
	
	-- This makes non-zero data only come out of lane 0
	signal lane0 : rom_t(0 to 31) :=
	(
		x"FFFFFF",
		x"FF0000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"0000FF",
		x"FFFFFF",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"00FFFF",
		x"FFFF00",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000",
		x"000000"
	);
	signal lane1 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"00FFFF",
		2 =>  x"FFFF00",
		3 =>  x"000000",
		4 =>  x"000000",
		5 =>  x"000000",
		6 =>  x"000000",
		7 =>  x"000000",
		8 =>  x"000000",
		9 =>  x"000000",
		10 => x"000000",
		11 => x"000000",
		12 => x"FFFFFF",
		13 => x"FF0000",
		14 => x"000000",
		15 => x"000000",
		16 => x"000000",
		17 => x"000000",
		18 => x"000000",
		19 => x"000000",
		20 => x"000000",
		21 => x"000000",
		22 => x"0000FF",
		23 => x"FFFFFF",
		24 => x"000000",
		25 => x"000000",
		26 => x"000000",
		27 => x"000000",
		28 => x"000000",
		29 => x"000000",
		30 => x"000000",
		31 => x"000000"
	);
	signal lane2 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"0000FF",
		3 =>  x"FFFFFF",
		4 =>  x"000000",
		5 =>  x"000000",
		6 =>  x"000000",
		7 =>  x"000000",
		8 =>  x"000000",
		9 =>  x"000000",
		10 => x"000000",
		11 => x"000000",
		12 => x"000000",
		13 => x"00FFFF",
		14 => x"FFFF00",
		15 => x"000000",
		16 => x"000000",
		17 => x"000000",
		18 => x"000000",
		19 => x"000000",
		20 => x"000000",
		21 => x"000000",
		22 => x"000000",
		23 => x"000000",
		24 => x"FFFFFF",
		25 => x"FF0000",
		26 => x"000000",
		27 => x"000000",
		28 => x"000000",
		29 => x"000000",
		30 => x"000000",
		31 => x"000000"
	);
	signal lane3 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"000000",
		3 =>  x"000000",
		4 =>  x"FFFFFF",
		5 =>  x"FF0000",
		6 =>  x"000000",
		7 =>  x"000000",
		8 =>  x"000000",
		9 =>  x"000000",
		10 => x"000000",
		11 => x"000000",
		12 => x"000000",
		13 => x"000000",
		14 => x"0000FF",
		15 => x"FFFFFF",
		16 => x"000000",
		17 => x"000000",
		18 => x"000000",
		19 => x"000000",
		20 => x"000000",
		21 => x"000000",
		22 => x"000000",
		23 => x"000000",
		24 => x"000000",
		25 => x"00FFFF",
		26 => x"FFFF00",
		27 => x"000000",
		28 => x"000000",
		29 => x"000000",
		30 => x"000000",
		31 => x"000000"
	);
	signal lane4 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"000000",
		3 =>  x"000000",
		4 =>  x"000000",
		5 =>  x"00FFFF",
		6 =>  x"FFFF00",
		7 =>  x"000000",
		8 =>  x"000000",
		9 =>  x"000000",
		10 => x"000000",
		11 => x"000000",
		12 => x"000000",
		13 => x"000000",
		14 => x"000000",
		15 => x"000000",
		16 => x"FFFFFF",
		17 => x"FF0000",
		18 => x"000000",
		19 => x"000000",
		20 => x"000000",
		21 => x"000000",
		22 => x"000000",
		23 => x"000000",
		24 => x"000000",
		25 => x"000000",
		26 => x"0000FF",
		27 => x"FFFFFF",
		28 => x"000000",
		29 => x"000000",
		30 => x"000000",
		31 => x"000000"
	);
	signal lane5 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"000000",
		3 =>  x"000000",
		4 =>  x"000000",
		5 =>  x"000000",
		6 =>  x"0000FF",
		7 =>  x"FFFFFF",
		8 =>  x"000000",
		9 =>  x"000000",
		10 => x"000000",
		11 => x"000000",
		12 => x"000000",
		13 => x"000000",
		14 => x"000000",
		15 => x"000000",
		16 => x"000000",
		17 => x"00FFFF",
		18 => x"FFFF00",
		19 => x"000000",
		20 => x"000000",
		21 => x"000000",
		22 => x"000000",
		23 => x"000000",
		24 => x"000000",
		25 => x"000000",
		26 => x"000000",
		27 => x"000000",
		28 => x"FFFFFF",
		29 => x"FF0000",
		30 => x"000000",
		31 => x"000000"
	);
	signal lane6 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"000000",
		3 =>  x"000000",
		4 =>  x"000000",
		5 =>  x"000000",
		6 =>  x"000000",
		7 =>  x"000000",
		8 =>  x"FFFFFF",
		9 =>  x"FF0000",
		10 => x"000000",
		11 => x"000000",
		12 => x"000000",
		13 => x"000000",
		14 => x"000000",
		15 => x"000000",
		16 => x"000000",
		17 => x"000000",
		18 => x"0000FF",
		19 => x"FFFFFF",
		20 => x"000000",
		21 => x"000000",
		22 => x"000000",
		23 => x"000000",
		24 => x"000000",
		25 => x"000000",
		26 => x"000000",
		27 => x"000000",
		28 => x"000000",
		29 => x"00FFFF",
		30 => x"FFFF00",
		31 => x"000000"
	);
	signal lane7 : rom_t(0 to 31) :=
	(
		0 =>  x"000000",
		1 =>  x"000000",
		2 =>  x"000000",
		3 =>  x"000000",
		4 =>  x"000000",
		5 =>  x"000000",
		6 =>  x"000000",
		7 =>  x"000000",
		8 =>  x"000000",
		9 =>  x"00ffff",
		10 => x"00ff00",
		11 => x"000000",
		12 => x"000000",
		13 => x"000000",
		14 => x"000000",
		15 => x"000000",
		16 => x"000000",
		17 => x"000000",
		18 => x"000000",
		19 => x"000000",
		20 => x"ffff00",
		21 => x"ff0000",
		22 => x"000000",
		23 => x"000000",
		24 => x"000000",
		25 => x"000000",
		26 => x"000000",
		27 => x"000000",
		28 => x"000000",
		29 => x"000000",
		30 => x"0000ff",
		31 => x"ff00ff"
	);
	
	signal srcYCbCr1 : std_logic_vector(23 downto 0) := (others => '0');
	signal srcY2 : std_logic_vector(7 downto 0) := (others => '0');
	
	signal blue : natural range 0 to 255 := 0;
	signal add : std_logic := '1';
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
		vs_old <= VS;
		if(vs_old = '0' and VS = '1') then
			if(add = '1') then
				if(blue = 255) then
					add <= '0';
				else
					blue <= blue + 1;
				end if;
			else
				if(blue = 0) then
					add <= '1';
				else
					blue <= blue - 1;
				end if;
			end if;
		end if;
		
		de1 <= DE;
		d1 <= D;
		de444 <= de1;
		
		hcountv := std_logic_vector(to_unsigned(hcount, hcountv'length));
		vcountv := std_logic_vector(to_unsigned(vcount, vcountv'length));
		if(PATTERN = x"00") then
			d444 <= d1;
		elsif(PATTERN = x"01") then
			d444 <= romRGB(to_integer(unsigned(hcountv(8 downto 7))));
		elsif(PATTERN = x"02") then
			d444(23 downto 16) <= hcountv(7 downto 0);
			d444(15 downto 8)  <= vcountv(7 downto 0);
			d444(7 downto 0) <= x"00";
		elsif(PATTERN = x"03") then
			d444(23 downto 16) <= hcountv(7 downto 0);
			d444(15 downto 8)  <= vcountv(7 downto 0);
			d444(7 downto 0) <= std_logic_vector(to_unsigned(blue, 8));
		elsif(PATTERN = x"04") then
			d444 <= lane0(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"05") then
			d444 <= lane1(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"06") then
			d444 <= lane2(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"07") then
			d444 <= lane3(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"08") then
			d444 <= lane4(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"09") then
			d444 <= lane5(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"0A") then
			d444 <= lane6(to_integer(unsigned(hcountv(4 downto 0))));
		elsif(PATTERN = x"0B") then
			d444 <= lane7(to_integer(unsigned(hcountv(4 downto 0))));
		else
			d444 <= x"AAAAAA";
		end if;
		
		sample := romYCbCr(to_integer(unsigned(hcountv(8 downto 7))));
		srcYCbCr1 <= sample;
		srcY2 <= sample(23 downto 16);
	end if;
	end process;
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
--		if(CE = '1') then
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
--		else
--			VSOUT <= VS;
--			HSOUT <= HS;
--			DEOUT <= DE;
--			DOUT <= D;
--		end if;
	end if;
	end process;

end Behavioral;

