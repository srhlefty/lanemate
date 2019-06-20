--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:48:47 06/20/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/ddr_to_pixel_fifo_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr_to_pixel_fifo
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
 
ENTITY ddr_to_pixel_fifo_tb IS
END ddr_to_pixel_fifo_tb;
 
ARCHITECTURE behavior OF ddr_to_pixel_fifo_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr_to_pixel_fifo
    PORT(
         MCLK : IN  std_logic;
         MRESET : IN  std_logic;
         MPUSH : IN  std_logic;
         MDATA : IN  std_logic_vector(255 downto 0);
         PCLK : IN  std_logic;
         PRESET : IN  std_logic;
         P8BIT : IN  std_logic;
         VS : IN  std_logic;
         HS : IN  std_logic;
         DE : IN  std_logic;
         VS_OUT : OUT  std_logic;
         HS_OUT : OUT  std_logic;
         DE_OUT : OUT  std_logic;
         D_OUT : OUT  std_logic_vector(23 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal MCLK : std_logic := '0';
   signal MRESET : std_logic := '0';
   signal MPUSH : std_logic := '0';
   signal MDATA : std_logic_vector(255 downto 0) := (others => '0');
   signal PCLK : std_logic := '0';
   signal PRESET : std_logic := '0';
   signal P8BIT : std_logic := '0';
   signal VS : std_logic := '0';
   signal HS : std_logic := '0';
   signal DE : std_logic := '0';

 	--Outputs
   signal VS_OUT : std_logic;
   signal HS_OUT : std_logic;
   signal DE_OUT : std_logic;
   signal D_OUT : std_logic_vector(23 downto 0);

	signal mcount : natural := 0;
	signal pcount : natural := 0;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ddr_to_pixel_fifo PORT MAP (
          MCLK => MCLK,
          MRESET => MRESET,
          MPUSH => MPUSH,
          MDATA => MDATA,
          PCLK => PCLK,
          PRESET => PRESET,
          P8BIT => P8BIT,
          VS => VS,
          HS => HS,
          DE => DE,
          VS_OUT => VS_OUT,
          HS_OUT => HS_OUT,
          DE_OUT => DE_OUT,
          D_OUT => D_OUT
        );

	MCLK <= not MCLK after 5 ns;
	PCLK <= not PCLK after 3.367 ns;
	
	-- There are 9 fifo elements = 96 24-bit pixels = 288 8-bit pixels
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
		mcount <= mcount + 1;
		if(mcount = 5 or mcount = 5+20) then
			MDATA <= x"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100";
			MPUSH <= '1';
		elsif(mcount = 6 or mcount = 6+20) then
			MDATA <= x"3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A29282726252423222120";
			MPUSH <= '1';
		elsif(mcount = 7 or mcount = 7+20) then
			MDATA <= x"5F5E5D5C5B5A595857565554535251504F4E4D4C4B4A49484746454443424140";
			MPUSH <= '1';
		elsif(mcount = 8 or mcount = 8+20) then
			MDATA <= x"7F7E7D7C7B7A797877767574737271706F6E6D6C6B6A69686766656463626160";
			MPUSH <= '1';
		elsif(mcount = 9 or mcount = 9+20) then
			MDATA <= x"9F9E9D9C9B9A999897969594939291908F8E8D8C8B8A89888786858483828180";
			MPUSH <= '1';
		elsif(mcount = 10 or mcount = 10+20) then
			MDATA <= x"BFBEBDBCBBBAB9B8B7B6B5B4B3B2B1B0AFAEADACABAAA9A8A7A6A5A4A3A2A1A0";
			MPUSH <= '1';
		elsif(mcount = 11 or mcount = 11+20) then
			MDATA <= x"DFDEDDDCDBDAD9D8D7D6D5D4D3D2D1D0CFCECDCCCBCAC9C8C7C6C5C4C3C2C1C0";
			MPUSH <= '1';
		elsif(mcount = 12 or mcount = 12+20) then
			MDATA <= x"FFFEFDFCFBFAF9F8F7F6F5F4F3F2F1F0EFEEEDECEBEAE9E8E7E6E5E4E3E2E1E0";
			MPUSH <= '1';
		elsif(mcount = 13 or mcount = 13+20) then
			MDATA <= x"1F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100";
			MPUSH <= '1';
		else
			MDATA <= (others => '0');
			MPUSH <= '0';
		end if;
	end if;
	end process;
	
	process(PCLK) is
	begin
	if(rising_edge(PCLK)) then
		pcount <= pcount + 1;
		if(P8BIT = '0') then
			if((pcount >= 20 and pcount < 20+96) or (pcount >= 20+96+30 and pcount < 20+96+30+96)) then
				DE <= '1';
			else
				DE <= '0';
			end if;
		else
			if((pcount >= 20 and pcount < 20+96*3) or (pcount >= 20+96*3+30 and pcount < 20+96*3+30+96*3)) then
				DE <= '1';
			else
				DE <= '0';
			end if;
		end if;
	end if;
	end process;
END;
