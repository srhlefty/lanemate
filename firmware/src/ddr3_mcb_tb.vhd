--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:13:47 08/28/2019
-- Design Name:   
-- Module Name:   C:/Users/Steven/Documents/Repositories/lanemate/firmware/src/ddr3_mcb_tb.vhd
-- Project Name:  firmware
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ddr3_mcb
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

use work.pkg_types.all;
 
ENTITY ddr3_mcb_tb IS
END ddr3_mcb_tb;
 
ARCHITECTURE behavior OF ddr3_mcb_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ddr3_mcb
	 Generic( DEBUG : boolean );
    PORT(
         MCLK : IN  std_logic;
         MTRANSACTION_SIZE : IN  std_logic_vector(7 downto 0);
         MAVAIL : IN  std_logic_vector(8 downto 0);
         MFLUSH : IN  std_logic;
         MPOP_W : OUT  std_logic;
         MADDR_W : IN  std_logic_vector(26 downto 0);
         MDATA_W : IN  std_logic_vector(255 downto 0);
         MDVALID_W : IN  std_logic;
         MPOP_R : OUT  std_logic;
         MADDR_R : IN  std_logic_vector(26 downto 0);
         MDVALID_R : IN  std_logic;
         MPUSH_R : OUT  std_logic;
         MDATA_R : OUT  std_logic_vector(255 downto 0);
			MFORCE_INIT : in std_logic;
         MTEST : IN  std_logic;
         MDEBUG_LED : OUT  std_logic_vector(7 downto 0);
			MDEBUG_SYNC : out std_logic;
         MADDITIVE_LATENCY : IN  std_logic_vector(1 downto 0);
         MCAS_LATENCY : IN  std_logic_vector(3 downto 0);
         B0_IOCLK : IN  std_logic;
         B0_STROBE : IN  std_logic;
         B0_IOCLK_180 : IN  std_logic;
         B0_STROBE_180 : IN  std_logic;
         B1_IOCLK : IN  std_logic;
         B1_STROBE : IN  std_logic;
         B1_IOCLK_180 : IN  std_logic;
         B1_STROBE_180 : IN  std_logic;
         B3_IOCLK : IN  std_logic;
         B3_STROBE : IN  std_logic;
         B3_IOCLK_180 : IN  std_logic;
         B3_STROBE_180 : IN  std_logic;
			IOCLK_LOCKED : in std_logic;
         DDR_RESET : INOUT  std_logic;
         CK0_P : INOUT  std_logic;
         CK0_N : INOUT  std_logic;
         CKE0 : INOUT  std_logic;
         CK1_P : INOUT  std_logic;
         CK1_N : INOUT  std_logic;
         CKE1 : INOUT  std_logic;
         RAS : INOUT  std_logic;
         CAS : INOUT  std_logic;
         WE : INOUT  std_logic;
         CS0 : INOUT  std_logic;
         CS1 : INOUT  std_logic;
         BA : INOUT  std_logic_vector(2 downto 0);
         MA : INOUT  std_logic_vector(15 downto 0);
         DM : INOUT  std_logic_vector(7 downto 0);
         DQSP : INOUT  std_logic_vector(7 downto 0);
         DQSN : INOUT  std_logic_vector(7 downto 0);
         DQ : INOUT  std_logic_vector(63 downto 0)
        );
    END COMPONENT;
    
	component clkgen is
	Port ( 
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
	end component;

	component bram_simple_dual_port is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
	);
    Port ( 
		CLK1 : in std_logic;
		WADDR1 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		WDATA1 : in std_logic_vector (DATA_WIDTH-1 downto 0);
		WE1    : in std_logic;

		CLK2 : in std_logic;
		RADDR2 : in std_logic_vector (ADDR_WIDTH-1 downto 0);
		RDATA2 : out std_logic_vector (DATA_WIDTH-1 downto 0)
	);
	end component;
	
	component fifo_2clk is
	generic (
		ADDR_WIDTH : natural;
		DATA_WIDTH : natural
	);
    Port ( 
		WRITE_CLK  : in std_logic;
		RESET      : in std_logic;
		FREE       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		DIN        : in std_logic_vector (DATA_WIDTH-1 downto 0);
		PUSH       : in std_logic;

		READ_CLK : in std_logic;
		USED     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		DOUT     : out std_logic_vector (DATA_WIDTH-1 downto 0);
		DVALID   : out std_logic;
		POP      : in std_logic;
		
		-- Dual port ram interface, optionally erasable. Note you wire clocks.
		RAM_WADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_WDATA : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RAM_WE    : out std_logic;
		RAM_RESET : out std_logic;
		
		RAM_RADDR : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_RDATA : in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
	end component;
	
   --Inputs
   signal MCLK : std_logic := '0';
   signal MTRANSACTION_SIZE : std_logic_vector(7 downto 0) := x"10";
   signal MAVAIL : std_logic_vector(8 downto 0) := (others => '0');
   signal MFLUSH : std_logic := '0';
   signal MADDR_W : std_logic_vector(26 downto 0) := (others => '0');
   signal MDATA_W : std_logic_vector(255 downto 0) := (others => '0');
   signal MDVALID_W : std_logic := '0';
   signal MADDR_R : std_logic_vector(26 downto 0) := (others => '0');
   signal MDVALID_R : std_logic := '0';
   signal MFORCE_INIT : std_logic := '0';
   signal MTEST : std_logic := '0';
   signal MADDITIVE_LATENCY : std_logic_vector(1 downto 0) := "00";
   signal MCAS_LATENCY : std_logic_vector(3 downto 0) := "0010";
   signal B0_IOCLK : std_logic := '0';
   signal B0_STROBE : std_logic := '0';
   signal B0_IOCLK_180 : std_logic := '0';
   signal B0_STROBE_180 : std_logic := '0';
   signal B1_IOCLK : std_logic := '0';
   signal B1_STROBE : std_logic := '0';
   signal B1_IOCLK_180 : std_logic := '0';
   signal B1_STROBE_180 : std_logic := '0';
   signal B3_IOCLK : std_logic := '0';
   signal B3_STROBE : std_logic := '0';
   signal B3_IOCLK_180 : std_logic := '0';
   signal B3_STROBE_180 : std_logic := '0';

	--BiDirs
   signal DDR_RESET : std_logic;
   signal CK0_P : std_logic;
   signal CK0_N : std_logic;
   signal CKE0 : std_logic;
   signal CK1_P : std_logic;
   signal CK1_N : std_logic;
   signal CKE1 : std_logic;
   signal RAS : std_logic;
   signal CAS : std_logic;
   signal WE : std_logic;
   signal CS0 : std_logic;
   signal CS1 : std_logic;
   signal BA : std_logic_vector(2 downto 0);
   signal MA : std_logic_vector(15 downto 0);
   signal DM : std_logic_vector(7 downto 0);
   signal DQSP : std_logic_vector(7 downto 0);
   signal DQSN : std_logic_vector(7 downto 0);
   signal DQ : std_logic_vector(63 downto 0);

 	--Outputs
   signal MPOP_W : std_logic;
   signal MPOP_R : std_logic;
   signal MPUSH_R : std_logic;
   signal MDATA_R : std_logic_vector(255 downto 0);
   signal MDEBUG_LED : std_logic_vector(7 downto 0);
	signal MDEBUG_SYNC : std_logic;
	signal LOCKED : std_logic;


	signal SYSCLK : std_logic := '0';
	signal PCLK : std_logic := '0';

	signal b0_serdesclk : std_logic;
	signal b0_serdesstrobe : std_logic;
	signal b0_serdesclk_180 : std_logic;
	signal b0_serdesstrobe_180 : std_logic;
	signal b1_serdesclk : std_logic;
	signal b1_serdesstrobe : std_logic;
	signal b1_serdesclk_180 : std_logic;
	signal b1_serdesstrobe_180 : std_logic;
	signal b3_serdesclk : std_logic;
	signal b3_serdesstrobe : std_logic;
	signal b3_serdesclk_180 : std_logic;
	signal b3_serdesstrobe_180 : std_logic;
	

	signal PADDR_W :std_logic_vector(26 downto 0) := (others => '0');
	signal PDATA_W : std_logic_vector(255 downto 0) := (others => '0');
	signal PPUSH_W : std_logic := '0';

	signal count : natural := 0;
	
BEGIN

	SYSCLK <= not SYSCLK after 5 ns; -- external crystal is 100MHz
	PCLK <= not PCLK after 3.367 ns; -- 148.5MHz (1080p60)
	
	Inst_clkgen: clkgen PORT MAP(
		SYSCLK100        => SYSCLK,
		CLK200           => MCLK,
		B0_CLK800        => b0_serdesclk,
		B0_STROBE800     => b0_serdesstrobe,
		B0_CLK800_180    => b0_serdesclk_180,
		B0_STROBE800_180 => b0_serdesstrobe_180,
		B1_CLK800        => b1_serdesclk,
		B1_STROBE800     => b1_serdesstrobe,
		B1_CLK800_180    => b1_serdesclk_180,
		B1_STROBE800_180 => b1_serdesstrobe_180,
		B3_CLK800        => b3_serdesclk,
		B3_STROBE800     => b3_serdesstrobe,
		B3_CLK800_180    => b3_serdesclk_180,
		B3_STROBE800_180 => b3_serdesstrobe_180,
		LOCKED           => LOCKED
	);


 
	-- Instantiate the Unit Under Test (UUT)
   uut: ddr3_mcb 
	Generic map ( DEBUG => true )
	PORT MAP (
          MCLK => MCLK,
          MTRANSACTION_SIZE => MTRANSACTION_SIZE,
          MAVAIL => MAVAIL,
          MFLUSH => MFLUSH,
			 
          MPOP_W => MPOP_W,
          MADDR_W => MADDR_W,
          MDATA_W => MDATA_W,
          MDVALID_W => MDVALID_W,
			 
          MPOP_R => MPOP_R,
          MADDR_R => MADDR_R,
          MDVALID_R => MDVALID_R,
			 
          MPUSH_R => MPUSH_R,
          MDATA_R => MDATA_R,
			 
          MFORCE_INIT => MFORCE_INIT,
          MTEST => MTEST,
          MDEBUG_LED => MDEBUG_LED,
			 MDEBUG_SYNC => MDEBUG_SYNC,
			 
          MADDITIVE_LATENCY => MADDITIVE_LATENCY,
          MCAS_LATENCY => MCAS_LATENCY,
			 
			B0_IOCLK      => b0_serdesclk,
			B0_STROBE     => b0_serdesstrobe,
			B0_IOCLK_180  => b0_serdesclk_180,
			B0_STROBE_180 => b0_serdesstrobe_180,
			B1_IOCLK      => b1_serdesclk,
			B1_STROBE     => b1_serdesstrobe,
			B1_IOCLK_180  => b1_serdesclk_180,
			B1_STROBE_180 => b1_serdesstrobe_180,
			B3_IOCLK      => b3_serdesclk,
			B3_STROBE     => b3_serdesstrobe,
			B3_IOCLK_180  => b3_serdesclk_180,
			B3_STROBE_180 => b3_serdesstrobe_180,
			
			IOCLK_LOCKED => LOCKED,
			 
          DDR_RESET => DDR_RESET,
          CK0_P => CK0_P,
          CK0_N => CK0_N,
          CKE0 => CKE0,
          CK1_P => CK1_P,
          CK1_N => CK1_N,
          CKE1 => CKE1,
          RAS => RAS,
          CAS => CAS,
          WE => WE,
          CS0 => CS0,
          CS1 => CS1,
          BA => BA,
          MA => MA,
          DM => DM,
          DQSP => DQSP,
          DQSN => DQSN,
          DQ => DQ
        );


	writer_fifo_block : block is
		constant ram_addr_width : natural := 9;
		constant ram_data_width_w : natural := 256 + 27; -- 256 for data, 27 for address
		constant ram_data_width_r : natural := 27; -- just address
		
		signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_wdata1 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0);
		signal ram_rdata2 : std_logic_vector(ram_data_width_w-1 downto 0);
		signal ram_we : std_logic;
		signal bus_in : std_logic_vector(ram_data_width_w-1 downto 0);
		signal bus_out : std_logic_vector(ram_data_width_w-1 downto 0);
	begin
	
		write_bram: bram_simple_dual_port 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_w
		)
		PORT MAP(
			CLK1 => PCLK,
			WADDR1 => ram_waddr1,
			WDATA1 => ram_wdata1,
			WE1 => ram_we,
			CLK2 => MCLK,
			RADDR2 => ram_raddr2,
			RDATA2 => ram_rdata2
		);
		
		bus_in(ram_data_width_w-1 downto ram_data_width_w-27) <= PADDR_W;
		bus_in(ram_data_width_w-27-1 downto 0)                <= PDATA_W;
	
		write_fifo: fifo_2clk 
		generic map(
			ADDR_WIDTH => ram_addr_width,
			DATA_WIDTH => ram_data_width_w
		)
		PORT MAP(
			WRITE_CLK => PCLK,
			RESET => '0',
			FREE => open,
			DIN => bus_in,
			PUSH => PPUSH_W,
			READ_CLK => MCLK,
			USED => MAVAIL,
			DOUT => bus_out,
			DVALID => MDVALID_W,
			POP => MPOP_W,
			RAM_WADDR => ram_waddr1,
			RAM_WDATA => ram_wdata1,
			RAM_WE => ram_we,
			RAM_RESET => open,
			RAM_RADDR => ram_raddr2,
			RAM_RDATA => ram_rdata2
		);
		
		MADDR_W <= bus_out(ram_data_width_w-1 downto ram_data_width_w-27); -- 27 bits wide
		MDATA_W <= bus_out(ram_data_width_w-27-1 downto 0);                -- 256 bits wide
		
	end block;


	----------------------------------------------------------------------------

	-- Fill FIFO with data-to-write
	filler : block is
		type state_t is (IDLE, FILLING);
		signal state : state_t := FILLING;
		constant TEST_WORD1 : burst_t(63 downto 0) := 
		(
			x"0",x"1",x"2",x"3",x"4",x"5",x"6",x"7",x"8",x"9",x"A",x"B",x"C",x"D",x"E",x"F",
			x"F",x"E",x"D",x"C",x"B",x"A",x"9",x"8",x"7",x"6",x"5",x"4",x"3",x"2",x"1",x"0",
			x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",
			x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F",x"D",x"E",x"A",x"D",x"B",x"E",x"E",x"F"
		);
		constant TEST_WORD2 : burst_t(63 downto 0) :=
		(
			x"4",x"3",x"b",x"c",x"e",x"d",x"a",x"6",x"f",x"5",x"a",x"8",x"d",x"e",x"e",x"f",
			x"8",x"9",x"4",x"7",x"b",x"7",x"7",x"e",x"7",x"e",x"2",x"b",x"f",x"2",x"3",x"c",
			x"2",x"4",x"5",x"c",x"b",x"3",x"7",x"f",x"7",x"b",x"c",x"7",x"d",x"6",x"6",x"7",
			x"3",x"e",x"9",x"4",x"f",x"8",x"d",x"9",x"6",x"e",x"c",x"f",x"8",x"c",x"2",x"1"
		);
		constant TEST_ADDR : std_logic_vector(26 downto 0) := "0" & "000" & x"0000" & "0000000";
		
		procedure burst_to_flat(
			variable flat : out std_logic_vector(255 downto 0);
			constant burst : in burst_t(63 downto 0)
		) is
		begin
			for i in 0 to burst'high loop
				flat(4*i+3 downto 4*i) := burst(i);
			end loop;
		end procedure;
		
		procedure build_addr(
			variable addr : out std_logic_vector(26 downto 0);
			constant rank : in std_logic;
			constant bank : in std_logic_vector(2 downto 0);
			constant row  : in std_logic_vector(15 downto 0);
			constant col  : in std_logic_vector(6 downto 0)
		) is
		begin
			addr := rank & bank & row & col;
		end procedure;
		
		
		signal count : natural := 0;
	begin
		process(PCLK) is
			variable wdata : std_logic_vector(255 downto 0);
			variable vcount : std_logic_vector(255 downto 0);
			variable base_addr : std_logic_vector(26 downto 0);
			variable vaddr : natural;
			variable vaddrinc : natural;
			variable newaddr : std_logic_vector(26 downto 0);
		begin
		if(rising_edge(PCLK)) then
		case state is
		
			when IDLE =>
				PADDR_W <= (others => '0');
				PDATA_W <= (others => '0');
				PPUSH_W <= '0';
				state <= IDLE;
			
			when FILLING =>
				if(count < 2) then
					base_addr := '0' & "000" & x"0000" & "0000000";
				else
					base_addr := '0' & "000" & x"1000" & "0000000";
				end if;
				vaddr := to_integer(unsigned(base_addr));
				vaddrinc := vaddr + count / 2;
				newaddr := std_logic_vector(to_unsigned(vaddrinc, newaddr'length));
				if(count mod 2 = 0) then
					burst_to_flat(wdata, TEST_WORD1);
					PADDR_W <= newaddr;
					PDATA_W <= wdata;
					PPUSH_W <= '1';
				else
					burst_to_flat(wdata, TEST_WORD2);
					PADDR_W <= newaddr;
					PDATA_W <= wdata;
					PPUSH_W <= '1';
				end if;
				
				if(count = 29) then
					state <= IDLE;
				else
					count <= count + 1;
				end if;
		end case;
		end if;
		end process;
	end block;

	process(MCLK) is
	begin
	if(rising_edge(MCLK) and LOCKED = '1') then
		count <= count + 1;
		if(count = 64) then
			MTEST <= '1';
		else
			MTEST <= '0';
		end if;
	end if;
	end process;


END;
