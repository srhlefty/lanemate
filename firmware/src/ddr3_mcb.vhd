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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.pkg_types.all;

entity ddr3_mcb is
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
		
		B0_DQS_READING : in std_logic;
		B1_DQS_READING : in std_logic;
		B3_DQS_READING : in std_logic;
		B0_DQ_READING : in std_logic;
		B1_DQ_READING : in std_logic;
		B3_DQ_READING : in std_logic;
		BITSLIP       : in std_logic_vector(7 downto 0);
		BITSLIP_RST : in std_logic_vector(7 downto 0);
	
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

	signal mDDR_RESET : std_logic_vector(3 downto 0) := "0000"; -- startup state is supposed to be low (active)
	signal mCKE0 : std_logic_vector(3 downto 0) := "0000"; -- active high
	signal mCKE1 : std_logic_vector(3 downto 0) := "0000";
	signal mRAS : std_logic_vector(3 downto 0) := "1111";
	signal mCAS : std_logic_vector(3 downto 0) := "1111";
	signal mWE : std_logic_vector(3 downto 0) := "1111";
	signal mCS0 : std_logic_vector(3 downto 0) := "1111"; -- rank chip enable, active low
	signal mCS1 : std_logic_vector(3 downto 0) := "1111";

	signal mBA : burst_t(2 downto 0) := (others => (others => '0'));
	signal mMA : burst_t(15 downto 0) := (others => (others => '0'));
	signal mDQS_TX : burst_t(7 downto 0) := (others => (others => '0'));
	signal mDQS_RX : burst_t(7 downto 0);
	signal mDQ_TX : burst_t(63 downto 0) := (others => (others => '0'));
	signal mDQ_RX : burst_t(63 downto 0);
	signal latched_read : std_logic_vector(7 downto 0) := (others => '0');

	attribute keep : string;
	-- The compiler would typically prefer to optimize away the array into a single register
	-- that gets passed to the OSERDES blocks. This is a problem because I'm using OSERDES
	-- blocks on 3 separate banks, which are very far apart. Placing the flip flop in the
	-- middle still has too much routing delay to get everywhere, causing the design to
	-- fail timing. The fix here is to keep the "redundant" flip flops so that each one
	-- that goes to a specific byte lane can be placed closer to the edge of the chip.
	attribute keep of mDQS_TX : signal is "true";

	
	signal dqs_reading0 : std_logic := '1';
	signal dqs_reading1 : std_logic := '1';
	signal dqs_reading3 : std_logic := '1';
	signal dq_reading0 : std_logic := '1';
	signal dq_reading1 : std_logic := '1';
	signal dq_reading3 : std_logic := '1';
	signal bitslip : std_logic_vector(7 downto 0) := (others => '0');
	signal bitslip_rst : std_logic_vector(7 downto 0) := (others => '0');

	-- Same thing here, I need separate registers to service the different edges of the chip
	-- in order to meet timing
	attribute keep of dqs_reading0 : signal is "true";
	attribute keep of dqs_reading1 : signal is "true";
	attribute keep of dqs_reading3 : signal is "true";
	attribute keep of dq_reading0 : signal is "true";
	attribute keep of dq_reading1 : signal is "true";
	attribute keep of dq_reading3 : signal is "true";
	attribute keep of bitslip : signal is "true";
	attribute keep of bitslip_rst : signal is "true";
	
	
	signal debug_sync : std_logic := '0';
	
	constant cCS   : natural := 0;
	constant cRAS  : natural := 1;
	constant cCAS  : natural := 2;
	constant cWE   : natural := 3;
	
	constant rMRS  : natural := 0;
	constant rREF  : natural := 1;
	constant rSRE  : natural := 2;
	constant rSRX  : natural := 3;
	constant rPRE  : natural := 4;
	constant rPREA : natural := 5;
	constant rACT  : natural := 6;
	constant rWR   : natural := 7;
	constant rWRS4 : natural := 8;
	constant rWRS8 : natural := 9;
	constant rWRA  : natural := 10;
	constant rWRAS4: natural := 11;
	constant rWRAS8: natural := 12;
	constant rRD   : natural := 13;
	constant rRDS4 : natural := 14;
	constant rRDS8 : natural := 15;
	constant rRDA  : natural := 16;
	constant rRDAS4: natural := 17;
	constant rRDAS8: natural := 18;
	constant rNOP  : natural := 19;
	constant rDES  : natural := 20;
	constant rPDE  : natural := 21;
	constant rPDX  : natural := 22;
	constant rZQCL : natural := 23;
	constant rZQCS : natural := 24;

	type row_t is array(0 to 3) of std_logic;
	type table_t is array(integer range <>) of row_t;
	
	-- This is the truth table for CS#, RAS#, CAS#, and WE#
	-- for each command. The row (first index) is the command,
	-- to be indexed with the rXXX constants. The column (second index)
	-- is to be indexed with the cXXX constants.
	-- Note that this is not the complete command since CKE and the address
	-- pins also contribute in some cases.
	constant cmd_table : table_t(0 to 24) :=
	(
		('0', '0', '0', '0'), -- rMRS
		('0', '0', '0', '1'), -- rREF
		('0', '0', '0', '1'), -- rSRE
		('0', '1', '1', '1'), -- rSRX (assuming CS# should be L)
		('0', '0', '1', '0'), -- rPRE
		('0', '0', '1', '0'), -- rPREA
		('0', '0', '1', '1'), -- rACT
		('0', '1', '0', '0'), -- rWR
		('0', '1', '0', '0'), -- rWRS4
		('0', '1', '0', '0'), -- rWRS8
		('0', '1', '0', '0'), -- rWRA
		('0', '1', '0', '0'), -- rWRAS4
		('0', '1', '0', '0'), -- rWRAS8
		('0', '1', '0', '1'), -- rRD
		('0', '1', '0', '1'), -- rRDS4
		('0', '1', '0', '1'), -- rRDS8
		('0', '1', '0', '1'), -- rRDA
		('0', '1', '0', '1'), -- rRDAS4
		('0', '1', '0', '1'), -- rRDAS8
		('0', '1', '1', '1'), -- rNOP
		('1', '1', '1', '1'), -- rDES
		('0', '1', '1', '1'), -- rPDE
		('0', '1', '1', '1'), -- rPDX
		('0', '1', '1', '0'), -- rZQCL
		('0', '1', '1', '0')  -- rZQCS		
	);
	
	type ranks_t is (RANK0, RANK1, RANK_BOTH);
	
	procedure build_command
	(
		constant RANK : in ranks_t;
		constant CMD : in natural;
		
		signal CS0 : out std_logic_vector(3 downto 0);
		signal CS1 : out std_logic_vector(3 downto 0);
		signal RAS : out std_logic_vector(3 downto 0);
		signal CAS : out std_logic_vector(3 downto 0);
		signal WE  : out std_logic_vector(3 downto 0)
	) is
	begin
		if(RANK = RANK0) then
			CS0 <= cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS);
			CS1 <= cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS);
		elsif(RANK = RANK1) then
			CS0 <= cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS);
			CS1 <= cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS);
		elsif(RANK = RANK_BOTH) then
			CS0 <= cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS);
			CS1 <= cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS);
		end if;
		
		RAS <= cmd_table(CMD)(cRAS) & cmd_table(rNOP)(cRAS) & cmd_table(rNOP)(cRAS) & cmd_table(rNOP)(cRAS);
		CAS <= cmd_table(CMD)(cCAS) & cmd_table(rNOP)(cCAS) & cmd_table(rNOP)(cCAS) & cmd_table(rNOP)(cCAS);
		WE  <= cmd_table(CMD)(cWE)  & cmd_table(rNOP)(cWE)  & cmd_table(rNOP)(cWE)  & cmd_table(rNOP)(cWE);
	end procedure;
		
	
	signal MR0_SETTINGS : burst_t(15 downto 0) := (others => (others => '0'));
	signal MR1_SETTINGS : burst_t(15 downto 0) := (others => (others => '0'));
	signal MR1_SETTINGS_WL : burst_t(15 downto 0) := (others => (others => '0'));
	signal MR2_SETTINGS : burst_t(15 downto 0) := (others => (others => '0'));
	signal MR3_SETTINGS : burst_t(15 downto 0) := (others => (others => '0'));
	signal MR3_SETTINGS_RL : burst_t(15 downto 0) := (others => (others => '0'));

begin

	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
		MR0_SETTINGS(15) <= "0000"; -- A(15 downto 13) = 0
		MR0_SETTINGS(14) <= "0000";
		MR0_SETTINGS(13) <= "0000";
		MR0_SETTINGS(12) <= "1000"; -- A(12) = DLL control for precharge PD (fast exit)
		MR0_SETTINGS(11) <= "1000"; -- A(11 downto 9) = Write recovery for autoprecharge. Min possible with 400MHz is 6. (8)
		MR0_SETTINGS(10) <= "0000"; 
		MR0_SETTINGS( 9) <= "0000";
		MR0_SETTINGS( 8) <= "1000"; -- A(8) = DLL reset; self clearing (reset)
		MR0_SETTINGS( 7) <= "0000"; -- A(7) = Test mode (normal)
		MR0_SETTINGS( 6) <= MCAS_LATENCY(3) & "000"; -- A(6 downto 4), A(2) = CAS read latency   [ !!! Micro should tell me if attached device supports this ]
		MR0_SETTINGS( 5) <= MCAS_LATENCY(2) & "000"; 
		MR0_SETTINGS( 4) <= MCAS_LATENCY(1) & "000"; 
		MR0_SETTINGS( 3) <= "0000"; -- A(3) = Read burst type (nibble sequential)
		MR0_SETTINGS( 2) <= MCAS_LATENCY(0) & "000";
		MR0_SETTINGS( 1) <= "0000"; -- A(1 downto 0) = burst length (8, fixed)
		MR0_SETTINGS( 0) <= "0000"; 
		
		MR1_SETTINGS(15) <= "0000"; -- A(15 downto 13) = 0
		MR1_SETTINGS(14) <= "0000";
		MR1_SETTINGS(13) <= "0000";
		MR1_SETTINGS(12) <= "0000"; -- A(12) = Qoff (output buffer enabled)
		MR1_SETTINGS(11) <= "0000"; -- A(11) = TDQS (disabled)
		MR1_SETTINGS(10) <= "0000"; -- A(10) = 0
		MR1_SETTINGS( 9) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		MR1_SETTINGS( 8) <= "0000"; -- A(8) = 0
		MR1_SETTINGS( 7) <= "0000"; -- A(7) = Write leveling (disabled)
		MR1_SETTINGS( 6) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled) 
		MR1_SETTINGS( 5) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)
		MR1_SETTINGS( 4) <= MADDITIVE_LATENCY(1) & "000"; -- A(4 downto 3) = Additive latency
		MR1_SETTINGS( 3) <= MADDITIVE_LATENCY(0) & "000"; 
		MR1_SETTINGS( 2) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		MR1_SETTINGS( 1) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)    [ I don't know what the right setting for this is ]
		MR1_SETTINGS( 0) <= "0000"; -- A(0) = DLL Enable (enabled)
		
		MR1_SETTINGS_WL(15) <= "0000"; -- A(15 downto 13) = 0
		MR1_SETTINGS_WL(14) <= "0000";
		MR1_SETTINGS_WL(13) <= "0000";
		MR1_SETTINGS_WL(12) <= "0000"; -- A(12) = Qoff (output buffer enabled)
		MR1_SETTINGS_WL(11) <= "0000"; -- A(11) = TDQS (disabled)
		MR1_SETTINGS_WL(10) <= "0000"; -- A(10) = 0
		MR1_SETTINGS_WL( 9) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		MR1_SETTINGS_WL( 8) <= "0000"; -- A(8) = 0
		MR1_SETTINGS_WL( 7) <= "1000"; -- A(7) = Write leveling (enabled)
		MR1_SETTINGS_WL( 6) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled) 
		MR1_SETTINGS_WL( 5) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)
		MR1_SETTINGS_WL( 4) <= MADDITIVE_LATENCY(1) & "000"; -- A(4 downto 3) = Additive latency
		MR1_SETTINGS_WL( 3) <= MADDITIVE_LATENCY(0) & "000"; 
		MR1_SETTINGS_WL( 2) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		MR1_SETTINGS_WL( 1) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)    [ I don't know what the right setting for this is ]
		MR1_SETTINGS_WL( 0) <= "0000"; -- A(0) = DLL Enable (enabled)
		
		MR2_SETTINGS(15) <= "0000"; -- A(15 downto 11) = 0
		MR2_SETTINGS(14) <= "0000";
		MR2_SETTINGS(13) <= "0000";
		MR2_SETTINGS(12) <= "0000";
		MR2_SETTINGS(11) <= "0000";
		MR2_SETTINGS(10) <= "0000"; -- A(10 downto 9) = Rtt_WR (dynamic ODT off)
		MR2_SETTINGS( 9) <= "0000";
		MR2_SETTINGS( 8) <= "0000"; -- A(8) = 0
		MR2_SETTINGS( 7) <= "0000"; -- A(7) = Self-refresh temperature range (normal)
		MR2_SETTINGS( 6) <= "0000"; -- A(6) = Auto self-refresh (manual)
		MR2_SETTINGS( 5) <= "0000"; -- A(5 downto 3) = CAS write latency (5). Must be 5 b/c tCK = 2.5ns
		MR2_SETTINGS( 4) <= "0000"; 
		MR2_SETTINGS( 3) <= "0000"; 
		MR2_SETTINGS( 2) <= "0000"; -- A(2 downto 0) = Partial array self refresh (full array)
		MR2_SETTINGS( 1) <= "0000"; 
		MR2_SETTINGS( 0) <= "0000"; 

		MR3_SETTINGS(15) <= "0000"; -- A(15 downto 3) = 0
		MR3_SETTINGS(14) <= "0000";
		MR3_SETTINGS(13) <= "0000";
		MR3_SETTINGS(12) <= "0000";
		MR3_SETTINGS(11) <= "0000";
		MR3_SETTINGS(10) <= "0000"; 
		MR3_SETTINGS( 9) <= "0000";
		MR3_SETTINGS( 8) <= "0000";
		MR3_SETTINGS( 7) <= "0000"; 
		MR3_SETTINGS( 6) <= "0000"; 
		MR3_SETTINGS( 5) <= "0000"; 
		MR3_SETTINGS( 4) <= "0000"; 
		MR3_SETTINGS( 3) <= "0000"; 
		MR3_SETTINGS( 2) <= "0000"; -- A(2) = Multi-purpose register operation (RD test pattern off) [*** this is used for read leveling]
		MR3_SETTINGS( 1) <= "0000"; -- A(1 downto 0) = MPR location (predefined pattern)
		MR3_SETTINGS( 0) <= "0000"; 
		
		MR3_SETTINGS_RL(15) <= "0000"; -- A(15 downto 3) = 0
		MR3_SETTINGS_RL(14) <= "0000";
		MR3_SETTINGS_RL(13) <= "0000";
		MR3_SETTINGS_RL(12) <= "0000";
		MR3_SETTINGS_RL(11) <= "0000";
		MR3_SETTINGS_RL(10) <= "0000"; 
		MR3_SETTINGS_RL( 9) <= "0000";
		MR3_SETTINGS_RL( 8) <= "0000";
		MR3_SETTINGS_RL( 7) <= "0000"; 
		MR3_SETTINGS_RL( 6) <= "0000"; 
		MR3_SETTINGS_RL( 5) <= "0000"; 
		MR3_SETTINGS_RL( 4) <= "0000"; 
		MR3_SETTINGS_RL( 3) <= "0000"; 
		MR3_SETTINGS_RL( 2) <= "1000"; -- A(2) = Multi-purpose register operation (RD test pattern on)
		MR3_SETTINGS_RL( 1) <= "0000"; -- A(1 downto 0) = MPR location (predefined pattern)
		MR3_SETTINGS_RL( 0) <= "0000"; 
	end if;
	end process;


	fsm : block is
		type state_t is (
			IDLE, 
			DELAY, 
			INIT1, 
			INIT2, 
			INIT3, 
			INIT4, 
			INIT5, 
			INIT6, 
			INIT7, 
			INIT8, 
			INIT9, 
			INIT10, 
			INIT_FINISHED,
			WRITE_LEVELING_ENTER,
			WRITE_LEVELING,
			WRITE_LEVELING_EXIT,
			READ_PATTERN_ENTER,
			ENABLE_PATTERN,
			READ_PATTERN,
			READ_PATTERN_EXIT
		);
		signal state : state_t := IDLE;
		signal ret : state_t := IDLE;
		signal delay_count : natural := 0;
		signal readout_delay : natural range 0 to 15 := 0;
		signal debug_string : string(1 to 6);
		constant INIT1_DELAY_REAL : natural := 40000;
		constant INIT1_DELAY_DEBUG : natural := 10;
		constant INIT2_DELAY_REAL : natural := 100000;
		constant INIT2_DELAY_DEBUG : natural := 10;
		signal INIT1_DELAY : natural;
		signal INIT2_DELAY : natural;
		
		signal leveling_lane : natural range 0 to 7 := 0;
		signal leveling_finished : std_logic := '0';
		constant LEVELING_CYCLE : natural := 32;
	begin
		
		gen_const_d : if(DEBUG = true) generate
		begin
			INIT1_DELAY <= INIT1_DELAY_DEBUG;
			INIT2_DELAY <= INIT2_DELAY_DEBUG;
		end generate;
		gen_const : if(DEBUG = false) generate
		begin
			INIT1_DELAY <= INIT1_DELAY_REAL;
			INIT2_DELAY <= INIT2_DELAY_REAL;
		end generate;
	
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
	case state is
	
		when IDLE =>
			if(MFORCE_INIT = '1' and IOCLK_LOCKED = '1') then
				state <= INIT1;
			end if;
			debug_string <= "IDLE  ";
			
		when DELAY =>
			build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
			mBA <= (others => (others => '0'));
			mMA <= (others => (others => '0'));
			mDQS_TX <= (others => (others => '0'));
			if(delay_count = 0) then
				state <= ret;
			else
				delay_count <= delay_count - 1;
			end if;

		-- Follow along with the init sequence on page 19 of JEDEC 79-3F
		
		when INIT1 =>
			-- Apply power. RESET# needs to be maintained (low) for a minimum 200us 
			-- with stable power. CKE must be low at least 10ns before RESET# is
			-- de-asserted, but this time can be a part of the 200us.
			mDDR_RESET <= "0000";
			mCKE0 <= "0000";
			mCKE1 <= "0000";
			delay_count <= INIT1_DELAY; -- MCLK has 5ns period, 5ns*40e3 = 200us
			state <= DELAY;
			ret <= INIT2;
			debug_string <= "INIT1 ";
			
		when INIT2 =>
			-- After RESET# is de-asserted, wait for another 500us until CKE becomes active (high).
			-- In step 3, NOP should be registered as CKE goes high so I may as well do it here for safety.
			mDDR_RESET <= "1111";
			mCKE0 <= "0000";
			mCKE1 <= "0000";
			build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
			delay_count <= INIT2_DELAY; -- 5ns*100e3 = 500us
			state <= DELAY;
			ret <= INIT3;
			debug_string <= "INIT2 ";
			
		when INIT3 =>
			-- Clocks need to be started and stabilized for at least 10ns before CKE goes active.
			-- True by assertion because I gate this FSM on the IOCLK_LOCKED signal
			mCKE0 <= "1111";
			mCKE1 <= "1111";
			state <= INIT4;
			debug_string <= "INIT3 ";
			
		when INIT4 =>
			-- ODT etc etc. On this board ODT is set by external resistors so it's not managed by the mcb.
			-- This implies I must have RTT_NOM disabled.
			state <= INIT5;
			debug_string <= "INIT4 ";
			
		when INIT5 =>
			-- After CKE is registered high, wait a minimum of "Reset CKE Exit Time" (tXPR) before
			-- issuing the first MRS command. tXPR is max(5 clocks, tRFC+10ns). tRFC is 350ns for
			-- an 8Gb density chip. So the minimum wait time is 360ns, or 72 system clocks.
			delay_count <= 72;
			state <= DELAY;
			ret <= INIT6;
			debug_string <= "INIT5 ";
			
		when INIT6 =>
			-- Issue MRS command to load MR2 with all application settings
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.30 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "0000";
			mMA <= MR2_SETTINGS;
			
			-- Note: the min time between MRS commands (tMRD) is 4 clocks.
			-- I can get 4 clocks by using a delay of 0, but there's no real hurry
			-- here so I'll use a delay of 1 (6 clocks).
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT7;
			debug_string <= "INIT6 ";
			
		when INIT7 =>
			-- Issue MRS command to load MR3 with all application settings
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.32 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "1000";
			mMA <= MR3_SETTINGS;
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT8;
			debug_string <= "INIT7 ";
			
		when INIT8 =>
			-- Issue MRS command to load MR1 with all application settings and DLL enabled
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.27 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "1000";
			mMA <= MR1_SETTINGS;
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT9;
			debug_string <= "INIT8 ";
			
		when INIT9 =>
			-- Issue MRS command to load MR0 with all application settings and DLL reset
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.24 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "0000";
			mMA <= MR0_SETTINGS;
			delay_count <= 6; -- If the next command is going to be non-MRS, must wait tMOD (min 12 clocks)
			state <= DELAY;
			ret <= INIT10;
			debug_string <= "INIT9 ";
			-- Note: tDLLK is the lock time of the DLL, and is 512 clocks. That must elapse
			-- prior to a command being issued that requires it, such as read/write. Time
			-- starts here.
			
		when INIT10 =>
			-- Issue ZQCL command to start ZQ calibration
			build_command(RANK_BOTH, rZQCL, mCS0,mCS1,mRAS,mCAS,mWE);
			mMA(15 downto 11) <= (others => (others => '0'));
			mMA(10) <= "1000";
			mMA(9 downto 0) <= (others => (others => '0'));
			delay_count <= 256; -- tZQinit = max(512 clocks, 640ns). For 250MHz DDR clock, 512CK > 640ns
			-- tDLLK will be satisfied by the time this delay is finished.
			state <= DELAY;
			ret <= INIT_FINISHED;
			debug_string <= "INIT10";

		when INIT_FINISHED =>
			state <= READ_PATTERN_ENTER;
--			state <= WRITE_LEVELING_ENTER;
			debug_string <= "END   ";
			
		when WRITE_LEVELING_ENTER =>
			-- Set MR1 again to enable write leveling.
			-- Note that since the ranks share DQ and DQS, I can only turn one rank on.
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.27 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "1000";
			mMA <= MR1_SETTINGS_WL;

			dqs_reading0 <= '0';
			dqs_reading1 <= '0';
			dqs_reading3 <= '0';
			mDQS_TX <= (others => (others => '0'));
			-- Need to wait at least tWLDQSEN (25 clocks) before the first DQS pulse
			delay_count <= 13;
			state <= DELAY;
			ret <= WRITE_LEVELING;
			debug_string <= "WLENTR";
			
		when WRITE_LEVELING =>
			if(delay_count = 0) then
				mDQS_TX <= (others => "1000");
				delay_count <= 16;
			else
				mDQS_TX <= (others => "0000");
				delay_count <= delay_count - 1;
			end if;
--			mDQS_TX <= (others => "1010");
			
			-- This is brought out to a test point to let me trigger off of on the scope.
			-- Wider than 1 clock to reduce bandwidth requirements.
			if(delay_count < 5) then
				debug_sync <= '1';
			else
				debug_sync <= '0';
			end if;
			
			if(MTEST = '1') then
				state <= WRITE_LEVELING_EXIT;
			else
				state <= WRITE_LEVELING;
			end if;
			debug_string <= "WL    ";
			
		when WRITE_LEVELING_EXIT =>
			dqs_reading0 <= '1';
			dqs_reading1 <= '1';
			dqs_reading3 <= '1';
			mDQS_TX <= (others => (others => '0'));
			debug_sync <= '0';
			-- This is a copy of INIT8
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.27 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "1000";
			mMA <= MR1_SETTINGS;
			delay_count <= 6; -- If the next command is going to be non-MRS, must wait tMOD (min 12 clocks)
			state <= DELAY;
			ret <= IDLE;
			debug_string <= "WLEXIT";
	
	
	
	
	
	
	
		when READ_PATTERN_ENTER =>
			dqs_reading0 <= '1';
			dqs_reading1 <= '1';
			dqs_reading3 <= '1';
			-- precharge all, wait tRP (15ns)
			build_command(RANK0, rPREA, mCS0,mCS1,mRAS,mCAS,mWE);
			mBA <= (others => (others => '0'));
			mMA(10) <= "1000";
			mMA(15 downto 11) <= (others => (others => '0'));
			mMA(9 downto 0) <= (others => (others => '0'));
			delay_count <= 2;
			state <= DELAY;
			ret <= ENABLE_PATTERN;
			
		when ENABLE_PATTERN =>
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.32 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "1000";
			mMA <= MR3_SETTINGS_RL;
			delay_count <= 6; -- wait tMOD
			state <= DELAY;
			ret <= READ_PATTERN;
			
		when READ_PATTERN =>
			if(leveling_finished = '1') then
				build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
				delay_count <= LEVELING_CYCLE; -- make sure any active reads complete, and make sure tMPRR is satisfied (1 CK)
				debug_sync <= '0';
				state <= DELAY;
				ret <= READ_PATTERN_EXIT;
			else

				if(delay_count = 0) then
					build_command(RANK0, rRD, mCS0,mCS1,mRAS,mCAS,mWE);
					delay_count <= LEVELING_CYCLE;
				else
					build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
					delay_count <= delay_count - 1;
				end if;
				mBA <= (others => (others => '0'));
				mMA <= (others => (others => '0'));

				debug_sync <= '1';
				
				if(delay_count = LEVELING_CYCLE-readout_delay) then
					latched_read(0) <= mDQ_RX(leveling_lane*8)(0);
					latched_read(1) <= mDQ_RX(leveling_lane*8)(1);
					latched_read(2) <= mDQ_RX(leveling_lane*8)(2);
					latched_read(3) <= mDQ_RX(leveling_lane*8)(3);
				elsif(delay_count = LEVELING_CYCLE-readout_delay-1) then
					latched_read(4) <= mDQ_RX(leveling_lane*8)(0);
					latched_read(5) <= mDQ_RX(leveling_lane*8)(1);
					latched_read(6) <= mDQ_RX(leveling_lane*8)(2);
					latched_read(7) <= mDQ_RX(leveling_lane*8)(3);
				end if;
			
			end if;
		
	
		when READ_PATTERN_EXIT =>
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			-- see p.32 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "1000";
			mMA <= MR3_SETTINGS;
			delay_count <= 6; -- wait until tMOD (max 12CK, 15ns), tMRD (4CK) satisfied
			state <= DELAY;
			ret <= IDLE;



	end case;
	end if;
	end process;
	
		read_leveling : block is
			type lstate_t is (IDLE, SEEK, WAIT_FOR_NEXT, VALIDATE, FINISH);
			signal lstate : lstate_t := IDLE;
			signal valid_count : natural range 0 to 1000 := 0;
			signal slip_attempts : natural range 0 to 4 := 0;
			signal raddr : std_logic_vector(7 downto 0) := x"00";
			signal rdata : std_logic_vector(7 downto 0) := x"00";
			signal rwe : std_logic := '0';
			signal once : std_logic := '0';
		begin
		
			REGADDR <= raddr;
			REGDATA <= rdata;
			REGWE <= rwe;
		
		process(MCLK) is
		begin
		if(rising_edge(MCLK)) then
		case lstate is
			when IDLE =>
				raddr <= x"00";
				rdata <= x"00";
				rwe <= '0';
				
				if(state = READ_PATTERN_ENTER) then
					leveling_lane <= 0;
					leveling_finished <= '0';
					bitslip_rst <= (others => '1');
					once <= '0';
				else
					bitslip_rst <= (others => '0');
				end if;
				
				if(state = READ_PATTERN and leveling_finished = '0' and delay_count = 0) then
					readout_delay <= 5;
					slip_attempts <= 0;
					lstate <= SEEK;
				end if;
			
			-- Incoming data looks like this (CAS latency = 5) (ignoring propagation delays):
			--  clk  1010 1010 1010 1010 1010
			--  cmd  1000 0000 0000 0000 0000
			--  dta  ---- ---- --01 0101 01--
			-- What I want is for the 8 bits to arrive at 2 sequential system clocks.
			-- So this FSM first determines at what clock data starts to appear.
			-- In the above example that would be a delay of 2. If the data is 1010,
			-- then the data is aligned to the system clock and we're done. But in
			-- general it will be misaligned, so we use the ISERDES bitslip mechanism
			-- to shift the bits over. In the above example once we've slipped 2 bits
			-- we'll have alignment and so the FSM will complete.
			-- If the FSM tries all 4 slips and still doesn't get the right data, it
			-- must mean that we're not in the data eye.
			when SEEK =>
				if(delay_count = LEVELING_CYCLE-readout_delay) then
					if(mDQ_RX(leveling_lane*8) = "1111") then     -- Here I'm relying on the bus idling high between reads
						-- Still too soon to find data
						if(readout_delay = 15) then
							rdata <= x"F1";
							lstate <= FINISH;
						else
							readout_delay <= readout_delay + 1;
							lstate <= WAIT_FOR_NEXT;
						end if;
					elsif(mDQ_RX(leveling_lane*8) = "1010") then
						-- Success! The test pattern exits the pin in the order 0,1,0,1
						valid_count <= 0;
						lstate <= VALIDATE;
					else
						-- This means we need a bitslip. Slip and then reset the delay counter.
						-- More than 4 shift attempts means that the data will never be
						-- correct. This implies the clock edge is not within the data eye and
						-- we need to add some input delay to the data.
						
						-- On this DDR stick at least, the first read in read leveling mode
						-- doesn't return the data I expect, even if I fix the readout_delay to
						-- the correct value.
						if(once = '0') then
							once <= '1';
							lstate <= WAIT_FOR_NEXT;
						else
						
							if(slip_attempts = 4) then
								rdata <= std_logic_vector(to_unsigned(readout_delay, 4)) & x"F";
								lstate <= FINISH;
							else
								slip_attempts <= slip_attempts + 1;
								bitslip(leveling_lane) <= '1';
								readout_delay <= 5;
								lstate <= WAIT_FOR_NEXT;
							end if;
						
						end if;
					end if;
				end if;
			
			when WAIT_FOR_NEXT =>
				bitslip <= (others => '0');
				if(delay_count = 0) then
					lstate <= SEEK;
				end if;
				
			when VALIDATE =>
				if(delay_count = LEVELING_CYCLE-readout_delay) then
					-- Guard against jitter by requiring the read succeed N times
					if(mDQ_RX(leveling_lane*8) = "1010") then
						if(valid_count = 100) then
							rdata <= std_logic_vector(to_unsigned(readout_delay, 4)) & std_logic_vector(to_unsigned(slip_attempts, 4));
							lstate <= FINISH;
						else
							valid_count <= valid_count + 1;
						end if;
					else
						rdata <= x"F3";
						lstate <= FINISH;
					end if;
				end if;
			
				
			when FINISH =>
				raddr <= std_logic_vector(to_unsigned(16+leveling_lane, raddr'length));
				rwe <= '1';
				if(leveling_lane = 7) then
					leveling_finished <= '1';
				else
					leveling_lane <= leveling_lane + 1;
				end if;
				lstate <= IDLE;
				
		end case;
		end if;
		end process;
		end block;
	
	
	end block;






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
		B0_DQS_READING=> dqs_reading0,
		B1_DQS_READING=> dqs_reading1,
		B3_DQS_READING=> dqs_reading3,
		B0_DQ_READING => dq_reading0,
		B1_DQ_READING => dq_reading1,
		B3_DQ_READING => dq_reading3,
		BITSLIP       => bitslip,
		BITSLIP_RST   => bitslip_rst,
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
	
	-- burst_t indexing is pin id then position within burst
	-- Write Leveling: output state of DQ, first pin in each lane
--	MDEBUG_LED(0) <= mDQ_RX(0*8)(0);
--	MDEBUG_LED(1) <= mDQ_RX(1*8)(0);
--	MDEBUG_LED(2) <= mDQ_RX(2*8)(0);
--	MDEBUG_LED(3) <= mDQ_RX(3*8)(0);
--	MDEBUG_LED(4) <= mDQ_RX(4*8)(0);
--	MDEBUG_LED(5) <= mDQ_RX(5*8)(0);
--	MDEBUG_LED(6) <= mDQ_RX(6*8)(0);
--	MDEBUG_LED(7) <= mDQ_RX(7*8)(0);

	-- Read Leveling: output burst data for one lane.
	-- If the read is correct, the byte should be 10101010
	-- (i.e., the first returned bit in time is 0)
	MDEBUG_LED(0) <= latched_read(0);
	MDEBUG_LED(1) <= latched_read(1);
	MDEBUG_LED(2) <= latched_read(2);
	MDEBUG_LED(3) <= latched_read(3);
	MDEBUG_LED(4) <= latched_read(4);
	MDEBUG_LED(5) <= latched_read(5);
	MDEBUG_LED(6) <= latched_read(6);
	MDEBUG_LED(7) <= latched_read(7);

	MDEBUG_SYNC <= debug_sync;
		
end Behavioral;

