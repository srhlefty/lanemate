--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:13:36 06/13/2019
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
         MCLK : IN  std_logic;
         PDE : IN  std_logic;
         PPUSHED : IN  std_logic;
         PADDR_W : IN  std_logic_vector(23 downto 0);
         PDATA_W : IN  std_logic_vector(255 downto 0);
         PPUSH_W : IN  std_logic;
         MPOP_W : IN  std_logic;
         MADDR_W : OUT  std_logic_vector(23 downto 0);
         MDATA_W : OUT  std_logic_vector(255 downto 0);
         MDVALID_W : OUT  std_logic;
         PADDR_R : IN  std_logic_vector(23 downto 0);
         PPUSH_R : IN  std_logic;
         MPOP_R : IN  std_logic;
         MADDR_R : OUT  std_logic_vector(23 downto 0);
         MDVALID_R : OUT  std_logic;
         MAVAIL : OUT  std_logic_vector(8 downto 0);
         MFLUSH : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal PCLK : std_logic := '0';
   signal MCLK : std_logic := '0';
   signal PDE : std_logic := '0';
   signal PPUSHED : std_logic := '0';
   signal PADDR_W : std_logic_vector(23 downto 0) := (others => '0');
   signal PDATA_W : std_logic_vector(255 downto 0) := (others => '0');
   signal PPUSH_W : std_logic := '0';
   signal MPOP_W : std_logic := '0';
   signal PADDR_R : std_logic_vector(23 downto 0) := (others => '0');
   signal PPUSH_R : std_logic := '0';
   signal MPOP_R : std_logic := '0';

 	--Outputs
   signal MADDR_W : std_logic_vector(23 downto 0);
   signal MDATA_W : std_logic_vector(255 downto 0);
   signal MDVALID_W : std_logic;
   signal MADDR_R : std_logic_vector(23 downto 0);
   signal MDVALID_R : std_logic;
   signal MAVAIL : std_logic_vector(8 downto 0);
   signal MFLUSH : std_logic;

	signal count : natural := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          MCLK => MCLK,
          PDE => PDE,
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

	PCLK <= not PCLK after 6.73 ns; -- 720p
	MCLK <= not MCLK after 5 ns; -- 100 MHz
	
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		count <= count + 1;
		if(count >= 10 and count < 50) then
			PDE <= '1';
		else
			PDE <= '0';
		end if;
		
		if(count = 12) then
			PADDR_W <= x"000000";
			PDATA_W <= x"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 13) then
			PADDR_W <= x"000000";
			PDATA_W <= x"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 14) then
			PADDR_W <= x"000001";
			PDATA_W <= x"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 15) then
			PPUSH_W <= '0';
			PPUSH_R <= '0';
			PPUSHED <= '1';
			
		elsif(count = 30) then
			PADDR_W <= x"000001";
			PDATA_W <= x"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 31) then
			PADDR_W <= x"000002";
			PDATA_W <= x"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 32) then
			PADDR_W <= x"000002";
			PDATA_W <= x"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 33) then
			PPUSH_W <= '0';
			PPUSH_R <= '0';
			PPUSHED <= '1';
			
		elsif(count = 50) then
			PADDR_W <= x"000001";
			PDATA_W <= x"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 51) then
			PADDR_W <= x"000002";
			PDATA_W <= x"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 52) then
			PADDR_W <= x"000002";
			PDATA_W <= x"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140";
			PPUSH_W <= '1';
			PADDR_R <= x"000000";
			PPUSH_R <= '1';
			PPUSHED <= '0';
		elsif(count = 53) then
			PPUSH_W <= '0';
			PPUSH_R <= '0';
			PPUSHED <= '1';
			
		else
			PPUSH_W <= '0';
			PPUSH_R <= '0';
			PPUSHED <= '0';
		end if;
		
	end if;
	end process;
	
	mcb_sim : block is
		type state_t is (WAITING, POPPING, REST);
		signal state : state_t := WAITING;
		constant limit : natural := 2;
		signal popcount : natural := 0;
	begin
	
		process(MCLK) is
		begin
		if(rising_edge(MCLK)) then
		case state is
		when WAITING =>
			MPOP_W <= '0';
			if(to_integer(unsigned(MAVAIL)) >= limit) then
				popcount <= 0;
				state <= POPPING;
			end if;
		
		when POPPING =>
			popcount <= popcount + 1;
			if(popcount = limit) then
				MPOP_W <= '0';
				state <= REST;
			else
				MPOP_W <= '1';
			end if;
			
		when REST =>
			state <= WAITING;
		end case;
		end if;
		end process;
	
	end block;

END;
