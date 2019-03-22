----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:13:56 03/22/2019 
-- Design Name: 
-- Module Name:    pulse_delay - Behavioral 
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
-- This module is designed to delay an arbitrary pulse train (on each of 3 lines)
-- by up to 32767 clocks. It does this by simply pushing the bus data into a FIFO
-- and popping it out again. After a RST, the output will be zero until the delay
-- time has been reached, at which point the data after the RST will begin to appear.
-- The actual delay is 4 clocks more than that provided by DELAY.
-- DELAY is only sampled on startup and after RST.
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

entity pulse_delay is
	Port ( 
		CLK : in  STD_LOGIC;
		D : in  STD_LOGIC_VECTOR(2 downto 0);
		RST : in STD_LOGIC;
		DELAY : in  STD_LOGIC_VECTOR (14 downto 0);
		DOUT : out  STD_LOGIC_VECTOR(2 downto 0);
		OVERFLOW : out  STD_LOGIC);
end pulse_delay;

architecture Behavioral of pulse_delay is

	component bram_simple_dual_port is
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
	end component;
	
	component fifo_1clk is
	generic (
		ADDR_WIDTH : natural := 8;
		DATA_WIDTH : natural := 8
	);
    Port ( 
		CLK : in std_logic;
		
		DIN  : in std_logic_vector (DATA_WIDTH-1 downto 0);
		PUSH : in std_logic;
		
		POP  : in std_logic;
		DOUT : out  std_logic_vector (DATA_WIDTH-1 downto 0);
		DVALID : out std_logic;
		
		RESET : in std_logic;
		
		EMPTY : out std_logic;
		OVERFLOW : out std_logic;
		
		-- dual port ram interface
		
		RAM_WADDR1 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_WDATA1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RAM_WE1    : out std_logic;
		
		RAM_RADDR2 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_RDATA2 : in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	end component;

	constant ram_addr_width : natural := 15;
	constant ram_data_width : natural := 3;

	signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_wdata1 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_rdata2 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_we : std_logic;
	signal fifo_din : std_logic_vector(ram_data_width-1 downto 0);
	signal fifo_dout : std_logic_vector(ram_data_width-1 downto 0);
	signal fifo_dvalid : std_logic;
	signal fifo_push : std_logic := '0';
	signal fifo_pop : std_logic := '0';
	signal fifo_reset : std_logic := '0';
	signal fifo_empty : std_logic;
	signal fifo_overflow : std_logic;
	
	type state_t is (FILLING, ACTIVE);
	signal state : state_t := FILLING;
	signal count : natural := 0;
	
begin

	Inst_bram_simple_dual_port: bram_simple_dual_port 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		CLK1 => CLK,
		WADDR1 => ram_waddr1,
		WDATA1 => ram_wdata1,
		WE1 => ram_we,
		CLK2 => CLK,
		RADDR2 => ram_raddr2,
		RDATA2 => ram_rdata2
	);
	Inst_fifo_1clk: fifo_1clk 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		CLK => CLK,
		DIN => fifo_din,
		PUSH => fifo_push,
		POP => fifo_pop,
		DOUT => fifo_dout,
		DVALID => fifo_dvalid,
		RESET => fifo_reset,
		EMPTY => fifo_empty,
		OVERFLOW => fifo_overflow,
		RAM_WADDR1 => ram_waddr1,
		RAM_WDATA1 => ram_wdata1,
		RAM_WE1 => ram_we,
		RAM_RADDR2 => ram_raddr2,
		RAM_RDATA2 => ram_rdata2
	);

	OVERFLOW <= fifo_overflow;
	fifo_din <= D;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
	case state is
		when FILLING =>
			fifo_push <= '1';
			fifo_pop <= '0';
			DOUT <= (others => '0');
			count <= count + 1;
			if(count = to_integer(unsigned(DELAY))) then
				state <= ACTIVE;
			end if;
			
		when ACTIVE =>
			fifo_push <= '1';
			fifo_pop <= '1';
			DOUT <= fifo_dout;
			if(RST = '1') then
				count <= 0;
				state <= FILLING;
			end if;
	end case;
	end if;
	end process;
	
end Behavioral;

