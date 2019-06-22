--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:42:55 06/17/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/delay_application_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: delay_application
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
USE ieee.numeric_std.ALL;
 
ENTITY delay_application_tb IS
END delay_application_tb;
 
ARCHITECTURE behavior OF delay_application_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT delay_application
    PORT(
         PCLK : IN  std_logic;
         VS : IN  std_logic;
         HS : IN  std_logic;
         DE : IN  std_logic;
         PDATA : IN  std_logic_vector(23 downto 0);
         IS422 : IN  std_logic;
			READOUT_DELAY : in std_logic_vector(10 downto 0);
			CE : in std_logic;
         FRAME_ADDR_W : IN  std_logic_vector(26 downto 0);
         FRAME_ADDR_R : IN  std_logic_vector(26 downto 0);
         VS_OUT : OUT  std_logic;
         HS_OUT : OUT  std_logic;
         DE_OUT : OUT  std_logic;
         PDATA_OUT : OUT  std_logic_vector(23 downto 0);
			DEBUG : out std_logic;
         MCLK : IN  std_logic;
         MTRANSACTION_SIZE : IN  std_logic_vector(7 downto 0);
         MAVAIL : OUT  std_logic_vector(8 downto 0);
         MFLUSH : OUT  std_logic;
         MPOP_W : IN  std_logic;
         MADDR_W : OUT  std_logic_vector(26 downto 0);
         MDATA_W : OUT  std_logic_vector(255 downto 0);
         MDVALID_W : OUT  std_logic;
         MPOP_R : IN  std_logic;
         MADDR_R : OUT  std_logic_vector(26 downto 0);
         MDVALID_R : OUT  std_logic;
         MPUSH : IN  std_logic;
         MDATA : IN  std_logic_vector(255 downto 0)
        );
    END COMPONENT;
	 
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

   --Inputs
   signal PCLK : std_logic := '0';
   signal VS : std_logic := '1';
   signal HS : std_logic := '1';
   signal DE : std_logic := '0';
   signal CE : std_logic := '1';
   signal PDATA : std_logic_vector(23 downto 0) := (others => '0');
   signal IS422 : std_logic := '0';
	signal READOUT_DELAY : std_logic_vector(10 downto 0) := (others => '0');
   signal FRAME_ADDR_W : std_logic_vector(26 downto 0) := (others => '0');
   signal FRAME_ADDR_R : std_logic_vector(26 downto 0) := std_logic_vector(to_unsigned(3, 27));
   signal MCLK : std_logic := '0';
   signal MTRANSACTION_SIZE : std_logic_vector(7 downto 0) := (others => '0');
   signal MPOP_W : std_logic := '0';
   signal MPOP_R : std_logic := '0';
   signal MPUSH : std_logic := '0';
   signal MDATA : std_logic_vector(255 downto 0) := (others => '0');

 	--Outputs
   signal VS_OUT : std_logic;
   signal HS_OUT : std_logic;
   signal DE_OUT : std_logic;
   signal PDATA_OUT : std_logic_vector(23 downto 0);
	signal DEBUG : std_logic;
   signal MAVAIL : std_logic_vector(8 downto 0);
   signal MFLUSH : std_logic;
   signal MADDR_W : std_logic_vector(26 downto 0);
   signal MDATA_W : std_logic_vector(255 downto 0);
   signal MDVALID_W : std_logic;
   signal MADDR_R : std_logic_vector(26 downto 0);
   signal MDVALID_R : std_logic;

	signal count : natural := 0;

	signal sel : std_logic_vector(1 downto 0);
	constant source : natural := 1;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: delay_application PORT MAP (
          PCLK => PCLK,
          VS => VS,
          HS => HS,
          DE => DE,
          PDATA => PDATA,
          IS422 => IS422,
			 READOUT_DELAY => READOUT_DELAY,
			 CE => CE,
          FRAME_ADDR_W => FRAME_ADDR_W,
          FRAME_ADDR_R => FRAME_ADDR_R,
          VS_OUT => VS_OUT,
          HS_OUT => HS_OUT,
          DE_OUT => DE_OUT,
          PDATA_OUT => PDATA_OUT,
			 DEBUG => DEBUG,
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
          MPUSH => MPUSH,
          MDATA => MDATA
        );

--	Inst_trivial_mcb: trivial_mcb PORT MAP(
	Inst_trivial_mcb: internal_mcb PORT MAP(
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
		MPUSH_R => MPUSH,
		MDATA_R => MDATA
	);

	gen_1080p : if(source = 0) generate
	begin
		PCLK <= not PCLK after 3.367 ns; -- 1080p
		READOUT_DELAY <= std_logic_vector(to_unsigned(1920/2, READOUT_DELAY'length));
		IS422 <= '0';
		MTRANSACTION_SIZE <= x"1e";
		sel <= "10";
	end generate;

	gen_720p : if(source = 1) generate
	begin
		PCLK <= not PCLK after 6.73 ns; -- 720p
		READOUT_DELAY <= std_logic_vector(to_unsigned(1280/2, READOUT_DELAY'length));
		IS422 <= '0';
		MTRANSACTION_SIZE <= x"14";
		sel <= "01";
	end generate;
	
	gen_480i : if(source = 2) generate
	begin
		PCLK <= not PCLK after 18.519 ns; -- 480i
		READOUT_DELAY <= std_logic_vector(to_unsigned(1440/2, READOUT_DELAY'length));
		IS422 <= '1';
		MTRANSACTION_SIZE <= x"08";
		sel <= "11";
	end generate;


	MCLK <= not MCLK after 5 ns;
	
	
	stim : block is
		signal stage1_vs, stage1_hs, stage1_de : std_logic := '0';
		signal stage1_d : std_logic_vector(23 downto 0) := (others => '0');
	begin
	
		Inst_timing_gen: timing_gen PORT MAP(
			CLK => PCLK,
			RST => '0',
			SEL => sel,
			VS => stage1_vs,
			HS => stage1_hs,
			DE => stage1_de,
			D => stage1_d
		);
	
		Inst_test_pattern: test_pattern PORT MAP(
			PCLK => PCLK,
			VS => stage1_vs,
			HS => stage1_hs,
			DE => stage1_de,
			CE => '1',
			IS422 => IS422,
			D => stage1_d,
			VSOUT => VS,
			HSOUT => HS,
			DEOUT => DE,
			DOUT => PDATA
		);
		
	end block;


END;
