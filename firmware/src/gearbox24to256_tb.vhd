--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:23:42 06/13/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/gearbox24to256_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gearbox24to256
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
 
ENTITY gearbox24to256_tb IS
END gearbox24to256_tb;
 
ARCHITECTURE behavior OF gearbox24to256_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT gearbox24to256
    PORT(
         PCLK : IN  std_logic;
         PDATA : IN  std_logic_vector(23 downto 0);
         PPUSH : IN  std_logic;
         PFRAME_ADDR_W : IN  std_logic_vector(23 downto 0);
         PFRAME_ADDR_R : IN  std_logic_vector(23 downto 0);
         PNEW_FRAME : IN  std_logic;
         PADDR_W : OUT  std_logic_vector(23 downto 0);
         PDATA_W : OUT  std_logic_vector(255 downto 0);
         PPUSH_W : OUT  std_logic;
         PADDR_R : OUT  std_logic_vector(23 downto 0);
         PPUSH_R : OUT  std_logic;
         PPUSHED : OUT  std_logic
        );
    END COMPONENT;
    
	component gearbox8to24 is
	Port ( 
		PCLK : in  STD_LOGIC;
		CE : in  STD_LOGIC;
		DIN : in  STD_LOGIC_VECTOR (23 downto 0);
		DE : in  STD_LOGIC;
		DOUT : out  STD_LOGIC_VECTOR (23 downto 0);
		DEOUT : out  STD_LOGIC
	);
	end component;

   --Inputs
   signal PCLK : std_logic := '0';
   signal PDATA : std_logic_vector(23 downto 0) := (others => '0');
   signal PPUSH : std_logic := '0';
   signal PFRAME_ADDR_W : std_logic_vector(23 downto 0) := (others => '0');
   signal PFRAME_ADDR_R : std_logic_vector(23 downto 0) := (others => '0');
   signal PNEW_FRAME : std_logic := '0';

 	--Outputs
   signal PADDR_W : std_logic_vector(23 downto 0);
   signal PDATA_W : std_logic_vector(255 downto 0);
   signal PPUSH_W : std_logic;
   signal PADDR_R : std_logic_vector(23 downto 0);
   signal PPUSH_R : std_logic;
   signal PPUSHED : std_logic;

	signal count : natural := 0;
	signal line_length : natural := 0;
	signal p8bit : std_logic := '0';
	
	signal ppush2 : std_logic;
	signal pdata2 : std_logic_vector(23 downto 0);

BEGIN

	Inst_gearbox8to24: gearbox8to24 PORT MAP(
		PCLK => PCLK,
		CE => p8bit,
		DIN => PDATA,
		DE => PPUSH,
		DOUT => pdata2,
		DEOUT => ppush2
	);
 
   inst_gearbox24_to_256: gearbox24to256 PORT MAP (
          PCLK => PCLK,
          PDATA => pdata2,
          PPUSH => ppush2,
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


	PCLK <= not PCLK after 6.73 ns; -- 720p
	--line_length <= 64;
	--p8bit <= '0';
	--PCLK <= not PCLK after 18.519 ns; -- 480i
	line_length <= 64*3;
	p8bit <= '1';
	
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

		if((count >= 10 and count < 10+line_length)) then
			n := std_logic_vector(to_unsigned(count-10, 8));
			if(p8bit = '1') then
				PDATA <= x"0000" & n;
			else
				PDATA <= n & n & n;
			end if;
			PPUSH <= '1';
		else
			PDATA <= (others => '0');
			PPUSH <= '0';
		end if;
		
	end if;
	end process;

END;
