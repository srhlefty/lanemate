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

use work.pkg_types.all;

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
	
	
	
	DDR_RESET : inout std_logic;
	CK0_P : inout std_logic;
	CK0_N : inout std_logic;
	CKE0 : inout std_logic;
	CK1_P : inout std_logic;
	CK1_N : inout std_logic;
	CKE1 : inout std_logic;
	RAS : inout std_logic;
	CAS : inout std_logic;
	WE : inout std_logic;
	CS0 : inout std_logic;
	CS1 : inout std_logic;
	BA : inout std_logic_vector(2 downto 0);
	MA : inout std_logic_vector(15 downto 0);
	DM : inout std_logic_vector(7 downto 0);
	DQSP : inout std_logic_vector(7 downto 0);
	DQSN : inout std_logic_vector(7 downto 0);
	DQ : inout std_logic_vector(63 downto 0);

	
	
	B0_GPIO0 : out std_logic;
	B1_GPIO1 : out std_logic;
	B1_GPIO2 : out std_logic;
	B1_GPIO3 : out std_logic;
	B1_GPIO4 : out std_logic;
	B1_GPIO5 : out std_logic;
	B1_GPIO6 : out std_logic;
	B1_GPIO7 : out std_logic;
	B1_GPIO8 : in std_logic;	-- switch, up position
	B1_GPIO9 : in std_logic;	-- reserved
	B1_GPIO10 : in std_logic;	-- switch, down position
	B1_GPIO11 : in std_logic;	-- shaft encoder port 1
	B1_GPIO12 : in std_logic;	-- shaft encoder port 2
	B1_GPIO13 : in std_logic;	-- reserved
	B1_GPIO14 : in std_logic;	-- shaft encoder switch
	B1_GPIO15 : in std_logic;	-- controller present
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
		PATTERN : in std_logic_vector(7 downto 0);
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
		READOUT_DELAY : in std_logic_vector(11 downto 0); -- needs to be about half a line, long enough so that a few transactions have occurred
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
		MDATA : in std_logic_vector(255 downto 0);
		
		--
		-------------------------------------------------------------------------
		MOUTPUT_USED : out std_logic_vector(8 downto 0) -- level of ddr_to_pixels fifo
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
	
	component ddr3_mcb is
	Generic ( DEBUG : boolean := false );
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0); -- number of fifo elements to read/write at once
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
		-- Interface to register map for communicating leveling results to the outside world
		REGADDR : out std_logic_vector(7 downto 0);
		REGDATA : out std_logic_vector(7 downto 0);
		REGWE   : out std_logic;

		-- interface to data-to-write fifo
		MPOP_W : out std_logic;
		MADDR_W : in std_logic_vector(26 downto 0);   -- ddr address, high 27 bits
		MDATA_W : in std_logic_vector(255 downto 0);  -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;                      -- data valid
		
		-- interface to data-to-read fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);   -- ddr address, high 27 bits
		MDVALID_R : in std_logic;
		
		-- interface to data-just-read fifo
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0);
		
		MFORCE_INIT : in std_logic;
		MTEST : in std_logic;
		MTRANSACTION_ACTIVE : out std_logic;
		MWRITE_ACTIVE : out std_logic;
		MREAD_ACTIVE : out std_logic;
		MDEBUG_LED : out std_logic_vector(7 downto 0);
		MDEBUG_SYNC : out std_logic;
		
		MADDITIVE_LATENCY : in std_logic_vector(1 downto 0);
		MCAS_LATENCY : in std_logic_vector(3 downto 0);
		
		B0_IOCLK : in std_logic;
		B0_STROBE : in std_logic;
		B0_IOCLK_180 : in std_logic;
		B0_STROBE_180 : in std_logic;
		
		B1_IOCLK : in std_logic;
		B1_STROBE : in std_logic;
		B1_IOCLK_180 : in std_logic;
		B1_STROBE_180 : in std_logic;
		
		B3_IOCLK : in std_logic;
		B3_STROBE : in std_logic;
		B3_IOCLK_180 : in std_logic;
		B3_STROBE_180 : in std_logic;

		IOCLK_LOCKED : in std_logic;

		-- physical interface
		DDR_RESET : inout std_logic;
		CK0_P : inout std_logic;
		CK0_N : inout std_logic;
		CKE0 : inout std_logic;
		CK1_P : inout std_logic;
		CK1_N : inout std_logic;
		CKE1 : inout std_logic;
		RAS : inout std_logic;
		CAS : inout std_logic;
		WE : inout std_logic;
		CS0 : inout std_logic;
		CS1 : inout std_logic;
		BA : inout std_logic_vector(2 downto 0);
		MA : inout std_logic_vector(15 downto 0);
		DM : inout std_logic_vector(7 downto 0);
		DQSP : inout std_logic_vector(7 downto 0);
		DQSN : inout std_logic_vector(7 downto 0);
		DQ : inout std_logic_vector(63 downto 0)
	);
	end component;

	component clkgen is
	Port ( 
		SYSCLK100 : in STD_LOGIC;
		
		CLK200 : out STD_LOGIC;
		
		B0_CLK800 : out std_logic;
		B0_STROBE800 : out std_logic;
		B0_CLK800_180 : out std_logic;
		B0_STROBE800_180 : out std_logic;

		B1_CLK800 : out std_logic;
		B1_STROBE800 : out std_logic;
		B1_CLK800_180 : out std_logic;
		B1_STROBE800_180 : out std_logic;

		B3_CLK800 : out std_logic;
		B3_STROBE800 : out std_logic;
		B3_CLK800_180 : out std_logic;
		B3_STROBE800_180 : out std_logic;
		
		LOCKED : out std_logic
	);
	end component;
	
	
	constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101100";
	
	type ram_t is array(natural range <>) of std_logic_vector(7 downto 0);
	signal register_map : ram_t(26 downto 0) :=
	(
		0 => x"03", -- Register table version
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
		15 => x"00", -- force DDR init + read leveling (self-clearing)
		16 => x"00", -- Lane 0 read leveling result
		17 => x"00", -- Lane 1 read leveling result
		18 => x"00", -- Lane 2 read leveling result
		19 => x"00", -- Lane 3 read leveling result
		20 => x"00", -- Lane 4 read leveling result
		21 => x"00", -- Lane 5 read leveling result
		22 => x"00", -- Lane 6 read leveling result
		23 => x"00", -- Lane 7 read leveling result
		24 => x"00", -- Run DDR transaction test
		25 => x"00", -- Shaft encoder value ('A' on GPIO8, 'B' on GPIO9)
		26 => x"00", -- GPIO10-15, in bit order (e.g. GPIO10 is (0), GPIO11 is (1), etc)
		others => x"00"
	);
	signal ram_addr : std_logic_vector(7 downto 0);
	signal ram_wdata : std_logic_vector(7 downto 0);
	signal ram_rdata : std_logic_vector(7 downto 0);
	signal ram_we : std_logic;
	signal i2c_register_write : std_logic;
	signal i2c_register_addr : std_logic_vector(7 downto 0);
	-- These are so I can set register data for reading by the micro
	signal internal_reg_we : std_logic := '0';
	signal internal_reg_addr : natural range 0 to 255 := 0;
	signal internal_reg_data : std_logic_vector(7 downto 0) := x"00";
	signal mcb_reg_we : std_logic := '0';
	signal mcb_reg_addr : std_logic_vector(7 downto 0) := x"00";
	signal mcb_reg_data : std_logic_vector(7 downto 0) := x"00";
	

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
	

	signal is422 : std_logic;
	
	signal readout_delay : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(1920/2, 12));
	signal frame_addr_w : std_logic_vector(26 downto 0) := (others => '0');
	signal frame_addr_r : std_logic_vector(26 downto 0) := (others => '0');
	signal mtransaction_size : std_logic_vector(7 downto 0) := x"1e";
	
	signal trigger_ddr_init : std_logic := '0';
	signal trigger_ddr_test : std_logic := '0'; -- put some data in the fifo
	signal run_ddr_test : std_logic := '0';
	signal mcb_debug : std_logic_vector(7 downto 0);
	signal mcb_transaction_active : std_logic;
	signal mcb_write_active : std_logic;
	signal mcb_read_active : std_logic;
	signal debug_sync : std_logic;
	
	signal delay_debug : std_logic;
	
	signal output_fifo_level : std_logic_vector(8 downto 0);
	
	signal b0_serdesclk : std_logic;
	signal b0_serdesstrobe : std_logic;
	signal b0_serdesclk_180 : std_logic;
	signal b0_serdesstrobe_180 : std_logic;
	signal b1_serdesclk : std_logic;
	signal b1_serdesstrobe : std_logic;
	signal b1_serdesclk_180 : std_logic;
	signal b1_serdesstrobe_180 : std_logic;
	signal b3_serdesclk : std_logic;
	signal b3_serdesstrobe : std_logic;
	signal b3_serdesclk_180 : std_logic;
	signal b3_serdesstrobe_180 : std_logic;
	signal ioclk_locked : std_logic;



		signal MPOP_W : std_logic;
		signal MPUSH : std_logic;

	constant ONLY_HD : boolean := true;

begin



	-- Main clock input
	Inst_clkgen: clkgen PORT MAP(
		SYSCLK100 => SYSCLK,
		CLK200 => clk,
		B0_CLK800 => b0_serdesclk,
		B0_STROBE800 => b0_serdesstrobe,
		B0_CLK800_180 => b0_serdesclk_180,
		B0_STROBE800_180 => b0_serdesstrobe_180,
		B1_CLK800 => b1_serdesclk,
		B1_STROBE800 => b1_serdesstrobe,
		B1_CLK800_180 => b1_serdesclk_180,
		B1_STROBE800_180 => b1_serdesstrobe_180,
		B3_CLK800 => b3_serdesclk,
		B3_STROBE800 => b3_serdesstrobe,
		B3_CLK800_180 => b3_serdesclk_180,
		B3_STROBE800_180 => b3_serdesstrobe_180,
		LOCKED => ioclk_locked
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
			CLKFX_MD_MAX => 1.0,       -- Specify maximum M/D ratio for timing anlysis
			CLKFX_MULTIPLY => 2,       -- Multiply value - M - (2-256)
			CLKIN_PERIOD => 6.734,       -- Input clock period specified in nS
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
			CLKFX_MD_MAX => 1.0,       -- Specify maximum M/D ratio for timing anlysis
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
		
		clksel : if ONLY_HD = false generate
		begin
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
		end generate;
		
		clksel2 : if ONLY_HD = true generate
			vid_bufg : BUFG
			port map (
				O => video_clock, -- 1-bit output: Clock buffer output
				I => hdclk  -- 1-bit input: Clock buffer input
			);
			video_source_ready <= dcm1_locked;
		end generate;
		
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
		
		capture_hd : block is
			signal edge_vs : std_logic;
			signal edge_hs : std_logic;
			signal edge_de : std_logic;
			signal edge_d  : std_logic_vector(23 downto 0);

			signal fd1_vs : std_logic;
			signal fd1_hs : std_logic;
			signal fd1_de : std_logic;
			signal fd1_d  : std_logic_vector(23 downto 0);
			
			signal rgbmask : std_logic_vector(23 downto 0);
		begin
			process(fd1_d, fd1_de) is
			begin
				for i in 0 to fd1_d'high loop
					rgbmask(i) <= fd1_d(i) and fd1_de;
				end loop;
			end process;
			
			process(hdclk) is
			begin
			if(rising_edge(hdclk)) then
				edge_vs <= HDI_VS;
				edge_hs <= HDI_HS;
				edge_de <= HDI_DE;
				edge_d  <= RGB_IN;
				
				fd1_vs <= edge_vs;
				fd1_hs <= edge_hs;
				fd1_de <= edge_de;
				fd1_d  <= edge_d;
				
				hd_vs <= fd1_vs;
				hd_hs <= fd1_hs;
				hd_de <= fd1_de;
				hd_d  <= rgbmask;
			end if;
			end process;
		end block;
		-------------------------------------------------------------------------
		
	end block;
	
	
		
		
	-- Video source select -----------------------------------------------------
	
	datasel : if ONLY_HD = false generate
	begin
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
	end generate;
	
	datasel2 : if ONLY_HD = true generate
	begin
		process(video_clock) is
		begin
		if(rising_edge(video_clock)) then
			stage1_vs <= hd_vs;
			stage1_hs <= hd_hs;
			stage1_de <= hd_de;
			stage1_d  <= hd_d;
		end if;
		end process;
		
		is422 <= '0';
	end generate;
	----------------------------------------------------------------------------





	-- Test pattern (overwrites source data if enabled) ------------------------

	Inst_test_pattern: test_pattern PORT MAP(
		PCLK => video_clock,
		VS => stage1_vs,
		HS => stage1_hs,
		DE => stage1_de,
		PATTERN => register_map(2),
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
		signal MPOP_R : std_logic;
		signal MDATA : std_logic_vector(255 downto 0);
		signal MAVAIL : std_logic_vector(8 downto 0);
		signal MFLUSH : std_logic;
		signal MADDR_W : std_logic_vector(26 downto 0);
		signal MDATA_W : std_logic_vector(255 downto 0);
		signal MDVALID_W : std_logic;
		signal MADDR_R : std_logic_vector(26 downto 0);
		signal MDVALID_R : std_logic;
		signal preadout_delay : std_logic_vector(11 downto 0);
		signal pframe_addr_w : std_logic_vector(26 downto 0);
		signal pframe_addr_r : std_logic_vector(26 downto 0);
		signal delay_enabled : std_logic_vector(7 downto 0);

	begin
	
		process(clk) is
		begin
		if(rising_edge(clk)) then
			-- writing to low byte triggers acceptance of new value
			if(i2c_register_write = '1' and to_integer(unsigned(i2c_register_addr)) = 4) then
				readout_delay(11 downto 8) <= register_map(3)(3 downto 0);
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
		generic map( DATA_WIDTH => 12, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
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
			 MDATA => MDATA,
			 MOUTPUT_USED => output_fifo_level
		  );
		
--		ddr_test : block is
--			constant TEST_WORD1 : burst_t(63 downto 0) := 
--			(
--				x"0",x"1",x"2",x"3",x"4",x"5",x"6",x"7",x"8",x"9",x"A",x"B",x"C",x"D",x"E",x"F",
--				x"F",x"E",x"D",x"C",x"B",x"A",x"9",x"8",x"7",x"6",x"5",x"4",x"3",x"2",x"1",x"0",
--				x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",
--				x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F"
--			);
--			constant TEST_WORD2 : burst_t(63 downto 0) :=
--			(
--				x"4",x"3",x"b",x"c",x"e",x"d",x"a",x"6",x"f",x"5",x"a",x"8",x"d",x"e",x"e",x"f",
--				x"8",x"9",x"4",x"7",x"b",x"7",x"7",x"e",x"7",x"e",x"2",x"b",x"f",x"2",x"3",x"c",
--				x"2",x"4",x"5",x"c",x"b",x"3",x"7",x"f",x"7",x"b",x"c",x"7",x"d",x"6",x"6",x"7",
--				x"3",x"e",x"9",x"4",x"f",x"8",x"d",x"9",x"6",x"e",x"c",x"f",x"8",x"c",x"2",x"1"
--			);
--			constant TEST_WORD3 : burst_t(63 downto 0) := 
--			(
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"F",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"1"
--			);
--			constant TEST_WORD4 : burst_t(63 downto 0) :=
--			(
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",
--				x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"0",x"1"
--			);
--			procedure burst_to_flat(
--				variable flat : out std_logic_vector(255 downto 0);
--				constant burst : in burst_t(63 downto 0)
--			) is
--			begin
--				for i in 0 to burst'high loop
--					flat(4*i+3 downto 4*i) := burst(i);
--				end loop;
--			end procedure;
--			
--			type state_t is (IDLE, FILL1, FILL2, DELAY, LAUNCH, WAIT_FOR_FINISH, READOUT);
--			signal state : state_t := IDLE;
--			signal catch : ram_t(0 to 63) := (others => x"00");
--			signal count : natural := 0;
--			constant reg_start : natural := 25;
--			
--			signal PADDR_W :std_logic_vector(26 downto 0) := (others => '0');
--			signal PADDR_R :std_logic_vector(26 downto 0) := (others => '0');
--			signal PDATA_W : std_logic_vector(255 downto 0) := (others => '0');
--			signal PPUSH_W : std_logic := '0';
--			signal PPUSH_R : std_logic := '0';
--			
--			component bram_simple_dual_port is
--			generic (
--				ADDR_WIDTH : natural;
--				DATA_WIDTH : natural
--			);
--			 Port ( 
--				CLK1 : in std_logic;
--				WADDR1 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
--				WDATA1 : in std_logic_vector (DATA_WIDTH-1 downto 0);
--				WE1    : in std_logic;
--
--				CLK2 : in std_logic;
--				RADDR2 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
--				RDATA2 : out std_logic_vector (DATA_WIDTH-1 downto 0)
--			);
--			end component;
--			
--			component fifo_2clk is
--			generic (
--				ADDR_WIDTH : natural;
--				DATA_WIDTH : natural
--			);
--			 Port ( 
--				WRITE_CLK  : in std_logic;
--				RESET      : in std_logic;
--				FREE       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--				DIN        : in std_logic_vector (DATA_WIDTH-1 downto 0);
--				PUSH       : in std_logic;
--
--				READ_CLK : in std_logic;
--				USED     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--				DOUT     : out std_logic_vector (DATA_WIDTH-1 downto 0);
--				DVALID   : out std_logic;
--				POP      : in std_logic;
--				
--				-- Dual port ram interface, optionally erasable. Note you wire clocks.
--				RAM_WADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--				RAM_WDATA : out std_logic_vector(DATA_WIDTH-1 downto 0);
--				RAM_WE    : out std_logic;
--				RAM_RESET : out std_logic;
--				
--				RAM_RADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
--				RAM_RDATA : in std_logic_vector(DATA_WIDTH-1 downto 0)
--			);
--			end component;
--			
--		begin
--		
--			process(clk) is
--				variable wdata : std_logic_vector(255 downto 0);
--				variable vcount : std_logic_vector(255 downto 0);
--				variable base_addr : std_logic_vector(26 downto 0);
--				variable vaddr : natural;
--				variable vaddrinc : natural;
--				variable newaddr : std_logic_vector(26 downto 0);
--			begin
--			if(rising_edge(clk)) then
--			case state is
--				when IDLE =>
--					PADDR_W <= (others => '0');
--					PADDR_R <= (others => '0');
--					PDATA_W <= (others => '0');
--					PPUSH_W <= '0';
--					PPUSH_R <= '0';
--					internal_reg_we <= '0';
--					if(trigger_ddr_test = '1') then
--						state <= FILL1;
--					end if;
--				
--				when FILL1 =>
--					base_addr := frame_addr_w;
--					burst_to_flat(wdata, TEST_WORD1);
--					PADDR_W <= base_addr;
--					PADDR_R <= base_addr;
--					PDATA_W <= wdata;
--					PPUSH_W <= '1';
--					PPUSH_R <= '1';
--					state <= FILL2;
--					
--				when FILL2 =>
--					base_addr := frame_addr_w;
--					burst_to_flat(wdata, TEST_WORD2);
--					PADDR_W <= base_addr;
--					PADDR_R <= base_addr;
--					PDATA_W <= wdata;
--					PPUSH_W <= '1';
--					PPUSH_R <= '1';
--					count <= 4; -- it takes a few clocks for the number of words available in the FIFO to be updated
--					state <= DELAY;
--				
--				when DELAY =>
--					PADDR_W <= (others => '0');
--					PADDR_R <= (others => '0');
--					PDATA_W <= (others => '0');
--					PPUSH_W <= '0';
--					PPUSH_R <= '0';
--					if(count = 0) then
--						state <= LAUNCH;
--					else
--						count <= count - 1;
--					end if;
--				
--				when LAUNCH =>
--					PADDR_W <= (others => '0');
--					PADDR_R <= (others => '0');
--					PDATA_W <= (others => '0');
--					PPUSH_W <= '0';
--					PPUSH_R <= '0';
--					run_ddr_test <= '1';
--					count <= 250; -- The complete transaction for 30 words takes less than 1us. This is 2us.
--					state <= WAIT_FOR_FINISH;
--				
--				when WAIT_FOR_FINISH =>
--					run_ddr_test <= '0';
--					if(count = 0) then
--						state <= READOUT;
--					else
--						count <= count - 1;
--					end if;
--					
--					if(MPUSH = '1') then
--						-- Data is stored in the upper half on arrival,
--						-- and shifted to the lower half when the next arrives
--						for i in 0 to 31 loop
--							catch(32+i) <= MDATA(8*i+7 downto 8*i);
----							catch(32+i) <= x"FF";
--							catch(i) <= catch(32+i);
--						end loop;
--						
--					end if;
--				
--				when READOUT =>
--					if(count = 64) then
--						internal_reg_we <= '0';
--						state <= IDLE;
--					else
--						internal_reg_addr <= reg_start + count;
--						internal_reg_data <= catch(0);
--						internal_reg_we <= '1';
--						
--						for i in 0 to 63-1 loop
--							catch(i) <= catch(i+1);
--						end loop;
--						
--						count <= count + 1;
--					end if;
--					
--			end case;
--			end if;
--			end process;
--		
--		
--		
--		
--		
--			writer_fifo_block : block is
--				constant ram_addr_width : natural := 9;
--				constant ram_data_width_w : natural := 256 + 27; -- 256 for data, 27 for address
--				constant ram_data_width_r : natural := 27; -- just address
--				
--				signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
--				signal ram_wdata1 : std_logic_vector(ram_data_width_w-1 downto 0);
--				signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
--				signal ram_rdata2 : std_logic_vector(ram_data_width_w-1 downto 0);
--				signal ram_we : std_logic;
--				signal bus_in : std_logic_vector(ram_data_width_w-1 downto 0);
--				signal bus_out : std_logic_vector(ram_data_width_w-1 downto 0);
--			begin
--			
--				write_bram: bram_simple_dual_port 
--				generic map(
--					ADDR_WIDTH => ram_addr_width,
--					DATA_WIDTH => ram_data_width_w
--				)
--				PORT MAP(
--					CLK1 => clk,
--					WADDR1 => ram_waddr1,
--					WDATA1 => ram_wdata1,
--					WE1 => ram_we,
--					CLK2 => clk,
--					RADDR2 => ram_raddr2,
--					RDATA2 => ram_rdata2
--				);
--				
--				bus_in(ram_data_width_w-1 downto ram_data_width_w-27) <= PADDR_W;
--				bus_in(ram_data_width_w-27-1 downto 0)                <= PDATA_W;
--			
--				write_fifo: fifo_2clk 
--				generic map(
--					ADDR_WIDTH => ram_addr_width,
--					DATA_WIDTH => ram_data_width_w
--				)
--				PORT MAP(
--					WRITE_CLK => clk,
--					RESET => '0',
--					FREE => open,
--					DIN => bus_in,
--					PUSH => PPUSH_W,
--					READ_CLK => clk,
--					USED => MAVAIL,
--					DOUT => bus_out,
--					DVALID => MDVALID_W,
--					POP => MPOP_W,
--					RAM_WADDR => ram_waddr1,
--					RAM_WDATA => ram_wdata1,
--					RAM_WE => ram_we,
--					RAM_RESET => open,
--					RAM_RADDR => ram_raddr2,
--					RAM_RDATA => ram_rdata2
--				);
--				
--				MADDR_W <= bus_out(ram_data_width_w-1 downto ram_data_width_w-27); -- 27 bits wide
--				MDATA_W <= bus_out(ram_data_width_w-27-1 downto 0);                -- 256 bits wide
--				
--			end block;
--
--
--
--			reader_fifo_block : block is
--				constant ram_addr_width : natural := 9;
--				constant ram_data_width_w : natural := 256 + 27; -- 256 for data, 27 for address
--				constant ram_data_width_r : natural := 27; -- just address
--
--				signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
--				signal ram_wdata1 : std_logic_vector(ram_data_width_r-1 downto 0);
--				signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
--				signal ram_rdata2 : std_logic_vector(ram_data_width_r-1 downto 0);
--				signal ram_we : std_logic;
--				signal bus_in : std_logic_vector(ram_data_width_r-1 downto 0);
--				signal bus_out : std_logic_vector(ram_data_width_r-1 downto 0);
--			begin
--			
--				read_bram: bram_simple_dual_port 
--				generic map(
--					ADDR_WIDTH => ram_addr_width,
--					DATA_WIDTH => ram_data_width_r
--				)
--				PORT MAP(
--					CLK1 => clk,
--					WADDR1 => ram_waddr1,
--					WDATA1 => ram_wdata1,
--					WE1 => ram_we,
--					CLK2 => clk,
--					RADDR2 => ram_raddr2,
--					RDATA2 => ram_rdata2
--				);
--				
--				bus_in <= PADDR_R;
--			
--				read_fifo: fifo_2clk 
--				generic map(
--					ADDR_WIDTH => ram_addr_width,
--					DATA_WIDTH => ram_data_width_r
--				)
--				PORT MAP(
--					WRITE_CLK => clk,
--					RESET => '0',
--					FREE => open,
--					DIN => bus_in,
--					PUSH => PPUSH_R,
--					READ_CLK => clk,
--					USED => open,
--					DOUT => bus_out,
--					DVALID => MDVALID_R,
--					POP => MPOP_R,
--					RAM_WADDR => ram_waddr1,
--					RAM_WDATA => ram_wdata1,
--					RAM_WE => ram_we,
--					RAM_RESET => open,
--					RAM_RADDR => ram_raddr2,
--					RAM_RDATA => ram_rdata2
--				);
--				
--				MADDR_R <= bus_out;
--				
--			end block;
--		end block;


--		Inst_mcb: internal_mcb PORT MAP(
--			MCLK => clk,
--			MTRANSACTION_SIZE => mtransaction_size,
--			MAVAIL    => MAVAIL,
--			MFLUSH    => MFLUSH,
--			MPOP_W    => MPOP_W,
--			MADDR_W   => MADDR_W,
--			MDATA_W   => MDATA_W,
--			MDVALID_W => MDVALID_W,
--			MPOP_R    => MPOP_R,
--			MADDR_R   => MADDR_R,
--			MDVALID_R => MDVALID_R,
--			MPUSH_R   => MPUSH,
--			MDATA_R   => MDATA
--		);
			
			
		Inst_mcb: ddr3_mcb 
		generic map ( DEBUG => false )
		PORT MAP(
			MCLK => clk,
			MTRANSACTION_SIZE => mtransaction_size,
			MAVAIL    => MAVAIL,
			MFLUSH    => MFLUSH,
			
			REGADDR => mcb_reg_addr,
			REGDATA => mcb_reg_data,
			REGWE   => mcb_reg_we,
			
			MPOP_W    => MPOP_W,
			MADDR_W   => MADDR_W,
			MDATA_W   => MDATA_W,
			MDVALID_W => MDVALID_W,
			MPOP_R    => MPOP_R,
			MADDR_R   => MADDR_R,
			MDVALID_R => MDVALID_R,
			MPUSH_R   => MPUSH,
			MDATA_R   => MDATA,
			
			MFORCE_INIT => trigger_ddr_init,
			MTEST => run_ddr_test,
			MTRANSACTION_ACTIVE => mcb_transaction_active,
			MWRITE_ACTIVE => mcb_write_active,
			MREAD_ACTIVE => mcb_read_active,
			MDEBUG_LED => mcb_debug,
			MDEBUG_SYNC => debug_sync,
			
			MADDITIVE_LATENCY => "00",
			MCAS_LATENCY => "0010",
		
			B0_IOCLK      => b0_serdesclk,
			B0_STROBE     => b0_serdesstrobe,
			B0_IOCLK_180  => b0_serdesclk_180,
			B0_STROBE_180 => b0_serdesstrobe_180,
			B1_IOCLK      => b1_serdesclk,
			B1_STROBE     => b1_serdesstrobe,
			B1_IOCLK_180  => b1_serdesclk_180,
			B1_STROBE_180 => b1_serdesstrobe_180,
			B3_IOCLK      => b3_serdesclk,
			B3_STROBE     => b3_serdesstrobe,
			B3_IOCLK_180  => b3_serdesclk_180,
			B3_STROBE_180 => b3_serdesstrobe_180,
			
			IOCLK_LOCKED => ioclk_locked,
			
			DDR_RESET => DDR_RESET,
			CK0_P => CK0_P,
			CK0_N => CK0_N,
			CKE0  => CKE0,
			CK1_P => CK1_P,
			CK1_N => CK1_N,
			CKE1  => CKE1,
			RAS   => RAS,
			CAS   => CAS,
			WE    => WE,
			CS0   => CS0,
			CS1   => CS1,
			BA    => BA,
			MA    => MA,
			DM    => DM,
			DQSP  => DQSP,
			DQSN  => DQSN,
			DQ    => DQ 
		);
	
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
			elsif(internal_reg_we = '1') then
				register_map(internal_reg_addr) <= internal_reg_data;
			elsif(mcb_reg_we = '1') then
				register_map(to_integer(unsigned(mcb_reg_addr))) <= mcb_reg_data;
			end if;
			ram_rdata <= register_map(to_integer(unsigned(ram_addr)));
		end if;
		end process;

	end block;
	
	process(clk) is
	begin
	if(rising_edge(clk)) then
		if(i2c_register_write = '1' and i2c_register_addr = x"0f") then
			trigger_ddr_init <= '1';
		else
			trigger_ddr_init <= '0';
		end if;

		if(i2c_register_write = '1' and i2c_register_addr = x"18") then
			trigger_ddr_test <= '1';
		else
			trigger_ddr_test <= '0';
		end if;
	end if;
	end process;

	
	



	----------------------------------------------------------------------------
	
	-- GPIO
	
	gpio_inputs : block is
		constant filter_depth : natural := 10;
		type history_t is array(natural range <>) of std_logic_vector(filter_depth downto 0);
		constant all_zero : std_logic_vector(filter_depth downto 0) := (others => '0');
		constant all_one : std_logic_vector(filter_depth downto 0) := (others => '1');
		signal history : history_t(0 to 7) := (others => (others => '0'));
		signal gpio_filtered : std_logic_vector(7 downto 0) := (others => '0');
		signal encoder_value : std_logic_vector(7 downto 0) := (others => '0');
		signal count : natural range 0 to 255 := 0;
	begin
		process(clk) is
		begin
		if(rising_edge(clk)) then
			-- Ingest GPIO into filter
			history(0)(0) <= B1_GPIO8;
			history(1)(0) <= B1_GPIO9;
			history(2)(0) <= B1_GPIO10;
			history(3)(0) <= '0'; -- B1_GPIO11; the shaft encoder doesn't get sent through the debounce filter
			history(4)(0) <= '0'; -- B1_GPIO12;
			history(5)(0) <= B1_GPIO13;
			history(6)(0) <= B1_GPIO14;
			history(7)(0) <= B1_GPIO15;
			
			-- shift from 0 to the end
			for line in 0 to history'high loop
				for i in 1 to filter_depth loop
					history(line)(i) <= history(line)(i-1);
				end loop;
			end loop;
			
			-- readout
			for line in 0 to history'high loop
				if(history(line) = all_one) then
					gpio_filtered(line) <= '1';
				elsif(history(line) = all_zero) then
					gpio_filtered(line) <= '0';
				end if;
			end loop;
			
			-- Write results to register table. Since this write enable line is
			-- lower priority than that coming from the user, sometimes this
			-- write will fail. But that's ok because these are slow updates
			-- anyway, read out once per frame
			if(count = 254) then
				internal_reg_addr <= 25;
				internal_reg_we <= '1';
				internal_reg_data <= encoder_value;
				count <= count + 1;
			elsif(count = 255) then
				internal_reg_addr <= 26;
				internal_reg_we <= '1';
				internal_reg_data <= gpio_filtered;
				count <= 0;
			else
				internal_reg_we <= '0';
				count <= count + 1;
			end if;
			
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
		
		B0_GPIO0 <= mcb_transaction_active;
		B1_GPIO1 <= val(0);
		B1_GPIO2 <= val(1);
		B1_GPIO3 <= val(2);
		B1_GPIO4 <= val(3);
		B1_GPIO5 <= val(4);
		B1_GPIO6 <= mcb_write_active;
		B1_GPIO7 <= mcb_read_active;

--		B1_GPIO8 <= MPOP_W;
--		B1_GPIO9 <= MPUSH;
--		B1_GPIO10 <= '0';
--		B1_GPIO11 <= '0';
--		B1_GPIO12 <= '0';
--		B1_GPIO13 <= '0';
--		B1_GPIO14 <= '0';
--		B1_GPIO15 <= '0';

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

