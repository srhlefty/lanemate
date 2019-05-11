----------------------------------------------------------------------------------
-- Company: self
-- Engineer: Steven Hunt
-- 
-- Create Date:    09:51:02 08/17/2018 
-- Design Name: 
-- Module Name:    lane_mate - Behavioral 
-- Project Name: Lane Mate
-- Target Devices: LX25, LX45
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

entity lane_mate is
port (
   SYSCLK : in std_logic;
	
	I2C_SDA : inout std_logic;
	I2C_SCL : inout std_logic;
	
	HDI_PCLK : in std_logic;
	HDI_VS : in std_logic;
	HDI_HS : in std_logic;
	HDI_DE : in std_logic;
	HDI_INT : in std_logic;
	RGB_IN : in std_logic_vector(23 downto 0);
	
	SDI_PCLK : in std_logic;
	SDI_HS : in std_logic;
	SDI_VS : in std_logic;
	SDI_INT : in std_logic;
	SDV : in std_logic_vector(7 downto 0);
	
	HDO_PCLK : out std_logic;
	HDO_VS : out std_logic;
	HDO_HS : out std_logic;
	HDO_DE : out std_logic;
	HDO_INT : in std_logic;
	RGB_OUT : out std_logic_vector(23 downto 0);
	
	B0_GPIO0 : out std_logic;
	B1_GPIO1 : out std_logic;
	B1_GPIO2 : out std_logic;
	B1_GPIO3 : out std_logic;
	B1_GPIO4 : out std_logic;
	B1_GPIO5 : out std_logic;
	B1_GPIO6 : out std_logic;
	B1_GPIO7 : out std_logic;
	B1_GPIO8 : out std_logic;
	B1_GPIO9 : out std_logic;
	B1_GPIO10 : out std_logic;
	B1_GPIO11 : out std_logic;
	B1_GPIO12 : out std_logic;
	B1_GPIO13 : out std_logic;
	B1_GPIO14 : out std_logic;
	B1_GPIO15 : out std_logic;
	B1_GPIO24 : out std_logic;
	B1_GPIO25 : out std_logic
);
end lane_mate;

architecture Behavioral of lane_mate is


	COMPONENT timing_gen
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		VIC : IN std_logic_vector(7 downto 0);          
		VS : OUT std_logic;
		HS : OUT std_logic;
		DE : OUT std_logic;
		D : OUT std_logic_vector(23 downto 0)
		);
	END COMPONENT;
	

	component clock_forwarding is
	 Generic( INVERT : boolean);
    Port ( CLK : in  STD_LOGIC;
           CLKO : out  STD_LOGIC);
	end component;
	
	COMPONENT bt656_decode
	PORT(
		D : IN std_logic_vector(7 downto 0);
		CLK : IN std_logic;          
		VS : OUT std_logic;
		HS : OUT std_logic;
		DE : OUT std_logic;
		DOUT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
	component i2c_slave is
	Generic (
		SLAVE_ADDRESS : std_logic_vector(6 downto 0)
	);
	Port ( 
		CLK : in  STD_LOGIC;
		SDA : inout  STD_LOGIC;
		SCL : inout  STD_LOGIC;
		
		-- Interface to the register map, e.g. dual-port bram
		RAM_ADDR : out std_logic_vector(7 downto 0);
		RAM_WDATA : out std_logic_vector(7 downto 0);
		RAM_WE : out std_logic;
		RAM_RDATA : in std_logic_vector(7 downto 0)
	);
	end component;
	
	component bram_true_dual_port is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
	);
    Port ( 
		CLK1 : in std_logic;
		ADDR1 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		RDATA1 : out std_logic_vector (DATA_WIDTH-1 downto 0);
		WDATA1 : in std_logic_vector (DATA_WIDTH-1 downto 0);
		WE1    : in std_logic;

		CLK2 : in std_logic;
		ADDR2 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		RDATA2 : out std_logic_vector (DATA_WIDTH-1 downto 0);
		WDATA2 : in std_logic_vector (DATA_WIDTH-1 downto 0);
		WE2    : in std_logic
	);
	end component;
	
	component programmable_clock is
	Port ( 
		CLK : in std_logic;
		PROGCLK : in std_logic;
		SEL : in std_logic_vector(1 downto 0); -- 00=100M, 01=27M, 10=74.25M, 11=148.5M
		DCM_LOCKED : out std_logic;
		CLKOUT : out std_logic
	);
	end component;
	
	component input_fifo
	port(
		rst : in std_logic;
		wr_clk : in std_logic;
		rd_clk : in std_logic;
		din : in std_logic_vector(26 downto 0);
		wr_en : in std_logic;
		rd_en : in std_logic;          
		dout : out std_logic_vector(26 downto 0);
		full : out std_logic;
		overflow : out std_logic;
		empty : out std_logic;
		underflow : out std_logic
		);
	end component;

	type ram_t is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal register_map : ram_t;
	signal REG_VIDEO_SRC : std_logic_vector(7 downto 0);
	signal REG_PCLK_FREQ : std_logic_vector(7 downto 0);
	
	signal video_clock : std_logic;
	signal video_clock_locked : std_logic;

	signal stage1_hs : std_logic;
	signal stage1_vs : std_logic;
	signal stage1_de : std_logic;
	signal stage1_d : std_logic_vector(23 downto 0);
	
	signal clk : std_logic;
	signal ibufg_to_bufgs : std_logic;
	signal progclk : std_logic;

begin



	-- Main clock input
	-- SYSCLK drives two BUFG symbols due to a special restriction on
	-- the DCM that I use as a programmable clock. The DCM's programming
	-- interface requires a clock driven by one of the 8 BUFG blocks in
	-- the upper half of the chip (see UG382, p.76). SYSCLK's pin is in
	-- the lower half of the chip and can't directly reach those BUFGs.
	-- So I have instantiated a separate BUFG constrained in the UCF to
	-- be in the upper half, and use it to service the programming port
	-- of the DCM. In order to route this the compiler has to take the
	-- long way to the BUFG, and so I have to use the CLOCK_DEDICATED_ROUTE
	-- constraint to prevent compile errors.
	-- According to the routed design, the delay is
	-- 5.5ns for SYSCLK -> progclk_bufgmux
	-- 0.8ns for SYSCLK -> clk_bufgmux
	-- Since progclk doesn't capture data from pins, this delay doesn't matter.

   sysclk_ibufg : IBUFG generic map (IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
		port map (
			I => SYSCLK,
			O => ibufg_to_bufgs
		);
   progclk_bufgmux : BUFG
		port map (
			I => ibufg_to_bufgs,
			O => progclk
		);
   clk_bufgmux : BUFG
		port map (
			I => ibufg_to_bufgs,
			O => clk
		);
	
		process(clk) is
		begin
		if(rising_edge(clk)) then
			REG_VIDEO_SRC <= register_map(1);
			REG_PCLK_FREQ <= register_map(2);
		end if;
		end process;
		
	Inst_programmable_clock: programmable_clock PORT MAP(
		CLK => clk,
		PROGCLK => progclk,
		SEL => REG_PCLK_FREQ(1 downto 0),
		DCM_LOCKED => video_clock_locked,
		CLKOUT => video_clock
	);


	-- There are 3 video sources: internal test pattern, HDMI, and SD.
	-- Each has its own clock and data bus, and I must mux between them
	-- before sending the data on to the memory interface. I can't just
	-- mux the entire bus, because clock muxes have restrictions based
	-- on pin location, and mine are arranged in such a way that you
	-- can't get them to pair up properly.
	
	-- So what I do here is capture the HDMI and SD buses at the chip edge
	-- with their own clocks, then feed all 3 sources into their own simple
	-- dual port FIFOs. A register setting picks which FIFO I'm going to read
	-- from. Another register programs a DCM to the pixel frequency of the
	-- input bus. In this way, the FIFO need not be very deep, because the
	-- read frequency is the same as the write frequency.
	
	-- Reset behavior is important with this sort of FIFO. I don't want to
	-- leave read enable high the whole time, because then there may only
	-- be one cell between the read and write pointers. A better strategy
	-- is to detect a video source change (by watching the registers),
	-- hold the fifos in reset until the DCM locks, release reset so that
	-- writing begins, wait until the FIFO is half full, then turn read
	-- enable on. 
	
--	source_select : block is
--		signal hdbus : std_logic_vector(26 downto 0);
--		signal sdbus : std_logic_vector(26 downto 0);
--		signal intbus : std_logic_vector(26 downto 0);
--
--		signal hd_input : std_logic_vector(26 downto 0);
--		signal sd_input : std_logic_vector(26 downto 0);
--		signal int_input : std_logic_vector(26 downto 0);
--
--		signal decoded_vs : std_logic;
--		signal decoded_hs : std_logic;
--		signal decoded_de : std_logic;
--		signal decoded_d : std_logic_vector(7 downto 0);
--
--		signal testpat_vs : std_logic;
--		signal testpat_hs : std_logic;
--		signal testpat_de : std_logic;
--		signal testpat_d : std_logic_vector(23 downto 0);
--		
--		signal fifo_rst : std_logic_vector(2 downto 0) := "000";
--		signal fifo_rd_en : std_logic_vector(2 downto 0) := "000";
--		signal fifo_overflow : std_logic_vector(2 downto 0);
--		signal fifo_underflow : std_logic_vector(2 downto 0);
--		
--		component input_fifo_control is
--		 Port ( CLK : in  STD_LOGIC;
--				  LOCKED : in  STD_LOGIC;
--				  RST : out  STD_LOGIC;
--				  RD_EN : out  STD_LOGIC);
--		end component;
--	begin
--
--		process(video_clock) is
--		begin
--		if(rising_edge(video_clock)) then
--			if(REG_VIDEO_SRC(1 downto 0) = "00") then
--				stage1_vs <= int_input(26);
--				stage1_hs <= int_input(25);
--				stage1_de <= int_input(24);
--				stage1_d  <= int_input(23 downto 0);
--			elsif(REG_VIDEO_SRC(1 downto 0) = "01") then
--				stage1_vs <= hd_input(26);
--				stage1_hs <= hd_input(25);
--				stage1_de <= hd_input(24);
--				stage1_d  <= hd_input(23 downto 0);
--			else --if(REG_VIDEO_SRC(1 downto 0) = "10") then
--				stage1_vs <= sd_input(26);
--				stage1_hs <= sd_input(25);
--				stage1_de <= sd_input(24);
--				stage1_d  <= sd_input(23 downto 0);
--			end if;
--		end if;
--		end process;
--
--		-------------------------------------------------------------------------
--		
--		testpat_gen: timing_gen PORT MAP(
--			CLK => video_clock,
--			RST => '0',
--			VIC => x"00", -- TODO: make this toggle between 720p and 1080p
--			VS => testpat_vs,
--			HS => testpat_hs,
--			DE => testpat_de,
--			D => testpat_d
--		);
--		
--		intbus(26) <= testpat_vs;
--		intbus(25) <= testpat_hs;
--		intbus(24) <= testpat_de;
--		intbus(23 downto 0) <= testpat_d;
--	
--		int_fifo: input_fifo PORT MAP(
--			rst => fifo_rst(0),
--			wr_clk => video_clock,
--			rd_clk => video_clock,
--			din => intbus,
--			wr_en => '1',
--			rd_en => fifo_rd_en(0),
--			dout => int_input,
--			full => open,
--			overflow => fifo_overflow(0),
--			empty => open,
--			underflow => fifo_underflow(0)
--		);
--		int_fifo_control: input_fifo_control PORT MAP(
--			CLK => clk,
--			LOCKED => video_clock_locked,
--			RST => fifo_rst(0),
--			RD_EN => fifo_rd_en(0)
--		);
--	
--		-------------------------------------------------------------------------
--		
--		hdbus(26) <= HDI_VS;
--		hdbus(25) <= HDI_HS;
--		hdbus(24) <= HDI_DE;
--		hdbus(23 downto 0) <= RGB_IN;
--	
--		hd_fifo: input_fifo PORT MAP(
--			rst => fifo_rst(1),
--			wr_clk => HDI_PCLK,
--			rd_clk => video_clock,
--			din => hdbus,
--			wr_en => '1',
--			rd_en => fifo_rd_en(1),
--			dout => hd_input,
--			full => open,
--			overflow => fifo_overflow(1),
--			empty => open,
--			underflow => fifo_underflow(1)
--		);
--		hd_fifo_control: input_fifo_control PORT MAP(
--			CLK => HDI_PCLK,
--			LOCKED => video_clock_locked,
--			RST => fifo_rst(1),
--			RD_EN => fifo_rd_en(1)
--		);
--	
--		-------------------------------------------------------------------------
--		
--		Inst_bt656_decode: bt656_decode PORT MAP(
--			D => SDV,
--			CLK => SDI_PCLK,
--			VS => decoded_vs,
--			HS => decoded_hs,
--			DE => decoded_de,
--			DOUT => decoded_d
--		);
--	
--		sdbus(26) <= decoded_vs;
--		sdbus(25) <= decoded_hs;
--		sdbus(24) <= decoded_de;
--		sdbus(23 downto 8) <= (others => '0');
--		sdbus(7 downto 0) <= decoded_d;
--	
--		sd_fifo: input_fifo PORT MAP(
--			rst => fifo_rst(2),
--			wr_clk => SDI_PCLK,
--			rd_clk => video_clock,
--			din => sdbus,
--			wr_en => '1',
--			rd_en => fifo_rd_en(2),
--			dout => sd_input,
--			full => open,
--			overflow => fifo_overflow(2),
--			empty => open,
--			underflow => fifo_underflow(2)
--		);
--		sd_fifo_control: input_fifo_control PORT MAP(
--			CLK => SDI_PCLK,
--			LOCKED => video_clock_locked,
--			RST => fifo_rst(2),
--			RD_EN => fifo_rd_en(2)
--		);
--	
--	end block;
	
		
	
	
	-- TODO
	-- Send data to ram FIFO
	-- Use delayed control signals to trigger readout of ram FIFO
	
	
	

	data_transmit : block is
	begin
		process(video_clock) is
		begin
		if(rising_edge(video_clock)) then
			HDO_VS <= stage1_vs;
			HDO_HS <= stage1_hs;
			HDO_DE <= stage1_de;
			RGB_OUT <= stage1_d;
		end if;
		end process;
		
		-- By inverting the clock here I'm putting the rising
		-- edge in the middle of the data eye
		Inst_clock_forwarding: clock_forwarding 
		GENERIC MAP(
			INVERT => true
		)
		PORT MAP(
			CLK => video_clock,
			CLKO => HDO_PCLK
		);
	end block;
	


--	bt656 : block is
--		signal data : std_logic_vector(7 downto 0);
--	begin
--	
--		Inst_bt656_decode: bt656_decode PORT MAP(
--			D => SDV,
--			CLK => SDI_PCLK,
--			VS => HDO_VS,
--			HS => HDO_HS,
--			DE => HDO_DE,
--			DOUT => data
--		);
--		
--		RGB_OUT(23 downto 8) <= (others => '0');
--		RGB_OUT(7 downto 0) <= data;
--
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => SDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--	end block;







--	synth : block is
--		signal clk148 : std_logic;
--		signal clk74 : std_logic;
--		signal clk27 : std_logic;
--		signal clk54 : std_logic;
--		signal rst : std_logic := '1';
--		signal once : std_logic := '0';
--		signal field_old : std_logic := '0';
--		signal d1 : std_logic_vector(7 downto 0);
--		signal d2 : std_logic_vector(7 downto 0);
--		signal d3 : std_logic_vector(7 downto 0);
--	begin
--
--		Inst_clk_hd: clk_hd PORT MAP(
--			CLK100 => SYSCLK,
--			CLK74p25 => clk74,
--			CLK148p5 => clk148,
--			RST => '0',
--			LOCKED => open
--		);
--		Inst_clk_sd: clk_sd PORT MAP(
--			CLK100 => SYSCLK,
--			CLK27 => clk27,
--			CLK54 => clk54,
--			RST => '0',
--			LOCKED => open
--		);
--	
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			--CLK => clk27,
--			--CLK => SDI_PCLK,
--			CLK => clk74,
--			CLKO => HDO_PCLK
--		);
--		
--		Inst_timing_gen: timing_gen PORT MAP(
--			--CLK => clk27,
--			--CLK => SDI_PCLK,
--			CLK => clk74,
--			RST => '0',
--			VIC => x"00",
--			VS => HDO_VS,
--			HS => HDO_HS,
--			DE => HDO_DE,
--			D => RGB_OUT
--		);
		
		
--		process(SDI_PCLK) is
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			field_old <= SDI_VS; -- 7180 sends me FIELD by default but this still works if it's configured to send VS instead
--			if(SDI_VS = '1' and field_old = '0') then
--				-- on rising edge of FIELD, trigger the timing generator (which begins with VSYNC)
--				rst <= '1';
--			else
--				rst <= '0';
--			end if;
--			
--			-- shift data by 4 to account for the time it takes for an incoming VSYNC to trigger the replaced VSYNC
--			d1 <= SDV;
--			d2 <= d1;
--			d3 <= d2;
--		end if;
--		end process;
--			RGB_OUT(23 downto 8) <= (others => '0');
--			RGB_OUT(7 downto 0) <= SDV;
		
		
--	end block;









--	sd_shunt : block is
--		signal idata : std_logic_vector(23 downto 0) := (others => '0');
--		signal ifield : std_logic := '0';
--		signal ihs : std_logic := '0';
--		signal ide : std_logic := '0';
--		signal odata : std_logic_vector(23 downto 0);
--		signal ovs : std_logic := '0';
--		signal ohs : std_logic := '0';
--		signal ode : std_logic := '0';
--		signal hcount : natural range 0 to 65535;
--		signal vcount : natural range 0 to 65535;
--	begin
--		process(SDI_PCLK) is
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			idata(7 downto 0) <= SDV;
--			ifield <= SDI_VS; -- 7180 sends me FIELD by default
--			ihs <= SDI_HS;
--			ide <= '0';
--			
--			odata <= idata;
--			--ovs <= ivs;
--			--ohs <= ihs;
--			--ode <= ide;
--			
--			RGB_OUT <= odata;
--			--HDO_VS <= ovs;
--			HDO_HS <= ohs;
--			--HDO_DE <= ode;
--			HDO_VS <= '0';
--			--HDO_HS <= '0';
--			HDO_DE <= '0';
--		end if;
--		end process;
--		
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => SDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--		
--		Inst_generate_sd_de: generate_sd_de PORT MAP(
--			PCLK => SDI_PCLK,
--			FIELD => ifield,
--			HSIN => ihs,
--			HS => ohs,
--			VS => ovs,
--			DE => ode
--		);
--		
--		Inst_timing_inspect: timing_inspect PORT MAP(
--			PCLK => SDI_PCLK,
--			VS => ovs,
--			HS => ohs,
--			HCOUNT => hcount,
--			HSYNC_WIDTH => open,
--			VCOUNT => vcount,
--			VSYNC_WIDTH => open
--		);
--		
--		process(SDI_PCLK) is
--			variable count : std_logic_vector(15 downto 0);
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			count := std_logic_vector(to_unsigned(vcount, count'length));
--			B0_GPIO0 <= count(0);
--			B1_GPIO1 <= count(1);
--			B1_GPIO2 <= count(2);
--			B1_GPIO3 <= count(3);
--			B1_GPIO4 <= count(4);
--			B1_GPIO5 <= count(5);
--			B1_GPIO6 <= count(6);
--			B1_GPIO7 <= count(7);
--			B1_GPIO8 <= count(8);
--			B1_GPIO9 <= count(9);
--			B1_GPIO10 <= count(10);
--			B1_GPIO11 <= count(11);
--			B1_GPIO12 <= count(12);
--			B1_GPIO13 <= count(13);
--			B1_GPIO14 <= count(14);
--			B1_GPIO15 <= count(15);
--		end if;
--		end process;
--		
--	end block;





--	hd_shunt : block is
--		signal idata : std_logic_vector(23 downto 0) := (others => '0');
--		signal ivs : std_logic := '0';
--		signal ihs : std_logic := '0';
--		signal ide : std_logic := '0';
--		signal odata : std_logic_vector(23 downto 0);
--		signal ovs : std_logic := '0';
--		signal ohs : std_logic := '0';
--		signal ode : std_logic := '0';
--	begin
--		process(HDI_PCLK) is
--		begin
--		if(rising_edge(HDI_PCLK)) then
--			idata <= RGB_IN;
--			ivs <= HDI_VS;
--			ihs <= HDI_HS;
--			ide <= HDI_DE;
--			
--			odata <= idata;
--			ovs <= ivs;
--			ohs <= ihs;
--			ode <= ide;
--			
--			RGB_OUT <= odata;
--			HDO_VS <= ovs;
--			HDO_HS <= ohs;
--			HDO_DE <= ode;
--		end if;
--		end process;
--		
--		-- By inverting the clock here I'm putting the rising
--		-- edge in the middle of the data eye
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => HDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--	
--	end block;


	-- The register map is actually 2 sections of memory: a true dual-port bram, and
	-- a distributed ram. With different design it would be possible to eliminate the
	-- bram, but I did it this way because I wanted the repository to be a true dual
	-- port memory. That way if I want to do things like self-clearing bits I don't
	-- have to worry about an I2C write colliding with a self write. Probably way
	-- overdesigned, but there's plenty of resources so it doesn't matter.
	
	-- The initial state of a bram is technically settable, but Xilinx recommends not
	-- to rely on it. So at boot I write the defaults to the bram, and then do a 
	-- refresh operation to synchronize the distributed ram to the bram. The refresh
	-- is also done after an i2c write is detected. Even if I were using all 256
	-- registers, the refresh takes about 260 clocks; compare this to the i2c clock,
	-- which has a period of 1000 clocks. So there's no chance of missing an i2c write
	-- while a refresh is taking place.

	register_map_handler : block is
	
		constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101100";
		
		constant map_defaults : ram_t := 
		(
			0 => x"01", -- Register table version
			1 => x"00", -- Input source. 0 = internal test pattern, 1 = HDMI, 2 = SD
			2 => x"02", -- Input pclk freq. 0 = 100M, 1 = 27M, 2 = 74.25M, 3 = 148.5M
			3 => x"78",
			4 => x"33",
			5 => x"FF",
			6 => x"AB",
			7 => x"CD",
			others => x"00"
		);
		
		signal ram_addr : std_logic_vector(7 downto 0);
		signal ram_wdata : std_logic_vector(7 downto 0);
		signal ram_rdata : std_logic_vector(7 downto 0);
		signal ram_we : std_logic;
		signal we_old : std_logic := '0';
		
		signal regmap_addr : std_logic_vector(7 downto 0);
		signal regmap_rdata : std_logic_vector(7 downto 0);
		signal regmap_wdata : std_logic_vector(7 downto 0) := (others => '0');
		signal regmap_we : std_logic := '0';
		
		type state_t is (IDLE, SET_DEFAULT, DEFAULT2, REFRESH, D1, D2, D3);
		signal state : state_t := SET_DEFAULT;
	
	begin
		Inst_bram_true_dual_port: bram_true_dual_port 
		generic map (
			ADDR_WIDTH => 8,
			DATA_WIDTH => 8
		)
		PORT MAP(
			CLK1 => clk,
			ADDR1 => ram_addr,
			RDATA1 => ram_rdata,
			WDATA1 => ram_wdata,
			WE1 => ram_we,
			CLK2 => clk,
			ADDR2 => regmap_addr,
			RDATA2 => regmap_rdata,
			WDATA2 => regmap_wdata,
			WE2 => regmap_we
		);

		Inst_i2c_slave: i2c_slave 
		generic map (
			SLAVE_ADDRESS => I2C_SLAVE_ADDR
		)
		PORT MAP(
			CLK => clk,
			SDA => I2C_SDA,
			SCL => I2C_SCL,
			RAM_ADDR => ram_addr,
			RAM_WDATA => ram_wdata,
			RAM_WE => ram_we,
			RAM_RDATA => ram_rdata
		);
		
		-- At boot, fill the register map with the defaults
		process(clk) is
			variable nextaddr : natural;
			variable raddr : natural;
		begin
		if(rising_edge(clk)) then

			we_old <= ram_we;

		case state is
			when SET_DEFAULT =>
				regmap_addr <= x"00";
				regmap_wdata <= map_defaults(0);
				regmap_we <= '1';
				state <= DEFAULT2;
			
			when DEFAULT2 =>
				nextaddr := to_integer(unsigned(regmap_addr)) + 1;
				if(nextaddr > map_defaults'high) then
					regmap_we <= '0';
					state <= REFRESH;
				else
					regmap_addr <= std_logic_vector(to_unsigned(nextaddr, regmap_addr'length));
					regmap_wdata <= map_defaults(nextaddr);
				end if;
				
			when REFRESH =>
				regmap_addr <= x"00";
				state <= D1;
			
			when D1 =>
				nextaddr := to_integer(unsigned(regmap_addr)) + 1;
				regmap_addr <= std_logic_vector(to_unsigned(nextaddr, regmap_addr'length));
				state <= D2;
				
			when D2 =>
				raddr := to_integer(unsigned(regmap_addr)) - 1;
				register_map(raddr) <= regmap_rdata;
				nextaddr := to_integer(unsigned(regmap_addr)) + 1;
				if(nextaddr > register_map'high) then
					state <= D3;
				else
					regmap_addr <= std_logic_vector(to_unsigned(nextaddr, regmap_addr'length));
				end if;
			
			when D3 =>
				raddr := to_integer(unsigned(regmap_addr));
				register_map(raddr) <= regmap_rdata;
				state <= IDLE;
				
			when IDLE =>
				if(ram_we = '0' and we_old = '1') then
					-- An i2c write has taken place, which means I should refresh the distributed array
					state <= REFRESH;
				else
					state <= IDLE;
				end if;
		end case;
		end if;
		end process;
		
		
	end block;


	blinker : block is
		signal val : std_logic_vector(15 downto 0) := x"0001";
		signal count : natural := 0;
	begin
	
		process(clk) is
		begin
		if(rising_edge(clk)) then
			if(count = 100000000 / 16) then
				count <= 0;
				val(15 downto 1) <= val(14 downto 0);
				val(0) <= val(15);
			else
				count <= count + 1;
			end if;
		end if;
		end process;
		
		B0_GPIO0 <= val(0);
		B1_GPIO1 <= val(1);
		B1_GPIO2 <= val(2);
		B1_GPIO3 <= val(3);
		B1_GPIO4 <= val(4);
		B1_GPIO5 <= val(5);
		B1_GPIO6 <= val(6);
		B1_GPIO7 <= val(7);
		B1_GPIO8 <= val(8);
		B1_GPIO9 <= val(9);
		B1_GPIO10 <= val(10);
		B1_GPIO11 <= val(11);
		B1_GPIO12 <= val(12);
		B1_GPIO13 <= val(13);
		--B1_GPIO14 <= val(14);
		--B1_GPIO15 <= val(15);
		B1_GPIO14 <= REG_PCLK_FREQ(0);
		B1_GPIO15 <= REG_PCLK_FREQ(1);

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

