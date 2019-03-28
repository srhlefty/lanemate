--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:34:15 11/03/2017
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Byron STTW/byron_sttw/firmware/adc_driver/src/binary_to_gray_tb.vhd
-- Project Name:  adc_driver
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: binary_to_gray
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
 
ENTITY binary_to_gray_tb IS
END binary_to_gray_tb;
 
ARCHITECTURE behavior OF binary_to_gray_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
	COMPONENT binary_to_gray
	generic ( DATA_WIDTH : natural );
	Port ( 
		DIN : in std_logic_vector(DATA_WIDTH-1 downto 0);
		DOUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	END COMPONENT;
	
	component gray_to_binary is
	generic ( DATA_WIDTH : natural);
	Port ( 
		DIN : in std_logic_vector(DATA_WIDTH-1 downto 0);
		DOUT : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	end component;
   
	constant DATA_WIDTH : natural := 8;
	signal DIN : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal dbus : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal DOUT : std_logic_vector(DATA_WIDTH-1 downto 0);

	signal count : natural range 0 to 255 := 0;
	signal CLK : std_logic := '0';
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: binary_to_gray 
	generic map ( DATA_WIDTH => DATA_WIDTH )
	PORT MAP (
          DIN => DIN,
          DOUT => dbus
        );
		  
   back: gray_to_binary 
	generic map ( DATA_WIDTH => DATA_WIDTH )
	PORT MAP (
          DIN => dbus,
          DOUT => DOUT
        );

	CLK <= not CLK after 4 ns;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		DIN <= std_logic_vector(to_unsigned(count, DIN'length));
	end if;
	end process;
	
END;
