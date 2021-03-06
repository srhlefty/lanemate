--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:15:49 06/20/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/lane_mate_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lane_mate
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
--USE ieee.numeric_std.ALL;
 
ENTITY lane_mate_tb IS
END lane_mate_tb;
 
ARCHITECTURE behavior OF lane_mate_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lane_mate
    PORT(
         SYSCLK : IN  std_logic;
         I2C_SDA : INOUT  std_logic;
         I2C_SCL : INOUT  std_logic;
         HDI_PCLK : IN  std_logic;
         HDI_VS : IN  std_logic;
         HDI_HS : IN  std_logic;
         HDI_DE : IN  std_logic;
         HDI_INT : IN  std_logic;
         RGB_IN : IN  std_logic_vector(23 downto 0);
         SDI_PCLK : IN  std_logic;
         SDI_HS : IN  std_logic;
         SDI_VS : IN  std_logic;
         SDI_INT : IN  std_logic;
         SDV : IN  std_logic_vector(7 downto 0);
         HDO_PCLK : OUT  std_logic;
         HDO_VS : OUT  std_logic;
         HDO_HS : OUT  std_logic;
         HDO_DE : OUT  std_logic;
         HDO_INT : IN  std_logic;
         RGB_OUT : OUT  std_logic_vector(23 downto 0);
         B0_GPIO0 : OUT  std_logic;
         B1_GPIO1 : OUT  std_logic;
         B1_GPIO2 : OUT  std_logic;
         B1_GPIO3 : OUT  std_logic;
         B1_GPIO4 : OUT  std_logic;
         B1_GPIO5 : OUT  std_logic;
         B1_GPIO6 : OUT  std_logic;
         B1_GPIO7 : OUT  std_logic;
         B1_GPIO8 : OUT  std_logic;
         B1_GPIO9 : OUT  std_logic;
         B1_GPIO10 : OUT  std_logic;
         B1_GPIO11 : OUT  std_logic;
         B1_GPIO12 : OUT  std_logic;
         B1_GPIO13 : OUT  std_logic;
         B1_GPIO14 : OUT  std_logic;
         B1_GPIO15 : OUT  std_logic;
         B1_GPIO24 : OUT  std_logic;
         B1_GPIO25 : OUT  std_logic
        );
    END COMPONENT;

	component timing_gen is
    Port ( CLK : in  STD_LOGIC;
	        RST : in std_logic;
           SEL : in  STD_LOGIC_VECTOR (1 downto 0);
           VS : out  STD_LOGIC;
           HS : out  STD_LOGIC;
           DE : out  STD_LOGIC;
           D : out  STD_LOGIC_VECTOR (23 downto 0));
	end component;
	
    

   --Inputs
   signal SYSCLK : std_logic := '0';
   signal HDI_PCLK : std_logic := '0';
   signal HDI_VS : std_logic := '0';
   signal HDI_HS : std_logic := '0';
   signal HDI_DE : std_logic := '0';
   signal HDI_INT : std_logic := '0';
   signal RGB_IN : std_logic_vector(23 downto 0) := (others => '0');
   signal SDI_PCLK : std_logic := '0';
   signal SDI_HS : std_logic := '0';
   signal SDI_VS : std_logic := '0';
   signal SDI_INT : std_logic := '0';
   signal SDV : std_logic_vector(7 downto 0) := (others => '0');
   signal HDO_INT : std_logic := '0';

	--BiDirs
   signal I2C_SDA : std_logic;
   signal I2C_SCL : std_logic;

 	--Outputs
   signal HDO_PCLK : std_logic;
   signal HDO_VS : std_logic;
   signal HDO_HS : std_logic;
   signal HDO_DE : std_logic;
   signal RGB_OUT : std_logic_vector(23 downto 0);
   signal B0_GPIO0 : std_logic;
   signal B1_GPIO1 : std_logic;
   signal B1_GPIO2 : std_logic;
   signal B1_GPIO3 : std_logic;
   signal B1_GPIO4 : std_logic;
   signal B1_GPIO5 : std_logic;
   signal B1_GPIO6 : std_logic;
   signal B1_GPIO7 : std_logic;
   signal B1_GPIO8 : std_logic;
   signal B1_GPIO9 : std_logic;
   signal B1_GPIO10 : std_logic;
   signal B1_GPIO11 : std_logic;
   signal B1_GPIO12 : std_logic;
   signal B1_GPIO13 : std_logic;
   signal B1_GPIO14 : std_logic;
   signal B1_GPIO15 : std_logic;
   signal B1_GPIO24 : std_logic;
   signal B1_GPIO25 : std_logic;

   -- Clock period definitions
   constant SYSCLK_period : time := 10 ns;
   constant HDI_PCLK_period : time := 10 ns;
   constant SDI_PCLK_period : time := 10 ns;
   constant HDO_PCLK_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lane_mate PORT MAP (
          SYSCLK => SYSCLK,
          I2C_SDA => I2C_SDA,
          I2C_SCL => I2C_SCL,
          HDI_PCLK => HDI_PCLK,
          HDI_VS => HDI_VS,
          HDI_HS => HDI_HS,
          HDI_DE => HDI_DE,
          HDI_INT => HDI_INT,
          RGB_IN => RGB_IN,
          SDI_PCLK => SDI_PCLK,
          SDI_HS => SDI_HS,
          SDI_VS => SDI_VS,
          SDI_INT => SDI_INT,
          SDV => SDV,
          HDO_PCLK => HDO_PCLK,
          HDO_VS => HDO_VS,
          HDO_HS => HDO_HS,
          HDO_DE => HDO_DE,
          HDO_INT => HDO_INT,
          RGB_OUT => RGB_OUT,
          B0_GPIO0 => B0_GPIO0,
          B1_GPIO1 => B1_GPIO1,
          B1_GPIO2 => B1_GPIO2,
          B1_GPIO3 => B1_GPIO3,
          B1_GPIO4 => B1_GPIO4,
          B1_GPIO5 => B1_GPIO5,
          B1_GPIO6 => B1_GPIO6,
          B1_GPIO7 => B1_GPIO7,
          B1_GPIO8 => B1_GPIO8,
          B1_GPIO9 => B1_GPIO9,
          B1_GPIO10 => B1_GPIO10,
          B1_GPIO11 => B1_GPIO11,
          B1_GPIO12 => B1_GPIO12,
          B1_GPIO13 => B1_GPIO13,
          B1_GPIO14 => B1_GPIO14,
          B1_GPIO15 => B1_GPIO15,
          B1_GPIO24 => B1_GPIO24,
          B1_GPIO25 => B1_GPIO25
        );


	Inst_timing_gen: timing_gen PORT MAP(
		CLK => HDI_PCLK,
		RST => '0',
		SEL => "01",
		VS => HDI_VS,
		HS => HDI_HS,
		DE => HDI_DE,
		D => open
	);

	SYSCLK <= not SYSCLK after 5 ns;
	HDI_PCLK <= not HDI_PCLK after 6.734 ns; -- 74.25 MHz

END;
