--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   07:18:06 10/16/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/quadrature_decoder_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: quadrature_decoder
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
 
ENTITY quadrature_decoder_tb IS
END quadrature_decoder_tb;
 
ARCHITECTURE behavior OF quadrature_decoder_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT quadrature_decoder
    PORT(
         CLK : IN  std_logic;
         A : IN  std_logic;
         B : IN  std_logic;
         COUNT : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal A : std_logic := '0';
   signal B : std_logic := '0';

 	--Outputs
   signal COUNT : std_logic_vector(7 downto 0);

 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: quadrature_decoder PORT MAP (
          CLK => CLK,
          A => A,
          B => B,
          COUNT => COUNT
        );

	CLK <= not CLK after 5 ns;

	gen_A : block is
		signal delay : std_logic := '1';
		constant period : time := 40 ns;
	begin
		process is
		begin
			if(delay = '1') then
				wait for 40 ns;
				delay <= '0';
			end if;
			
			A <= '1';
			wait for period/2.0;
			A <= '0';
			wait for period/2.0;
			
		end process;
	end block;

	gen_B : block is
		signal delay : std_logic := '1';
		constant period : time := 40 ns;
	begin
		process is
		begin
			if(delay = '1') then
				wait for 30 ns;
				delay <= '0';
			end if;
			
			B <= '1';
			wait for period/2.0;
			B <= '0';
			wait for period/2.0;
			
		end process;
	end block;

END;
