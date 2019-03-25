----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:26:11 10/20/2017 
-- Design Name: 
-- Module Name:    synchronizer_2ff - Behavioral 
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

entity synchronizer_2ff is
	Generic ( 
		DATA_WIDTH : natural;
		EXTRA_INPUT_REGISTER : boolean := false
	);
	Port ( 
		CLKA   : in std_logic;
		DA     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		CLKB   : in  std_logic;
		DB     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RESETB : in std_logic
	);
end synchronizer_2ff;

architecture Behavioral of synchronizer_2ff is

	signal regbufA : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal sync1 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal sync2 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	attribute ASYNC_REG : string;
	attribute ASYNC_REG of sync1 : signal is "TRUE";
	attribute ASYNC_REG of sync2 : signal is "TRUE";
	
	-- For proper timing results you must add something like the following
	-- to your constraint file:
	--NET "CLKA" TNM_NET = FFS "GRP_A";
	--NET "CLKB" TNM_NET = FFS "GRP_B";
	--TIMESPEC TS_DOMAINCROSS = FROM "GRP_A" TO "GRP_B" 3 ns DATAPATHONLY;	

begin

	extra : if(EXTRA_INPUT_REGISTER = true) generate
	begin

		process(CLKA) is
		begin
		if(rising_edge(CLKA)) then
			regbufA <= DA;
		end if;
		end process;
	
	end generate extra;
	
	noextra : if(EXTRA_INPUT_REGISTER = false) generate
	
		regbufA <= DA;
		
	end generate noextra;
	
	
	
	
	process(CLKB) is
	begin
	if(rising_edge(CLKB)) then
		if(RESETB = '1') then
			sync1 <= (others => '0');
			sync2 <= (others => '0');
		else
			sync1 <= regbufA;
			sync2 <= sync1;
		end if;
	end if;
	end process;

	DB <= sync2;

end Behavioral;

