--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:13:47 08/28/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/ddr3_mcb_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr3_mcb
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY ddr3_mcb_tb IS
END ddr3_mcb_tb;
 
ARCHITECTURE behavior OF ddr3_mcb_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr3_mcb
	 Generic( DEBUG : boolean );
    PORT(
         MCLK : IN  std_logic;
         MTRANSACTION_SIZE : IN  std_logic_vector(7 downto 0);
         MAVAIL : IN  std_logic_vector(8 downto 0);
         MFLUSH : IN  std_logic;
         MPOP_W : OUT  std_logic;
         MADDR_W : IN  std_logic_vector(26 downto 0);
         MDATA_W : IN  std_logic_vector(255 downto 0);
         MDVALID_W : IN  std_logic;
         MPOP_R : OUT  std_logic;
         MADDR_R : IN  std_logic_vector(26 downto 0);
         MDVALID_R : IN  std_logic;
         MPUSH_R : OUT  std_logic;
         MDATA_R : OUT  std_logic_vector(255 downto 0);
         MTEST : IN  std_logic;
         MDEBUG_LED : OUT  std_logic_vector(7 downto 0);
         MADDITIVE_LATENCY : IN  std_logic_vector(1 downto 0);
         MCAS_LATENCY : IN  std_logic_vector(3 downto 0);
         B0_IOCLK : IN  std_logic;
         B0_STROBE : IN  std_logic;
         B0_IOCLK_180 : IN  std_logic;
         B0_STROBE_180 : IN  std_logic;
         B1_IOCLK : IN  std_logic;
         B1_STROBE : IN  std_logic;
         B1_IOCLK_180 : IN  std_logic;
         B1_STROBE_180 : IN  std_logic;
         B3_IOCLK : IN  std_logic;
         B3_STROBE : IN  std_logic;
         B3_IOCLK_180 : IN  std_logic;
         B3_STROBE_180 : IN  std_logic;
			IOCLK_LOCKED : in std_logic;
         DDR_RESET : INOUT  std_logic;
         CK0_P : INOUT  std_logic;
         CK0_N : INOUT  std_logic;
         CKE0 : INOUT  std_logic;
         CK1_P : INOUT  std_logic;
         CK1_N : INOUT  std_logic;
         CKE1 : INOUT  std_logic;
         RAS : INOUT  std_logic;
         CAS : INOUT  std_logic;
         WE : INOUT  std_logic;
         CS0 : INOUT  std_logic;
         CS1 : INOUT  std_logic;
         BA : INOUT  std_logic_vector(2 downto 0);
         MA : INOUT  std_logic_vector(15 downto 0);
         DM : INOUT  std_logic_vector(7 downto 0);
         DQSP : INOUT  std_logic_vector(7 downto 0);
         DQSN : INOUT  std_logic_vector(7 downto 0);
         DQ : INOUT  std_logic_vector(63 downto 0)
        );
    END COMPONENT;
    
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

   --Inputs
   signal MCLK : std_logic := '0';
   signal MTRANSACTION_SIZE : std_logic_vector(7 downto 0) := x"10";
   signal MAVAIL : std_logic_vector(8 downto 0) := (others => '0');
   signal MFLUSH : std_logic := '0';
   signal MADDR_W : std_logic_vector(26 downto 0) := (others => '0');
   signal MDATA_W : std_logic_vector(255 downto 0) := (others => '0');
   signal MDVALID_W : std_logic := '0';
   signal MADDR_R : std_logic_vector(26 downto 0) := (others => '0');
   signal MDVALID_R : std_logic := '0';
   signal MTEST : std_logic := '0';
   signal MADDITIVE_LATENCY : std_logic_vector(1 downto 0) := "00";
   signal MCAS_LATENCY : std_logic_vector(3 downto 0) := "0010";
   signal B0_IOCLK : std_logic := '0';
   signal B0_STROBE : std_logic := '0';
   signal B0_IOCLK_180 : std_logic := '0';
   signal B0_STROBE_180 : std_logic := '0';
   signal B1_IOCLK : std_logic := '0';
   signal B1_STROBE : std_logic := '0';
   signal B1_IOCLK_180 : std_logic := '0';
   signal B1_STROBE_180 : std_logic := '0';
   signal B3_IOCLK : std_logic := '0';
   signal B3_STROBE : std_logic := '0';
   signal B3_IOCLK_180 : std_logic := '0';
   signal B3_STROBE_180 : std_logic := '0';

	--BiDirs
   signal DDR_RESET : std_logic;
   signal CK0_P : std_logic;
   signal CK0_N : std_logic;
   signal CKE0 : std_logic;
   signal CK1_P : std_logic;
   signal CK1_N : std_logic;
   signal CKE1 : std_logic;
   signal RAS : std_logic;
   signal CAS : std_logic;
   signal WE : std_logic;
   signal CS0 : std_logic;
   signal CS1 : std_logic;
   signal BA : std_logic_vector(2 downto 0);
   signal MA : std_logic_vector(15 downto 0);
   signal DM : std_logic_vector(7 downto 0);
   signal DQSP : std_logic_vector(7 downto 0);
   signal DQSN : std_logic_vector(7 downto 0);
   signal DQ : std_logic_vector(63 downto 0);

 	--Outputs
   signal MPOP_W : std_logic;
   signal MPOP_R : std_logic;
   signal MPUSH_R : std_logic;
   signal MDATA_R : std_logic_vector(255 downto 0);
   signal MDEBUG_LED : std_logic_vector(7 downto 0);
	signal LOCKED : std_logic;


	signal SYSCLK : std_logic := '0';

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
	

	signal count : natural := 0;
	
BEGIN

	SYSCLK <= not SYSCLK after 5 ns;
	
	Inst_clkgen: clkgen PORT MAP(
		SYSCLK100        => SYSCLK,
		CLK200           => MCLK,
		B0_CLK800        => b0_serdesclk,
		B0_STROBE800     => b0_serdesstrobe,
		B0_CLK800_180    => b0_serdesclk_180,
		B0_STROBE800_180 => b0_serdesstrobe_180,
		B1_CLK800        => b1_serdesclk,
		B1_STROBE800     => b1_serdesstrobe,
		B1_CLK800_180    => b1_serdesclk_180,
		B1_STROBE800_180 => b1_serdesstrobe_180,
		B3_CLK800        => b3_serdesclk,
		B3_STROBE800     => b3_serdesstrobe,
		B3_CLK800_180    => b3_serdesclk_180,
		B3_STROBE800_180 => b3_serdesstrobe_180,
		LOCKED           => LOCKED
	);


 
	-- Instantiate the Unit Under Test (UUT)
   uut: ddr3_mcb 
	Generic map ( DEBUG => true )
	PORT MAP (
          MCLK => MCLK,
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
			 
          MPUSH_R => MPUSH_R,
          MDATA_R => MDATA_R,
			 
          MTEST => MTEST,
          MDEBUG_LED => MDEBUG_LED,
			 
          MADDITIVE_LATENCY => MADDITIVE_LATENCY,
          MCAS_LATENCY => MCAS_LATENCY,
			 
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
			
			IOCLK_LOCKED => LOCKED,
			 
          DDR_RESET => DDR_RESET,
          CK0_P => CK0_P,
          CK0_N => CK0_N,
          CKE0 => CKE0,
          CK1_P => CK1_P,
          CK1_N => CK1_N,
          CKE1 => CKE1,
          RAS => RAS,
          CAS => CAS,
          WE => WE,
          CS0 => CS0,
          CS1 => CS1,
          BA => BA,
          MA => MA,
          DM => DM,
          DQSP => DQSP,
          DQSN => DQSN,
          DQ => DQ
        );


	-- Look at this section in the simulator to verify data/clock phase is set correctly
	
	alignment_test : block is
		signal data0 : std_logic_vector(3 downto 0) := "0000";
		signal data180 : std_logic_vector(3 downto 0) := "0000";
		signal pin_0 : std_logic;
		signal pin_180 : std_logic;
		signal delay : natural := 0;
	begin
	
		pin_data0: ddr_pin_se 
		generic map (
			IDELAY_VALUE => 0,
			ODELAY_VALUE => 0
		)
		port map (
			CLK => MCLK,
			IOCLK => b0_serdesclk,
			STROBE => b0_serdesstrobe,
			READING => '0',
			BITSLIP => '0',
			TXD => data0,
			RXD => open,
			PIN => pin_0
		);
		
		pin_data180: ddr_pin_se 
		generic map (
			IDELAY_VALUE => 0,
			ODELAY_VALUE => 0
		)
		port map (
			CLK => MCLK,
			IOCLK => b0_serdesclk_180,
			STROBE => b0_serdesstrobe_180,
			READING => '0',
			BITSLIP => '0',
			TXD => data180,
			RXD => open,
			PIN => pin_180
		);
		
		process(MCLK) is
		begin
		if(rising_edge(MCLK)) then
			if(delay = 100) then
				data0 <= "1000";
				data180 <= "1000";
				delay <= 0;
			else
				data0 <= "0000";
				data180 <= "0000";
				delay <= delay + 1;
			end if;
		end if;
		end process;
	
	end block;

	----------------------------------------------------------------------------

	process(MCLK) is
	begin
	if(rising_edge(MCLK) and LOCKED = '1') then
		count <= count + 1;
		if(count = 64 or count = 600) then
			MTEST <= '1';
		else
			MTEST <= '0';
		end if;
	end if;
	end process;


END;
