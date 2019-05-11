--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:25:26 05/11/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/source_select_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: source_select
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
 
ENTITY source_select_tb IS
END source_select_tb;
 
ARCHITECTURE behavior OF source_select_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT source_select
    PORT(
         SYSCLK : IN  std_logic;
         PIXEL_CLK : IN  std_logic;
         PIXEL_CLK_LOCKED : IN  std_logic;
         INT_VS : IN  std_logic;
         INT_HS : IN  std_logic;
         INT_DE : IN  std_logic;
         INT_D : IN  std_logic_vector(23 downto 0);
         HD_PCLK : IN  std_logic;
         HD_VS : IN  std_logic;
         HD_HS : IN  std_logic;
         HD_DE : IN  std_logic;
         HD_D : IN  std_logic_vector(23 downto 0);
         SD_PCLK : IN  std_logic;
         SD_D : IN  std_logic_vector(7 downto 0);
         SEL : IN  std_logic_vector(1 downto 0);
         OUT_VS : OUT  std_logic;
         OUT_HS : OUT  std_logic;
         OUT_DE : OUT  std_logic;
         OUT_D : OUT  std_logic_vector(23 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal SYSCLK : std_logic := '0';
   signal PIXEL_CLK : std_logic := '0';
   signal PIXEL_CLK_LOCKED : std_logic := '1';
   signal INT_VS : std_logic := '0';
   signal INT_HS : std_logic := '0';
   signal INT_DE : std_logic := '0';
   signal INT_D : std_logic_vector(23 downto 0) := (others => '0');
   signal HD_PCLK : std_logic := '0';
   signal HD_VS : std_logic := '0';
   signal HD_HS : std_logic := '0';
   signal HD_DE : std_logic := '0';
   signal HD_D : std_logic_vector(23 downto 0) := (others => '0');
   signal SD_PCLK : std_logic := '0';
   signal SD_D : std_logic_vector(7 downto 0) := (others => '0');
   signal SEL : std_logic_vector(1 downto 0) := (others => '0');

 	--Outputs
   signal OUT_VS : std_logic;
   signal OUT_HS : std_logic;
   signal OUT_DE : std_logic;
   signal OUT_D : std_logic_vector(23 downto 0);

	signal int_count : natural range 0 to 2**24-1 := 0;
	signal hd_count : natural range 0 to 2**24-1 := 0;
	signal sd_count : natural range 0 to 255 := 0;
	
	signal count : natural := 0;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: source_select PORT MAP (
          SYSCLK => SYSCLK,
          PIXEL_CLK => PIXEL_CLK,
          PIXEL_CLK_LOCKED => PIXEL_CLK_LOCKED,
          INT_VS => INT_VS,
          INT_HS => INT_HS,
          INT_DE => INT_DE,
          INT_D => INT_D,
          HD_PCLK => HD_PCLK,
          HD_VS => HD_VS,
          HD_HS => HD_HS,
          HD_DE => HD_DE,
          HD_D => HD_D,
          SD_PCLK => SD_PCLK,
          SD_D => SD_D,
          SEL => SEL,
          OUT_VS => OUT_VS,
          OUT_HS => OUT_HS,
          OUT_DE => OUT_DE,
          OUT_D => OUT_D
        );


	SYSCLK <= not SYSCLK after 5 ns;
	HD_PCLK <= not HD_PCLK after 3.367 ns;
	SD_PCLK <= not SD_PCLK after 18.519 ns;
	
	SEL <= "00";
	PIXEL_CLK <= (not PIXEL_CLK and PIXEL_CLK_LOCKED) after 6.734 ns;

	process(SYSCLK) is
	begin
	if(rising_edge(SYSCLK)) then
		count <= count + 1;
		
		if(count > 100 and count < 500) then
			PIXEL_CLK_LOCKED <= '0';
		else
			PIXEL_CLK_LOCKED <= '1';
		end if;
	end if;
	end process;



	process(PIXEL_CLK) is
	begin
	if(rising_edge(PIXEL_CLK)) then
		if(int_count = 2**24-1) then
			int_count <= 0;
		else
			int_count <= int_count + 1;
		end if;
	end if;
	end process;
	
	INT_D <= std_logic_vector(to_unsigned(int_count, INT_D'length));
	
	
	process(HD_PCLK) is
	begin
	if(rising_edge(HD_PCLK)) then
		if(hd_count = 2**24-1) then
			hd_count <= 0;
		else
			hd_count <= hd_count + 1;
		end if;
	end if;
	end process;
	
	HD_D <= std_logic_vector(to_unsigned(hd_count, HD_D'length));
	
	
	process(SD_PCLK) is
	begin
	if(rising_edge(SD_PCLK)) then
		if(sd_count = 255) then
			sd_count <= 0;
		else
			sd_count <= sd_count + 1;
		end if;
	end if;
	end process;
	
	SD_D <= std_logic_vector(to_unsigned(sd_count, SD_D'length));
	
	
	
END;
