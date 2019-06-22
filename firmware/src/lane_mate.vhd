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
	
	component test_pattern is
	Port ( 
		PCLK : in  STD_LOGIC;
		VS : in  STD_LOGIC;
		HS : in  STD_LOGIC;
		DE : in  STD_LOGIC;
		CE : in  STD_LOGIC;
		IS422 : in std_logic;
		D : in  STD_LOGIC_VECTOR (23 downto 0);
		VSOUT : out  STD_LOGIC;
		HSOUT : out  STD_LOGIC;
		DEOUT : out  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0)
	);
	end component;
	
	component delay_application is
	Port ( 
		-- Video input
		PCLK : in std_logic;
		VS   : in std_logic;
		HS   : in std_logic;
		DE   : in std_logic;
		PDATA : in std_logic_vector(23 downto 0);
		IS422 : in std_logic; -- if true, bottom 8 bits are assumed to be the data
		READOUT_DELAY : in std_logic_vector(10 downto 0); -- needs to be about half a line, long enough so that a few transactions have occurred
		CE : in std_logic;
		
		-- R/W settings
		FRAME_ADDR_W : in std_logic_vector(26 downto 0); -- DDR write pointer. Captured on VS.
		FRAME_ADDR_R : in std_logic_vector(26 downto 0); -- DDR read pointer. Captured on VS.
		
		-- Video output
		VS_OUT : out std_logic;
		HS_OUT : out std_logic;
		DE_OUT : out std_logic;
		PDATA_OUT  : out std_logic_vector(23 downto 0);

		DEBUG : out std_logic;
		-------------------------------------------------------------------------
		-- MCB interface
		MCLK : in std_logic;
		
		-- fifo status and control
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0);
		MAVAIL : out std_logic_vector(8 downto 0);
		MFLUSH : out std_logic;
		
		-- write-transaction fifo, output side
		MPOP_W : in std_logic;
		MADDR_W : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDATA_W : out std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : out std_logic;
		
		-- read-transaction fifo, output side
		MPOP_R : in std_logic;
		MADDR_R : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : out std_logic;

		-- read-transaction results
		MPUSH : in std_logic;
		MDATA : in std_logic_vector(255 downto 0)
		
		--
		-------------------------------------------------------------------------
	);
	end component;
	
	component internal_mcb is
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0);
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
		-- write-transaction fifo
		MPOP_W : out std_logic;
		MADDR_W : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDATA_W : in std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;
		
		-- read-transaction fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDVALID_R : in std_logic;
		
		-- output side
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
	end component;
	
	component trivial_mcb is
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0);
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
		-- write-transaction fifo
		MPOP_W : out std_logic;
		MADDR_W : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDATA_W : in std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;
		
		-- read-transaction fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);    -- ddr address, high 27 bits
		MDVALID_R : in std_logic;
		
		-- output side
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
	end component;
	
	
	
	constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101100";
	
	type ram_t is array(14 downto 0) of std_logic_vector(7 downto 0);
	signal register_map : ram_t :=
	(
		0 => x"02", -- Register table version
		1 => x"00", -- video source, HD (0x00) or SD (0x01)
		2 => x"01", -- test pattern, off (0x00) or on (0x01)
		3 => x"02", -- readout_delay(10 downto 8)
		4 => x"80", -- readout_delay(7 downto 0)
		5 => x"14", -- mtransaction_size(7 downto 0)
		6 => x"00", -- delay_enabled
		7  => x"00", -- ddr write pointer (26 downto 24)
		8  => x"00", -- ddr write pointer (23 downto 16)
		9  => x"00", -- ddr write pointer (15 downto  8)
		10 => x"00", -- ddr write pointer ( 7 downto  0)
		11 => x"00", -- ddr read pointer (26 downto 24)
		12 => x"00", -- ddr read pointer (23 downto 16)
		13 => x"00", -- ddr read pointer (15 downto  8)
		14 => x"00", -- ddr read pointer ( 7 downto  0)
		others => x"00"
	);
	signal ram_addr : std_logic_vector(7 downto 0);
	signal ram_wdata : std_logic_vector(7 downto 0);
	signal ram_rdata : std_logic_vector(7 downto 0);
	signal ram_we : std_logic;
	signal i2c_register_write : std_logic;
	signal i2c_register_addr : std_logic_vector(7 downto 0);
	

	signal testpat_vs : std_logic;
	signal testpat_hs : std_logic;
	signal testpat_de : std_logic;
	signal testpat_d : std_logic_vector(23 downto 0);

	signal hd_vs : std_logic;
	signal hd_hs : std_logic;
	signal hd_de : std_logic;
	signal hd_d : std_logic_vector(23 downto 0);

	signal hdt_vs : std_logic;
	signal hdt_hs : std_logic;
	signal hdt_de : std_logic;
	signal hdt_d : std_logic_vector(23 downto 0);
	
	signal decoded_sd_vs : std_logic;
	signal decoded_sd_hs : std_logic;
	signal decoded_sd_de : std_logic;
	signal decoded_sd_d : std_logic_vector(7 downto 0);
	
	
	signal stage1_hs : std_logic;
	signal stage1_vs : std_logic;
	signal stage1_de : std_logic;
	signal stage1_d : std_logic_vector(23 downto 0);

	signal stage2_hs : std_logic;
	signal stage2_vs : std_logic;
	signal stage2_de : std_logic;
	signal stage2_d : std_logic_vector(23 downto 0);
	
	signal stage3_hs : std_logic;
	signal stage3_vs : std_logic;
	signal stage3_de : std_logic;
	signal stage3_d : std_logic_vector(23 downto 0);
	
	signal clk : std_logic;
	signal ibufg_to_bufgs : std_logic;
	
	signal video_clock : std_logic;
	signal dcm1_locked : std_logic;
	signal dcm2_locked : std_logic;
	
	signal video_source_ready : std_logic := '0';
	
	signal enable_test_pattern : std_logic := '0';
	
	signal rgbmask : std_logic_vector(23 downto 0);

	signal is422 : std_logic;
	
	signal readout_delay : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(1920/2, 11));
	signal frame_addr_w : std_logic_vector(26 downto 0) := (others => '0');
	signal frame_addr_r : std_logic_vector(26 downto 0) := (others => '0');
	signal mtransaction_size : std_logic_vector(7 downto 0) := x"1e";
	
	signal delay_debug : std_logic;
	
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

	
	clock_manager : block is
		type state_t is (IDLE, RESETTING);
		signal state : state_t := IDLE;
		signal count : natural range 0 to 12 := 0;
		signal hdclk : std_logic;
		signal sdclk : std_logic;
		signal clk_select : std_logic := '0';
		signal dcm_rst : std_logic := '0';
	begin
	
		hd_dcm : DCM_CLKGEN
		generic map (
			CLKFXDV_DIVIDE => 2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
			CLKFX_DIVIDE => 2,         -- Divide value - D - (1-256)
			CLKFX_MD_MAX => 1.5,       -- Specify maximum M/D ratio for timing anlysis
			CLKFX_MULTIPLY => 2,       -- Multiply value - M - (2-256)
			CLKIN_PERIOD => 13.468,       -- Input clock period specified in nS
			SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
												-- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
			STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
		)
		port map (
			CLKFX => hdclk,         -- 1-bit output: Generated clock output
			CLKFX180 => open,   -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
			CLKFXDV => open,     -- 1-bit output: Divided clock output
			LOCKED => dcm1_locked,       -- 1-bit output: Locked output
			PROGDONE => open,   -- 1-bit output: Active high output to indicate the successful re-programming
			STATUS => open,       -- 2-bit output: DCM_CLKGEN status
			CLKIN => HDI_PCLK,         -- 1-bit input: Input clock
			FREEZEDCM => '0', -- 1-bit input: Prevents frequency adjustments to input clock
			PROGCLK => '0',     -- 1-bit input: Clock input for M/D reconfiguration
			PROGDATA => '0',   -- 1-bit input: Serial data input for M/D reconfiguration
			PROGEN => '0',       -- 1-bit input: Active high program enable
			RST => dcm_rst              -- 1-bit input: Reset input pin
		);
		
		sd_dcm : DCM_CLKGEN
		generic map (
			CLKFXDV_DIVIDE => 2,       -- CLKFXDV divide value (2, 4, 8, 16, 32)
			CLKFX_DIVIDE => 2,         -- Divide value - D - (1-256)
			CLKFX_MD_MAX => 1.5,       -- Specify maximum M/D ratio for timing anlysis
			CLKFX_MULTIPLY => 2,       -- Multiply value - M - (2-256)
			CLKIN_PERIOD => 37.037,       -- Input clock period specified in nS
			SPREAD_SPECTRUM => "NONE", -- Spread Spectrum mode "NONE", "CENTER_LOW_SPREAD", "CENTER_HIGH_SPREAD",
												-- "VIDEO_LINK_M0", "VIDEO_LINK_M1" or "VIDEO_LINK_M2" 
			STARTUP_WAIT => FALSE      -- Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
		)
		port map (
			CLKFX => sdclk,         -- 1-bit output: Generated clock output
			CLKFX180 => open,   -- 1-bit output: Generated clock output 180 degree out of phase from CLKFX.
			CLKFXDV => open,     -- 1-bit output: Divided clock output
			LOCKED => dcm2_locked,       -- 1-bit output: Locked output
			PROGDONE => open,   -- 1-bit output: Active high output to indicate the successful re-programming
			STATUS => open,       -- 2-bit output: DCM_CLKGEN status
			CLKIN => SDI_PCLK,         -- 1-bit input: Input clock
			FREEZEDCM => '0', -- 1-bit input: Prevents frequency adjustments to input clock
			PROGCLK => '0',     -- 1-bit input: Clock input for M/D reconfiguration
			PROGDATA => '0',   -- 1-bit input: Serial data input for M/D reconfiguration
			PROGEN => '0',       -- 1-bit input: Active high program enable
			RST => dcm_rst              -- 1-bit input: Reset input pin
		);
		
		clkmux : BUFGMUX
		generic map (
			CLK_SEL_TYPE => "SYNC"  -- Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
		)
		port map (
			O => video_clock,   -- 1-bit output: Clock buffer output
			I0 => hdclk, -- 1-bit input: Clock buffer input (S=0)
			I1 => sdclk, -- 1-bit input: Clock buffer input (S=1)
			S => clk_select    -- 1-bit input: Clock buffer select
		);
	
		process(clk) is
		begin
		if(rising_edge(clk)) then
		case register_map(1) is
			when x"00" =>
				-- HD clock
				video_source_ready <= dcm1_locked;
				clk_select <= '0';
			
			when x"01" =>
				-- SD clock
				video_source_ready <= dcm2_locked;
				clk_select <= '1';
				
			when others =>
				video_source_ready <= '0';
				clk_select <= '0';
		end case;
		end if;
		end process;
		
		-- The HD video source can change resolutions and thus clock frequencies.
		-- When that happens, the hd dcm will unlock and stay unlocked until a 
		-- reset is performed. In general I will know when this happens in the 
		-- micro, because it will be monitoring the receiver's registers, which
		-- indicate the resolution output. So here I provide the facility to cause
		-- a dcm reset by doing so any time the video source register is written to.
		process(clk) is
		begin
		if(rising_edge(clk)) then
		case state is
			when IDLE =>
				if(i2c_register_addr = x"01" and i2c_register_write = '1') then
					dcm_rst <= '1';
					count <= 12; -- 100MHz is 3.7x faster than 27MHz, and resets must be >3 input clocks long
					state <= RESETTING;
				else
					dcm_rst <= '0';
				end if;
			
			when RESETTING =>
				if(count = 0) then
					state <= IDLE;
				else
					count <= count - 1;
				end if;
		end case;
		end if;
		end process;
		
		
		-- Primary SD video data capture ----------------------------------------
		
		Inst_bt656_decode: bt656_decode PORT MAP(
			D => SDV,
			CLK => sdclk,
			VS => decoded_sd_vs,
			HS => decoded_sd_hs,
			DE => decoded_sd_de,
			DOUT => decoded_sd_d
		);
		
		-------------------------------------------------------------------------
		
		
		
		
		-- Primary HD video data capture ----------------------------------------
		
		process(RGB_IN, HDI_DE) is
		begin
			for i in 0 to RGB_IN'high loop
				rgbmask(i) <= RGB_IN(i) and HDI_DE;
			end loop;
		end process;
		
		process(hdclk) is
		begin
		if(rising_edge(hdclk)) then
			hd_vs <= HDI_VS;
			hd_hs <= HDI_HS;
			hd_de <= HDI_DE;
			hd_d  <= rgbmask;
		end if;
		end process;
		
		-------------------------------------------------------------------------
		
	end block;
	
	
		
		
	-- Video source select -----------------------------------------------------
		
	process(video_clock) is
	begin
	if(rising_edge(video_clock)) then
		if(register_map(1) = x"00") then
			stage1_vs <= hd_vs;
			stage1_hs <= hd_hs;
			stage1_de <= hd_de;
			stage1_d  <= hd_d;
		elsif(register_map(1) = x"01") then
			stage1_vs <= decoded_sd_vs;
			stage1_hs <= decoded_sd_hs;
			stage1_de <= decoded_sd_de;
			stage1_d(23 downto 8) <= (others => '0');
			stage1_d(7 downto 0)  <= decoded_sd_d;
		else
			stage1_vs <= '1';
			stage1_hs <= '1';
			stage1_de <= '0';
			stage1_d  <= (others => '0');
		end if;
	end if;
	end process;
	
	with register_map(1) select is422 <=
		'1' when x"01",
		'0' when others;
	
	----------------------------------------------------------------------------





	-- Test pattern (overwrites source data) -----------------------------------

	with register_map(2) select enable_test_pattern <=
		'1' when x"01",
		'0' when others;
	
	Inst_test_pattern: test_pattern PORT MAP(
		PCLK => video_clock,
		VS => stage1_vs,
		HS => stage1_hs,
		DE => stage1_de,
		CE => enable_test_pattern,
		IS422 => is422,
		D => stage1_d,
		VSOUT => stage2_vs,
		HSOUT => stage2_hs,
		DEOUT => stage2_de,
		DOUT => stage2_d
	);
	
	----------------------------------------------------------------------------
	
	
	-- Main application --------------------------------------------------------
	-- External parameters: readout_delay, mtransaction_size, frame_addr_w, frame_addr_r
	-- Of those, all are on the pixel clock domain except mtransaction_size.
	
	app : block is
		signal MPOP_W : std_logic;
		signal MPOP_R : std_logic;
		signal MPUSH : std_logic;
		signal MDATA : std_logic_vector(255 downto 0);
		signal MAVAIL : std_logic_vector(8 downto 0);
		signal MFLUSH : std_logic;
		signal MADDR_W : std_logic_vector(26 downto 0);
		signal MDATA_W : std_logic_vector(255 downto 0);
		signal MDVALID_W : std_logic;
		signal MADDR_R : std_logic_vector(26 downto 0);
		signal MDVALID_R : std_logic;
		signal preadout_delay : std_logic_vector(10 downto 0);
		signal pframe_addr_w : std_logic_vector(26 downto 0);
		signal pframe_addr_r : std_logic_vector(26 downto 0);
		signal delay_enabled : std_logic_vector(7 downto 0);
	begin
	
		process(clk) is
		begin
		if(rising_edge(clk)) then
			-- writing to low byte triggers acceptance of new value
			if(i2c_register_write = '1' and to_integer(unsigned(i2c_register_addr)) = 4) then
				readout_delay(10 downto 8) <= register_map(3)(2 downto 0);
				readout_delay(7 downto 0) <= register_map(4)(7 downto 0);
			end if;
			mtransaction_size <= register_map(5);
			
			-- Double buffered, new value takes affect on VS
			if(i2c_register_write = '1' and to_integer(unsigned(i2c_register_addr)) = 10) then
				frame_addr_w(26 downto 24) <= register_map(7)(2 downto 0);
				frame_addr_w(23 downto 16) <= register_map(8);
				frame_addr_w(15 downto  8) <= register_map(9);
				frame_addr_w( 7 downto  0) <= register_map(10);
			end if;
			if(i2c_register_write = '1' and to_integer(unsigned(i2c_register_addr)) = 14) then
				frame_addr_r(26 downto 24) <= register_map(11)(2 downto 0);
				frame_addr_r(23 downto 16) <= register_map(12);
				frame_addr_r(15 downto  8) <= register_map(13);
				frame_addr_r( 7 downto  0) <= register_map(14);
			end if;
		end if;
		end process;
	
		cross_delay : synchronizer_2ff 
		generic map( DATA_WIDTH => 11, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => clk,
			DA => readout_delay,
			CLKB => video_clock,
			DB => preadout_delay,
			RESETB => '0'
		);
		cross_addrw : synchronizer_2ff 
		generic map( DATA_WIDTH => 27, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => clk,
			DA => frame_addr_w,
			CLKB => video_clock,
			DB => pframe_addr_w,
			RESETB => '0'
		);
		cross_addrr : synchronizer_2ff 
		generic map( DATA_WIDTH => 27, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => clk,
			DA => frame_addr_r,
			CLKB => video_clock,
			DB => pframe_addr_r,
			RESETB => '0'
		);
		cross_ce : synchronizer_2ff 
		generic map( DATA_WIDTH => 8, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => clk,
			DA => register_map(6),
			CLKB => video_clock,
			DB => delay_enabled,
			RESETB => '0'
		);
	
		inst_delay_application: delay_application PORT MAP (
			 PCLK => video_clock,
			 VS => stage2_vs,
			 HS => stage2_hs,
			 DE => stage2_de,
			 PDATA => stage2_d,
			 IS422 => is422,
			 READOUT_DELAY => preadout_delay, -- pclk
			 CE => delay_enabled(0),
			 FRAME_ADDR_W => pframe_addr_w, -- pclk
			 FRAME_ADDR_R => pframe_addr_r, -- pclk
			 VS_OUT => stage3_vs,
			 HS_OUT => stage3_hs,
			 DE_OUT => stage3_de,
			 PDATA_OUT => stage3_d,
			 DEBUG => delay_debug,
			 MCLK => clk,
			 MTRANSACTION_SIZE => mtransaction_size, -- mclk
			 MAVAIL => MAVAIL,
			 MFLUSH => MFLUSH,
			 MPOP_W => MPOP_W,
			 MADDR_W => MADDR_W,
			 MDATA_W => MDATA_W,
			 MDVALID_W => MDVALID_W,
			 MPOP_R => MPOP_R,
			 MADDR_R => MADDR_R,
			 MDVALID_R => MDVALID_R,
			 MPUSH => MPUSH,
			 MDATA => MDATA
		  );

--		Inst_trivial_mcb: trivial_mcb PORT MAP(
		Inst_trivial_mcb: internal_mcb PORT MAP(
			MCLK => clk,
			MTRANSACTION_SIZE => MTRANSACTION_SIZE,
			MAVAIL => MAVAIL,
			MFLUSH => MFLUSH,
			MPOP_W => MPOP_W,
			MADDR_W => MADDR_W,
			MDATA_W => MDATA_W,
			MDVALID_W => MDVALID_W,
			MPOP_R => MPOP_R,
			MADDR_R => MADDR_R,
			MDVALID_R => MDVALID_R,
			MPUSH_R => MPUSH,
			MDATA_R => MDATA
		);
	
	B1_GPIO13 <= MPOP_W;
	B1_GPIO14 <= MPUSH;	
	B1_GPIO15 <= MFLUSH;
	end block;
	
	
	----------------------------------------------------------------------------
	
	



	-- Output ------------------------------------------------------------------
	
	process(video_clock) is
	begin
	if(rising_edge(video_clock)) then
		HDO_VS <= stage3_vs;
		HDO_HS <= stage3_hs;
		HDO_DE <= stage3_de;
		RGB_OUT <= stage3_d;
	end if;
	end process;
	
	Inst_clock_forwarding: clock_forwarding 
	GENERIC MAP(
		INVERT => false
	)
	PORT MAP(
		CLK => video_clock,
		CLKO => HDO_PCLK
	);
	
	----------------------------------------------------------------------------
	
	






	-- I2C register map --------------------------------------------------------

	register_map_handler : block is
	begin

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
		
		process(clk) is
		begin
		if(rising_edge(clk)) then
			i2c_register_write <= ram_we;
			i2c_register_addr  <= ram_addr;
			if(ram_we = '1') then
				register_map(to_integer(unsigned(ram_addr))) <= ram_wdata;
			end if;
			ram_rdata <= register_map(to_integer(unsigned(ram_addr)));
		end if;
		end process;
		
	end block;
	
	----------------------------------------------------------------------------
	
	
	
	
	


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
		--B1_GPIO12 <= val(12);
		--B1_GPIO13 <= val(13);
		--B1_GPIO14 <= val(14);
		--B1_GPIO15 <= val(15);
		B1_GPIO12 <= register_map(1)(0);
		--B1_GPIO13 <= register_map(1)(1);
		--B1_GPIO14 <= register_map(1)(2);
		--B1_GPIO15 <= de_debug;

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

