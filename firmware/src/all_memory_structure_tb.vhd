--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:22:08 06/13/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/all_memory_structure_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gearbox8to24
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
 
ENTITY all_memory_structure_tb IS
END all_memory_structure_tb;
 
ARCHITECTURE behavior OF all_memory_structure_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT gearbox8to24
    PORT(
         PCLK : IN  std_logic;
         CE : IN  std_logic;
         DIN : IN  std_logic_vector(23 downto 0);
         DE : IN  std_logic;
         DOUT : OUT  std_logic_vector(23 downto 0);
         DEOUT : OUT  std_logic
        );
    END COMPONENT;
    
	component gearbox24to256 is
	Port ( 
		PCLK : in std_logic;
		-- input data
		PDATA : in std_logic_vector(23 downto 0);
		PPUSH : in std_logic;                             -- DE
		
		-- address management
		PFRAME_ADDR_W : in std_logic_vector(26 downto 0); -- DDR write pointer
		PFRAME_ADDR_R : in std_logic_vector(26 downto 0); -- DDR read pointer
		PNEW_FRAME : in std_logic;                        -- pulse to capture write/read pointers
		
		-- output to write-transaction address & data fifos
		PADDR_W : out std_logic_vector(26 downto 0);
		PDATA_W : out std_logic_vector(255 downto 0);
		PPUSH_W : out std_logic;
		
		-- output to read-transaction address fifo
		PADDR_R : out std_logic_vector(26 downto 0);
		PPUSH_R : out std_logic;
		
		-- signal that a group of 3 pushes has just completed
		-- (this is used downstream as a 'done' signal to flush a queue
		PPUSHED : out std_logic
	);
	end component;

	component pixel_to_ddr_fifo is
    Port ( 
		PCLK : in  STD_LOGIC;
		MCLK : in  STD_LOGIC;
		
		PDE : in std_logic;
		PPUSHED : in std_logic;
		
		-- write-transaction fifo, input side
		PADDR_W : in std_logic_vector(26 downto 0);
		PDATA_W : in std_logic_vector(255 downto 0);
		PPUSH_W : in std_logic;
		-- write-transaction fifo, output side
		MPOP_W : in std_logic;
		MADDR_W : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDATA_W : out std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : out std_logic;

		-- read-transaction fifo, input side
		PADDR_R : in std_logic_vector(26 downto 0);
		PPUSH_R : in std_logic;
		-- read-transaction fifo, output side
		MPOP_R : in std_logic;
		MADDR_R : out std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : out std_logic;

		-- mcb signals
		MAVAIL : out std_logic_vector(8 downto 0);
		MFLUSH : out std_logic
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
		MADDR_W : in std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDATA_W : in std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;
		
		-- read-transaction fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
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
		MADDR_W : in std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDATA_W : in std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;
		
		-- read-transaction fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : in std_logic;
		
		-- output side
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
	end component;

	component ddr_to_pixel_fifo is
    Port ( PCLK : in  STD_LOGIC;
           PDATA : out  STD_LOGIC_VECTOR (23 downto 0);
			  P8BIT : in std_logic;                           -- if high, only the lower 8 bits are active (SD 4:2:2)
           PPOP : in  STD_LOGIC;
			  PDVALID : out STD_LOGIC;
			  PRESET : in STD_LOGIC;
           MCLK : in  STD_LOGIC;
			  MRESET : in STD_LOGIC;
           MPUSH : in  STD_LOGIC;
           MDATA : in  STD_LOGIC_VECTOR (255 downto 0)
           );
	end component;


   --Inputs
   signal PCLK : std_logic := '0';
   signal MCLK : std_logic := '0';
   signal CE : std_logic := '0';
   signal DIN : std_logic_vector(23 downto 0) := (others => '0');
   signal DE : std_logic := '0';

 	--Outputs
   signal DOUT : std_logic_vector(23 downto 0);
   signal DEOUT : std_logic;

   signal PFRAME_ADDR_W : std_logic_vector(26 downto 0) := (others => '0');
   signal PFRAME_ADDR_R : std_logic_vector(26 downto 0) := (others => '0');
   signal PNEW_FRAME : std_logic := '0';
   signal PADDR_W : std_logic_vector(26 downto 0);
   signal PDATA_W : std_logic_vector(255 downto 0);
   signal PPUSH_W : std_logic;
   signal PADDR_R : std_logic_vector(26 downto 0);
   signal PPUSH_R : std_logic;
   signal PPUSHED : std_logic;



   signal MADDR_W : std_logic_vector(26 downto 0);
   signal MDATA_W : std_logic_vector(255 downto 0);
   signal MDVALID_W : std_logic;
   signal MADDR_R : std_logic_vector(26 downto 0);
   signal MDVALID_R : std_logic;
   signal MAVAIL : std_logic_vector(8 downto 0);
   signal MFLUSH : std_logic;



	signal MPOP_W : std_logic;
	signal MPOP_R : std_logic;
	signal MPUSH_R : std_logic;
	signal MDATA_R : std_logic_vector(255 downto 0);


	signal PDATA_FINAL : std_logic_vector(23 downto 0);
	signal PDE_FINAL : std_logic := '0';
	signal PDVALID_FINAL : std_logic;

	signal count : natural := 0;
	signal line_length : natural := 0;
	signal hblank : natural := 0;
	signal p8bit : std_logic := '0';
	signal transaction_size : std_logic_vector(7 downto 0) := (others => '0');
	signal readout_delay : natural := 0;

	constant source : natural := 1;
	
BEGIN

	
	gen_1080p : if(source = 0) generate
	begin
		PCLK <= not PCLK after 3.367 ns; -- 1080p
		line_length <= 1920;
		readout_delay <= 1920/2;
		hblank <= 88+148+44;
		p8bit <= '0';
		transaction_size <= x"1e";
	end generate;

	gen_720p : if(source = 1) generate
	begin
		PCLK <= not PCLK after 6.73 ns; -- 720p
		line_length <= 1280;
		readout_delay <= 1280/2;
		hblank <= 110+220+40;
		p8bit <= '0';
		transaction_size <= x"14";
	end generate;
	
	gen_480i : if(source = 2) generate
	begin
		PCLK <= not PCLK after 18.519 ns; -- 480i
		line_length <= 1440;
		readout_delay <= 1440/2;
		hblank <= 38+114+124;
		p8bit <= '1';
		transaction_size <= x"08";
	end generate;


	MCLK <= not MCLK after 5 ns;
	
	
	
		  
	process(PCLK) is
		variable n : std_logic_vector(7 downto 0);
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;

		if((count >= 10 and count < 10+line_length) or
		   (count >= 10+line_length+hblank and count < 10+line_length+hblank+line_length)) then
			n := std_logic_vector(to_unsigned(count-10, 8));
			if(p8bit = '1') then
				DIN <= x"0000" & n;
			else
				DIN <= n & n & n;
			end if;
			DE <= '1';
		else
			DIN <= (others => '0');
			DE <= '0';
		end if;
		
		
		if((count >= 10+readout_delay and count < 10+readout_delay+line_length) or
		   (count >= 10+readout_delay+line_length+hblank and count < 10+readout_delay+line_length+hblank+line_length)) then
			PDE_FINAL <= '1';
		else
			PDE_FINAL <= '0';
		end if;
		
	end if;
	end process;


	-- stage 1: (optionally) pack 8-bit SD data into 24-bit bus

   inst_gearbox8to24: gearbox8to24 PORT MAP (
          PCLK => PCLK,
          CE => p8bit,
          DIN => DIN,
          DE => DE,
          DOUT => DOUT,
          DEOUT => DEOUT
        );
		  
	-- stage 2: pack 24-bit bus into 256-bit bus
	-- and generate ddr addresses for read and write transactions
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		if(count = 2) then
			PNEW_FRAME <= '1';
		else
			PNEW_FRAME <= '0';
		end if;
	end if;
	end process;
	
   inst_gearbox24_to_256: gearbox24to256 PORT MAP (
          PCLK => PCLK,
          PDATA => DOUT,
          PPUSH => DEOUT,
          PFRAME_ADDR_W => PFRAME_ADDR_W,
          PFRAME_ADDR_R => PFRAME_ADDR_R,
          PNEW_FRAME => PNEW_FRAME,
          PADDR_W => PADDR_W,
          PDATA_W => PDATA_W,
          PPUSH_W => PPUSH_W,
          PADDR_R => PADDR_R,
          PPUSH_R => PPUSH_R,
          PPUSHED => PPUSHED
        );


	-- stage 3: fill transaction fifos
	
   inst_pixel_to_ddr_fifo: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          MCLK => MCLK,
          PDE => DEOUT,
          PPUSHED => PPUSHED,
          PADDR_W => PADDR_W,
          PDATA_W => PDATA_W,
          PPUSH_W => PPUSH_W,
          MPOP_W => MPOP_W,
          MADDR_W => MADDR_W,
          MDATA_W => MDATA_W,
          MDVALID_W => MDVALID_W,
          PADDR_R => PADDR_R,
          PPUSH_R => PPUSH_R,
          MPOP_R => MPOP_R,
          MADDR_R => MADDR_R,
          MDVALID_R => MDVALID_R,
          MAVAIL => MAVAIL,
          MFLUSH => MFLUSH
        );


	-- stage 4: mcb
	
--	Inst_trivial_mcb: trivial_mcb PORT MAP(
	Inst_trivial_mcb: internal_mcb PORT MAP(
		MCLK => MCLK,
		MTRANSACTION_SIZE => transaction_size,
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
		MDATA_R => MDATA_R
	);

	
	-- stage 5: inverse gearbox back to pixels
	Inst_ddr_to_pixel_fifo: ddr_to_pixel_fifo PORT MAP(
		PCLK => PCLK,
		PDATA => PDATA_FINAL,
		P8BIT => p8bit,
		PPOP => PDE_FINAL,
		PDVALID => PDVALID_FINAL,
		PRESET => '0',
		MCLK => MCLK,
		MRESET => '0',
		MPUSH => MPUSH_R,
		MDATA => MDATA_R
	);
	
END;
