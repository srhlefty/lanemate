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
    Port ( PCLK : in  STD_LOGIC;
           PDATA : out  STD_LOGIC_VECTOR (23 downto 0);
           PPOP : in  STD_LOGIC;
			  PDVALID : out STD_LOGIC;
			  PRESET : in STD_LOGIC;
           MCLK : in  STD_LOGIC;
			  MRESET : in STD_LOGIC;
           MPUSH : in  STD_LOGIC;
           MDATA : in  STD_LOGIC_VECTOR (255 downto 0)
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
	
	component fifo_1clk is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
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
		FULL : out std_logic;
		OVERFLOW : out std_logic;
		
		-- dual port ram interface
		
		RAM_WADDR1 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_WDATA1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RAM_WE1    : out std_logic;
		
		RAM_RADDR2 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_RDATA2 : in std_logic_vector(DATA_WIDTH-1 downto 0)
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
	signal fifo_dvalid : std_logic;
	signal fifo_pop : std_logic := '0';
	signal fifo_used : std_logic_vector(ram_addr_width-1 downto 0);
	
	
	constant pram_addr_width : natural := 11;
	constant pram_data_width : natural := 24;

	signal pram_waddr1 : std_logic_vector(pram_addr_width-1 downto 0);
	signal pram_wdata1 : std_logic_vector(pram_data_width-1 downto 0);
	signal pram_raddr2 : std_logic_vector(pram_addr_width-1 downto 0);
	signal pram_rdata2 : std_logic_vector(pram_data_width-1 downto 0);
	signal pram_we : std_logic;
	
	signal pfifo_data : std_logic_vector(pram_data_width-1 downto 0);
	signal pfifo_push : std_logic := '0';
	signal pfifo_full : std_logic;
	signal pfifo_empty : std_logic;
	
	
	
	
	

begin


	-- This is the FIFO that receives data from the MCB. Thus the write side runs at
	-- MCLK (100MHz) and the read side runs at PCLK (up to 150MHz for 1080p).
	-- In normal operation the MCB will dump about 90 elements into the ram before
	-- being quiet for a while.

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
		USED => fifo_used,
		DOUT => fifo_data,
		DVALID => fifo_dvalid,
		POP => fifo_pop,
		RAM_WADDR => ram_waddr1,
		RAM_WDATA => ram_wdata1,
		RAM_WE => ram_we,
		RAM_RESET => open,
		RAM_RADDR => ram_raddr2,
		RAM_RDATA => ram_rdata2
	);

	-- Attached to the read side is some translation logic to convert the 256-bit words
	-- into a stream of 24-bit words. This logic tries to keep the 24-bit FIFO filled
	-- by reading out 3 256-bit words at a time and shifting them into the FIFO. It takes
	-- 3 256-bit words to make an integer number of 24-bit words.

	width_translator : block is
		type shift_t is array(integer range <>) of std_logic_vector(23 downto 0);
		signal shifter : shift_t(0 to 31) := (others => (others => '0'));
		type state_t is (S1, S2, S3, S4, S5, S6);
		signal state : state_t := S1;
		signal count : natural range 0 to 32 := 0;
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
		case state is
		
			when S1 =>
				-- pop 3 words if they're available and I'm ready for them
				if(count = 0 and to_integer(unsigned(fifo_used)) >= 3) then
					fifo_pop <= '1';
					state <= S2;
				end if;
				
			when S2 =>
				fifo_pop <= '1';
				state <= S3;
				
			when S3 =>
				-- first word ready
				shifter(0) <= fifo_data(1*24-1 downto 0*24);
				shifter(1) <= fifo_data(2*24-1 downto 1*24);
				shifter(2) <= fifo_data(3*24-1 downto 2*24);
				shifter(3) <= fifo_data(4*24-1 downto 3*24);
				shifter(4) <= fifo_data(5*24-1 downto 4*24);
				shifter(5) <= fifo_data(6*24-1 downto 5*24);
				shifter(6) <= fifo_data(7*24-1 downto 6*24);
				shifter(7) <= fifo_data(8*24-1 downto 7*24);
				shifter(8) <= fifo_data(9*24-1 downto 8*24);
				shifter(9) <= fifo_data(10*24-1 downto 9*24);
				shifter(10)(15 downto 0) <= fifo_data(255 downto 10*24);
				
				fifo_pop <= '1';
				state <= S4;
				
			when S4 =>
				-- second word ready
				shifter(10)(23 downto 16) <= fifo_data(7 downto 0);
				shifter(11) <= fifo_data(1*24-1+8 downto 0*24+8);
				shifter(12) <= fifo_data(2*24-1+8 downto 1*24+8);
				shifter(13) <= fifo_data(3*24-1+8 downto 2*24+8);
				shifter(14) <= fifo_data(4*24-1+8 downto 3*24+8);
				shifter(15) <= fifo_data(5*24-1+8 downto 4*24+8);
				shifter(16) <= fifo_data(6*24-1+8 downto 5*24+8);
				shifter(17) <= fifo_data(7*24-1+8 downto 6*24+8);
				shifter(18) <= fifo_data(8*24-1+8 downto 7*24+8);
				shifter(19) <= fifo_data(9*24-1+8 downto 8*24+8);
				shifter(20) <= fifo_data(10*24-1+8 downto 9*24+8);
				shifter(21)(7 downto 0) <= fifo_data(255 downto 248);

				fifo_pop <= '0';
				state <= S5;
			
			when S5 =>
				-- third word ready
				shifter(21)(23 downto 8) <= fifo_data(15 downto 0);
				shifter(22) <= fifo_data(1*24-1+16 downto 0*24+16);
				shifter(23) <= fifo_data(2*24-1+16 downto 1*24+16);
				shifter(24) <= fifo_data(3*24-1+16 downto 2*24+16);
				shifter(25) <= fifo_data(4*24-1+16 downto 3*24+16);
				shifter(26) <= fifo_data(5*24-1+16 downto 4*24+16);
				shifter(27) <= fifo_data(6*24-1+16 downto 5*24+16);
				shifter(28) <= fifo_data(7*24-1+16 downto 6*24+16);
				shifter(29) <= fifo_data(8*24-1+16 downto 7*24+16);
				shifter(30) <= fifo_data(9*24-1+16 downto 8*24+16);
				shifter(31) <= fifo_data(10*24-1+16 downto 9*24+16);
				
				count <= 32;
				state <= S6;
				
			when S6 =>
				-- push the shift register content into the fifo as space becomes available
				if(count > 0 and pfifo_full = '0') then
					count <= count - 1;
					pfifo_data <= shifter(0);
					pfifo_push <= '1';
					
					for i in 1 to 31 loop
						shifter(i-1) <= shifter(i);
					end loop;
				else
					pfifo_push <= '0';
				end if;
				
				if(count = 0) then
					state <= S1;
				end if;
		end case;
		end if;
		end process;
	end block;



	-- This is the output FIFO that the consumer uses to pull out a stream of 24-bit words.
	-- Thus the read side is connected to the top level signals. 
	-- The write side is connected to the translation logic to handle the intermittent writes.

	narrow_bram: bram_simple_dual_port 
	generic map(
		ADDR_WIDTH => pram_addr_width,
		DATA_WIDTH => pram_data_width
	)
	PORT MAP(
		CLK1 => PCLK,
		WADDR1 => pram_waddr1,
		WDATA1 => pram_wdata1,
		WE1 => pram_we,
		CLK2 => PCLK,
		RADDR2 => pram_raddr2,
		RDATA2 => pram_rdata2
	);
	
	narrow_fifo: fifo_1clk 
	generic map(
		ADDR_WIDTH => pram_addr_width,
		DATA_WIDTH => pram_data_width
	)
	PORT MAP(
		CLK => PCLK,
		DIN => pfifo_data,
		PUSH => pfifo_push,
		POP => PPOP,
		DOUT => PDATA,
		DVALID => PDVALID,
		RESET => PRESET,
		EMPTY => pfifo_empty,
		FULL => pfifo_full,
		OVERFLOW => open,
		RAM_WADDR1 => pram_waddr1,
		RAM_WDATA1 => pram_wdata1,
		RAM_WE1 => pram_we,
		RAM_RADDR2 => pram_raddr2,
		RAM_RDATA2 => pram_rdata2
	);

end Behavioral;

