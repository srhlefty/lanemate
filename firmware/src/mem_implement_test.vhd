----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:31:52 03/27/2019 
-- Design Name: 
-- Module Name:    mem_implement_test - Behavioral 
-- Project Name: 
-- Target Devices: 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity mem_implement_test is
    Port ( 
	PCLK : in  STD_LOGIC;
	MCLK : in  STD_LOGIC;
	PDATA : IN  std_logic_vector(23 downto 0);
	PPUSH : IN  std_logic;
	PDATAO : out  STD_LOGIC_VECTOR (23 downto 0);
	PPOP : in  STD_LOGIC;
	PDVALID : out STD_LOGIC
	 );
end mem_implement_test;

architecture Behavioral of mem_implement_test is

    COMPONENT pixel_to_ddr_fifo
    PORT(
         PCLK : IN  std_logic;
         PDATA : IN  std_logic_vector(23 downto 0);
         PPUSH : IN  std_logic;
         PRESET : IN  std_logic;
         MCLK : IN  std_logic;
         MPOP : IN  std_logic;
         MDATA : OUT  std_logic_vector(255 downto 0);
         MDVALID : OUT  std_logic;
         MLIMIT : IN  std_logic_vector(7 downto 0);
         MREADY : OUT  std_logic
        );
    END COMPONENT;
    
	component ddr_to_pixel_fifo is
    Port ( PCLK : in  STD_LOGIC;
           PDATA : out  STD_LOGIC_VECTOR (23 downto 0);
           PPOP : in  STD_LOGIC;
			  PDVALID : out STD_LOGIC;
			  PRESET : in STD_LOGIC;
           MCLK : in  STD_LOGIC;
			  MRESET : in STD_LOGIC;
           MPUSH : in  STD_LOGIC;
           MDATA : in  STD_LOGIC_VECTOR (255 downto 0)
           );
	end component;
	
   signal mlimit : std_logic_vector(7 downto 0) := x"04";

	signal mpop : std_logic := '0';
	
   signal mdata : std_logic_vector(255 downto 0);
   signal mdvalid : std_logic;
   signal mready : std_logic;
	
	type state_t is (WAITING, P1, P2, P3);
	signal state : state_t := WAITING;

begin

   uut: pixel_to_ddr_fifo PORT MAP (
          PCLK => PCLK,
          PDATA => PDATA,
          PPUSH => PPUSH,
          PRESET => '0',
          MCLK => MCLK,
          MPOP => mpop,
          MDATA => mdata,
          MDVALID => mdvalid,
          MLIMIT => mlimit,
          MREADY => mready
        );
	Inst_ddr_to_pixel_fifo: ddr_to_pixel_fifo PORT MAP(
		PCLK => PCLK,
		PDATA => PDATAO,
		PPOP => PPOP,
		PDVALID => PDVALID,
		PRESET => '0',
		MCLK => MCLK,
		MRESET => '0',
		MPUSH => mdvalid,
		MDATA => mdata
	);
	
	process(MCLK) is
	begin
	if(rising_edge(MCLK)) then
	case state is
	when WAITING =>
		if(mready = '1') then
			mpop <= '1';
			state <= P1;
		else
			mpop <= '0';
		end if;
	when P1 =>
		mpop <= '1';
		state <= P2;
	when P2 =>
		mpop <= '1';
		state <= P3;
	when P3 =>
		mpop <= '0';
		state <= WAITING;
	end case;
	end if;
	end process;

end Behavioral;

