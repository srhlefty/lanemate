----------------------------------------------------------------------------------
-- Company: self
-- Engineer: Steven Hunt
-- 
-- Create Date:    09:51:02 08/17/2018 
-- Design Name: 
-- Module Name:    lane_mate - Behavioral 
-- Project Name: Lane Mate
-- Target Devices: LX25, LX45
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

entity lane_mate is
port (
   SYSCLK : in std_logic;
	
	GPIO0 : out std_logic;
	GPIO1 : out std_logic;
	GPIO2 : out std_logic;
	GPIO3 : out std_logic;
	GPIO4 : out std_logic;
	GPIO5 : out std_logic;
	GPIO6 : out std_logic;
	GPIO7 : out std_logic;
	GPIO8 : out std_logic;
	GPIO9 : out std_logic;
	GPIO10 : out std_logic;
	GPIO11 : out std_logic;
	GPIO12 : out std_logic;
	GPIO13 : out std_logic;
	GPIO14 : out std_logic;
	GPIO15 : out std_logic;
	GPIO24 : out std_logic;
	GPIO25 : out std_logic
);
end lane_mate;

architecture Behavioral of lane_mate is

	signal val : std_logic_vector(15 downto 0) := x"0001";
	signal count : natural := 0;
	
begin

	process(SYSCLK) is
	begin
	if(rising_edge(SYSCLK)) then
		if(count = 100000000 / 16) then
			count <= 0;
			val(15 downto 1) <= val(14 downto 0);
			val(0) <= val(15);
		else
			count <= count + 1;
		end if;
	end if;
	end process;
	
	GPIO0 <= val(0);
	GPIO1 <= val(1);
	GPIO2 <= val(2);
	GPIO3 <= val(3);
	GPIO4 <= val(4);
	GPIO5 <= val(5);
	GPIO6 <= val(6);
	GPIO7 <= val(7);
	GPIO8 <= val(8);
	GPIO9 <= val(9);
	GPIO10 <= val(10);
	GPIO11 <= val(11);
	GPIO12 <= val(12);
	GPIO13 <= val(13);
	GPIO14 <= val(14);
	GPIO15 <= val(15);

	GPIO24 <= '0';
	GPIO25 <= '0';

end Behavioral;

