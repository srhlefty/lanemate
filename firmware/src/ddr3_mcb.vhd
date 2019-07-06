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

use work.pkg_types.all;

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

	component ddr3_phy is
	Port ( 
		MCLK : in  STD_LOGIC;
	
		mDDR_RESET : in std_logic_vector(3 downto 0);
		mCKE0 : in std_logic_vector(3 downto 0);
		mCKE1 : in std_logic_vector(3 downto 0);
		mRAS : in std_logic_vector(3 downto 0);
		mCAS : in std_logic_vector(3 downto 0);
		mWE : in std_logic_vector(3 downto 0);
		
		mCS0 : in std_logic_vector(3 downto 0);
		mCS1 : in std_logic_vector(3 downto 0);
		mBA : in burst_t(2 downto 0);
		mMA : in burst_t(15 downto 0);
		mDQS_TX : in burst_t(7 downto 0);
		mDQS_RX : out burst_t(7 downto 0);
		mDQ_TX : in burst_t(63 downto 0);
		mDQ_RX : out burst_t(63 downto 0);
		
		READING : in std_logic;
		BITSLIP : in std_logic;
	
		--------------------------------
	
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

	signal mDDR_RESET : std_logic_vector(3 downto 0) := "LLLL"; -- startup state is supposed to be low (active)
	signal mCKE0 : std_logic_vector(3 downto 0) := "LLLL"; -- active high
	signal mCKE1 : std_logic_vector(3 downto 0) := "LLLL";
	signal mRAS : std_logic_vector(3 downto 0) := "HHHH";
	signal mCAS : std_logic_vector(3 downto 0) := "HHHH";
	signal mWE : std_logic_vector(3 downto 0) := "HHHH";
	signal mCS0 : std_logic_vector(3 downto 0) := "LLLL"; -- rank chip enable, active low
	signal mCS1 : std_logic_vector(3 downto 0) := "LLLL";

	signal mBA : burst_t(2 downto 0) := (others => (others => 'L'));
	signal mMA : burst_t(15 downto 0) := (others => (others => 'L'));
	signal mDQS_TX : burst_t(7 downto 0) := (others => (others => 'L'));
	signal mDQS_RX : burst_t(7 downto 0);
	signal mDQ_TX : burst_t(63 downto 0) := (others => (others => 'L'));
	signal mDQ_RX : burst_t(63 downto 0);
	
	signal reading : std_logic := '1';
	signal bitslip : std_logic := '0';
	

begin

	Inst_ddr3_phy: ddr3_phy PORT MAP(
		MCLK          => MCLK,
		mDDR_RESET    => mDDR_RESET,
		mCKE0         => mCKE0,
		mCKE1         => mCKE1,
		mRAS          => mRAS,
		mCAS          => mCAS,
		mWE           => mWE,
		mCS0          => mCS0,
		mCS1          => mCS1,
		mBA           => mBA,
		mMA           => mMA,
		mDQS_TX       => mDQS_TX,
		mDQS_RX       => mDQS_RX,
		mDQ_TX        => mDQ_TX,
		mDQ_RX        => mDQ_RX,
		READING       => reading,
		BITSLIP       => bitslip,
		B0_IOCLK      => B0_IOCLK,
		B0_STROBE     => B0_STROBE,
		B0_IOCLK_180  => B0_IOCLK_180,
		B0_STROBE_180 => B0_STROBE_180,
		B1_IOCLK      => B1_IOCLK,
		B1_STROBE     => B1_STROBE,
		B1_IOCLK_180  => B1_IOCLK_180,
		B1_STROBE_180 => B1_STROBE_180,
		B3_IOCLK      => B3_IOCLK,
		B3_STROBE     => B3_STROBE,
		B3_IOCLK_180  => B3_IOCLK_180,
		B3_STROBE_180 => B3_STROBE_180,
		DDR_RESET     => DDR_RESET,
		CK0_P         => CK0_P,
		CK0_N         => CK0_N,
		CKE0          => CKE0,
		CK1_P         => CK1_P,
		CK1_N         => CK1_N,
		CKE1          => CKE1,
		RAS           => RAS,
		CAS           => CAS,
		WE            => WE,
		CS0           => CS0,
		CS1           => CS1,
		BA            => BA,
		MA            => MA,
		DM            => DM,
		DQSP          => DQSP,
		DQSN          => DQSN,
		DQ            => DQ 
	);
		
end Behavioral;

