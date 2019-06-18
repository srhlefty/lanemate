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
			READOUT_DELAY : in std_logic_vector(9 downto 0);
         FRAME_ADDR_W : IN  std_logic_vector(26 downto 0);
         FRAME_ADDR_R : IN  std_logic_vector(26 downto 0);
         VS_OUT : OUT  std_logic;
         HS_OUT : OUT  std_logic;
         DE_OUT : OUT  std_logic;
         PDATA_OUT : OUT  std_logic_vector(23 downto 0);
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
    

   --Inputs
   signal PCLK : std_logic := '0';
   signal VS : std_logic := '1';
   signal HS : std_logic := '1';
   signal DE : std_logic := '0';
   signal PDATA : std_logic_vector(23 downto 0) := (others => '0');
   signal IS422 : std_logic := '0';
	signal READOUT_DELAY : std_logic_vector(9 downto 0) := (others => '0');
   signal FRAME_ADDR_W : std_logic_vector(26 downto 0) := (others => '0');
   signal FRAME_ADDR_R : std_logic_vector(26 downto 0) := (others => '0');
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
   signal MAVAIL : std_logic_vector(8 downto 0);
   signal MFLUSH : std_logic;
   signal MADDR_W : std_logic_vector(26 downto 0);
   signal MDATA_W : std_logic_vector(255 downto 0);
   signal MDVALID_W : std_logic;
   signal MADDR_R : std_logic_vector(26 downto 0);
   signal MDVALID_R : std_logic;

	signal count : natural := 0;
	signal line_length : natural := 0;
	signal hblank : natural := 0;

	constant source : natural := 2;

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
          FRAME_ADDR_W => FRAME_ADDR_W,
          FRAME_ADDR_R => FRAME_ADDR_R,
          VS_OUT => VS_OUT,
          HS_OUT => HS_OUT,
          DE_OUT => DE_OUT,
          PDATA_OUT => PDATA_OUT,
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
		line_length <= 1920;
		READOUT_DELAY <= std_logic_vector(to_unsigned(1920/2, READOUT_DELAY'length));
		hblank <= 88+148+44;
		IS422 <= '0';
		MTRANSACTION_SIZE <= x"1e";
	end generate;

	gen_720p : if(source = 1) generate
	begin
		PCLK <= not PCLK after 6.73 ns; -- 720p
		line_length <= 1280;
		READOUT_DELAY <= std_logic_vector(to_unsigned(1280/2, READOUT_DELAY'length));
		hblank <= 110+220+40;
		IS422 <= '0';
		MTRANSACTION_SIZE <= x"14";
	end generate;
	
	gen_480i : if(source = 2) generate
	begin
		PCLK <= not PCLK after 18.519 ns; -- 480i
		line_length <= 1440;
		READOUT_DELAY <= std_logic_vector(to_unsigned(1440/2, READOUT_DELAY'length));
		hblank <= 38+114+124;
		IS422 <= '1';
		MTRANSACTION_SIZE <= x"08";
	end generate;


	MCLK <= not MCLK after 5 ns;
	
	
	
		  
	process(PCLK) is
		variable n : std_logic_vector(7 downto 0);
		variable de1start, de1end, de2start, de2end : natural;
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
		
		if(count = 5) then
			VS <= '0';
		else
			VS <= '1';
		end if;
		
		if(count = 6 or count = 6+line_length+hblank) then
			HS <= '0';
		else
			HS <= '1';
		end if;
		
		if((count >= 10 and count < 10+line_length) or
		   (count >= 10+line_length+hblank and count < 10+line_length+hblank+line_length)) then
			n := std_logic_vector(to_unsigned(count-10, 8));
			if(IS422 = '1') then
				PDATA <= x"0000" & n;
			else
				PDATA <= n & n & n;
			end if;
			DE <= '1';
		else
			PDATA <= (others => '0');
			DE <= '0';
		end if;
		
	end if;
	end process;


END;
