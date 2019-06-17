----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:14:57 06/14/2019 
-- Design Name: 
-- Module Name:    delay_application - Behavioral 
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

entity delay_application is
	Port ( 
		-- Video input
		PCLK : in std_logic;
		VS   : in std_logic;
		DE   : in std_logic;
		PDATA : in std_logic_vector(23 downto 0);
		IS422 : in std_logic; -- if true, bottom 8 bits are assumed to be the data
		
		-- R/W settings
		FRAME_ADDR_W : in std_logic_vector(23 downto 0); -- DDR write pointer. Captured on VS.
		FRAME_ADDR_R : in std_logic_vector(23 downto 0); -- DDR read pointer. Captured on VS.
		
		-- Video output
		DE_DELAYED : in std_logic; -- needs to be about half a line, long enough so that a few transactions have occurred
		DE_OUT : out std_logic;
		PDATA_OUT  : out std_logic_vector(23 downto 0);

		-------------------------------------------------------------------------
		-- MCB interface
		MCLK : in std_logic;
		
		-- fifo status and control
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0);
		MAVAIL : out std_logic_vector(8 downto 0);
		MFLUSH : out std_logic;
		
		-- write-transaction fifo, output side
		MPOP_W : in std_logic;
		MADDR_W : out std_logic_vector(23 downto 0);    -- ddr address, high 24 bits
		MDATA_W : out std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : out std_logic;
		
		-- read-transaction fifo, output side
		MPOP_R : in std_logic;
		MADDR_R : out std_logic_vector(23 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : out std_logic;

		-- read-transaction results
		MPUSH : in std_logic;
		MDATA : in std_logic_vector(255 downto 0)
		
		--
		-------------------------------------------------------------------------
	);
end delay_application;

architecture Behavioral of delay_application is


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
		PFRAME_ADDR_W : in std_logic_vector(23 downto 0); -- DDR write pointer
		PFRAME_ADDR_R : in std_logic_vector(23 downto 0); -- DDR read pointer
		PNEW_FRAME : in std_logic;                        -- pulse to capture write/read pointers
		
		-- output to write-transaction address & data fifos
		PADDR_W : out std_logic_vector(23 downto 0);
		PDATA_W : out std_logic_vector(255 downto 0);
		PPUSH_W : out std_logic;
		
		-- output to read-transaction address fifo
		PADDR_R : out std_logic_vector(23 downto 0);
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
		PADDR_W : in std_logic_vector(23 downto 0);
		PDATA_W : in std_logic_vector(255 downto 0);
		PPUSH_W : in std_logic;
		-- write-transaction fifo, output side
		MPOP_W : in std_logic;
		MADDR_W : out std_logic_vector(23 downto 0);    -- ddr address, high 24 bits
		MDATA_W : out std_logic_vector(255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : out std_logic;

		-- read-transaction fifo, input side
		PADDR_R : in std_logic_vector(23 downto 0);
		PPUSH_R : in std_logic;
		-- read-transaction fifo, output side
		MPOP_R : in std_logic;
		MADDR_R : out std_logic_vector(23 downto 0);    -- ddr address, high 24 bits
		MDVALID_R : out std_logic;

		-- mcb signals
		MAVAIL : out std_logic_vector(8 downto 0);
		MFLUSH : out std_logic
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


	signal de_post_gearbox : std_logic;
	signal data_post_gearbox : std_logic_vector(23 downto 0);

	signal newframe : std_logic := '0';

	signal paddr_w : std_logic_vector(23 downto 0);
	signal pdata_w : std_logic_vector(255 downto 0);
	signal ppush_w : std_logic;
	signal paddr_r : std_logic_vector(23 downto 0);
	signal ppush_r : std_logic;
	signal ppushed : std_logic;
	
begin


	-- stage 1: (optionally) pack 8-bit SD data into 24-bit bus

   inst_gearbox8to24: gearbox8to24 PORT MAP (
          PCLK => PCLK,
          CE => IS422,
          DIN => PDATA,
          DE => DE,
          DOUT => data_post_gearbox,
          DEOUT => de_post_gearbox
        );
		  
	-- stage 2: pack 24-bit bus into 256-bit bus
	-- and generate ddr addresses for read and write transactions
	
	newframe_gen : block is
		signal vs_old : std_logic := '1';
	begin
		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
			vs_old <= VS;
			if(vs_old = '1' and VS = '0') then
				newframe <= '1';
			else
				newframe <= '0';
			end if;
		end if;
		end process;
	end block;
	
   inst_gearbox24_to_256: gearbox24to256 PORT MAP (
          PCLK => PCLK,
          PDATA => data_post_gearbox,
          PPUSH => de_post_gearbox,
          PFRAME_ADDR_W => FRAME_ADDR_W,
          PFRAME_ADDR_R => FRAME_ADDR_R,
          PNEW_FRAME => newframe,
          PADDR_W => paddr_w,
          PDATA_W => pdata_w,
          PPUSH_W => ppush_w,
          PADDR_R => paddr_r,
          PPUSH_R => ppush_r,
          PPUSHED => ppushed
        );


	-- stage 3: fill transaction fifos
	
   inst_pixel_to_ddr_fifo: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          MCLK => MCLK,
          PDE => de_post_gearbox,
          PPUSHED => ppushed,
          PADDR_W => paddr_w,
          PDATA_W => pdata_w,
          PPUSH_W => ppush_w,
          MPOP_W => MPOP_W,
          MADDR_W => MADDR_W,
          MDATA_W => MDATA_W,
          MDVALID_W => MDVALID_W,
          PADDR_R => paddr_r,
          PPUSH_R => ppush_r,
          MPOP_R => MPOP_R,
          MADDR_R => MADDR_R,
          MDVALID_R => MDVALID_R,
          MAVAIL => MAVAIL,
          MFLUSH => MFLUSH
        );


	-- stage 5: inverse gearbox back to pixels
	Inst_ddr_to_pixel_fifo: ddr_to_pixel_fifo PORT MAP(
		MCLK => MCLK,
		MRESET => '0',
		MPUSH => MPUSH,
		MDATA => MDATA,
		PCLK => PCLK,
		PDATA => PDATA_OUT,
		P8BIT => IS422,
		PPOP => DE_DELAYED,
		PDVALID => DE_OUT,
		PRESET => '0'
	);


end Behavioral;

