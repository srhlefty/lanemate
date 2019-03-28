--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:23:35 11/03/2017
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Byron STTW/byron_sttw/firmware/adc_driver/src/gray_to_binary_tb.vhd
-- Project Name:  adc_driver
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: gray_to_binary
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
 
ENTITY gray_to_binary_tb IS
END gray_to_binary_tb;
 
ARCHITECTURE behavior OF gray_to_binary_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT gray_to_binary
	generic ( DATA_WIDTH : natural := 4);
	Port ( 
		DIN : in std_logic_vector(DATA_WIDTH-1 downto 0);
		DOUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
    END COMPONENT;
    

   --Inputs
   signal DIN : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal DOUT : std_logic_vector(3 downto 0);


	signal CLK : std_logic := '0';
	signal count : natural := 0;
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: gray_to_binary PORT MAP (
          DIN => DIN,
          DOUT => DOUT
        );

	CLK <= not CLK after 4 ns;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		if(count = 0) then
			DIN <= "0000";
		elsif(count = 1) then
			DIN <= "0001";
		elsif(count = 2) then
			DIN <= "0011";
		elsif(count = 3) then
			DIN <= "0010";
		elsif(count = 4) then
			DIN <= "0110";
		elsif(count = 5) then
			DIN <= "0111";
		elsif(count = 6) then
			DIN <= "0101";
		elsif(count = 7) then
			DIN <= "0100";
		elsif(count = 8) then
			DIN <= "1100";
		elsif(count = 9) then
			DIN <= "1101";
		elsif(count = 10) then
			DIN <= "1111";
		elsif(count = 11) then
			DIN <= "1110";
		elsif(count = 12) then
			DIN <= "1010";
		elsif(count = 13) then
			DIN <= "1011";
		elsif(count = 14) then
			DIN <= "1001";
		elsif(count = 15) then
			DIN <= "1000";
		else
			DIN <= "0000";
		end if;
	end if;
	end process;
END;
