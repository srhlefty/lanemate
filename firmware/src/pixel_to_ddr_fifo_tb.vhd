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
    PORT(
         PCLK : IN  std_logic;
         PDATA : IN  std_logic_vector(23 downto 0);
         PPUSH : IN  std_logic;
         PRESET : IN  std_logic;
         MCLK : IN  std_logic;
         MPOP : IN  std_logic;
         MDATA : OUT  std_logic_vector(255 downto 0);
         MDVALID : OUT  std_logic;
         MLIMIT : IN  std_logic_vector(7 downto 0);
         MREADY : OUT  std_logic
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
   signal PPUSH : std_logic := '0';
   signal PRESET : std_logic := '0';
   signal MCLK : std_logic := '0';
   signal MLIMIT : std_logic_vector(7 downto 0) := x"04";

	signal mpop : std_logic := '0';
	
 	--Outputs
   signal MDATA : std_logic_vector(255 downto 0);
   signal MDVALID : std_logic;
   signal MREADY : std_logic;
	
	signal pdata_out : std_logic_vector(23 downto 0);
	signal ppop : std_logic := '0';
	signal pdatavalid : std_logic;

	signal count : natural := 0;
	signal mcount : natural := 0;
	
	type state_t is (WAITING, P1, P2, P3);
	signal state : state_t := WAITING;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          PDATA => PDATA,
          PPUSH => PPUSH,
          PRESET => PRESET,
          MCLK => MCLK,
          MPOP => mpop,
          MDATA => MDATA,
          MDVALID => MDVALID,
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
		MPUSH => MDVALID,
		MDATA => MDATA
	);

	PCLK <= not PCLK after 3.367 ns; -- 1080p
	MCLK <= not MCLK after 5 ns; -- 100MHz

	process(PCLK) is
		variable n : std_logic_vector(7 downto 0);
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
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
	
	
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
	case state is
	when WAITING =>
		if(MREADY = '1') then
			mpop <= '1';
			state <= P1;
		else
			mpop <= '0';
		end if;
	when P1 =>
		mpop <= '1';
		state <= P2;
	when P2 =>
		mpop <= '1';
		state <= P3;
	when P3 =>
		mpop <= '0';
		state <= WAITING;
	end case;
	end if;
	end process;
	
END;
