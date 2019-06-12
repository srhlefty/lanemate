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

-- That last one, 720(1440)x480i, has an even number of lines which means there are an even
-- number of bursts which means we're guaranteed to finish storing the frame before the
-- frame write pointer changes.

-- To allow for different memory access patterns, the MLIMIT input determines how many elements
-- it takes before MREADY is triggered. My notional plan is 30 elements for the HD resolutions
-- so that the fixed delay between incoming and outgoing DE can be about half a line.

-- DDR address management is done through the PFRAME_ADDR_* and PNEW_FRAME controls.
-- PFRAME_ADDR is the base frame address, set by the micro based on what the application
-- wants to do. Even though the DDR3 address bus is 27 bits wide, it is only 24 bits
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
		PCLK : in  STD_LOGIC;                           -- pixel clock
		PDATA : in  STD_LOGIC_VECTOR (23 downto 0);     -- pixel data
		P8BIT : in std_logic;                           -- if high, only the lower 8 bits are active (SD 4:2:2)
		PPUSH : in  STD_LOGIC;                          -- DE
		PFRAME_ADDR_W : in std_logic_vector(23 downto 0); -- DDR write pointer
		PFRAME_ADDR_R : in std_logic_vector(23 downto 0); -- DDR read pointer
		PNEW_FRAME : in std_logic;                      -- pulse to indicate start of frame
		PRESET_FIFO : in STD_LOGIC;                     -- clear the data and address FIFOs
		
		-- data-to-write fifo
		MCLK : in  STD_LOGIC;                             -- memory clock
		MPOP_W : in  STD_LOGIC;                           -- fifo control
		MDATA_W : out  STD_LOGIC_VECTOR (255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MADDR_W : out std_logic_vector(23 downto 0);      -- ddr address, high 24 bits
		MDVALID_W : out  STD_LOGIC;                       -- data valid

		-- data-to-read fifo
		MPOP_R : in  STD_LOGIC;                           -- fifo control
		MADDR_R : out std_logic_vector(23 downto 0);      -- ddr address, high 24 bits
		MDVALID_R : out  STD_LOGIC;                       -- data valid

		-- common interface
		MLIMIT : in STD_LOGIC_VECTOR (7 downto 0);      -- minimum number of fifo elements for MREADY = 1
		MREADY : out  STD_LOGIC
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
	
	component gearbox8to24 is
	Port ( 
		PCLK : in  STD_LOGIC;
		CE : in  STD_LOGIC;
		DIN : in  STD_LOGIC_VECTOR (23 downto 0);
		DE : in  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0);
		DEOUT : out  STD_LOGIC
	);
	end component;
	

	constant ram_addr_width : natural := 9;
	constant ram_data_width_w : natural := 256 + 24; -- 256 for data, 24 for address
	constant ram_data_width_r : natural := 24; -- just address
	
	signal gearbox_out_w : std_logic_vector(ram_data_width_w-1 downto 0) := (others => '0');
	signal gearbox_out_r : std_logic_vector(ram_data_width_r-1 downto 0) := (others => '0');
	
	signal fifo_push : std_logic := '0';
	signal fifo_used : std_logic_vector(ram_addr_width-1 downto 0);


	signal pdata2 : std_logic_vector(23 downto 0);
	signal ppush2 : std_logic;

begin

	Inst_gearbox8to24: gearbox8to24 PORT MAP(
		PCLK => PCLK,
		CE => P8BIT,
		DIN => PDATA,
		DE => PPUSH,
		DOUT => pdata2,
		DEOUT => ppush2
	);



	gearbox : block is
		type shift_t is array(integer range <>) of std_logic_vector(23 downto 0);
		signal shifter : shift_t(0 to 31) := (others => (others => '0'));
		signal word1 : std_logic_vector(255 downto 0) := (others => '0');
		signal word2 : std_logic_vector(255 downto 0) := (others => '0');
		signal word3 : std_logic_vector(255 downto 0) := (others => '0');
		signal count : natural range 0 to 32 := 0;
		type pusher_state_t is (IDLE, P1, P2, P3);
		signal pusher_state : pusher_state_t := IDLE;
		
		signal base_addr_w : std_logic_vector(23 downto 0) := (others => '0');
		signal base_addr_r : std_logic_vector(23 downto 0) := (others => '0');
		-- 1080p has 1080 lines, 180 elements per line, so max address offset is 1080*180/2 = 97,200
		-- with the /2 because it takes 2 elements to do one burst at the same address. Thus a 17-bit number.
		signal addr_offset_w : std_logic_vector(16 downto 0) := (others => '0');
		signal addr_offset_r : std_logic_vector(16 downto 0) := (others => '0');
		
		type offset_mode_t is (EVEN, ODD);
		signal offset_mode : offset_mode_t := EVEN;
		
		signal waddr_plus_0 : std_logic_vector(23 downto 0) := (others => '0');
		signal raddr_plus_0 : std_logic_vector(23 downto 0) := (others => '0');
		signal waddr_plus_1 : std_logic_vector(23 downto 0) := (others => '0');
		signal raddr_plus_1 : std_logic_vector(23 downto 0) := (others => '0');
		signal woffset_plus_1 : std_logic_vector(16 downto 0) := (others => '0');
		signal roffset_plus_1 : std_logic_vector(16 downto 0) := (others => '0');
		signal woffset_plus_2 : std_logic_vector(16 downto 0) := (others => '0');
		signal roffset_plus_2 : std_logic_vector(16 downto 0) := (others => '0');
		
		-- I push 3 elements into the fifo at a time, but the address only increments
		-- every other. So the mechanism for computing the address is slightly nontrivial.
		-- If the starting address is 'A', then the actual addresses pushed should look
		-- like this: A,A,A+1,  A+1,A+2,A+2,  A+3,A+3,A+4, etc.
		-- The pattern repeats after every other group of 3 writes. The offset_mode signal
		-- keeps track of whether we're going to store using the first pattern (+0,+0,+1)
		-- or the second pattern (+0,+1,+1). After the 3rd push, I save the new address offset
		-- and switch the pattern.
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
		
			if(PNEW_FRAME = '1') then
				base_addr_w <= PFRAME_ADDR_W;
				base_addr_r <= PFRAME_ADDR_R;
				addr_offset_w <= (others => '0');
				addr_offset_r <= (others => '0');
				offset_mode <= EVEN;
			else
			
		
				if(ppush2 = '1') then
					shifter(31) <= pdata2;
					for i in 0 to 30 loop
						shifter(i) <= shifter(i+1);
					end loop;
					
					if(count = 32) then
						-- we've just done a shift so there's already 1
						count <= 1;
					else
						count <= count + 1;
					end if;
				else
					if(count = 32) then
						count <= 0;
					end if;
				end if;
				
				-- I need to add the base address to the offset as well as get that value plus 1.
				-- That's a significant amount of propagation delay, so here I spread out those
				-- two add operations over 2 clocks.
				if(count = 31) then
					waddr_plus_0 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_w)) + to_integer(unsigned(addr_offset_w)) , waddr_plus_0'length));
					raddr_plus_0 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_r)) + to_integer(unsigned(addr_offset_r)) , raddr_plus_0'length));
					woffset_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_w)) + 1 , woffset_plus_1'length));
					roffset_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_r)) + 1 , roffset_plus_1'length));
					woffset_plus_2 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_w)) + 2 , woffset_plus_2'length));
					roffset_plus_2 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_r)) + 2 , roffset_plus_2'length));
				end if;
				
				if(count = 32) then
					-- this should happen once by design
					word1 <= shifter(10)(15 downto 0) & shifter(9) & shifter(8) & shifter(7) & shifter(6) & shifter(5) & shifter(4) & shifter(3) & shifter(2) & shifter(1) & shifter(0);
					word2 <= shifter(21)(7 downto 0) & shifter(20) & shifter(19) & shifter(18) & shifter(17) & shifter(16) & shifter(15) & shifter(14) & shifter(13) & shifter(12) & shifter(11) & shifter(10)(23 downto 16);
					word3 <= shifter(31) & shifter(30) & shifter(29) & shifter(28) & shifter(27) & shifter(26) & shifter(25) & shifter(24) & shifter(23) & shifter(22) & shifter(21)(23 downto 8);
					waddr_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_w)) + to_integer(unsigned(woffset_plus_1)) , waddr_plus_1'length));
					raddr_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_r)) + to_integer(unsigned(roffset_plus_1)) , raddr_plus_1'length));
					pusher_state <= P1;
				else
					case pusher_state is
						when IDLE =>
							fifo_push <= '0';
							pusher_state <= IDLE;
						when P1 =>
							fifo_push <= '1';
							gearbox_out_w <= waddr_plus_0 & word1;
							gearbox_out_r <= raddr_plus_0;
							pusher_state <= P2;
						when P2 =>
							fifo_push <= '1';
							if(offset_mode = EVEN) then
								gearbox_out_w <= waddr_plus_0 & word2;
								gearbox_out_r <= raddr_plus_0;
							else
								gearbox_out_w <= waddr_plus_1 & word2;
								gearbox_out_r <= raddr_plus_1;
							end if;
							pusher_state <= P3;
						when P3 =>
							fifo_push <= '1';
							gearbox_out_w <= waddr_plus_1 & word3;
							gearbox_out_r <= raddr_plus_1;
							pusher_state <= IDLE;
							
							if(offset_mode = EVEN) then
								addr_offset_w <= woffset_plus_1;
								addr_offset_r <= roffset_plus_1;
								offset_mode <= ODD;
							else
								addr_offset_w <= woffset_plus_2;
								addr_offset_r <= roffset_plus_2;
								offset_mode <= EVEN;
							end if;
					end case;
				end if;
			
			
			end if;
		end if;
		end process;
	
	end block;


	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
		if(to_integer(unsigned(fifo_used)) >= to_integer(unsigned(MLIMIT)) and to_integer(unsigned(MLIMIT)) > 0) then
			MREADY <= '1';
		else
			MREADY <= '0';
		end if;
	end if;
	end process;

	
	writer_fifo_block : block is
		signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_wdata1 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_rdata2 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_we : std_logic;
		signal bus_tmp : std_logic_vector(ram_data_width_w-1 downto 0);
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
	
		write_fifo: fifo_2clk 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_w
		)
		PORT MAP(
			WRITE_CLK => PCLK,
			RESET => PRESET_FIFO,
			FREE => open,
			DIN => gearbox_out_w,
			PUSH => fifo_push,
			READ_CLK => MCLK,
			USED => fifo_used,
			DOUT => bus_tmp,
			DVALID => MDVALID_W,
			POP => MPOP_W,
			RAM_WADDR => ram_waddr1,
			RAM_WDATA => ram_wdata1,
			RAM_WE => ram_we,
			RAM_RESET => open,
			RAM_RADDR => ram_raddr2,
			RAM_RDATA => ram_rdata2
		);
		
		MADDR_W <= bus_tmp(ram_data_width_w-1 downto ram_data_width_w-24); -- 24 bits wide
		MDATA_W <= bus_tmp(ram_data_width_w-24-1 downto 0);                -- 256 bits wide
		
	end block;

	reader_fifo_block : block is
		signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_wdata1 : std_logic_vector(ram_data_width_r-1 downto 0);
		signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_rdata2 : std_logic_vector(ram_data_width_r-1 downto 0);
		signal ram_we : std_logic;
		signal bus_tmp : std_logic_vector(ram_data_width_r-1 downto 0);
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
	
		read_fifo: fifo_2clk 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_r
		)
		PORT MAP(
			WRITE_CLK => PCLK,
			RESET => PRESET_FIFO,
			FREE => open,
			DIN => gearbox_out_r,
			PUSH => fifo_push,
			READ_CLK => MCLK,
			USED => open,
			DOUT => bus_tmp,
			DVALID => MDVALID_R,
			POP => MPOP_R,
			RAM_WADDR => ram_waddr1,
			RAM_WDATA => ram_wdata1,
			RAM_WE => ram_we,
			RAM_RESET => open,
			RAM_RADDR => ram_raddr2,
			RAM_RDATA => ram_rdata2
		);
		
		MADDR_R <= bus_tmp;
		
	end block;

end Behavioral;

