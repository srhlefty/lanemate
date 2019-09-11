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
end ddr3_mcb;

architecture Behavioral of ddr3_mcb is

	component ddr3_phy is
	Generic (
		DEBUG : boolean := false
	);
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

	type dqs_source_t is (IMMEDIATE, DELAYED);
	signal dqs_source : dqs_source_t := IMMEDIATE;
	signal dqs_immediate : burst_t(7 downto 0) := (others => (others => '0'));
	signal dqs_delayed : burst_t(7 downto 0) := (others => (others => '0'));

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
		-- Normally you'd expect to put the command on the first rising edge, but this
		-- would create an issue with the write command. The CAS write latency is fixed
		-- to 5CK by the fact that I'm running at low frequency. Here is what the lines
		-- should look like with a CAS write latency of 5:
		--  clk  1010 1010 1010 1010 1010
		--  cmd  1000 0000 0000 0000 0000
		--  dta  ---- ---- --VV VVVV VV--
		-- You can see that the data is not aligned to the words that I feed the OSERDES
		-- block. Unlike reading data, I can't do the equivalent of bitslip on output.
		-- So by moving the command over one clock I get this situation instead:
		--  clk  1010 1010 1010 1010 1010
		--  cmd  0010 0000 0000 0000 0000
		--  dta  ---- ---- ---- VVVV VVVV
		-- This is properly aligned with the system clock and so makes life much easier.
		if(RANK = RANK0) then
			CS0 <= cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS);
			CS1 <= cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS);
		elsif(RANK = RANK1) then
			CS0 <= cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS)  & cmd_table(rDES)(cCS);
			CS1 <= cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS);
		elsif(RANK = RANK_BOTH) then
			CS0 <= cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS);
			CS1 <= cmd_table(rNOP)(cCS)  & cmd_table(rNOP)(cCS)  & cmd_table( CMD)(cCS)  & cmd_table(rNOP)(cCS);
		end if;
		
		RAS <= cmd_table(rNOP)(cRAS) & cmd_table(rNOP)(cRAS) & cmd_table(CMD)(cRAS) & cmd_table(rNOP)(cRAS);
		CAS <= cmd_table(rNOP)(cCAS) & cmd_table(rNOP)(cCAS) & cmd_table(CMD)(cCAS) & cmd_table(rNOP)(cCAS);
		WE  <= cmd_table(rNOP)(cWE)  & cmd_table(rNOP)(cWE)  & cmd_table(CMD)(cWE)  & cmd_table(rNOP)(cWE);
	end procedure;
	
	
	-- !!! Be very careful when using this procedure with constants.
	-- build_bus(A, "001") will actually give the wrong answer, because the compiler
	-- treats "001" as (0,0,1): it doesn't know whether you intended the constant to
	-- be an array ordered "0 to 2" or "2 downto 0", and apparently defaults to the former.
	procedure build_bus(
		signal dbus : out burst_t;
		constant val : in std_logic_vector
	) is
	begin
		for i in 0 to dbus'high loop
			dbus(i) <= "00" & val(i) & "0";
		end loop;
	end procedure;

	procedure build_col_bus(
		signal addrbus : out burst_t(15 downto 0);
		constant col : in std_logic_vector(9 downto 0) 
	) is
	begin
		for i in 10 to addrbus'high loop
			addrbus(i) <= "0000";
		end loop;
		for i in 0 to col'high loop
			addrbus(i) <= "00" & col(i) & "0";
		end loop;
	end procedure;

		
	
	signal MR0_SETTINGS    : std_logic_vector(15 downto 0) := (others => '0');
	signal MR1_SETTINGS    : std_logic_vector(15 downto 0) := (others => '0');
	signal MR1_SETTINGS_WL : std_logic_vector(15 downto 0) := (others => '0');
	signal MR2_SETTINGS    : std_logic_vector(15 downto 0) := (others => '0');
	signal MR3_SETTINGS    : std_logic_vector(15 downto 0) := (others => '0');
	signal MR3_SETTINGS_RL : std_logic_vector(15 downto 0) := (others => '0');
	signal ZQCL_SETTINGS   : std_logic_vector(15 downto 0) := (others => '0');
	
	constant MR0 : std_logic_vector(2 downto 0) := "000";
	constant MR1 : std_logic_vector(2 downto 0) := "001";
	constant MR2 : std_logic_vector(2 downto 0) := "010";
	constant MR3 : std_logic_vector(2 downto 0) := "011";
	constant PREA_SETTINGS : std_logic_vector(15 downto 0) := "0000010000000000"; -- A10 high, everything else any valid value
	
	
	procedure get_rank( 
		variable rank : out std_logic;
		constant addr : in std_logic_vector(26 downto 0)
	) is
	begin
		rank := addr(26);
	end procedure;
	
	procedure get_bank( 
		variable bank : out std_logic_vector(2 downto 0);
		constant addr : in std_logic_vector(26 downto 0)
	) is
	begin
		bank := addr(25 downto 23);
	end procedure;
	
	procedure get_row( 
		variable row : out std_logic_vector(15 downto 0);
		constant addr : in std_logic_vector(26 downto 0)
	) is
	begin
		row := addr(22 downto 7);
	end procedure;
	
	procedure get_col( 
		variable col : out std_logic_vector(9 downto 0);
		constant addr : in std_logic_vector(26 downto 0)
	) is
	begin
		col := addr(6 downto 0) & "000";
	end procedure;
	
	procedure get_rowid( 
		variable rowid : out std_logic_vector((1+3+16)-1 downto 0);
		constant addr : in std_logic_vector(26 downto 0)
	) is
	begin
		rowid := addr(26 downto 7);
	end procedure;
	
	
	signal popw : std_logic := '0';
	signal popr : std_logic := '0';
	signal pop_count : natural range 0 to 255 := 0;
	signal cmd_count : natural range 0 to 255 := 0;
	signal saved : std_logic := '0';
	signal saved_addr : std_logic_vector(26 downto 0) := (others => '0');
	signal saved_addr2 : std_logic_vector(26 downto 0) := (others => '0');
	signal saved_data1 : std_logic_vector(255 downto 0) := (others => '0');
	signal saved_data2 : std_logic_vector(255 downto 0) := (others => '0');
	signal out_data : std_logic_vector(255 downto 0) := (others => '0');
	signal debug_we : std_logic := '0';
	signal have_open_row : std_logic := '0';
	signal open_row : std_logic_vector((1+3+16)-1 downto 0); -- rank + bank + row uniquely identifies what's open
	
	signal transaction_active : std_logic := '0';
	signal read_active : std_logic := '0';
	signal write_active : std_logic := '0';
begin

	MPOP_W <= popw;
	MPOP_R <= popr;
	MTRANSACTION_ACTIVE <= transaction_active;
	MREAD_ACTIVE <= read_active;
	MWRITE_ACTIVE <= write_active;

	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
		MR0_SETTINGS <= (
		'0',             -- A(15 downto 13) = 0
		'0',
		'0',
		'1',             -- A(12) = DLL control for precharge PD (fast exit)
		'1',             -- A(11 downto 9) = Write recovery for autoprecharge. Min possible with 400MHz is 6. (8)
		'0', 
		'0',
		'1',             -- A(8) = DLL reset; self clearing (reset)
		'0',             -- A(7) = Test mode (normal)
		MCAS_LATENCY(3), -- A(6 downto 4), A(2) = CAS read latency   [ !!! Micro should tell me if attached device supports this ]
		MCAS_LATENCY(2), 
		MCAS_LATENCY(1), 
		'0',             -- A(3) = Read burst type (nibble sequential)
		MCAS_LATENCY(0),
		'0',             -- A(1 downto 0) = burst length (8, fixed)
		'0' 
		);
		
		MR1_SETTINGS <= (
		'0',                  -- A(15 downto 13) = 0
		'0',
		'0',
		'0',                  -- A(12) = Qoff (output buffer enabled)
		'0',                  -- A(11) = TDQS (disabled)
		'0',                  -- A(10) = 0
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		'0',                  -- A(8) = 0
		'0',                  -- A(7) = Write leveling (disabled)
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled) 
		'0',                  -- A(5), A(1) = Output driver impedance control (RZQ/6)
		MADDITIVE_LATENCY(1), -- A(4 downto 3) = Additive latency
		MADDITIVE_LATENCY(0), 
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		'0',                  -- A(5), A(1) = Output driver impedance control (RZQ/6)    [ I don't know what the right setting for this is ]
		'0'                   -- A(0) = DLL Enable (enabled)
		);
		
		MR1_SETTINGS_WL <= (
		'0',                  -- A(15 downto 13) = 0
		'0',
		'0',
		'0',                  -- A(12) = Qoff (output buffer enabled)
		'0',                  -- A(11) = TDQS (disabled)
		'0',                  -- A(10) = 0
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		'0',                  -- A(8) = 0
		'1',                  -- A(7) = Write leveling (enabled)
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled) 
		'0',                  -- A(5), A(1) = Output driver impedance control (RZQ/6)
		MADDITIVE_LATENCY(1), -- A(4 downto 3) = Additive latency
		MADDITIVE_LATENCY(0), 
		'0',                  -- A(9), A(6), A(2) = Rtt_Nom (disabled)
		'0',                  -- A(5), A(1) = Output driver impedance control (RZQ/6)    [ I don't know what the right setting for this is ]
		'0'                   -- A(0) = DLL Enable (enabled)
		);

		MR2_SETTINGS <= (
		'0', -- A(15 downto 11) = 0
		'0',
		'0',
		'0',
		'0',
		'0', -- A(10 downto 9) = Rtt_WR (dynamic ODT off)
		'0',
		'0', -- A(8) = 0
		'0', -- A(7) = Self-refresh temperature range (normal)
		'0', -- A(6) = Auto self-refresh (manual)
		'0', -- A(5 downto 3) = CAS write latency (5). Must be 5 b/c tCK = 2.5ns
		'0', 
		'0', 
		'0', -- A(2 downto 0) = Partial array self refresh (full array)
		'0', 
		'0' 
		);

		MR3_SETTINGS <= (
		'0', -- A(15 downto 3) = 0
		'0',
		'0',
		'0',
		'0',
		'0', 
		'0',
		'0',
		'0', 
		'0', 
		'0', 
		'0', 
		'0', 
		'0', -- A(2) = Multi-purpose register operation (RD test pattern off) [*** this is used for read leveling]
		'0', -- A(1 downto 0) = MPR location (predefined pattern)
		'0' 
		);
		
		MR3_SETTINGS_RL <= (
		'0', -- A(15 downto 3) = 0
		'0',
		'0',
		'0',
		'0',
		'0', 
		'0',
		'0',
		'0', 
		'0', 
		'0', 
		'0', 
		'0', 
		'1', -- A(2) = Multi-purpose register operation (RD test pattern on)
		'0', -- A(1 downto 0) = MPR location (predefined pattern)
		'0' 
		);	

		ZQCL_SETTINGS <= (
		'0',
		'0',
		'0',
		'0',
		'0',
		'1', 
		'0',
		'0',
		'0', 
		'0', 
		'0', 
		'0', 
		'0', 
		'0',
		'0',
		'0' 
		);	
		
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
			READ_PATTERN_EXIT,
			BEGIN_TRANSACTION,
			OP_INIT,
			OP_A,
			OP_B,
			CLOSE_ROW,
			ACT_ROW,
			WRITE_FINISH,
			READ_FINISH
		);
		signal state : state_t := IDLE;
		signal ret : state_t := IDLE;
		signal delay_count : natural := 0;
		signal readout_delay : natural range 0 to 15 := 8;
		signal read_enable : std_logic := '0';
		signal capture_read1 : std_logic;
		signal capture_read2 : std_logic;
		
		type cmd_op_t is (WR, RD);
		signal cmd_op : cmd_op_t := WR;
		
		signal debug_string : string(1 to 6);
		constant INIT1_DELAY_REAL : natural := 25000;
		constant INIT1_DELAY_DEBUG : natural := 10;
		constant INIT2_DELAY_REAL : natural := 62500;
		constant INIT2_DELAY_DEBUG : natural := 10;
		signal INIT1_DELAY : natural;
		signal INIT2_DELAY : natural;
		
		signal init_active : std_logic := '0';
		
		signal leveling_lane : natural range 0 to 7 := 0;
		signal leveling_finished : std_logic := '0';
		constant LEVELING_CYCLE : natural := 32;
		
		-- For the time delays, I subtract 1 because one clock is consumed by switching to the DELAY state
		constant tWR  : natural := 4; -- Write recovery time. 15ns but in this case I need to let data finish actually coming out
		constant tRP  : natural := 2 - 1; -- PRE duration. 15ns
		constant tRCD : natural := 0; -- ACT to RD/WR. 15ns min. (1 clock to get to DELAY, 1 clock to get to WRITE)
		constant tRTP : natural := 1; -- RD to PRE. max(4CK, 7.5ns)
		
		signal actual_transaction_size : natural range 0 to 255 := 0;
		
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
		variable vrank : std_logic;
		variable vbank : std_logic_vector(2 downto 0);
		variable vrow : std_logic_vector(15 downto 0);
		variable vcol : std_logic_vector(9 downto 0);
		variable vrowid : std_logic_vector((1+3+16)-1 downto 0);
		variable vaddr : std_logic_vector(26 downto 0);
		variable vdata : std_logic_vector(255 downto 0);
		variable words_available : natural;
		variable transaction_size : natural;
	begin
	if(rising_edge(MCLK)) then
	case state is
	
		when IDLE =>
			if(MFORCE_INIT = '1' and IOCLK_LOCKED = '1') then
				state <= INIT1;
			elsif(MTEST = '1' and IOCLK_LOCKED = '1') then
				words_available := to_integer(unsigned(MAVAIL(7 downto 0)));
				transaction_size := to_integer(unsigned(MTRANSACTION_SIZE(7 downto 0)));
				if(words_available < transaction_size) then
					actual_transaction_size <= words_available;
				else
					actual_transaction_size <= transaction_size;
				end if;
				cmd_op <= WR;
				state <= BEGIN_TRANSACTION;
			end if;
			init_active <= '0';
			debug_sync <= '0';
			transaction_active <= '0';
			debug_string <= "IDLE  ";
			
		when DELAY =>
			build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
			mBA <= (others => (others => '0'));
			mMA <= (others => (others => '0'));
			dqs_immediate <= (others => (others => '0'));
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
			dqs_source <= IMMEDIATE;
			init_active <= '1';
			mDDR_RESET <= "0000";
			mCKE0 <= "0000";
			mCKE1 <= "0000";
			delay_count <= INIT1_DELAY; -- MCLK has 8ns period, 8ns*25e3 = 200us
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
			delay_count <= INIT2_DELAY; -- 8ns*62.5e3 = 500us
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
			-- an 8Gb density chip. So the minimum wait time is 360ns / 8ns = 45 system clocks.
			delay_count <= 45;
			state <= DELAY;
			ret <= INIT6;
			debug_string <= "INIT5 ";
			
		when INIT6 =>
			-- Issue MRS command to load MR2 with all application settings
			-- see p.30 of spec
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR2);
			build_bus(mMA, MR2_SETTINGS);
			
			-- Note: the min time between MRS commands (tMRD) is 4 clocks.
			-- I can get 4 clocks by using a delay of 0, but there's no real hurry
			-- here so I'll use a delay of 1 (6 clocks).
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT7;
			debug_string <= "INIT6 ";
			
		when INIT7 =>
			-- Issue MRS command to load MR3 with all application settings
			-- see p.32 of spec
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR3);
			build_bus(mMA, MR3_SETTINGS);
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT8;
			debug_string <= "INIT7 ";
			
		when INIT8 =>
			-- Issue MRS command to load MR1 with all application settings and DLL enabled
			-- see p.27 of spec
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR1);
			build_bus(mMA, MR1_SETTINGS);
			delay_count <= 1;
			state <= DELAY;
			ret <= INIT9;
			debug_string <= "INIT8 ";
			
		when INIT9 =>
			-- Issue MRS command to load MR0 with all application settings and DLL reset
			-- see p.24 of spec
			build_command(RANK_BOTH, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR0);
			build_bus(mMA, MR0_SETTINGS);
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
			mBA <= (others => (others => '0')); -- BA is "don't care" during ZQCL
			build_bus(mMA, ZQCL_SETTINGS);
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
			-- see p.27 of spec
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR1);
			build_bus(mMA, MR1_SETTINGS_WL);

			dqs_reading0 <= '0';
			dqs_reading1 <= '0';
			dqs_reading3 <= '0';
			dqs_immediate <= (others => (others => '0'));
			-- Need to wait at least tWLDQSEN (25 clocks) before the first DQS pulse
			delay_count <= 13;
			state <= DELAY;
			ret <= WRITE_LEVELING;
			debug_string <= "WLENTR";
			
		when WRITE_LEVELING =>
			if(delay_count = 0) then
--				dqs_immediate <= (others => "0010");
				delay_count <= 16;
			else
--				dqs_immediate <= (others => "0000");
				delay_count <= delay_count - 1;
			end if;
			dqs_immediate <= (others => "1010");
			
			-- This is brought out to a test point to let me trigger off of on the scope.
			-- Wider than 1 clock to reduce bandwidth requirements.
			if(delay_count < 5) then
				debug_sync <= '1';
			else
				debug_sync <= '0';
			end if;
			
			if(MFORCE_INIT = '1') then
				state <= WRITE_LEVELING_EXIT;
			else
				state <= WRITE_LEVELING;
			end if;
			debug_string <= "WL    ";
			
		when WRITE_LEVELING_EXIT =>
			dqs_reading0 <= '1';
			dqs_reading1 <= '1';
			dqs_reading3 <= '1';
			dqs_immediate <= (others => (others => '0'));
			debug_sync <= '0';
			-- This is a copy of INIT8
			-- see p.27 of spec
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR1);
			build_bus(mMA, MR1_SETTINGS);
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
			mBA <= (others => (others => '0')); -- BA can be anything during precharge all
			build_bus(mMA, PREA_SETTINGS); -- A10 high, everything else any valid value
			delay_count <= 2;
			state <= DELAY;
			ret <= ENABLE_PATTERN;
			
		when ENABLE_PATTERN =>
			-- see p.32 of spec
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR3);
			build_bus(mMA, MR3_SETTINGS_RL);
			delay_count <= 6; -- wait tMOD
			state <= DELAY;
			ret <= READ_PATTERN;
			
		when READ_PATTERN =>
			if(leveling_finished = '1') then
				build_command(RANK0, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
				read_enable <= '0';
				delay_count <= LEVELING_CYCLE; -- make sure any active reads complete, and make sure tMPRR is satisfied (1 CK)
				debug_sync <= '0';
				state <= DELAY;
				ret <= READ_PATTERN_EXIT;
			else

				if(delay_count = 0) then
					build_command(RANK0, rRD, mCS0,mCS1,mRAS,mCAS,mWE);
					read_enable <= '1'; -- this gets sent through a shift register to generate capture_read1/2
					delay_count <= LEVELING_CYCLE;
				else
					build_command(RANK0, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
					read_enable <= '0';
					delay_count <= delay_count - 1;
				end if;
				mBA <= (others => (others => '0'));
				mMA <= (others => (others => '0'));

				if(delay_count < 5) then
					debug_sync <= '1';
				else
					debug_sync <= '0';
				end if;
				
				if(capture_read1 = '1') then
					latched_read(0) <= mDQ_RX(leveling_lane*8)(0);
					latched_read(1) <= mDQ_RX(leveling_lane*8)(1);
					latched_read(2) <= mDQ_RX(leveling_lane*8)(2);
					latched_read(3) <= mDQ_RX(leveling_lane*8)(3);
				elsif(capture_read2 = '1') then
					latched_read(4) <= mDQ_RX(leveling_lane*8)(0);
					latched_read(5) <= mDQ_RX(leveling_lane*8)(1);
					latched_read(6) <= mDQ_RX(leveling_lane*8)(2);
					latched_read(7) <= mDQ_RX(leveling_lane*8)(3);
				end if;
			
			end if;
		
	
		when READ_PATTERN_EXIT =>
			-- see p.32 of spec
			build_command(RANK0, rMRS, mCS0,mCS1,mRAS,mCAS,mWE);
			build_bus(mBA, MR3);
			build_bus(mMA, MR3_SETTINGS);
			delay_count <= 6; -- wait until tMOD (max 12CK, 15ns), tMRD (4CK) satisfied
			state <= DELAY;
			ret <= IDLE;




		when BEGIN_TRANSACTION =>
			if(actual_transaction_size = 0) then
				state <= IDLE;
			else
				saved <= '0';
				saved_addr <= (others => '0');
				saved_data1 <= (others => '0');
				saved_data2 <= (others => '0');
				have_open_row <= '0';
				open_row <= (others => '0');
				out_data <= (others => '0');
				if(cmd_op = WR) then
					popw <= '1';
				elsif(cmd_op = RD) then
					popr <= '1';
				end if;
				pop_count <= 1;
				cmd_count <= 0;
				dqs_source <= DELAYED;
				dqs_delayed <= (others => (others => '0'));
				state <= OP_INIT;
			end if;
			debug_sync <= '1';
			transaction_active <= '1';
		
		when OP_INIT =>
			if(cmd_op = WR) then
				write_active <= '1';
				popw <= '1';
			elsif(cmd_op = RD) then
				read_active <= '1';
				popr <= '1';
			end if;
			pop_count <= pop_count + 1;
			state <= OP_A;
			
		when OP_A =>
			if(cmd_op = WR) then
				dq_reading0 <= '0';
				dq_reading1 <= '0';
				dq_reading3 <= '0';
				dqs_reading0 <= '0';
				dqs_reading1 <= '0';
				dqs_reading3 <= '0';
			elsif(cmd_op = RD) then
				dq_reading0 <= '1';
				dq_reading1 <= '1';
				dq_reading3 <= '1';
				dqs_reading0 <= '1';
				dqs_reading1 <= '1';
				dqs_reading3 <= '1';
			end if;
			
			if(cmd_count < actual_transaction_size) then
			
				-- saved data is left over from elements we popped from the fifo
				-- but had to hold off on writing/reading because their row wasn't open yet
				if(saved = '1') then
					vaddr := saved_addr;
					vdata := saved_data1;
				else
					if(cmd_op = WR) then
						vaddr := MADDR_W;
						vdata := MDATA_W;
					elsif(cmd_op = RD) then
						vaddr := MADDR_R;
						vdata := saved_data1; -- ignored anyway
					end if;
				end if;
				
				get_rowid(vrowid, vaddr);
				get_rank(vrank, vaddr);
				get_bank(vbank, vaddr);
				get_col(vcol, vaddr);
				
				if(have_open_row = '1' and vrowid = open_row) then
					-- This is the most common case, when the row is already open
					if(cmd_op = WR) then
						if(vrank = '0') then
							build_command(RANK0, rWR, mCS0,mCS1,mRAS,mCAS,mWE);
						else
							build_command(RANK1, rWR, mCS0,mCS1,mRAS,mCAS,mWE);
						end if;
						debug_we <= '1';
					elsif(cmd_op = RD) then
						if(vrank = '0') then
							build_command(RANK0, rRD, mCS0,mCS1,mRAS,mCAS,mWE);
						else
							build_command(RANK1, rRD, mCS0,mCS1,mRAS,mCAS,mWE);
						end if;
						read_enable <= '1'; -- shift register generates delayed capture_read1/2 signals
					end if;
					build_bus(mBA, vbank);
					build_col_bus(mMA, vcol);
					-- data goes into a shift register to account for CAS write latency
					out_data <= vdata;
					dqs_delayed <= (others => "1010");
					cmd_count <= cmd_count + 1;
					
					if(pop_count < actual_transaction_size) then
						if(cmd_op = WR) then
							popw <= '1';
						elsif(cmd_op = RD) then
							popr <= '1';
						end if;
						pop_count <= pop_count + 1;
					else
						popw <= '0';
						popr <= '0';
					end if;
					
					state <= OP_B;
				
				else
					-- If there's no row open, or the open row isn't the one we want,
					-- then we need to pause and open it. For simplicity, I don't
					-- distinguish between these two cases, and always do PREA then ACT.
					
					-- Note that I have some data from the FIFO in-flight: it's likely
					-- that on the previous two clock cycles popw was high. So here I
					-- need to both shut off the FIFO emptying process, and save the
					-- two data that will emerge anyway.
					debug_we <= '0';
					read_enable <= '0';
					build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
					out_data <= (others => '0');
					dqs_delayed <= (others => (others => '0'));
					popw <= '0';
					popr <= '0';
					saved <= '1';
					if(cmd_op = WR) then
						saved_addr <= MADDR_W;
						saved_data1 <= MDATA_W; -- second data saved in CLOSE_ROW
						delay_count <= tWR;
					elsif(cmd_op = RD) then
						saved_addr <= MADDR_R;
						saved_data1 <= (others => '0');
						delay_count <= tRTP;
					end if;
					state <= CLOSE_ROW;
					ret <= OP_A;
				end if;

			else
				-- The correct number of words have been written, time to proceed to the
				-- next stage of the transaction.
				build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
				out_data <= (others => '0');
				dqs_delayed <= (others => (others => '0'));
				state <= CLOSE_ROW;
				if(cmd_op = WR) then
					delay_count <= tWR;
					ret <= WRITE_FINISH;
				elsif(cmd_op = RD) then
					delay_count <= tRTP;
					ret <= READ_FINISH;
				end if;
			end if;
		
		when OP_B =>
			-- Write commands only escape every other system clock in order to fully
			-- stream data out. The write-to-write time is 4CK.
			debug_we <= '0';
			read_enable <= '0';
			build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
			
			if(saved = '1') then
				out_data <= saved_data2;
				saved <= '0';
			else
				out_data <= MDATA_W;
			end if;
			dqs_delayed <= (others => "1010");
			cmd_count <= cmd_count + 1;
			
			if(pop_count < actual_transaction_size) then
				if(cmd_op = WR) then
					popw <= '1';
				elsif(cmd_op = RD) then
					popr <= '1';
				end if;
				pop_count <= pop_count + 1;
			else
				popw <= '0';
				popr <= '0';
			end if;
			
			state <= OP_A;

		when CLOSE_ROW =>
			out_data <= (others => '0');
			dqs_delayed <= (others => (others => '0'));
			if(delay_count = tWR) then
				saved_data2 <= MDATA_W;
			end if;
			
			if(delay_count = 0) then
				if(have_open_row = '1') then
					build_command(RANK_BOTH, rPREA, mCS0,mCS1,mRAS,mCAS,mWE);
					mBA <= (others => (others => '0')); -- BA can be anything during precharge all
					build_bus(mMA, PREA_SETTINGS); -- A10 high, everything else any valid value
					
					have_open_row <= '0';
					open_row <= (others => '0');
					
					delay_count <= tRP; -- meet tRP
				else
					delay_count <= 0;
				end if;
				
				if(saved = '0') then
					-- If saved is zero, that means we're not waiting for a row to be opened,
					-- meaning the next step is not ACT. In this case, ret has been set before
					-- getting here, so I can skip the ACT state once tRP is satisfied.
					if(have_open_row = '1') then
						-- actual delay needed b/c we did the PRE
						state <= DELAY;
					else
						state <= ret;
					end if;
				else
					-- Data is waiting which means we need an ACT
					state <= ACT_ROW;
				end if;
				
			else
				build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
				delay_count <= delay_count - 1;
			end if;
		
		when ACT_ROW =>
			out_data <= (others => '0');
			dqs_delayed <= (others => (others => '0'));
			if(delay_count = 0) then
				get_rank(vrank, saved_addr);
				get_bank(vbank, saved_addr);
				get_row(vrow, saved_addr);
				get_rowid(vrowid, saved_addr);
				
				if(vrank = '0') then
					build_command(RANK0, rACT, mCS0,mCS1,mRAS,mCAS,mWE);
				else
					build_command(RANK1, rACT, mCS0,mCS1,mRAS,mCAS,mWE);
				end if;
				build_bus(mBA, vbank);
				build_bus(mMA, vrow);
				
				have_open_row <= '1';
				open_row <= vrowid;
				
				delay_count <= tRCD;
				state <= DELAY;
				-- ret was set by OP_A or the read state, this allows the close-open cycle
				-- to be shared between the two paths
			else
				build_command(RANK_BOTH, rNOP, mCS0,mCS1,mRAS,mCAS,mWE);
				delay_count <= delay_count - 1;
			end if;
			
			
		when WRITE_FINISH =>
			-- move on to reading
			saved <= '0';
			saved_addr <= (others => '0');
			have_open_row <= '0';
			open_row <= (others => '0');
			out_data <= (others => '0');
			dqs_delayed <= (others => (others => '0'));
			cmd_op <= RD;
			write_active <= '0';
			state <= BEGIN_TRANSACTION;
			
			
		when READ_FINISH =>
			read_enable <= '0';
			saved <= '0';
			saved_addr <= (others => '0');
			have_open_row <= '0';
			open_row <= (others => '0');
			out_data <= (others => '0');
			dqs_delayed <= (others => (others => '0'));
			cmd_op <= WR;
			read_active <= '0';
			state <= IDLE;
				

	end case;
	end if;
	end process;
	
		cwl_delay : block is
			signal dq1 : std_logic_vector(255 downto 0) := (others => '0');
			signal dq2 : std_logic_vector(255 downto 0) := (others => '0');
			signal dqs1 : burst_t(7 downto 0) := (others => (others => '0'));
			signal dqs2 : burst_t(7 downto 0) := (others => (others => '0'));
			signal dqs_out : burst_t(7 downto 0) := (others => (others => '0'));
			
			procedure flat_to_burst(
				variable d : out burst_t(63 downto 0);
				constant din : in std_logic_vector(255 downto 0)
			) is
			begin
				for i in 0 to d'high loop
					d(i) := din(4*i+3 downto 4*i);
				end loop;
			end procedure;
			
		begin
		
			process(MCLK) is
				variable dqout : burst_t(63 downto 0);
			begin
			if(rising_edge(MCLK)) then
				dq1 <= out_data;
				dq2 <= dq1;
				flat_to_burst(dqout, dq2);
				mDQ_TX <= dqout;
				
				dqs1 <= dqs_delayed;
				dqs2 <= dqs1;
				dqs_out <= dqs2;
				
			end if;
			end process;
			
			process(dqs_source, dqs_immediate, dqs_out) is
			begin
			if(dqs_source = IMMEDIATE) then
				mDQS_TX <= dqs_immediate;
			elsif(dqs_source = DELAYED) then
				mDQS_TX <= dqs_out;
			end if;
			end process;
		
		end block;
		
		
		
		cl_delay : block is
			signal shiftreg1 : std_logic_vector(16 downto 0) := (others => '0');
			signal shiftreg2 : std_logic_vector(16 downto 0) := (others => '0');
		begin
			
			process(MCLK) is
			begin
			if(rising_edge(MCLK)) then
				
				shiftreg1(16) <= '0';
				for i in 0 to shiftreg1'high-1 loop
					if(i = readout_delay) then
						shiftreg1(i) <= read_enable;
					else
						shiftreg1(i) <= shiftreg1(i+1);
					end if;
				end loop;

				shiftreg2(16) <= '0';
				for i in 0 to shiftreg2'high-1 loop
					if(i = readout_delay+1) then
						shiftreg2(i) <= read_enable;
					else
						shiftreg2(i) <= shiftreg2(i+1);
					end if;
				end loop;
			end if;
			end process;

			capture_read1 <= shiftreg1(0);
			capture_read2 <= shiftreg2(0);
			
		end block;
		
		
		data_capture : block is
		
			procedure burst_to_flat(
				variable flat : out std_logic_vector(255 downto 0);
				constant burst : in burst_t(63 downto 0)
			) is
			begin
				for i in 0 to burst'high loop
					flat(4*i+3 downto 4*i) := burst(i);
				end loop;
			end procedure;
		
		begin
		process(MCLK) is
			variable flat : std_logic_vector(255 downto 0);
		begin
		if(rising_edge(MCLK)) then
			if((capture_read1 = '1' or capture_read2 = '1') and init_active = '0') then
				MPUSH_R <= '1';
				burst_to_flat(flat, mDQ_RX);
				MDATA_R <= flat;
			else
				MPUSH_R <= '0';
				MDATA_R <= (others => '0');
			end if;
		end if;
		end process;
		end block;
		
	
		read_leveling : block is
			type lstate_t is (IDLE, SEEK, WAIT_FOR_NEXT, VALIDATE, FINISH);
			signal lstate : lstate_t := IDLE;
			signal valid_count : natural range 0 to 1000 := 0;
			signal slip_attempts : natural range 0 to 4 := 0;
			signal raddr : std_logic_vector(7 downto 0) := x"00";
			signal rdata : std_logic_vector(7 downto 0) := x"00";
			signal rwe : std_logic := '0';
			signal once : std_logic := '0';
			constant pattern : std_logic_vector(7 downto 0) := "01010101";
			signal capture : std_logic_vector(3 downto 0) := "0000";
		begin
		
			REGADDR <= raddr;
			REGDATA <= rdata;
			REGWE <= rwe;
		
		process(MCLK) is
			variable combined : std_logic_vector(7 downto 0);
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
				
				if(state = READ_PATTERN and leveling_finished = '0' and read_enable = '1') then
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
			-- In the above example that would be a delay of 2. If the data is 0101,
			-- then the data is aligned to the system clock and we're done. But in
			-- general it will be misaligned, so we use the ISERDES bitslip mechanism
			-- to shift the bits over. In the above example once we've slipped 2 bits
			-- we'll have alignment and so the FSM will complete.
			-- If the FSM tries all 4 slips and still doesn't get the right data, it
			-- must mean that we're not in the data eye.
			when SEEK =>
				if(capture_read1 = '1') then
					capture <= mDQ_RX(leveling_lane*8);
				end if;
				if(capture_read2 = '1') then
					combined := capture & mDQ_RX(leveling_lane*8);
					if(combined = pattern) then
						-- Success! Validate the results with a brief consistency test.
						valid_count <= 0;
						lstate <= VALIDATE;
					else
						if(readout_delay = 10) then
							-- I tried all reasonable offsets and still didn't find the right data.
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
							
						else
							-- This slot didn't contain the right data, so increment and try again
							readout_delay <= readout_delay + 1;
							lstate <= WAIT_FOR_NEXT;
						end if;
					end if;
				end if;
			
			when WAIT_FOR_NEXT =>
				bitslip <= (others => '0');
				if(read_enable = '1') then
					lstate <= SEEK;
				end if;
				
			when VALIDATE =>
				if(capture_read1 = '1') then
					capture <= mDQ_RX(leveling_lane*8);
				end if;
				if(capture_read2 = '1') then
					combined := capture & mDQ_RX(leveling_lane*8);
					-- Guard against jitter by requiring the read succeed N times
					if(combined = pattern) then
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



	
		process(MCLK) is
		begin
		if(rising_edge(MCLK)) then
			if(state = WRITE_LEVELING) then
				-- burst_t indexing is pin id then position within burst
				-- Write Leveling: output state of DQ, first pin in each lane
				MDEBUG_LED(0) <= mDQ_RX(0*8)(0);
				MDEBUG_LED(1) <= mDQ_RX(1*8)(0);
				MDEBUG_LED(2) <= mDQ_RX(2*8)(0);
				MDEBUG_LED(3) <= mDQ_RX(3*8)(0);
				MDEBUG_LED(4) <= mDQ_RX(4*8)(0);
				MDEBUG_LED(5) <= mDQ_RX(5*8)(0);
				MDEBUG_LED(6) <= mDQ_RX(6*8)(0);
				MDEBUG_LED(7) <= mDQ_RX(7*8)(0);
			elsif(state = READ_PATTERN) then
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
			end if;
		end if;
		end process;
	
	end block;






	Inst_ddr3_phy: ddr3_phy 
	generic map ( DEBUG => DEBUG )
	PORT MAP(
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
	

	MDEBUG_SYNC <= debug_sync;
		
end Behavioral;

