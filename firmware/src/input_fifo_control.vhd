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
	generic (
		DESIRED_FIFO_LEVEL : natural := 15
	);
    Port ( 
		SYSCLK : in  STD_LOGIC;
		LOCKED : in  STD_LOGIC;
		RCLK : in std_logic;		
		RST : out  STD_LOGIC;
		RD_EN : out  STD_LOGIC);
end input_fifo_control;

architecture Behavioral of input_fifo_control is

		type state_t is (RUNNING, WAIT_FOR_LOCK, D1, D2, D3, D4);
		signal state : state_t := RUNNING;
		signal counter : natural range 0 to 15;

		type cmd_t is (NONE, RESET_SEQ);
		signal cmd : cmd_t := NONE;


		type rstate_t is (NORMAL, RESETTING, WAITING);
		signal rstate : rstate_t := NORMAL;
		signal out_rst : std_logic := '0';
		signal out_rd_en : std_logic := '0';
		signal count : natural := 0;
begin

		-- When the clock relocks, set cmd to RESET_SEQ
		-- for 4 clocks to make sure that the process on
		-- the other clock sees it. The slowest clock is
		-- 27MHz so 4 should be enough. This is a form of
		-- blind pulse cross logic.
		process(SYSCLK) is
		begin
		if(rising_edge(SYSCLK)) then
		case state is
			when RUNNING =>
				if(LOCKED = '0') then
					state <= WAIT_FOR_LOCK;
				end if;
			
			when WAIT_FOR_LOCK =>
				if(LOCKED = '1') then
					cmd <= RESET_SEQ;
					state <= D1;
				end if;
				
			when D1 =>
				state <= D2;
				
			when D2 =>
				state <= D3;

			when D3 =>
				state <= D4;
			
			when D4 =>
				cmd <= NONE;
				state <= RUNNING;
			
		end case;
		end if;
		end process;
		
		
		process(RCLK) is
		begin
		if(rising_edge(RCLK)) then
		case rstate is
			when NORMAL =>
				out_rst <= '0';
				out_rd_en <= '1';
				-- Wait at least 10 clocks before checking cmd.
				-- This will prevent the command from running twice.
				-- Since this is a very slow rate event there's no danger
				-- of missing a future command.
				if(count = 0) then
					if(cmd = RESET_SEQ) then
						rstate <= RESETTING;
					end if;
				else
					count <= count - 1;
				end if;
			
			when RESETTING =>
				out_rst <= '1';
				out_rd_en <= '0';
				count <= DESIRED_FIFO_LEVEL;
				rstate <= WAITING;
			
			when WAITING =>
				out_rst <= '0';
				out_rd_en <= '0';
				if(count = 0) then
					count <= 10;
					rstate <= NORMAL;
				else
					count <= count - 1;
				end if;
			
		end case;
		end if;
		end process;
		
		RST <= out_rst;
		RD_EN <= out_rd_en;

end Behavioral;

