----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:57:57 06/08/2019 
-- Design Name: 
-- Module Name:    internal_mcb - Behavioral 
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

entity internal_mcb is
	Port ( 
		MCLK : in std_logic;
		TRANSACTION_SIZE : in std_logic_vector(7 downto 0); -- number of fifo elements to read/write at once
		
		-- interface common to both fifos
		MREADY : in std_logic;
		MFLUSH : in std_logic;
		MAVAIL : in std_logic_vector(8 downto 0);
		
		-- interface to data-to-write fifo
		MPOP_W : out std_logic;
		MDATA_W : in std_logic_vector(255 downto 0);  -- half-burst data (4 high speed clocks worth of data)
		MADDR_W : in std_logic_vector(23 downto 0);   -- ddr address, high 24 bits
		MDVALID_W : in std_logic;                      -- data valid
		
		-- interface to data-to-read fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(23 downto 0);   -- ddr address, high 24 bits
		MDVALID_R : in std_logic;
		
		-- interface to data-just-read fifo
		MPUSH : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
end internal_mcb;

architecture Behavioral of internal_mcb is

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

	constant ram_addr_width : natural := 9;
	constant ram_data_width : natural := 512;
	signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0) := (others => '0');
	signal ram_wdata1 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0) := (others => '0');
	signal ram_rdata2 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_we : std_logic;

	
	type state_t is (WAITING_FOR_DATA, DELAY1, WRITE_STREAM, DELAY1R, DELAY2R, READ_STREAM, READFINISH);
	signal state : state_t := WAITING_FOR_DATA;
	signal count : natural range 0 to 255 := 0;
	signal limit : natural range 0 to 255 := 0;
	signal pop_w : std_logic := '0';
	signal pop_r : std_logic := '0';
	signal mpush_r : std_logic := '0';
	
	signal wdata : std_logic_vector(255 downto 0) := (others => '0');
	signal we_d : std_logic := '0';

	signal even : std_logic := '1';
	signal active : std_logic := '0';
begin

	MPOP_W <= pop_w;
	MPOP_R <= pop_r;
	MPUSH <= mpush_r;
	ram_raddr2 <= MADDR_R(8 downto 0);

	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
	case state is
		when WAITING_FOR_DATA =>
			active <= '0';
			mpush_r <= '0';
			if(MREADY = '1') then
				-- This indicates that it is safe to read out TRANSACTION_SIZE elements
				-- from the two fifos
				pop_w <= '1';
				count <= 0;
				even <= '1';
				limit <= to_integer(unsigned(TRANSACTION_SIZE));
				state <= DELAY1;
			elsif(MFLUSH = '1' and to_integer(unsigned(MAVAIL)) > 0) then
				pop_w <= '1';
				count <= 0;
				even <= '1';
				limit <= to_integer(unsigned(MAVAIL));
				state <= DELAY1;
			else
				pop_w <= '0';
			end if;
			
		when DELAY1 =>
			state <= WRITE_STREAM;
			
		when WRITE_STREAM =>
			if(count = limit-2) then
				pop_w <= '0';
			end if;
			
			
			if(count = limit) then
				even <= '1';
				active <= '0';
				pop_r <= '1';
				count <= 0;
				state <= DELAY1R;
			else
				active <= '1';
				count <= count + 1;
				even <= not even;
				if(even = '1') then
					ram_wdata1(255 downto 0) <= MDATA_W;
				else
					ram_wdata1(511 downto 256) <= MDATA_W;
				end if;
			end if;
			
		
		when DELAY1R =>
			state <= DELAY2R;
		when DELAY2R =>
			state <= READ_STREAM;
			
		when READ_STREAM =>
			if(count = limit-3) then
				pop_r <= '0';
			end if;
			
			if(count = limit) then
				even <= '0';
				mpush_r <= '0';
				state <= READFINISH;
			else
				count <= count + 1;
				mpush_r <= '1';
				even <= not even;
				if(even = '1') then
					MDATA_R <= ram_rdata2(255 downto 0);
				else
					MDATA_R <= ram_rdata2(511 downto 256);
				end if;
			end if;
			
			
		when READFINISH =>
			state <= WAITING_FOR_DATA;
			
	end case;
	end if;
	end process;
	
	ram_we <= active and even;
	
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
		ram_waddr1 <= MADDR_W(8 downto 0);
	end if;
	end process;
	
	
	bram_inst: bram_simple_dual_port 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		CLK1 => MCLK,
		WADDR1 => ram_waddr1,
		WDATA1 => ram_wdata1,
		WE1 => ram_we,
		CLK2 => MCLK,
		RADDR2 => ram_raddr2,
		RDATA2 => ram_rdata2
	);
	

end Behavioral;

