----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:09:31 12/21/2016 
-- Design Name: 
-- Module Name:    bram_simple_dual_port - Behavioral 
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

entity bram_simple_dual_port is
	generic (
		ADDR_WIDTH : natural := 8;
		DATA_WIDTH : natural := 8
	);
    Port ( 
		CLK1 : in std_logic;
		WADDR1 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		WDATA1 : in std_logic_vector (DATA_WIDTH-1 downto 0);
		WE1    : in std_logic;

		CLK2 : in std_logic;
		RADDR2 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		RDATA2 : out std_logic_vector (DATA_WIDTH-1 downto 0)
	);
end bram_simple_dual_port;

architecture Behavioral of bram_simple_dual_port is

	type ram_t is array((2**ADDR_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal ram : ram_t := (others => (others => '0'));

	attribute ram_style : string;
	attribute ram_style of ram : signal is "block"; -- "distributed", "block", or "Auto" (default)

begin

	process(CLK1) is
	begin
	if(rising_edge(CLK1)) then
		if(WE1 = '1') then
			ram(to_integer(unsigned(WADDR1))) <= WDATA1;
		end if;
	end if; 
	end process;
	
	process(CLK2) is
	begin
	if(rising_edge(CLK2)) then
		RDATA2 <= ram(to_integer(unsigned(RADDR2)));
	end if; 
	end process;


end Behavioral;

