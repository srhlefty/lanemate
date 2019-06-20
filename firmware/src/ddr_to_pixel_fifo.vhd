----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:06:50 03/26/2019 
-- Design Name: 
-- Module Name:    ddr_to_pixel_fifo - Behavioral 
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
-- This module is the reverse of pixel_to_ddr_fifo: it catches data thrown at it
-- by the MCB. Delayed video timing signals cause the outside logic to pull out
-- pixel data from the P interface of this module.
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

entity ddr_to_pixel_fifo is
	Port ( 
		MCLK   : in  STD_LOGIC;
		MRESET : in STD_LOGIC;
		MPUSH  : in  STD_LOGIC;
		MDATA  : in  STD_LOGIC_VECTOR (255 downto 0);
		
		PCLK : in  STD_LOGIC;
		PRESET : in STD_LOGIC;
		P8BIT : in std_logic; -- if high, only the lower 8 bits are active (SD 4:2:2)
		VS : in  STD_LOGIC;
		HS : in  STD_LOGIC;
		DE : in  STD_LOGIC;
		VS_OUT : out STD_LOGIC;
		HS_OUT : out STD_LOGIC;
		DE_OUT : out STD_LOGIC;
		D_OUT : out  STD_LOGIC_VECTOR (23 downto 0)
	);
end ddr_to_pixel_fifo;

architecture Behavioral of ddr_to_pixel_fifo is

	component bram_simple_dual_port is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
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
	end component;
	
	component fifo_2clk is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
	);
    Port ( 
		WRITE_CLK  : in std_logic;
		RESET      : in std_logic;
		FREE       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		DIN        : in std_logic_vector (DATA_WIDTH-1 downto 0);
		PUSH       : in std_logic;

		READ_CLK : in std_logic;
		USED     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		DOUT     : out std_logic_vector (DATA_WIDTH-1 downto 0);
		DVALID   : out std_logic;
		POP      : in std_logic;
		
		-- Dual port ram interface, optionally erasable. Note you wire clocks.
		RAM_WADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_WDATA : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RAM_WE    : out std_logic;
		RAM_RESET : out std_logic;
		
		RAM_RADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_RDATA : in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	end component;
	
	

	constant ram_addr_width : natural := 9;
	constant ram_data_width : natural := 256;

	signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_wdata1 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_rdata2 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_we : std_logic;
	
	signal fifo_data : std_logic_vector(ram_data_width-1 downto 0);
	signal fifo_pop : std_logic := '0';
	
	signal word1 : std_logic_vector(255 downto 0) := (others => '0');
	signal word2 : std_logic_vector(255 downto 0) := (others => '0');
	signal word3 : std_logic_vector(255 downto 0) := (others => '0');
	signal words_ready : std_logic := '0';
	
	signal cmd_pop3 : std_logic := '0';
	signal cmd_output_RGB : std_logic := '0';
	signal cmd_output_L : std_logic := '0';
	signal cmd_output_M : std_logic := '0';
	signal cmd_output_H : std_logic := '0';
	signal cmd_shift : std_logic := '0';
	signal cmd_load : std_logic := '0';
	
	-- The magnitude of the sync delay is determined by de_proc_delay
	-- needing to be long enough that DE is low by the time the final
	-- fifo_pop would take place. This way I don't attempt to load the
	-- next line's data at the end of this one.
	type bit_delay_t is array(natural range <>) of std_logic;
	signal de_proc_delay : bit_delay_t(0 to 16) := (others => '0');
	signal vs_delay : bit_delay_t(0 to 17) := (others => '0');
	signal hs_delay : bit_delay_t(0 to 17) := (others => '0');
	signal de_delay : bit_delay_t(0 to 17) := (others => '0');
begin

	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		vs_delay(vs_delay'high) <= VS;
		hs_delay(vs_delay'high) <= HS;
		de_delay(vs_delay'high) <= DE;
		
		for i in 0 to vs_delay'high-1 loop
			vs_delay(i) <= vs_delay(i+1);
			hs_delay(i) <= hs_delay(i+1);
			de_delay(i) <= de_delay(i+1);
		end loop;
		
		VS_OUT <= vs_delay(0);
		HS_OUT <= hs_delay(0);
		DE_OUT <= de_delay(0);
	end if;
	end process;

	-- This is the FIFO that receives data from the MCB. The the write side runs at
	-- MCLK (100MHz) and the read side runs at PCLK (up to 150MHz for 1080p).

	wide_bram: bram_simple_dual_port 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		CLK1 => MCLK,
		WADDR1 => ram_waddr1,
		WDATA1 => ram_wdata1,
		WE1 => ram_we,
		CLK2 => PCLK,
		RADDR2 => ram_raddr2,
		RDATA2 => ram_rdata2
	);
	
	wide_fifo: fifo_2clk 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		WRITE_CLK => MCLK,
		RESET => MRESET,
		FREE => open,
		DIN => MDATA,
		PUSH => MPUSH,
		READ_CLK => PCLK,
		USED => open,
		DOUT => fifo_data,
		DVALID => open,
		POP => fifo_pop,
		RAM_WADDR => ram_waddr1,
		RAM_WDATA => ram_wdata1,
		RAM_WE => ram_we,
		RAM_RESET => open,
		RAM_RADDR => ram_raddr2,
		RAM_RDATA => ram_rdata2
	);

	-- Attached to the read side is some translation logic to convert the 256-bit words
	-- into a stream of 24-bit words. Like pixel_to_ddr_fifo, 3 256-bit words are handled
	-- at a time and used to fill a 32x24-bit shift register whose shifting is controlled
	-- by DE.
	

	fifo_manager : block is
		type state_t is (MONITOR, DELAY, SAVE1, SAVE2, SAVE3);
		signal state : state_t := MONITOR;
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			case state is
		
			when MONITOR =>
				words_ready <= '0';
				if(cmd_pop3 = '1') then
					fifo_pop <= '1';
					state <= DELAY;
				end if;
					
			when DELAY =>
				fifo_pop <= '1';
				state <= SAVE1;
				
			when SAVE1 =>
				fifo_pop <= '1';
				word1 <= fifo_data;
				state <= SAVE2;
				
			when SAVE2 =>
				fifo_pop <= '0';
				word2 <= fifo_data;
				state <= SAVE3;
			
			when SAVE3 =>
				word3 <= fifo_data;
				words_ready <= '1';
				state <= MONITOR;
				
			end case;
		end if;
		end process;
	end block;
	
	shift_manager : block is
		type shift_t is array(integer range <>) of std_logic_vector(23 downto 0);
		signal shifter : shift_t(0 to 31) := (others => (others => '0'));
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			
			if(cmd_output_RGB = '1') then
				D_OUT <= shifter(0);
			elsif(cmd_output_L = '1') then
				D_OUT <= x"0000" & shifter(0)(7 downto 0);
			elsif(cmd_output_M = '1') then
				D_OUT <= x"0000" & shifter(0)(15 downto 8);
			elsif(cmd_output_H = '1') then
				D_OUT <= x"0000" & shifter(0)(23 downto 16);
			else
				D_OUT <= x"ffffff";
			end if;
			
			if(cmd_shift = '1') then
				for i in 0 to shifter'high-1 loop
					shifter(i) <= shifter(i+1);
				end loop;
				
			elsif(cmd_load = '1') then
				shifter( 0) <= word1( 1*24-1 downto  0*24);
				shifter( 1) <= word1( 2*24-1 downto  1*24);
				shifter( 2) <= word1( 3*24-1 downto  2*24);
				shifter( 3) <= word1( 4*24-1 downto  3*24);
				shifter( 4) <= word1( 5*24-1 downto  4*24);
				shifter( 5) <= word1( 6*24-1 downto  5*24);
				shifter( 6) <= word1( 7*24-1 downto  6*24);
				shifter( 7) <= word1( 8*24-1 downto  7*24);
				shifter( 8) <= word1( 9*24-1 downto  8*24);
				shifter( 9) <= word1(10*24-1 downto  9*24);
				shifter(10) <= word2(7 downto 0) & word1(255 downto 10*24);
				shifter(11) <= word2( 1*24-1 +8 downto 0*24 +8);
				shifter(12) <= word2( 2*24-1 +8 downto 1*24 +8);
				shifter(13) <= word2( 3*24-1 +8 downto 2*24 +8);
				shifter(14) <= word2( 4*24-1 +8 downto 3*24 +8);
				shifter(15) <= word2( 5*24-1 +8 downto 4*24 +8);
				shifter(16) <= word2( 6*24-1 +8 downto 5*24 +8);
				shifter(17) <= word2( 7*24-1 +8 downto 6*24 +8);
				shifter(18) <= word2( 8*24-1 +8 downto 7*24 +8);
				shifter(19) <= word2( 9*24-1 +8 downto 8*24 +8);
				shifter(20) <= word2(10*24-1 +8 downto 9*24 +8);
				shifter(21) <= word3(15 downto 0) & word2(255 downto 10*24 +8);
				shifter(22) <= word3( 1*24-1 +16 downto 0*24 +16);
				shifter(23) <= word3( 2*24-1 +16 downto 1*24 +16);
				shifter(24) <= word3( 3*24-1 +16 downto 2*24 +16);
				shifter(25) <= word3( 4*24-1 +16 downto 3*24 +16);
				shifter(26) <= word3( 5*24-1 +16 downto 4*24 +16);
				shifter(27) <= word3( 6*24-1 +16 downto 5*24 +16);
				shifter(28) <= word3( 7*24-1 +16 downto 6*24 +16);
				shifter(29) <= word3( 8*24-1 +16 downto 7*24 +16);
				shifter(30) <= word3( 9*24-1 +16 downto 8*24 +16);
				shifter(31) <= word3(10*24-1 +16 downto 9*24 +16);
			end if;
		
		end if;
		end process;
	end block;


	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		de_proc_delay(de_proc_delay'high) <= DE;
		for i in 0 to de_proc_delay'high-1 loop
			de_proc_delay(i) <= de_proc_delay(i+1);
		end loop;
	end if;
	end process;

	main_fsm : block is
		type state_t is (WAIT_FOR_DE, STARTUP, NORMAL);
		signal state : state_t := WAIT_FOR_DE;
		signal de_old : std_logic := '0';
		signal shiftcount : natural range 0 to 32 := 0;
		signal cycle : natural range 0 to 2 := 0; -- for 4:2:2 readout
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			de_old <= DE;

		case state is
		when WAIT_FOR_DE =>
			cmd_output_RGB <= '0';
			cmd_output_L <= '0';
			cmd_output_M <= '0';
			cmd_output_H <= '0';
			cmd_shift <= '0';
			cmd_load <= '0';
			shiftcount <= 0;
			cycle <= 0;
			
			if(de_old = '0' and DE = '1') then
				cmd_pop3 <= '1';
				state <= STARTUP;
			end if;
			
		when STARTUP =>
			cmd_pop3 <= '0';
			if(de_proc_delay(1) = '1') then
				cmd_load <= '1';
				state <= NORMAL;
			end if;
			
		when NORMAL =>
			if(de_proc_delay(0) = '1') then
				
				if(P8BIT = '1') then
					if(cycle = 0) then
						cmd_output_L <= '1';
						cmd_output_M <= '0';
						cmd_output_H <= '0';
						cycle <= 1;
					elsif(cycle = 1) then
						cmd_output_L <= '0';
						cmd_output_M <= '1';
						cmd_output_H <= '0';
						cycle <= 2;
					elsif(cycle = 2) then
						cmd_output_L <= '0';
						cmd_output_M <= '0';
						cmd_output_H <= '1';
						cycle <= 0;
					end if;
				else
					cmd_output_RGB <= '1';
				end if;
				
				if(P8BIT = '0' or (P8BIT = '1' and cycle = 2)) then
					-- The DE condition prevents fifo popping at the end of the line.
					-- This works because the startup delay is long enough that DE is
					-- low by the time a pop would take place.
					if(shiftcount = 31-5 and DE = '1') then
						cmd_pop3 <= '1';
					else
						cmd_pop3 <= '0';
					end if;
					
					if(shiftcount = 31) then
						cmd_shift <= '0';
						cmd_load <= '1';
						shiftcount <= 0;
					else
						cmd_shift <= '1';
						cmd_load <= '0';
						shiftcount <= shiftcount + 1;
					end if;
				else
					cmd_pop3 <= '0';
					cmd_shift <= '0';
					cmd_load <= '0';
				end if;
			else
				cmd_pop3 <= '0';
				cmd_output_RGB <= '0';
				cmd_output_L <= '0';
				cmd_output_M <= '0';
				cmd_output_H <= '0';
				cmd_shift <= '0';
				cmd_load <= '0';
				state <= WAIT_FOR_DE;
			end if;
		
		end case;
		
		end if;
		end process;
	end block;

end Behavioral;

