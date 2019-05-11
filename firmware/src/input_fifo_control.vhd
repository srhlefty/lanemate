----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:51:07 05/10/2019 
-- Design Name: 
-- Module Name:    input_fifo_control - Behavioral 
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

entity input_fifo_control is
    Port ( CLK : in  STD_LOGIC;
           LOCKED : in  STD_LOGIC;
           RST : out  STD_LOGIC;
           RD_EN : out  STD_LOGIC);
end input_fifo_control;

architecture Behavioral of input_fifo_control is

		type state_t is (RUNNING, WAIT_FOR_LOCK, D1, D2, COUNTDOWN);
		signal state : state_t := RUNNING;
		signal counter : natural range 0 to 15;

begin

		process(CLK) is
		begin
		if(rising_edge(CLK)) then
		case state is
			when RUNNING =>
				if(LOCKED = '0') then
					RST <= '1';
					RD_EN <= '0';
					state <= WAIT_FOR_LOCK;
				else
					RST <= '0';
					RD_EN <= '1';
				end if;
			
			when WAIT_FOR_LOCK =>
				if(LOCKED = '1') then
					state <= D1;
				end if;
				
			when D1 =>
				state <= D2;
				
			when D2 =>
				RST <= '0';
				counter <= 15;
				state <= COUNTDOWN;
			
			when COUNTDOWN =>
				if(counter = 0) then
					RD_EN <= '1';
					state <= RUNNING;
				else
					counter <= counter - 1;
				end if;
		end case;
		end if;
		end process;
		

end Behavioral;

