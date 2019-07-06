----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:44:18 07/05/2019 
-- Design Name: 
-- Module Name:    ddr3_mcb - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ddr3_mcb is
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0); -- number of fifo elements to read/write at once
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
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
end ddr3_mcb;

architecture Behavioral of ddr3_mcb is

	component ddr_pin_se is
	Generic ( 
		IDELAY_VALUE : natural range 0 to 255 := 0;
		ODELAY_VALUE : natural range 0 to 255 := 0
	);
	Port ( 
		CLK : in  STD_LOGIC;
		IOCLK : in std_logic;
		STROBE : in std_logic;
		READING : in std_logic;
		
		BITSLIP : in std_logic;
		
		TXD : in std_logic_vector(3 downto 0);
		RXD : out std_logic_vector(3 downto 0);
		PIN : inout std_logic
	);
	end component;

	component ddr_pin_diff is
	Generic ( 
		IDELAY_VALUE : natural range 0 to 255 := 0;
		ODELAY_VALUE : natural range 0 to 255 := 0
	);
	Port ( 
		CLK : in  STD_LOGIC;
		IOCLK : in std_logic;
		STROBE : in std_logic;
		READING : in std_logic;
		
		BITSLIP : in std_logic;
		
		TXD : in std_logic_vector(3 downto 0);
		RXD : out std_logic_vector(3 downto 0);
		PIN_P : inout std_logic;
		PIN_N : inout std_logic
	);
	end component;

	signal mDDR_RESET : std_logic_vector(3 downto 0) := "LLLL"; -- startup state is supposed to be low (active)
	signal mCKE0 : std_logic_vector(3 downto 0) := "LLLL"; -- active high
	signal mCKE1 : std_logic_vector(3 downto 0) := "LLLL";
	signal mRAS : std_logic_vector(3 downto 0) := "HHHH";
	signal mCAS : std_logic_vector(3 downto 0) := "HHHH";
	signal mWE : std_logic_vector(3 downto 0) := "HHHH";
	signal mCS0 : std_logic_vector(3 downto 0) := "LLLL"; -- rank chip enable, active low
	signal mCS1 : std_logic_vector(3 downto 0) := "LLLL";

	type burst_t is array(natural range <>) of std_logic_vector(3 downto 0);
	signal mBA : burst_t(2 downto 0) := (others => (others => 'L'));
	signal mMA : burst_t(15 downto 0) := (others => (others => 'L'));
	signal mDQSout : burst_t(7 downto 0) := (others => (others => 'L'));
	signal mDQSNout : burst_t(7 downto 0) := (others => (others => 'L'));
	signal mDQSin : burst_t(7 downto 0);
	signal mDQout : burst_t(63 downto 0) := (others => (others => 'L'));
	signal mDQin : burst_t(63 downto 0);
	
	signal reading : std_logic := '1';
	signal bitslip : std_logic := '0';
	
	type delay_array_t is array(0 to 7) of natural;
	constant LANE_INPUT_DELAY : delay_array_t := (0,0,0,0,0,0,0,0);
	constant LANE_OUTPUT_DELAY : delay_array_t := (0,0,0,0,0,0,0,0);

begin

	DM <= (others => 'L');



	pin_ckp0: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => "1010",
		RXD => open,
		PIN => CK0_P
	);
	pin_ckn0: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => "0101",
		RXD => open,
		PIN => CK0_N
	);

	pin_ckp1: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => "1010",
		RXD => open,
		PIN => CK1_P
	);
	pin_ckn1: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => "0101",
		RXD => open,
		PIN => CK1_N
	);
	
	
	
	
	
	
	
	pin_ddr_reset: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK_180,
		STROBE => B0_STROBE_180,
		READING => '0',
		BITSLIP => '0',
		TXD => mDDR_RESET,
		RXD => open,
		PIN => DDR_RESET
	);
	
	-- clock enable
	pin_cke0: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B3_IOCLK,
		STROBE => B3_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mCKE0,
		RXD => open,
		PIN => CKE0
	);
	pin_cke1: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B3_IOCLK_180,
		STROBE => B3_STROBE_180,
		READING => '0',
		BITSLIP => '0',
		TXD => mCKE1,
		RXD => open,
		PIN => CKE1
	);
	
	
	-- command
	pin_cs0: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mCS0,
		RXD => open,
		PIN => CS0
	);
	pin_cs1: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mCS1,
		RXD => open,
		PIN => CS1
	);
	pin_ras: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mRAS,
		RXD => open,
		PIN => RAS
	);
	pin_cas: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mCAS,
		RXD => open,
		PIN => CAS
	);
	pin_we: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mWE,
		RXD => open,
		PIN => WE
	);
	



	pin_ba0: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mBA(0),
		RXD => open,
		PIN => BA(0)
	);
	pin_ba1: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B0_IOCLK,
		STROBE => B0_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mBA(1),
		RXD => open,
		PIN => BA(1)
	);
	pin_ba2: ddr_pin_se 
	generic map (
		IDELAY_VALUE => 0,
		ODELAY_VALUE => 0
	)
	port map (
		CLK => MCLK,
		IOCLK => B3_IOCLK,
		STROBE => B3_STROBE,
		READING => '0',
		BITSLIP => '0',
		TXD => mBA(2),
		RXD => open,
		PIN => BA(2)
	);
	
	
	
	
	
	gen_addr : for i in 0 to 15 generate
	
		is_bank3 : if(i=9 or i=11 or i=14 or i=15) generate
		
			pin_ma: ddr_pin_se 
			generic map (
				IDELAY_VALUE => 0,
				ODELAY_VALUE => 0
			)
			port map (
				CLK => MCLK,
				IOCLK => B3_IOCLK,
				STROBE => B3_STROBE,
				READING => '0',
				BITSLIP => '0',
				TXD => mMA(i),
				RXD => open,
				PIN => MA(i)
			);
		end generate;
	
		is_bank0 : if(not(i=9 or i=11 or i=14 or i=15)) generate
		
			pin_ma: ddr_pin_se 
			generic map (
				IDELAY_VALUE => 0,
				ODELAY_VALUE => 0
			)
			port map (
				CLK => MCLK,
				IOCLK => B0_IOCLK,
				STROBE => B0_STROBE,
				READING => '0',
				BITSLIP => '0',
				TXD => mMA(i),
				RXD => open,
				PIN => MA(i)
			);
		end generate;
	
	end generate;
	
	
	
















	
	gen_lane : for ln in 0 to 7 generate
	
		is_bank0 : if(ln=4) generate
		
			pin_dqsp: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B0_IOCLK,
				STROBE => B0_STROBE,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSout(ln),
				RXD => mDQSin(ln),
				PIN => DQSP(ln)
			);
			pin_dqsn: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B0_IOCLK,
				STROBE => B0_STROBE,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSNout(ln),
				RXD => open,
				PIN => DQSN(ln)
			);
		
		end generate;
		
		is_bank1 : if(ln=5 or ln=6 or ln=7) generate
		
			pin_dqsp: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B1_IOCLK,
				STROBE => B1_STROBE,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSout(ln),
				RXD => mDQSin(ln),
				PIN => DQSP(ln)
			);
			pin_dqsn: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B1_IOCLK_180,
				STROBE => B1_STROBE_180,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSNout(ln),
				RXD => open,
				PIN => DQSN(ln)
			);
		
		end generate;
		
		
		is_bank3 : if(ln=0 or ln=1 or ln=2 or ln=3) generate
		
			pin_dqsp: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B3_IOCLK,
				STROBE => B3_STROBE,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSout(ln),
				RXD => mDQSin(ln),
				PIN => DQSP(ln)
			);
			pin_dqsn: ddr_pin_se 
			generic map (
				IDELAY_VALUE => LANE_INPUT_DELAY(ln),
				ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
			)
			port map (
				CLK => MCLK,
				IOCLK => B3_IOCLK,
				STROBE => B3_STROBE,
				READING => reading,
				BITSLIP => bitslip,
				TXD => mDQSNout(ln),
				RXD => open,
				PIN => DQSN(ln)
			);
		
		end generate;



		
		gen_inv : for i in 0 to mDQSout'high generate
			mDQSNout(i) <= not mDQSout(i);
		end generate;
		
		
		
		
		
	
		gen_bit : for b in 0 to 7 generate

			is_bank3 : if(ln*8+b <= 31) generate
			
				pin_dq: ddr_pin_se 
				generic map (
					IDELAY_VALUE => LANE_INPUT_DELAY(ln),
					ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
				)
				port map (
					CLK => MCLK,
					IOCLK => B3_IOCLK,
					STROBE => B3_STROBE,
					READING => reading,
					BITSLIP => bitslip,
					TXD => mDQout(ln*8+b),    -- lane 0: 7 downto 0. lane 1: 15 downto 8. etc.
					RXD => mDQin(ln*8+b),
					PIN => DQ(ln*8+b)
				);
			
			end generate;
			
			is_bank0 : if( (ln*8+b >= 32 and ln*8+b <= 39) 
								or ln*8+b = 41
								or ln*8+b = 42
								or ln*8+b = 44
								or ln*8+b = 45 ) generate
			
				pin_dq: ddr_pin_se 
				generic map (
					IDELAY_VALUE => LANE_INPUT_DELAY(ln),
					ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
				)
				port map (
					CLK => MCLK,
					IOCLK => B0_IOCLK,
					STROBE => B0_STROBE,
					READING => reading,
					BITSLIP => bitslip,
					TXD => mDQout(ln*8+b),
					RXD => mDQin(ln*8+b),
					PIN => DQ(ln*8+b)
				);
			
			end generate;
			
			
			
			is_bank1 : if( ln*8+b >= 46
								or ln*8+b = 40
								or ln*8+b = 43 ) generate
			
				pin_dq: ddr_pin_se 
				generic map (
					IDELAY_VALUE => LANE_INPUT_DELAY(ln),
					ODELAY_VALUE => LANE_OUTPUT_DELAY(ln)
				)
				port map (
					CLK => MCLK,
					IOCLK => B1_IOCLK,
					STROBE => B1_STROBE,
					READING => reading,
					BITSLIP => bitslip,
					TXD => mDQout(ln*8+b),
					RXD => mDQin(ln*8+b),
					PIN => DQ(ln*8+b)
				);
			
			end generate;
			
			
			
			
		
		end generate;
		
	end generate;
		
end Behavioral;

