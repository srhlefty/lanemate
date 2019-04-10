--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:48:54 04/05/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/i2c/src/i2c_master_tb.vhd
-- Project Name:  i2c
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: i2c_master
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
 
ENTITY i2c_master_tb IS
END i2c_master_tb;
 
ARCHITECTURE behavior OF i2c_master_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT i2c_master
    PORT(
         CLK : IN  std_logic;
         SLAVE_ADDR : IN  std_logic_vector(6 downto 0);
         SLAVE_REG : IN  std_logic_vector(7 downto 0);
         CMD_WRITE : IN  std_logic;
         WRITE_DATA : IN  std_logic_vector(7 downto 0);
         CMD_READ : IN  std_logic;
         REPLY_ACK : OUT  std_logic;
         REPLY_NACK : OUT  std_logic;
         REPLY_DATA : OUT  std_logic_vector(7 downto 0);
         REPLY_VALID : OUT  std_logic;
         SDA : INOUT  std_logic;
         SCL : INOUT  std_logic
        );
    END COMPONENT;
    
	component i2c_slave is
	Generic (
		SLAVE_ADDRESS : std_logic_vector(6 downto 0)
	);
	Port ( 
		CLK : in  STD_LOGIC;
		SDA : inout  STD_LOGIC;
		SCL : inout  STD_LOGIC;
		
		-- Interface to the register map, e.g. dual-port bram
		RAM_ADDR : out std_logic_vector(7 downto 0);
		RAM_WDATA : out std_logic_vector(7 downto 0);
		RAM_WE : out std_logic;
		RAM_RDATA : in std_logic_vector(7 downto 0)
	);
	end component;

   --Inputs
   signal CLK : std_logic := '0';
   signal SLAVE_ADDR : std_logic_vector(6 downto 0) := "0101100";
   signal SLAVE_REG : std_logic_vector(7 downto 0) := x"00";
   signal CMD_WRITE : std_logic := '0';
   signal WRITE_DATA : std_logic_vector(7 downto 0) := (others => '0');
   signal CMD_READ : std_logic := '0';
	signal RAM_RDATA : std_logic_vector(7 downto 0);

	--BiDirs
   signal SDA : std_logic;
   signal SCL : std_logic;

 	--Outputs
   signal REPLY_ACK : std_logic;
   signal REPLY_NACK : std_logic;
   signal REPLY_DATA : std_logic_vector(7 downto 0);
   signal REPLY_VALID : std_logic;
	
	signal RAM_ADDR : std_logic_vector(7 downto 0);
	signal RAM_WDATA : std_logic_vector(7 downto 0);
	signal RAM_WE : std_logic;


	signal count : natural := 0;
	
BEGIN

		ram : block is
		
			type ram_t is array(0 to 10) of std_logic_vector(7 downto 0);
			signal ram_data : ram_t := 
			(
				0 => x"12",
				1 => x"34",
				2 => x"56",
				3 => x"78",
				4 => x"AA",
				5 => x"BB",
				6 => x"CC",
				7 => x"DD",
				others => x"00"
			);
		
		begin
			process(CLK) is
			begin
			if(rising_edge(CLK)) then
				if(RAM_WE = '1') then
					ram_data(to_integer(unsigned(RAM_ADDR))) <= RAM_WDATA;
				end if;
				RAM_RDATA <= ram_data(to_integer(unsigned(RAM_ADDR)));
			end if;
			end process;
		end block;
		
		Inst_i2c_slave: i2c_slave 
		generic map (
			SLAVE_ADDRESS => "0101100"
		)
		PORT MAP(
			CLK => CLK,
			SDA => SDA,
			SCL => SCL,
			RAM_ADDR => RAM_ADDR,
			RAM_WDATA => RAM_WDATA,
			RAM_WE => RAM_WE,
			RAM_RDATA => RAM_RDATA
		);

 
	-- Instantiate the Unit Under Test (UUT)
   uut: i2c_master PORT MAP (
          CLK => CLK,
          SLAVE_ADDR => SLAVE_ADDR,
          SLAVE_REG => SLAVE_REG,
          CMD_WRITE => CMD_WRITE,
          WRITE_DATA => WRITE_DATA,
          CMD_READ => CMD_READ,
          REPLY_ACK => REPLY_ACK,
          REPLY_NACK => REPLY_NACK,
          REPLY_DATA => REPLY_DATA,
          REPLY_VALID => REPLY_VALID,
          SDA => SDA,
          SCL => SCL
        );


	CLK <= not CLK after 5 ns;

	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		count <= count + 1;
		
		if(count = 10) then
			SLAVE_REG <= x"00";
			--WRITE_DATA <= x"BF";
			--CMD_WRITE <= '1';
			CMD_READ <= '1';
		elsif(count = 43520) then
			SLAVE_REG <= x"01";
			CMD_READ <= '1';
		else
			CMD_WRITE <= '0';
			CMD_READ <= '0';
		end if;
	end if;
	end process;

END;
