--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:24:21 03/26/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/pixel_to_ddr_fifo_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pixel_to_ddr_fifo
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
 
ENTITY pixel_to_ddr_fifo_tb IS
END pixel_to_ddr_fifo_tb;
 
ARCHITECTURE behavior OF pixel_to_ddr_fifo_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT pixel_to_ddr_fifo
    Port ( 
		PCLK : in  STD_LOGIC;                           -- pixel clock
		PDATA : in  STD_LOGIC_VECTOR (23 downto 0);     -- pixel data
		PPUSH : in  STD_LOGIC;                          -- DE
		PFRAME_ADDR_W : in std_logic_vector(23 downto 0); -- DDR write pointer
		PFRAME_ADDR_R : in std_logic_vector(23 downto 0); -- DDR read pointer
		PNEW_FRAME : in std_logic;                      -- pulse to indicate start of frame
		PRESET_FIFO : in STD_LOGIC;                     -- clear the data and address FIFOs
		
		-- data-to-write fifo
		MCLK : in  STD_LOGIC;                             -- memory clock
		MPOP_W : in  STD_LOGIC;                           -- fifo control
		MDATA_W : out  STD_LOGIC_VECTOR (255 downto 0);   -- half-burst data (4 high speed clocks worth of data)
		MADDR_W : out std_logic_vector(23 downto 0);      -- ddr address, high 24 bits
		MDVALID_W : out  STD_LOGIC;                       -- data valid

		-- data-to-read fifo
		MPOP_R : in  STD_LOGIC;                           -- fifo control
		MADDR_R : out std_logic_vector(23 downto 0);      -- ddr address, high 24 bits
		MDVALID_R : out  STD_LOGIC;                       -- data valid

		-- common interface
		MLIMIT : in STD_LOGIC_VECTOR (7 downto 0);      -- minimum number of fifo elements for MREADY = 1
		MREADY : out  STD_LOGIC
	);
    END COMPONENT;
    
	component ddr_to_pixel_fifo is
    Port ( PCLK : in  STD_LOGIC;
           PDATA : out  STD_LOGIC_VECTOR (23 downto 0);
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
   signal PDATA : std_logic_vector(23 downto 0) := (others => '0');
   signal PFRAME_ADDR_W : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned(15, 24));
   signal PFRAME_ADDR_R : std_logic_vector(23 downto 0) := std_logic_vector(to_unsigned(4, 24));
   signal PPUSH : std_logic := '0';
   signal PNEW_FRAME : std_logic := '0';
   signal PRESET_FIFO : std_logic := '0';
   signal MCLK : std_logic := '0';
   signal MLIMIT : std_logic_vector(7 downto 0) := x"04";

	signal mpop_w : std_logic := '0';
	signal mpop_r : std_logic := '0';
	
 	--Outputs
   signal MDATA_W : std_logic_vector(255 downto 0);
   signal MADDR_W : std_logic_vector(23 downto 0);
   signal MADDR_R : std_logic_vector(23 downto 0);
   signal MDVALID_W : std_logic;
   signal MDVALID_R : std_logic;
   signal MREADY : std_logic;
	
	signal pdata_out : std_logic_vector(23 downto 0);
	signal ppop : std_logic := '0';
	signal pdatavalid : std_logic;

	signal count : natural := 0;
	signal mcount : natural := 0;
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          PDATA => PDATA,
          PPUSH => PPUSH,
          PFRAME_ADDR_W => PFRAME_ADDR_W,
          PFRAME_ADDR_R => PFRAME_ADDR_R,
          PNEW_FRAME => PNEW_FRAME,
          PRESET_FIFO => PRESET_FIFO,
          MCLK => MCLK,
          MPOP_W => mpop_w,
          MDATA_W => MDATA_W,
          MADDR_W => MADDR_W,
          MDVALID_W => MDVALID_W,
			 MPOP_R => mpop_r,
			 MADDR_R => MADDR_R,
			 MDVALID_R => MDVALID_R,
          MLIMIT => MLIMIT,
          MREADY => MREADY
        );
	Inst_ddr_to_pixel_fifo: ddr_to_pixel_fifo PORT MAP(
		PCLK => PCLK,
		PDATA => pdata_out,
		PPOP => ppop,
		PDVALID => pdatavalid,
		PRESET => '0',
		MCLK => MCLK,
		MRESET => '0',
		MPUSH => MDVALID_W,
		MDATA => MDATA_W
	);

	PCLK <= not PCLK after 3.367 ns; -- 1080p
	MCLK <= not MCLK after 5 ns; -- 100MHz

	process(PCLK) is
		variable n : std_logic_vector(7 downto 0);
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
		if(count = 2) then
			PNEW_FRAME <= '1';
		else
			PNEW_FRAME <= '0';
		end if;
--		if((count >= 10 and count < 10+32) or (count >= 50 and count < 50+32)) then
		if((count >= 10 and count < 10+32*4)) then
			n := std_logic_vector(to_unsigned(count-10, 8));
			PDATA <= n & n & n;
			PPUSH <= '1';
		else
			PDATA <= (others => '0');
			PPUSH <= '0';
		end if;
		
		-- I can't just leave pop high the whole time. To absorb the ~ 6 clocks it takes
		-- to retrieve and process the next 3 256-bit words from the wide FIFO the pop
		-- line needs to go high after at least ~ 6 elements have made it into the
		-- narrow FIFO. This is fairly soon after the MCB first begins reading out lines
		-- from ram so it's not a huge delay.
		if(count > 200) then
			ppop <= '1';
		else
			ppop <= '0';
		end if;
	end if;
	end process;
	
	
	mcb_block : block is
		type state_t is (WAITING, P1);
		signal state : state_t := WAITING;
	begin
		process(MCLK) is
		begin
		if(rising_edge(MCLK)) then
		case state is
		when WAITING =>
			if(MREADY = '1') then
				mpop_w <= '1';
				state <= P1;
			else
				mpop_w <= '0';
			end if;
		when P1 =>
			mpop_w <= '0';
			state <= WAITING;
		end case;
		end if;
		end process;
	end block;
END;
