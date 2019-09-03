--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:47:58 07/04/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/ddr_pin_tb_bitslip_test.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr_pin_se
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
 
ENTITY ddr_pin_tb_bitslip_test IS
END ddr_pin_tb_bitslip_test;
 
ARCHITECTURE behavior OF ddr_pin_tb_bitslip_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr_pin_se
    PORT(
         CLK : IN  std_logic;
         IOCLK : IN  std_logic;
         STROBE : IN  std_logic;
         READING : IN  std_logic;
         BITSLIP : IN  std_logic;
         TXD : IN  std_logic_vector(3 downto 0);
         RXD : OUT  std_logic_vector(3 downto 0);
         PIN : INOUT  std_logic
        );
    END COMPONENT;
	 
	COMPONENT clkgen
	PORT(
		SYSCLK100 : in STD_LOGIC;
		
		CLK200 : out STD_LOGIC;
		
		B0_CLK800 : out std_logic;
		B0_STROBE800 : out std_logic;
		B0_CLK800_180 : out std_logic;
		B0_STROBE800_180 : out std_logic;

		B1_CLK800 : out std_logic;
		B1_STROBE800 : out std_logic;
		B1_CLK800_180 : out std_logic;
		B1_STROBE800_180 : out std_logic;

		B3_CLK800 : out std_logic;
		B3_STROBE800 : out std_logic;
		B3_CLK800_180 : out std_logic;
		B3_STROBE800_180 : out std_logic;
		
		LOCKED : out std_logic
		);
	END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal IOCLK : std_logic := '0';
   signal STROBE : std_logic := '0';
   signal READING : std_logic := '1';
   signal BITSLIP : std_logic := '0';
   signal TXD : std_logic_vector(3 downto 0) := (others => '0');

	--BiDirs
   signal PIN : std_logic := 'L';

 	--Outputs
   signal RXD : std_logic_vector(3 downto 0);

	signal IOCLK_180 : std_logic;
	signal STROBE_180 : std_logic;
	signal clk200 : std_logic := '0';
	signal ckp : std_logic;
 
BEGIN

	CLK <= not CLK after 5 ns;

	Inst_clkgen: clkgen PORT MAP(
		SYSCLK100 => CLK,
		CLK200 => clk200,
		B0_CLK800 => IOCLK,
		B0_STROBE800 => STROBE,
		B0_CLK800_180 => IOCLK_180,
		B0_STROBE800_180 => STROBE_180,
		B1_CLK800 => open,
		B1_STROBE800 => open,
		B1_CLK800_180 => open,
		B1_STROBE800_180 => open,
		B3_CLK800 => open,
		B3_STROBE800 => open,
		B3_CLK800_180 => open,
		B3_STROBE800_180 => open,
		LOCKED => open
	);

   clk_pin: ddr_pin_se PORT MAP (
          CLK => clk200,
          IOCLK => IOCLK,
          STROBE => STROBE,
          READING => '0',
          BITSLIP => '0',
          TXD => "1010",
          RXD => open,
          PIN => ckp
        );

   stim_pin: ddr_pin_se PORT MAP (
          CLK => clk200,
          IOCLK => IOCLK,
          STROBE => STROBE,
          READING => '0',
          BITSLIP => '0',
          TXD => TXD,
          RXD => open,
          PIN => PIN
        );
 
	-- Instantiate the Unit Under Test (UUT)
   rx_pin: ddr_pin_se PORT MAP (
          CLK => clk200,
          IOCLK => IOCLK,
          STROBE => STROBE,
          READING => '1',
          BITSLIP => BITSLIP,
          TXD => "0000",
          RXD => RXD,
          PIN => PIN
        );

	bitslip_handler : block is
		signal count : natural range 0 to 63 := 40;
		signal tries : natural range 0 to 4 := 0;
		type state_t is (STARTUP, PROBE, DELAY, EXAMINE, FINISHED, FAILED);
		signal state : state_t := STARTUP;
		signal ret : state_t := STARTUP;
	begin
	process(clk200) is
	begin
	if(rising_edge(clk200)) then
	case state is
		when STARTUP =>
			BITSLIP <= '0';
			if(count = 0) then
				state <= PROBE;
			else
				count <= count - 1;
			end if;
			
		when PROBE =>
			TXD <= "1011";
			state <= DELAY;
			ret <= EXAMINE;
			count <= 3;
		
		when DELAY =>
			TXD <= "0000";
			BITSLIP <= '0';
			
			if(count = 0) then
				state <= ret;
			else
				count <= count - 1;
			end if;
			
		when EXAMINE =>
			if(RXD /= "1011") then
				if(tries = 4) then
					state <= FAILED;
				else
					tries <= tries + 1;
					BITSLIP <= '1';
					state <= DELAY;
					ret <= PROBE;
					count <= 2;
				end if;
			else
				state <= FINISHED;
			end if;
		


			
		when FINISHED =>
			state <= FINISHED;
			
		when FAILED =>
			state <= FAILED;
			
	end case;
	end if;
	end process;
	end block;
END;
