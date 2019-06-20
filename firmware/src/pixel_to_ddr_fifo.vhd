----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:21:10 03/25/2019 
-- Design Name: 
-- Module Name:    pixel_to_ddr_fifo - Behavioral 
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
-- This FIFO sits in between the video source and the SERDES blocks that emit data
-- to the RAM. It has enough space for just under 2 lines of 1080p video. (512x256bit)
-- The pixel side of the interface is the inputs starting with P.
-- The RAM side of the interface is the inputs starting with M.
-- Internally, a gearbox unpacks the stream of 24-bit data into a 256-bit bus which
-- is connected to the 64 SERDES blocks (recall you have to provide 4 data bits per
-- clock when the SERDES is in x4 mode).

-- Notice that 24 does not go evenly into 256: it takes 3 ram elements (768 bits) to hold an
-- integer number of pixels (32). This is handled by using a 32-element, 24-bit shift register
-- to perform a serial-to-parallel conversion to 768 bits. A second stage then does a
-- parallel-to-serial conversion to push 3 256-bit registers into the output FIFO.

-- The intent is for the consumer, the MCB, to monitor MREADY and pop elements out
-- as needed for transfer to the DDR memory.

-- One DDR3 burst is 8 transfers, which is 2 elements of this ram. One complete line:
 
--   1920px * (24 bits/px) / (64 bits/transfer) / (8 transfers/burst) = 90 bursts = 180 elements
--   1280px * (24 bits/px) / (64 bits/transfer) / (8 transfers/burst) = 60 bursts = 120 elements
--   1440ck * ( 8 bits/ck) / (64 bits/transfer) / (8 transfers/burst) = 22.5 bursts = 45 elements

-- To allow for different memory access patterns, the MLIMIT input determines how many elements
-- it takes before MREADY is triggered. This value does not have to be an integer fraction
-- of the line length. In the simplest case, where MLIMIT is both an integer fraction of the 
-- line length and an even number (e.g., 30 elements for both HD resolutions), when the line
-- is finished all data has been transferred to the MCB. But this need not be true in general,
-- and in fact for SD it's not possible to choose an appropriate MLIMIT. To handle this case
-- this module outputs MFLUSH after the full line has been pushed into the output fifo, so
-- that the MCB can transfer the remaining elements.

-- DDR address management is done through the PFRAME_ADDR_* and PNEW_FRAME controls.
-- PFRAME_ADDR is the base frame address, set by the micro based on what the application
-- wants to do. Even though the DDR3 address bus is 30 bits wide, it is only 27 bits
-- because I always read or write a complete burst, which is 8 locations, thus the last
-- 3 bits of the actual DDR address will always be zero. To compute the DDR address,
-- this module has an internal accumulator that it adds to PFRAME_ADDR_*. Obviously this
-- offset needs to be reset at the start of the next frame; this is done by pulsing
-- PNEW_FRAME. 

-- Note: this module samples PFRAME_ADDR_* only when PNEW_FRAME is pulsed.


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

entity pixel_to_ddr_fifo is
    Port ( 
		PCLK : in  STD_LOGIC;
		MCLK : in  STD_LOGIC;
		
		PDE : in std_logic;
		PPUSHED : in std_logic;
		
		PRESET_FIFOS : in std_logic;
		
		-- write-transaction fifo, input side
		PADDR_W : in std_logic_vector(26 downto 0);
		PDATA_W : in std_logic_vector(255 downto 0);
		PPUSH_W : in std_logic;
		-- write-transaction fifo, output side
		MPOP_W : in std_logic;
		MADDR_W : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDATA_W : out std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : out std_logic;

		-- read-transaction fifo, input side
		PADDR_R : in std_logic_vector(26 downto 0);
		PPUSH_R : in std_logic;
		-- read-transaction fifo, output side
		MPOP_R : in std_logic;
		MADDR_R : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : out std_logic;

		-- mcb signals
		MAVAIL : out std_logic_vector(8 downto 0);
		MFLUSH : out std_logic
	);
end pixel_to_ddr_fifo;

architecture Behavioral of pixel_to_ddr_fifo is
	
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
	
	COMPONENT pulse_cross_fast2slow
	PORT(
		CLKFAST : IN  std_logic;
		TRIGIN : IN  std_logic;
		CLKSLOW : IN  std_logic;
		TRIGOUT : OUT  std_logic
	  );
	END COMPONENT;
	
	component synchronizer_2ff is
	Generic ( 
		DATA_WIDTH : natural;
		EXTRA_INPUT_REGISTER : boolean := false;
		USE_GRAY_CODE : boolean := true
	);
	Port ( 
		CLKA   : in std_logic;
		DA     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		CLKB   : in  std_logic;
		DB     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RESETB : in std_logic
	);
	end component;
	
	constant ram_addr_width : natural := 9;
	constant ram_data_width_w : natural := 256 + 27; -- 256 for data, 27 for address
	constant ram_data_width_r : natural := 27; -- just address
	
	signal flush_remainder : std_logic := '0';
	signal flushd1 : std_logic := '0';
	signal flushd2 : std_logic := '0';
	signal flushd3 : std_logic := '0';
	signal flushd4 : std_logic := '0';
	signal crossin : std_logic_vector(0 downto 0);
	signal crossout : std_logic_vector(0 downto 0);
begin

--	flush_remainder <= (not PDE) and PPUSHED;
--
--	flush_cross : pulse_cross_fast2slow PORT MAP(
--		CLKFAST => PCLK,
--		TRIGIN => flush_remainder,
--		CLKSLOW => MCLK,
--		TRIGOUT => MFLUSH
--	);
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		if(PDE = '1') then
			flush_remainder <= '0';
		else
			if(PPUSHED = '1') then
				flush_remainder <= '1';
			end if;
		end if;
		
		flushd4 <= flushd3;
		flushd3 <= flushd2;
		flushd2 <= flushd1;
		flushd1 <= flush_remainder;
	end if;
	end process;
			
	flush_cross : synchronizer_2ff
	generic map (
		DATA_WIDTH => 1,
		EXTRA_INPUT_REGISTER => false,
		USE_GRAY_CODE => false
	)
	port map (
		CLKA => PCLK,
		DA => crossin,
		CLKB => MCLK,
		DB => crossout,
		RESETB => '0'
	);
	
	crossin(0) <= flushd4;
	MFLUSH <= crossout(0);
--	MFLUSH <= '0';
	
	writer_fifo_block : block is
		signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_wdata1 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_rdata2 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_we : std_logic;
		signal bus_in : std_logic_vector(ram_data_width_w-1 downto 0);
		signal bus_out : std_logic_vector(ram_data_width_w-1 downto 0);
	begin
	
		write_bram: bram_simple_dual_port 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_w
		)
		PORT MAP(
			CLK1 => PCLK,
			WADDR1 => ram_waddr1,
			WDATA1 => ram_wdata1,
			WE1 => ram_we,
			CLK2 => MCLK,
			RADDR2 => ram_raddr2,
			RDATA2 => ram_rdata2
		);
		
		bus_in(ram_data_width_w-1 downto ram_data_width_w-27) <= PADDR_W;
		bus_in(ram_data_width_w-27-1 downto 0)                <= PDATA_W;
	
		write_fifo: fifo_2clk 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_w
		)
		PORT MAP(
			WRITE_CLK => PCLK,
			RESET => PRESET_FIFOS,
			FREE => open,
			DIN => bus_in,
			PUSH => PPUSH_W,
			READ_CLK => MCLK,
			USED => MAVAIL,
			DOUT => bus_out,
			DVALID => MDVALID_W,
			POP => MPOP_W,
			RAM_WADDR => ram_waddr1,
			RAM_WDATA => ram_wdata1,
			RAM_WE => ram_we,
			RAM_RESET => open,
			RAM_RADDR => ram_raddr2,
			RAM_RDATA => ram_rdata2
		);
		
		MADDR_W <= bus_out(ram_data_width_w-1 downto ram_data_width_w-27); -- 27 bits wide
		MDATA_W <= bus_out(ram_data_width_w-27-1 downto 0);                -- 256 bits wide
		
	end block;

	reader_fifo_block : block is
		signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_wdata1 : std_logic_vector(ram_data_width_r-1 downto 0);
		signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_rdata2 : std_logic_vector(ram_data_width_r-1 downto 0);
		signal ram_we : std_logic;
		signal bus_in : std_logic_vector(ram_data_width_r-1 downto 0);
		signal bus_out : std_logic_vector(ram_data_width_r-1 downto 0);
	begin
	
		read_bram: bram_simple_dual_port 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_r
		)
		PORT MAP(
			CLK1 => PCLK,
			WADDR1 => ram_waddr1,
			WDATA1 => ram_wdata1,
			WE1 => ram_we,
			CLK2 => MCLK,
			RADDR2 => ram_raddr2,
			RDATA2 => ram_rdata2
		);
		
		bus_in <= PADDR_R;
	
		read_fifo: fifo_2clk 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_r
		)
		PORT MAP(
			WRITE_CLK => PCLK,
			RESET => PRESET_FIFOS,
			FREE => open,
			DIN => bus_in,
			PUSH => PPUSH_R,
			READ_CLK => MCLK,
			USED => open,
			DOUT => bus_out,
			DVALID => MDVALID_R,
			POP => MPOP_R,
			RAM_WADDR => ram_waddr1,
			RAM_WDATA => ram_wdata1,
			RAM_WE => ram_we,
			RAM_RESET => open,
			RAM_RADDR => ram_raddr2,
			RAM_RDATA => ram_rdata2
		);
		
		MADDR_R <= bus_out;
		
	end block;

end Behavioral;

