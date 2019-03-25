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
-- to the RAM. It has enough space for just under 2 lines of 1080p video.
-- The pixel side of the interface is the inputs starting with P.
-- The RAM side of the interface is the inputs starting with M.
-- Internally, a gearbox unpacks the stream of 24-bit data into a 256-bit bus which
-- is connected to the 64 SERDES blocks (recall you have to provide 4 data bits per
-- clock when the SERDES is in x4 mode).

-- One DDR3 burst is 8 transfers, which is 2 elements of this ram. Complete line:
 
--   1920px * (24 bits/px) / (64 bits/transfer) / (8 transfers/burst) = 90 bursts = 180 elements
--   1280px * (24 bits/px) / (64 bits/transfer) / (8 transfers/burst) = 60 bursts = 120 elements
--   1440ck * ( 8 bits/ck) / (64 bits/transfer) / (8 transfers/burst) = 22.5 bursts = 45 elements     <-- what am I going to do about this?

-- To allow for different line lengths, the MLIMIT input determines how many elements
-- it takes before MREADY is triggered.

-- Notice that 24 does not go evenly into 256: it takes 3 ram elements to hold an
-- integer number of pixels. Fortunately the number of elements in a line (180, 120, 45) 
-- is divisible by 3 for all of the video modes I'm interested in. To pack the bits
-- into ram, I start by normally placing the first 10 samples. For the 11th sample,
-- the last 8 bits spill over; I save those in a separate 16-bit register. Then
-- again the next 10 are normal, with the last 8 bits of the 11th saved to the
-- overflow register, and finally a third set of 10 normal followed by the 16 overflow
-- bits. Thus 32 samples are stored across 3 elements.

-- TODO: gearbox
-- TODO: pulse cross code, does it actually work? Seems like it would fail if fast clock > 2x slow clock

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

entity pixel_to_ddr_fifo is
    Port ( PCLK : in  STD_LOGIC;
           PDATA : in  STD_LOGIC_VECTOR (23 downto 0);
           PPUSH : in  STD_LOGIC;
			  PRESET : in STD_LOGIC;
           MCLK : in  STD_LOGIC;
           MPOP : in  STD_LOGIC;
           MDATA : out  STD_LOGIC_VECTOR (255 downto 0);
           MDVALID : out  STD_LOGIC;
			  MLIMIT : in STD_LOGIC_VECTOR (7 downto 0);
           MREADY : out  STD_LOGIC);
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
	
	
	constant ram_addr_width : natural := 9;
	constant ram_data_width : natural := 256;

	signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_wdata1 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
	signal ram_rdata2 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_we : std_logic;
	
	signal gearbox_in : std_logic_vector(ram_data_width-1 downto 0) := (others => '0');
	signal gearbox_out : std_logic_vector(ram_data_width-1 downto 0) := (others => '0');
	
	signal fifo_push : std_logic := '0';
	signal fifo_used : std_logic_vector(ram_addr_width-1 downto 0);

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
	
	Inst_fifo_2clk: fifo_2clk 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		WRITE_CLK => PCLK,
		RESET => PRESET,
		FREE => open,
		DIN => gearbox_out,
		PUSH => fifo_push,
		READ_CLK => MCLK,
		USED => fifo_used,
		DOUT => MDATA,
		DVALID => MDVALID,
		POP => MPOP,
		RAM_WADDR => ram_waddr1,
		RAM_WDATA => ram_wdata1,
		RAM_WE => ram_we,
		RAM_RESET => open,
		RAM_RADDR => ram_raddr2,
		RAM_RDATA => ram_rdata2
	);

end Behavioral;

