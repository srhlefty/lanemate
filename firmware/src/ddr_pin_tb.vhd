--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:43:47 07/02/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/ddr_pin_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr_pin
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
 
ENTITY ddr_pin_tb IS
END ddr_pin_tb;
 
ARCHITECTURE behavior OF ddr_pin_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr_pin
    PORT(
         CLK : IN  std_logic;
         IOCLK : IN  std_logic;
         STROBE : IN  std_logic;
         READING : IN  std_logic;
         TXD : IN  std_logic_vector(3 downto 0);
         RXD : OUT  std_logic_vector(3 downto 0);
         PIN : INOUT  std_logic
        );
    END COMPONENT;
    
	COMPONENT clkgen
	PORT(
		SYSCLK100 : IN std_logic;          
		CLK200 : OUT std_logic;
		CLK800 : OUT std_logic;
		STROBE800 : OUT std_logic;
		CLK800_180 : OUT std_logic;
		STROBE800_180 : OUT std_logic
		);
	END COMPONENT;

   --Inputs
   signal CLK : std_logic := '0';
   signal IOCLK : std_logic := '0';
   signal IOCLK_180 : std_logic := '0';
   signal STROBE : std_logic := '0';
   signal STROBE_180 : std_logic := '0';
   signal READING : std_logic := '0';
   signal TXD : std_logic_vector(3 downto 0) := (others => '0');

	--BiDirs
   signal PIN : std_logic := 'H';

 	--Outputs
   signal RXD : std_logic_vector(3 downto 0);
	signal CKP : std_logic;

	signal clk200 : std_logic;
	signal count : natural := 0;
	signal val : natural range 1 to 15 := 1;
 
BEGIN

	CLK <= not CLK after 5 ns;

	Inst_clkgen: clkgen PORT MAP(
		SYSCLK100 => CLK,
		CLK200 => clk200,
		CLK800 => IOCLK,
		STROBE800 => STROBE,
		CLK800_180 => IOCLK_180,
		STROBE800_180 => STROBE_180
	);
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ddr_pin PORT MAP (
          CLK => clk200,
          IOCLK => IOCLK,
          STROBE => STROBE,
          READING => READING,
          TXD => TXD,
          RXD => RXD,
          PIN => PIN
        );
   clk_pin: ddr_pin PORT MAP (
          CLK => clk200,
          IOCLK => IOCLK_180,
          STROBE => STROBE_180,
          READING => '0',
          TXD => "1010",
          RXD => open,
          PIN => CKP
        );


	process(clk200) is
	begin
	if(rising_edge(clk200)) then
		count <= count + 1;
		if(count mod 10 = 0) then
			TXD <= std_logic_vector(to_unsigned(val, TXD'length));
			if(val = 15) then
				val <= 1;
			else
				val <= val + 1;
			end if;
		else
			TXD <= (others => '0');
		end if;
	end if;
	end process;
	
END;
