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

	COMPONENT timing_gen
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		SEL : IN std_logic_vector(1 downto 0);          
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
		SEL : in std_logic_vector(1 downto 0); -- 00=27M, 01=74.25M, 10=148.5M
		DCM1_LOCKED : out std_logic;
		DCM2_LOCKED : out std_logic;
		CLKOUT : out std_logic
	);
	end component;

	component source_manager is
    Port ( CLK : in  STD_LOGIC;
           SOURCE : in  STD_LOGIC_VECTOR (2 downto 0);   -- 00=720p test pat, 01=1080p test pat, 10=hd in 720p, 11=hd in 1080p, 100=sd in
           CLK_SEL : out  STD_LOGIC_VECTOR (1 downto 0);
           SRC_SEL : out  STD_LOGIC_VECTOR (1 downto 0);
           SRC_ENABLE : out  STD_LOGIC);
	end component;
	
	component source_select is
	Port ( 
		SYSCLK : in  STD_LOGIC;
		
		PIXEL_CLK : in std_logic;
		PIXEL_CLK_LOCKED : in std_logic;
		
		-- clk is PIXEL_CLK
		INT_VS : in std_logic;
		INT_HS : in std_logic;
		INT_DE : in std_logic;
		INT_D  : in std_logic_vector(23 downto 0);
		
		HD_PCLK : in std_logic;
		HD_VS : in std_logic;
		HD_HS : in std_logic;
		HD_DE : in std_logic;
		HD_D  : in std_logic_vector(23 downto 0);
		
		-- BT.656 (YCbCr 4:2:2, embedded syncs)
		SD_PCLK : in std_logic;
		SD_D : in std_logic_vector(7 downto 0);
		
		SEL : in std_logic_vector(1 downto 0);
		
		-- clk is PIXEL_CLK
		OUT_VS : out std_logic;
		OUT_HS : out std_logic;
		OUT_DE : out std_logic;
		OUT_D  : out std_logic_vector(23 downto 0)
	);
	end component;
	
	
	
	
	type ram_t is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal register_map : ram_t;
	
	signal video_clock : std_logic;

	signal testpat_vs : std_logic;
	signal testpat_hs : std_logic;
	signal testpat_de : std_logic;
	signal testpat_d : std_logic_vector(23 downto 0);
	
	signal stage1_hs : std_logic;
	signal stage1_vs : std_logic;
	signal stage1_de : std_logic;
	signal stage1_d : std_logic_vector(23 downto 0);
	
	signal clk : std_logic;
	signal ibufg_to_bufgs : std_logic;
	
	signal dcm1_locked : std_logic;
	signal dcm2_locked : std_logic;
	
	signal source_sel : std_logic_vector(1 downto 0) := "00";
	signal clk_sel : std_logic_vector(1 downto 0) := "00";
	signal clk_sel_v : std_logic_vector(1 downto 0) := "00";
	signal source_enabled : std_logic;
begin



	-- Main clock input

   sysclk_ibufg : IBUFG generic map (IBUF_LOW_PWR => TRUE, IOSTANDARD => "DEFAULT")
		port map (
			I => SYSCLK,
			O => ibufg_to_bufgs
		);
   clk_bufgmux : BUFG
		port map (
			I => ibufg_to_bufgs,
			O => clk
		);

	
	
	
	
	-- There are 3 video sources: internal test pattern, HDMI, and SD.
	-- Each has its own clock and data bus, and I must mux between them
	-- before sending the data on to the memory interface. 
	
	-- But I can't mux between the clocks provided to me by the HD and SD
	-- receiver chips, due to the Spartan-6 BUFGMUX topology. What I can
	-- do though is use 2 DCMs to generate the 3 clock frequencies I plan
	-- on dealing with: 27MHz, 74.25MHz, and 148.5MHz. I can then use a
	-- series of 2 BUFGMUX blocks to select which one to use. This is done
	-- in the programmable_clock module.

	Inst_programmable_clock: programmable_clock PORT MAP(
		CLK => clk,
		SEL => clk_sel,
		DCM1_LOCKED => dcm1_locked,
		DCM2_LOCKED => dcm2_locked,
		CLKOUT => video_clock
	);
	Inst_clock_forwarding: clock_forwarding 
	GENERIC MAP(
		INVERT => true
	)
	PORT MAP(
		CLK => video_clock,
		CLKO => HDO_PCLK
	);
	
	
	Inst_source_manager: source_manager PORT MAP(
		CLK => clk,
		SOURCE => register_map(1)(2 downto 0),
		CLK_SEL => clk_sel,
		SRC_SEL => source_sel,
		SRC_ENABLE => source_enabled
	);
	
	
	
	-- So at the chip edge, I ingest video data into short FIFOs using the
	-- actual external clock. Then on the read side, I use the DCM-generated
	-- clocks to empty the FIFO. When the desired video source changes, I
	-- reset the FIFOs and reenable FIFO reads once the FIFO is half full.
	-- This gives me the most amount of margin to guard against clock freq
	-- differences between the external and internal sources.
	
	sel_cross: synchronizer_2ff
	generic map (
		DATA_WIDTH => 2,
		EXTRA_INPUT_REGISTER => false,
		USE_GRAY_CODE => true
	)
	port map(
		CLKA => clk,
		DA => clk_sel,
		CLKB => video_clock,
		DB => clk_sel_v,
		RESETB => '0'
	);
	testpat_gen: timing_gen PORT MAP(
		CLK => video_clock,
		RST => '0',
		SEL => clk_sel_v,
		VS => testpat_vs,
		HS => testpat_hs,
		DE => testpat_de,
		D => testpat_d
	);
	
	Inst_source_select: source_select PORT MAP(
		SYSCLK => clk,
		PIXEL_CLK => video_clock,
		PIXEL_CLK_LOCKED => source_enabled,
		
		INT_VS => testpat_vs,
		INT_HS => testpat_hs,
		INT_DE => testpat_de,
		INT_D => testpat_d,
		
		HD_PCLK => HDI_PCLK,
		HD_VS => HDI_VS,
		HD_HS => HDI_HS,
		HD_DE => HDI_DE,
		HD_D => RGB_IN,
		
		SD_PCLK => SDI_PCLK,
		SD_D => SDV,
		
		SEL => source_sel,
		
		OUT_VS => stage1_vs,
		OUT_HS => stage1_hs,
		OUT_DE => stage1_de,
		OUT_D => stage1_d
	);
	
	process(video_clock) is
	begin
	if(rising_edge(video_clock)) then
		HDO_VS <= stage1_vs;
		HDO_HS <= stage1_hs;
		HDO_DE <= stage1_de;
		RGB_OUT <= stage1_d;
	end if;
	end process;
	

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
			1 => x"00", -- Output source. 0 = 720p test pattern, 1 = HD shunt, 2 = SD shunt
			2 => x"56",
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
		--B1_GPIO13 <= val(13);
		--B1_GPIO14 <= val(14);
		--B1_GPIO15 <= val(15);
		B1_GPIO13 <= source_enabled;
		B1_GPIO14 <= register_map(2)(0);
		B1_GPIO15 <= register_map(2)(1);

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

