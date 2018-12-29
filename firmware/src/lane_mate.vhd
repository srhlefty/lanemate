----------------------------------------------------------------------------------
-- Company: self
-- Engineer: Steven Hunt
-- 
-- Create Date:    09:51:02 08/17/2018 
-- Design Name: 
-- Module Name:    lane_mate - Behavioral 
-- Project Name: Lane Mate
-- Target Devices: LX25, LX45
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity lane_mate is
port (
   SYSCLK : in std_logic;
	
	I2C_SDA : inout std_logic;
	I2C_SCL : inout std_logic;
	
	HDI_PCLK : in std_logic;
	HDI_VS : in std_logic;
	HDI_HS : in std_logic;
	HDI_DE : in std_logic;
	HDI_INT : in std_logic;
	RGB_IN : in std_logic_vector(23 downto 0);
	
	HDO_PCLK : out std_logic;
	HDO_VS : out std_logic;
	HDO_HS : out std_logic;
	HDO_DE : out std_logic;
	HDO_INT : in std_logic;
	RGB_OUT : out std_logic_vector(23 downto 0);
	
	B0_GPIO0 : out std_logic;
	B1_GPIO1 : out std_logic;
	B1_GPIO2 : out std_logic;
	B1_GPIO3 : out std_logic;
	B1_GPIO4 : out std_logic;
	B1_GPIO5 : out std_logic;
	B1_GPIO6 : out std_logic;
	B1_GPIO7 : out std_logic;
	B1_GPIO8 : out std_logic;
	B1_GPIO9 : out std_logic;
	B1_GPIO10 : out std_logic;
	B1_GPIO11 : out std_logic;
	B1_GPIO12 : out std_logic;
	B1_GPIO13 : out std_logic;
	B1_GPIO14 : out std_logic;
	B1_GPIO15 : out std_logic;
	B1_GPIO24 : out std_logic;
	B1_GPIO25 : out std_logic
);
end lane_mate;

architecture Behavioral of lane_mate is

	component clock_forwarding is
    Port ( CLK : in  STD_LOGIC;
           CLKO : out  STD_LOGIC);
	end component;
	
begin

	hd_shunt : block is
		signal idata : std_logic_vector(23 downto 0) := (others => '0');
		signal ivs : std_logic := '0';
		signal ihs : std_logic := '0';
		signal ide : std_logic := '0';
		signal odata : std_logic_vector(23 downto 0);
		signal ovs : std_logic := '0';
		signal ohs : std_logic := '0';
		signal ode : std_logic := '0';
	begin
		process(HDI_PCLK) is
		begin
		if(rising_edge(HDI_PCLK)) then
			idata <= RGB_IN;
			ivs <= HDI_VS;
			ihs <= HDI_HS;
			ide <= HDI_DE;
			
			odata <= idata;
			ovs <= ivs;
			ohs <= ihs;
			ode <= ide;
			
			RGB_OUT <= odata;
			HDO_VS <= ovs;
			HDO_HS <= ohs;
			HDO_DE <= ode;
		end if;
		end process;
		
		-- TODO: adjust phase of output clock
		Inst_clock_forwarding: clock_forwarding PORT MAP(
			CLK => HDI_PCLK,
			CLKO => HDO_PCLK
		);
	
	end block;


   iobuf1 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "I2C",
      SLEW => "SLOW")
   port map (
      O => open,     -- Buffer output
      IO => I2C_SDA,   -- Buffer inout port (connect directly to top-level port)
      I => '1',     -- Buffer input
      T => '1'      -- 3-state enable input, high=input, low=output 
   );

   iobuf2 : IOBUF
   generic map (
      DRIVE => 12,
      IOSTANDARD => "I2C",
      SLEW => "SLOW")
   port map (
      O => open,     -- Buffer output
      IO => I2C_SCL,   -- Buffer inout port (connect directly to top-level port)
      I => '1',     -- Buffer input
      T => '1'      -- 3-state enable input, high=input, low=output 
   );



	blinker : block is
		signal val : std_logic_vector(15 downto 0) := x"0001";
		signal count : natural := 0;
	begin
	
		process(SYSCLK) is
		begin
		if(rising_edge(SYSCLK)) then
			if(count = 100000000 / 16) then
				count <= 0;
				val(15 downto 1) <= val(14 downto 0);
				val(0) <= val(15);
			else
				count <= count + 1;
			end if;
		end if;
		end process;
		
		B0_GPIO0 <= val(0);
		B1_GPIO1 <= val(1);
		B1_GPIO2 <= val(2);
		B1_GPIO3 <= val(3);
		B1_GPIO4 <= val(4);
		B1_GPIO5 <= val(5);
		B1_GPIO6 <= val(6);
		B1_GPIO7 <= val(7);
		B1_GPIO8 <= val(8);
		B1_GPIO9 <= val(9);
		B1_GPIO10 <= val(10);
		B1_GPIO11 <= val(11);
		B1_GPIO12 <= val(12);
		B1_GPIO13 <= val(13);
		B1_GPIO14 <= val(14);
		B1_GPIO15 <= val(15);

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

