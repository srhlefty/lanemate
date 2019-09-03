----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:06:36 04/05/2019 
-- Design Name: 
-- Module Name:    i2c_slave - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity i2c_slave is
	Generic (
		SLAVE_ADDRESS : std_logic_vector(6 downto 0)
	);
	Port ( 
		CLK : in  STD_LOGIC;
		SDA : inout  STD_LOGIC;
		SCL : inout  STD_LOGIC;
		
		DEBUG_STATE : out std_logic_vector(15 downto 0);
		
		-- Interface to the register map, e.g. dual-port bram
		RAM_ADDR : out std_logic_vector(7 downto 0);
		RAM_WDATA : out std_logic_vector(7 downto 0);
		RAM_WE : out std_logic;
		RAM_RDATA : in std_logic_vector(7 downto 0)
	);
end i2c_slave;

architecture Behavioral of i2c_slave is

	component i2c_debounce is
	Generic (
		DEPTH : natural
	);
	Port ( 
		CLK : in  STD_LOGIC;
		DIN : in  STD_LOGIC;
		DOUT : out  STD_LOGIC);
	end component;

	signal reg_ptr : std_logic_vector(7 downto 0) := x"00";
	signal reg_addr : std_logic_vector(7 downto 0) := x"00";
	signal reg_wdata : std_logic_vector(7 downto 0) := x"00";
	signal reg_we : std_logic := '0';
	
	type target_t is (WRITE_REG, WRITE_VAL);
	signal write_target : target_t := WRITE_REG;

	
	constant CLK_FREQ : natural := 50e6;
	constant I2C_FREQ : natural := 100e3; -- standard I2C mode 100kHz
	constant SCL_PERIOD : natural := CLK_FREQ / I2C_FREQ;
	constant SCL_HALF_PERIOD : natural := SCL_PERIOD / 2;
	constant SCL_QUARTER_PERIOD : natural := SCL_PERIOD / 4;

	type state_t is (IDLE, S1, S2, S3, S4);
	signal state : state_t := IDLE;
	signal listen_ret : state_t := IDLE;
	
	signal read_buffer : std_logic_vector(7 downto 0) := (others => '0');
	signal read_bit : std_logic := '0';
	signal write_bit : std_logic := '0';
	signal write_enable : std_logic := '0';
	signal shift_reset : std_logic := '0';
	signal shift_load : std_logic := '0';
	signal wdata : std_logic_vector(8 downto 0) := (others => '0');
	
	
	signal sda_old : std_logic := '1';
	signal scl_old : std_logic := '1';
	signal sda_state : std_logic := '1';
	signal sda_read : std_logic;
	signal sda_pin : std_logic;
	signal scl_read : std_logic;
	signal scl_pin : std_logic;
	
	signal debug : std_logic_vector(15 downto 0) := x"0000";
begin

	RAM_ADDR <= reg_addr;
	RAM_WE <= reg_we;
	RAM_WDATA <= reg_wdata;
	
	DEBUG_STATE <= debug;


   sdabuf : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "I2C",
      SLEW => "SLOW")
   port map (
      O => sda_pin,  -- data received from pin
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
      O => scl_pin,
      IO => SCL,
      I => '0',
      T => '1' -- my slave doesn't need to drive SCL
   );
   scl_pullup : PULLUP
   port map (
      O => SCL     -- Pullup output (connect directly to top-level port)
   );

	scl_debounce: i2c_debounce
	generic map ( DEPTH => 5)
	PORT MAP(
		CLK => CLK,
		DIN => scl_pin,
		DOUT => scl_read
	);
	sda_debounce: i2c_debounce
	generic map ( DEPTH => 5)
	PORT MAP(
		CLK => CLK,
		DIN => sda_pin,
		DOUT => sda_read
	);

	edge_detect : process(CLK) is
	begin
	if(rising_edge(CLK)) then
		sda_old <= sda_read;
		scl_old <= scl_read;
	end if;
	end process;
	
	read_shifter : block is
		type state_t is (IDLE, DELAY);
		signal state : state_t := IDLE;
		signal count : natural range 0 to SCL_QUARTER_PERIOD := 0;
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if(shift_reset = '1') then
				debug(7 downto 0) <= x"FF";
				state <= IDLE;
			else
				case state is
					when IDLE =>
						debug(7 downto 0) <= x"01";
						read_bit <= '0';
						-- wait for rising edge
						if(scl_old = '0' and scl_read = '1') then
							count <= SCL_QUARTER_PERIOD;
							state <= DELAY;
						end if;
						
					when DELAY =>
						debug(7 downto 0) <= x"02";
						if(count = 0) then
							read_buffer(0) <= sda_read;
							read_bit <= '1';
							for i in 1 to read_buffer'high loop
								read_buffer(i) <= read_buffer(i-1);
							end loop;
							state <= IDLE;
						else
							count <= count - 1;
						end if;
				end case;
			end if;
		end if;
		end process;
	end block;
	
	write_shifter : block is
		type state_t is (IDLE, DELAY);
		signal state : state_t := IDLE;
		signal count : natural range 0 to SCL_QUARTER_PERIOD := 0;
		signal shift_data : std_logic_vector(8 downto 0) := (others => '1');
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if(shift_reset = '1') then
				debug(15 downto 8) <= x"FF";
				state <= IDLE;
				sda_state <= '1';
				shift_data <= (others => '1');
			elsif(shift_load = '1') then
				debug(15 downto 8) <= x"AA";
				shift_data <= wdata;
			else
				case state is
					when IDLE =>
						debug(15 downto 8) <= x"01";
						write_bit <= '0';
						-- wait for falling edge
						if(scl_old = '1' and scl_read = '0') then
							count <= SCL_QUARTER_PERIOD;
							state <= DELAY;
						end if;
						
					when DELAY =>
						debug(15 downto 8) <= x"02";
						if(count = 0) then
							write_bit <= '1';
							if(write_enable = '1') then
								sda_state <= shift_data(shift_data'high);
							else
								sda_state <= '1';
							end if;
							for i in 1 to shift_data'high loop
								shift_data(i) <= shift_data(i-1);
							end loop;
							shift_data(0) <= '1';
							state <= IDLE;
						else
							count <= count - 1;
						end if;
				end case;
			end if;
		end if;
		end process;
	end block;
	
	
	protocol : block is
		signal read_count : natural range 0 to 8 := 0;
		signal write_count : natural range 0 to 8 := 0;
		type state_t is (IDLE, STARTED, ACK, ACK2, ACK3, ACCEPT_REGISTER, ACCEPT_DATA, READOUT, DELAY1, LOAD_NEXT, WAIT_FOR_WRITE, WAIT_FOR_ACK);
		signal state : state_t := IDLE;
		signal ack_ret : state_t := IDLE;
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if(sda_old = '1' and sda_read = '0' and scl_read = '1') then
				-- START
				shift_reset <= '1';
				read_count <= 0;
				write_count <= 0;
				state <= STARTED;
			elsif(sda_old = '0' and sda_read = '1' and scl_read = '1') then
				-- STOP
				shift_reset <= '1';
				state <= IDLE;
			else
				shift_reset <= '0';
				
				case state is
					
					when IDLE =>
						state <= IDLE;
						
					when STARTED =>
						-- After start, I need to read 8 bits and then ACK if it's for me
						if(read_bit = '1') then
							read_count <= read_count + 1;
							if(read_count = 7) then
								-- read_count lags by 1, so if it's 7 that means I just shifted in
								-- the 8th bit, and so can look at the address and R/W bit
								if(read_buffer(7 downto 1) = SLAVE_ADDRESS) then
									state <= ACK;
									if(read_buffer(0) = '0') then
										-- Master is writing my register pointer optionally followed by data
										ack_ret <= ACCEPT_REGISTER;
									else
										-- Master wants to read whatever's at the register pointer
										-- After reading, pointer is auto-incremented
										ack_ret <= READOUT;
									end if;
								else
									state <= IDLE;
								end if;
							end if;
						end if;
						
					when ACK =>
						-- Give control to the write shift register
						-- so that it will write out an ACK for me
						reg_we <= '0';
						reg_addr <= reg_ptr;
						write_enable <= '1';
						if(ack_ret = READOUT) then
							wdata <= "0" & RAM_RDATA;
						else
							wdata <= "011111111";
						end if;
						shift_load <= '1';
						state <= ACK2;
						
					when ACK2 =>
						shift_load <= '0';
						-- wait for the next write_bit indicating SDA changed
						if(write_bit = '1') then
							state <= ACK3;
						end if;
					
					when ACK3 =>
						-- wait again for the next write_bit, indicating that
						-- the clock pulse is over
						if(write_bit = '1') then
							write_enable <= '0';
							-- next stage of protocol
							-- After ACK we could get a register value, data, start, or stop
							read_count <= 0;
							state <= ack_ret;
						end if;
						
						
					when ACCEPT_REGISTER =>
						-- Read 8 bits and then set my register pointer
						if(read_bit = '1') then
							read_count <= read_count + 1;
							if(read_count = 7) then
								-- read_count lags by 1, so if it's 7 that means I just shifted in
								-- the 8th bit
								reg_ptr <= read_buffer;
								reg_addr <= read_buffer;
								state <= ACK;
								-- After this byte, I'll normally get either a data byte or a start.
								-- Start/stop is handled outside the state machine, so here I can
								-- just assume data is to follow.
								ack_ret <= ACCEPT_DATA;
							end if;
						end if;
						
					when ACCEPT_DATA =>
						if(read_bit = '1') then
							read_count <= read_count + 1;
							if(read_count = 7) then
								-- read_count lags by 1, so if it's 7 that means I just shifted in
								-- the 8th bit
								reg_addr <= reg_ptr;
								reg_wdata <= read_buffer;
								reg_we <= '1';
								reg_ptr <= std_logic_vector(to_unsigned(to_integer(unsigned(reg_ptr)) + 1, reg_ptr'length));
								state <= ACK;
								ack_ret <= ACCEPT_DATA; -- the only way out of this state is a start/stop
							end if;
						end if;
						
						
					when READOUT =>
						-- Here we are after the ACK of a read command.
						-- I've already loaded the write shift register with the data to be
						-- sent out, and the first bit of data has just transitioned onto SDA.
						-- Let the write shift register run 7 more times.
						write_enable <= '1';
						if(write_bit = '1') then
							write_count <= write_count + 1;
							if(write_count = 6) then
								-- All done writing. Now I expect an ACK or NACK from the master,
								-- and I need to increment the read pointer.
								reg_ptr  <= std_logic_vector(to_unsigned(to_integer(unsigned(reg_ptr)) + 1, reg_ptr'length));
								reg_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(reg_ptr)) + 1, reg_ptr'length));
								state <= DELAY1;
							end if;
						end if;

					when DELAY1 =>
						state <= LOAD_NEXT;
						
					when LOAD_NEXT =>
						wdata <= RAM_RDATA & "1";
						shift_load <= '1';
						write_enable <= '0';
						state <= WAIT_FOR_WRITE;

					when WAIT_FOR_WRITE =>
						shift_load <= '0';
						-- Wait until the next write bit
						if(write_bit = '1') then
							-- Now we are in the gap before the ACK bit.
							-- Since we've already shifted out all the data, SDA has transitioned high
							-- in preparation for the read.
							-- The next thing to do is wait until the next bit is read, and that will
							-- be the master's ACK or NACK
							state <= WAIT_FOR_ACK;
						end if;
					
					when WAIT_FOR_ACK =>
						if(read_bit = '1') then
							-- If the master sends ACK, there will be another read.
							-- If NACK, next will be stop.
							if(read_buffer(0) = '0') then
								-- ACK
								state <= READOUT;
							else
								-- NACK
								state <= IDLE;
							end if;
						end if;
						
				end case;
			end if;
		end if;
		end process;
	end block;

end Behavioral;

