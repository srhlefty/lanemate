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
		
		MTEST : in std_logic;
		MDEBUG_LED : out std_logic_vector(7 downto 0);
		
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
	constant cmd : table_t(0 to 24) :=
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

begin


	fsm : block is
		type state_t is (IDLE, DELAY, 
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
			WRITE_LEVELING
		);
		signal state : state_t := IDLE;
		signal ret : state_t := IDLE;
		signal delay_count : natural := 0;
		signal debug_string : string(1 to 6);
	begin
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
	case state is
	
		when IDLE =>
			if(MTEST = '1') then
				state <= INIT1;
			end if;
			debug_string <= "IDLE  ";
			
		when DELAY =>
			mCS0 <= cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1 <= cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			mBA <= (others => (others => '0'));
			mMA <= (others => (others => '0'));
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
			delay_count <= 40000; -- MCLK has 5ns period, 5ns*40e3 = 200us
			state <= DELAY;
			ret <= INIT2;
			debug_string <= "INIT1 ";
			
		when INIT2 =>
			-- After RESET# is de-asserted, wait for another 500us until CKE becomes active (high).
			-- In step 3, NOP should be registered as CKE goes high so I may as well do it here for safety.
			mDDR_RESET <= "1111";
			mCKE0 <= "0000";
			mCKE1 <= "0000";
			mCS0 <= cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1 <= cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			delay_count <= 100000; -- 5ns*100e3 = 500us
			state <= DELAY;
			ret <= INIT3;
			debug_string <= "INIT2 ";
			
		when INIT3 =>
			-- Clocks need to be started and stabilized for at least 10ns before CKE goes active.
			-- (This is true because MCLK is generated by the same PLL that generates the DDR clock.
			-- Thus if this circuit is running, the PLL is locked and we're more than 2 clocks from
			-- clock startup)
			mCKE0 <= "1111";
			mCKE1 <= "1111";
			state <= INIT4;
			debug_string <= "INIT3 ";
			
		when INIT4 =>
			-- ODT etc etc. On this board ODT is set by external resistors so it's not managed by the mcb.
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
			mCS0 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rMRS)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rMRS)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rMRS)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			-- see p.30 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "0000";
			mMA(15) <= "0000"; -- A(15 downto 11) = 0
			mMA(14) <= "0000";
			mMA(13) <= "0000";
			mMA(12) <= "0000";
			mMA(11) <= "0000";
			mMA(10) <= "0000"; -- A(10 downto 9) = Rtt_WR (dynamic ODT off)
			mMA( 9) <= "0000";
			mMA( 8) <= "0000";
			mMA( 7) <= "0000"; -- A(7) = SRT (normal operating temperature range)
			mMA( 6) <= "0000"; -- A(6) = ASR (manual self refresh)
			mMA( 5) <= "0000"; -- A(5 downto 3) = CAS write latency (5). This is fixed by the clock frequency.
			mMA( 4) <= "0000"; 
			mMA( 3) <= "0000"; 
			mMA( 2) <= "0000"; -- A(2 downto 0) = Partial array self refresh (full array)
			mMA( 1) <= "0000"; 
			mMA( 0) <= "0000"; 
			
			-- Note: the min time between MRS commands (tMRD) is 4 clocks.
			-- Actual delay will be 5
			delay_count <= 2;
			state <= DELAY;
			ret <= INIT7;
			debug_string <= "INIT6 ";
			
		when INIT7 =>
			-- Issue MRS command to load MR3 with all application settings
			mCS0 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rMRS)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rMRS)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rMRS)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			-- see p.32 of spec
			mBA(2) <= "0000";
			mBA(1) <= "1000";
			mBA(0) <= "1000";
			mMA(15) <= "0000"; -- A(15 downto 3) = 0
			mMA(14) <= "0000";
			mMA(13) <= "0000";
			mMA(12) <= "0000";
			mMA(11) <= "0000";
			mMA(10) <= "0000"; 
			mMA( 9) <= "0000";
			mMA( 8) <= "0000";
			mMA( 7) <= "0000"; 
			mMA( 6) <= "0000"; 
			mMA( 5) <= "0000"; 
			mMA( 4) <= "0000"; 
			mMA( 3) <= "0000"; 
			mMA( 2) <= "0000"; -- A(2) = MPR operation (RD test pattern off)
			mMA( 1) <= "0000"; -- A(1 downto 0) = MPR location (predefined pattern)
			mMA( 0) <= "0000"; 
			delay_count <= 2;
			state <= DELAY;
			ret <= INIT8;
			debug_string <= "INIT7 ";
			
		when INIT8 =>
			-- Issue MRS command to load MR1 with all application settings and DLL enabled
			mCS0 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1 <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rMRS)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rMRS)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rMRS)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			-- see p.27 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "1000";
			mMA(15) <= "0000"; -- A(15 downto 13) = 0
			mMA(14) <= "0000";
			mMA(13) <= "0000";
			mMA(12) <= "0000"; -- A(12) = Qoff (output buffer enabled)
			mMA(11) <= "0000"; -- A(11) = TDQS (disabled)
			mMA(10) <= "0000"; -- A(10) = 0
			mMA( 9) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
			mMA( 8) <= "0000"; -- A(8) = 0
			mMA( 7) <= "0000"; -- A(7) = Write leveling (disabled)
			mMA( 6) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled) 
			mMA( 5) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)
			mMA( 4) <= MADDITIVE_LATENCY(1) & "000"; -- A(4 downto 3) = Additive latency
			mMA( 3) <= MADDITIVE_LATENCY(0) & "000"; 
			mMA( 2) <= "0000"; -- A(9), A(6), A(2) = Rtt_Nom (disabled)
			mMA( 1) <= "0000"; -- A(5), A(1) = Output driver impedance control (RZQ/6)
			mMA( 0) <= "0000"; -- A(0) = DLL Enable (enabled)
			delay_count <= 2;
			state <= DELAY;
			ret <= INIT9;
			debug_string <= "INIT8 ";
			
		when INIT9 =>
			-- Issue MRS command to load MR0 with all application settings and DLL reset
			mCS0  <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1  <= cmd(rMRS)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rMRS)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rMRS)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rMRS)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			-- see p.24 of spec
			mBA(2) <= "0000";
			mBA(1) <= "0000";
			mBA(0) <= "0000";
			mMA(15) <= "0000"; -- A(15 downto 13) = 0
			mMA(14) <= "0000";
			mMA(13) <= "0000";
			mMA(12) <= "1000"; -- A(12) = DLL control for precharge PD (fast exit)
			mMA(11) <= "1000"; -- A(11 downto 9) = Write recovery for autoprecharge. Min possible with 400MHz is 6. (8)
			mMA(10) <= "0000"; 
			mMA( 9) <= "0000";
			mMA( 8) <= "1000"; -- A(8) = DLL reset; self clearing (reset)
			mMA( 7) <= "0000"; -- A(7) = Test mode (normal)
			mMA( 6) <= MCAS_LATENCY(3) & "000"; -- A(6 downto 4), A(2) = CAS read latency !!! Micro should tell me if attached device supports this
			mMA( 5) <= MCAS_LATENCY(2) & "000"; 
			mMA( 4) <= MCAS_LATENCY(1) & "000"; 
			mMA( 3) <= "0000"; -- A(3) = Read burst type (nibble sequential)
			mMA( 2) <= MCAS_LATENCY(0) & "000";
			mMA( 1) <= "0000"; -- A(1 downto 0) = burst length (8, fixed)
			mMA( 0) <= "0000"; 
			delay_count <= 6; -- If the next command is going to be non-MRS, must wait tMOD (min 12 clocks)
			state <= DELAY;
			ret <= INIT10;
			debug_string <= "INIT9 ";
			-- Note: tDLLK is the lock time of the DLL, and is 512 clocks. That must elapse
			-- prior to a command being issued that requires it, such as read/write. Time
			-- starts here.
			
		when INIT10 =>
			-- Issue ZQCL command to start ZQ calibration
			mCS0  <= cmd(rZQCL)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mCS1  <= cmd(rZQCL)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS)  & cmd(rNOP)(cCS);
			mRAS <= cmd(rZQCL)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS) & cmd(rNOP)(cRAS);
			mCAS <= cmd(rZQCL)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS) & cmd(rNOP)(cCAS);
			mWE  <= cmd(rZQCL)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE)  & cmd(rNOP)(cWE);
			mMA(10) <= "1000";
			delay_count <= 256; -- tZQinit = max(512 clocks, 640ns). 256 system clocks is 512 clocks and 640ns at 400MHz
			-- tDLLK will be satisfied by the time this delay is finished.
			state <= DELAY;
			ret <= INIT_FINISHED;
			debug_string <= "INIT10";

		when INIT_FINISHED =>
			state <= WRITE_LEVELING;
			debug_string <= "END   ";
			
		when WRITE_LEVELING =>
			-- Set MR1 again to enable write leveling
			-- Turn on DQS pulse generator
			state <= WRITE_LEVELING ;
	
	end case;
	end if;
	end process;
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
	
	-- burst_t indexing is pin id then position within burst
	MDEBUG_LED(0) <= mDQ_RX(0*8)(0);
	MDEBUG_LED(1) <= mDQ_RX(1*8)(0);
	MDEBUG_LED(2) <= mDQ_RX(2*8)(0);
	MDEBUG_LED(3) <= mDQ_RX(3*8)(0);
	MDEBUG_LED(4) <= mDQ_RX(4*8)(0);
	MDEBUG_LED(5) <= mDQ_RX(5*8)(0);
	MDEBUG_LED(6) <= mDQ_RX(6*8)(0);
	MDEBUG_LED(7) <= mDQ_RX(7*8)(0);
		
end Behavioral;

