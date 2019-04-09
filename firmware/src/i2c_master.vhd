----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:12:36 04/03/2019 
-- Design Name: 
-- Module Name:    i2c_master - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity i2c_master is
	Port ( 
		CLK : in  STD_LOGIC;
		SLAVE_ADDR : in std_logic_vector(6 downto 0);
		SLAVE_REG : in std_logic_vector(7 downto 0);
		
		CMD_WRITE : in std_logic;
		WRITE_DATA : in std_logic_vector(7 downto 0);

		CMD_READ : in std_logic;
		
		REPLY_ACK : out std_logic;
		REPLY_NACK : out std_logic;
		REPLY_DATA : out std_logic_vector(7 downto 0);
		REPLY_VALID : out std_logic;
		
		SDA : inout  STD_LOGIC;
		SCL : inout  STD_LOGIC
	);
end i2c_master;

architecture Behavioral of i2c_master is

	-- This sets the baud of the transfer.
	-- It is the number of CLKs in one period of SCL.
	-- Normal speed is 100kHz which is 10us period.
	-- If CLK is 100MHz that means there are 1e8 / 1e5 = 1000 CLKs per SCL
	constant SCL_PERIOD : natural := 1000;
	constant SCL_HALF_PERIOD : natural := SCL_PERIOD / 2;
	constant SCL_QUARTER_PERIOD : natural := SCL_PERIOD / 4;
	
	signal sda_read : std_logic;
	signal scl_read : std_logic;

	signal sda_state : std_logic := '1';
	signal scl_state : std_logic := '1';
	

	type sub_cmd_t is (NONE, SUB_RST, START, REPEATED_START, STOP, WRITE_BIT, READ_BIT);
	signal sub_cmd : sub_cmd_t := NONE;
	
	type sub_state_t is (SUB_IDLE, DELAY, SUB_START2, SUB_RSTART2, SUB_RSTART3, SUB_WRITE2, 
								SUB_WRITE3, SUB_READ2, SUB_READ3, SUB_READ4, SUB_STOP2, SUB_STOP3);
	signal sub_state : sub_state_t := SUB_IDLE;
	signal sub_ret : sub_state_t := SUB_IDLE;
	signal count : natural range 0 to SCL_PERIOD := 0;
	signal sub_input_bit : std_logic := '0';
	signal sub_output_bit : std_logic := '0';
	
	type cmd_t is (CWRITE, CREAD);
	signal cmd_saved : cmd_t := CWRITE;
	signal addr_saved : std_logic_vector(6 downto 0) := (others => '0');
	signal reg_saved : std_logic_vector(7 downto 0) := (others => '0');
	signal data_saved : std_logic_vector(7 downto 0) := (others => '0');
	
	type fsm_state_t is (IDLE, DELAY, WAIT_FOR_DONE, SEND_ADDR_W, SEND_REG, SEND_DATA, 
								BEGIN_READ, SEND_ADDR_R, RECEIVE_DATA, SHIFT_BITS, SHIFT_BITS_IN,
								BIT9, BIT9W, ACK, STOP, FINISH_WRITE, FINISH_READ, FINISH_FAILED);
	signal fsm_state : fsm_state_t := IDLE;
	signal fsm_ret : fsm_state_t := IDLE;
	signal ack_ret : fsm_state_t := IDLE;
	signal stop_ret : fsm_state_t := IDLE;
	
	signal shifter : std_logic_vector(7 downto 0) := (others => '0');
	signal shift_count : natural range 0 to 8 := 0;
	
begin

	-- SDA switches directions depending on where we are in the protocol,
	-- so this line is a true bidirectional I/O. Because I2C operates using
	-- pullups, we only ever drive the pin to ground. Sending a '1' is done
	-- by tri-stating the buffer, which allows the pullup to do its job.
	
   sdabuf : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "I2C",
      SLEW => "SLOW")
   port map (
      O => sda_read,  -- data received from pin
      IO => SDA,      -- pin
      I => '0',       -- data to send to pin
      T => sda_state  -- High = Z (receive data from pin; pin floats high)
   );
   sda_pullup : PULLUP
   port map (
      O => SDA     -- Pullup output (connect directly to top-level port)
   );

   sclbuf : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "I2C",
      SLEW => "SLOW")
   port map (
      O => open,
      IO => SCL,
      I => '0',
      T => scl_state
   );
   scl_pullup : PULLUP
   port map (
      O => SCL     -- Pullup output (connect directly to top-level port)
   );
	
	
	
	-- I2C write register(s):
	-- start | slave_addr | 0 | ACK | register | ACK | data | ACK | stop
	
	-- I2C read register(s) via repeated start:
	-- start | slave_addr | 0 | ACK | register | ACK | start | slave_addr | 1 | ACK | data | ACK | stop

	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
	
		case fsm_state is
			when IDLE =>
				REPLY_ACK <= '0';
				REPLY_NACK <= '0';
				REPLY_VALID <= '0';
			
				if(CMD_WRITE = '1') then
					cmd_saved <= CWRITE;
					addr_saved <= SLAVE_ADDR;
					reg_saved <= SLAVE_REG;
					data_saved <= WRITE_DATA;
					sub_cmd <= START;
					fsm_state <= DELAY;
					fsm_ret <= SEND_ADDR_W;
				elsif(CMD_READ = '1') then
					cmd_saved <= CREAD;
					addr_saved <= SLAVE_ADDR;
					reg_saved <= SLAVE_REG;
					sub_cmd <= START;
					fsm_state <= DELAY;
					fsm_ret <= SEND_ADDR_W;
				else
					sub_cmd <= NONE;
				end if;
				
			when DELAY =>
				-- it takes a clock for the subroutine to see the command
				sub_cmd <= NONE;
				fsm_state <= WAIT_FOR_DONE;
				
			when WAIT_FOR_DONE =>
				if(sub_state = SUB_IDLE) then
					fsm_state <= fsm_ret;
				end if;
				
			when SEND_ADDR_W =>
				shifter <= addr_saved & '0'; -- write operation to follow
				shift_count <= 0;
				fsm_state <= SHIFT_BITS;
				ack_ret <= SEND_REG;
				
			when SEND_REG =>
				shifter <= reg_saved;
				shift_count <= 0;
				fsm_state <= SHIFT_BITS;
				if(cmd_saved = CWRITE) then
					ack_ret <= SEND_DATA;
				else
					ack_ret <= BEGIN_READ;
				end if;
				
			when SEND_DATA =>
				shifter <= data_saved;
				shift_count <= 0;
				fsm_state <= SHIFT_BITS;
				ack_ret <= STOP;
				stop_ret <= FINISH_WRITE;
				
			when BEGIN_READ =>
				sub_cmd <= REPEATED_START;
				fsm_state <= DELAY;
				fsm_ret <= SEND_ADDR_R;
				
			when SEND_ADDR_R =>
				shifter <= addr_saved & '1'; -- read operation to follow
				shift_count <= 0;
				fsm_state <= SHIFT_BITS;
				ack_ret <= RECEIVE_DATA;
				
			when RECEIVE_DATA =>
				shifter <= (others => '0');
				shift_count <= 0;
				sub_cmd <= READ_BIT;
				fsm_state <= DELAY;
				fsm_ret <= SHIFT_BITS_IN;
				stop_ret <= FINISH_READ;
				
				
			
			when SHIFT_BITS =>
				if(shift_count = 8) then
					fsm_state <= BIT9;
				else
					sub_output_bit <= shifter(7);
					for i in 1 to 7 loop
						shifter(i) <= shifter(i-1);
					end loop;
					shift_count <= shift_count + 1;
					sub_cmd <= WRITE_BIT;
					fsm_state <= DELAY;
					fsm_ret <= SHIFT_BITS;
				end if;
			
			when SHIFT_BITS_IN =>
				shifter(0) <= sub_input_bit;
				for i in 1 to 7 loop
					shifter(i) <= shifter(i-1);
				end loop;
				shift_count <= shift_count + 1;
				
				if(shift_count = 7) then
					fsm_state <= BIT9W;
				else
					sub_cmd <= READ_BIT;
					fsm_state <= DELAY;
					fsm_ret <= SHIFT_BITS_IN;
				end if;
			
			when BIT9 =>
				sub_cmd <= READ_BIT;
				fsm_state <= DELAY;
				fsm_ret <= ACK;
				
			when BIT9W =>
				-- When I'm reading from the slave, I must send an ACK in order to
				-- read more bytes, or send a NACK to conclude the transaction
				sub_output_bit <= '1'; -- hardcoded NACK (single byte read)
				sub_cmd <= WRITE_BIT;
				fsm_state <= DELAY;
				fsm_ret <= STOP;
			
			when ACK =>
				-- The subroutine writes sub_input_bit to tell me the value it read.
				-- An ACK is 0, a NACK is 1
				if(sub_input_bit = '1') then
					-- getting a NACK also cancels the operation
					sub_cmd <= STOP;
					fsm_state <= DELAY;
					fsm_ret <= FINISH_FAILED;
				else
					-- proceed
					fsm_state <= ack_ret;
				end if;
				
			when STOP =>
				sub_cmd <= STOP;
				fsm_state <= DELAY;
				fsm_ret <= stop_ret;
				
			
			when FINISH_WRITE =>
				REPLY_ACK <= '1';
				REPLY_NACK <= '0';
				REPLY_DATA <= (others => '0');
				REPLY_VALID <= '1';
				fsm_state <= IDLE;
				
			when FINISH_READ =>
				REPLY_ACK <= '1';
				REPLY_NACK <= '0';
				REPLY_DATA <= shifter;
				REPLY_VALID <= '1';
				fsm_state <= IDLE;
			
			when FINISH_FAILED =>
				REPLY_ACK <= '0';
				REPLY_NACK <= '1';
				REPLY_VALID <= '1';
				fsm_state <= IDLE;
				
				
		end case;
	
	
	
		if(sub_cmd = SUB_RST) then
			scl_state <= '1';
			sda_state <= '1';
			sub_state <= SUB_IDLE;
		else
			case sub_state is
				when SUB_IDLE =>
				
					if(sub_cmd = START) then
						-- START is a high-to-low transition on SDA while SCL is high
						-- (Here I've assumed SCL was already high)
						scl_state <= '1';
						sda_state <= '0';
						-- stay in this state for period/2
						count <= SCL_HALF_PERIOD;
						sub_state <= DELAY;
						sub_ret <= SUB_START2;
						
					elsif(sub_cmd = REPEATED_START) then
						-- Here I assume SCL is low because we're at the end of a bit
						scl_state <= '0';
						sda_state <= '1';
						count <= SCL_QUARTER_PERIOD;
						sub_state <= DELAY;
						sub_ret <= SUB_RSTART2;
						
					elsif(sub_cmd = STOP) then
						scl_state <= '0';
						sda_state <= '0';
						-- stay in this state for period/2
						count <= SCL_QUARTER_PERIOD;
						sub_state <= DELAY;
						sub_ret <= SUB_STOP2;
					
					elsif(sub_cmd = WRITE_BIT) then
						-- SCL should already be low but just to be explicit
						scl_state <= '0';
						sda_state <= sub_output_bit;
						count <= SCL_QUARTER_PERIOD;
						sub_state <= DELAY;
						sub_ret <= SUB_WRITE2;
						
					elsif(sub_cmd = READ_BIT) then
						-- Here we tristate SDA and get the value of the bus in the middle of SCL being high
						scl_state <= '0';
						sda_state <= '1';
						count <= SCL_QUARTER_PERIOD;
						sub_state <= DELAY;
						sub_ret <= SUB_READ2;
					
					else
						sub_state <= SUB_IDLE;
					end if;
				
				when SUB_START2 =>
					-- finish off the start sequence by driving scl low for 1/4 period
					scl_state <= '0';
					sda_state <= '0';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_IDLE;
					
				when SUB_RSTART2 =>
					scl_state <= '1';
					sda_state <= '1';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_RSTART3;
					
				when SUB_RSTART3 =>
					scl_state <= '1';
					sda_state <= '0';
					count <= SCL_HALF_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_START2;
					
				when SUB_WRITE2 =>
					scl_state <= '1';
					count <= SCL_HALF_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_WRITE3;
					
				when SUB_WRITE3 =>
					scl_state <= '0';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_IDLE;
					
				when SUB_READ2 =>
					scl_state <= '1';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_READ3;
					
				when SUB_READ3 =>
					scl_state <= '1';
					sub_input_bit <= sda_read;
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_READ4;
					
				when SUB_READ4 =>
					scl_state <= '0';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_IDLE;
					
				when SUB_STOP2 =>
					sda_state <= '0';
					scl_state <= '1';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_STOP3;
					
				when SUB_STOP3 =>
					sda_state <= '1';
					scl_state <= '1';
					count <= SCL_QUARTER_PERIOD;
					sub_state <= DELAY;
					sub_ret <= SUB_IDLE;
					
					
				when DELAY =>
					if(count = 0) then
						sub_state <= sub_ret;
					else
						count <= count - 1;
					end if;
					
			end case;
		end if;

	end if;
	end process;

end Behavioral;

