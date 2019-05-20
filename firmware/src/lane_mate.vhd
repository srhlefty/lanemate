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
	
	constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101100";
	
	type ram_t is array(7 downto 0) of std_logic_vector(7 downto 0);
	signal register_map : ram_t :=
	(
		0 => x"01", -- Register table version
		1 => x"00", -- video source, HD (0x00) or SD (0x01)
		2 => x"00", -- test pattern, off (0x00) or on (0x01)
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
	
	signal clk : std_logic;
	signal ibufg_to_bufgs : std_logic;
	
	signal video_clock : std_logic;
	signal dcm1_locked : std_logic;
	signal dcm2_locked : std_logic;
	
	signal video_source_ready : std_logic := '0';
	
	signal enable_test_pattern : std_logic := '0';
	
	signal rgbmask : std_logic_vector(23 downto 0);
	
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
				if(ram_addr = x"01" and ram_we = '1') then
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
			stage1_vs <= '0';
			stage1_hs <= '0';
			stage1_de <= '0';
			stage1_d  <= (others => '0');
		end if;
	end if;
	end process;
	
	----------------------------------------------------------------------------





	-- Test pattern (overwrites source data) -----------------------------------

	pat : block is
		signal is422 : std_logic;
	begin

		with register_map(1) select is422 <=
			'1' when x"01",
			'0' when others;

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
	
	end block;
	
	----------------------------------------------------------------------------
	
	
	
	
	




	-- Output ------------------------------------------------------------------
	
	process(video_clock) is
	begin
	if(rising_edge(video_clock)) then
		HDO_VS <= stage2_vs;
		HDO_HS <= stage2_hs;
		HDO_DE <= stage2_de;
		RGB_OUT <= stage2_d;
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
		B1_GPIO13 <= register_map(1)(1);
		B1_GPIO14 <= register_map(1)(2);
		B1_GPIO15 <= SDI_VS;

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

