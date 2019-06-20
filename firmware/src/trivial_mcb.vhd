----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:06:06 06/13/2019 
-- Design Name: 
-- Module Name:    trivial_mcb - Behavioral 
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

entity trivial_mcb is
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0);
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
		-- write-transaction fifo
		MPOP_W : out std_logic;
		MADDR_W : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDATA_W : in std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;
		
		-- read-transaction fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDVALID_R : in std_logic;
		
		-- output side
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
end trivial_mcb;

architecture Behavioral of trivial_mcb is

	type state_t is (WAITING, POPW, REST, POPR, REST2);
	signal state : state_t := WAITING;
	signal popcount : natural := 0;
	signal limit : natural := 0;
	signal passcount : natural range 0 to 4 := 0;
begin

	process(MCLK) is
		variable available : natural;
		variable transaction : natural;
	begin
	if(rising_edge(MCLK)) then
	
		case state is
		when WAITING =>
			MPOP_W <= '0';
			MPOP_R <= '0';
			available := to_integer(unsigned(MAVAIL));
			transaction := to_integer(unsigned(MTRANSACTION_SIZE));
			-- requite MAVAIL to pass for 4 clocks in a row to guard against temporary
			-- changes due to clock domain shenanigains
			if(available >= transaction) then
				if(passcount = 4) then
					limit <= transaction;
					popcount <= 0;
					state <= POPW;
				else
					passcount <= passcount + 1;
				end if;
--			elsif(MFLUSH = '1' and avail > 0) then
--				limit <= avail;
--				popcount <= 0;
--				state <= POPW;
			else
				passcount <= 0;
			end if;
		
		when POPW =>
			popcount <= popcount + 1;
			if(popcount = limit) then
				MPOP_W <= '0';
				state <= REST;
			else
				MPOP_W <= '1';
			end if;
			
		when REST =>
			popcount <= 0;
			state <= POPR;
			
		when POPR =>
			popcount <= popcount + 1;
			if(popcount = limit) then
				MPOP_R <= '0';
				state <= REST2;
			else
				MPOP_R <= '1';
			end if;
			
		when REST2 =>
			passcount <= 0;
			state <= WAITING;
			
		end case;
	
	end if;
	end process;
	
	MPUSH_R <= MDVALID_W;
	MDATA_R <= MDATA_W;

end Behavioral;

