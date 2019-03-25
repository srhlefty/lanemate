library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- This module is a FIFO but does not embed its own ram. Thus, to use it
-- you must instantiate a dual-port ram and connect it to this module.
-- The size of the ram address bus is configurable through the ADDR_WIDTH
-- generic. This FIFO can hold one fewer than the number of ram elements.

-- Data can be streamed into of the FIFO on every clock using the
-- standard pattern where the PUSH line transitions at the same time as the
-- data, i.e. to push a, b, c into the FIFO looks like this:
-- PUSH _____|-----------|_____
--      _____ ___ ___ ___ _____
-- DIN  _____X_a_X_b_X_c_X_____

-- The POP line, when high, will similarly stream data out of the FIFO.
-- But due to ram latency, the output data is valid a couple clocks after
-- POP. The DVALID line transitions with the output data just like PUSH, above:
-- DVALID _____|-----------|_____
--        _____ ___ ___ ___ _____
-- DOUT   _____X_a_X_b_X_c_X_____

-- This FIFO is "dumb", in that no attempt is made to prevent overflows or
-- underflows. It is up to the caller to decide how to avoid those situations.
-- The number of slots available and used are provided on the various clock
-- domains so that the caller can take action as appropriate. Note that as
-- you push and as you pop, the number free/used lags by one clock. Because
-- of the different clock domains, the free/used values are always going to
-- be somewhat stale. Importantly, however, they are always a lower bound:
-- FREE says *at least* how many are actually free, and USED says how many
-- *at least* are available to read.

entity fifo_2clk is
	generic (
		ADDR_WIDTH : natural := 4;
		DATA_WIDTH : natural := 8
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
end fifo_2clk;

architecture Behavioral of fifo_2clk is

	component synchronizer_2ff is
	Generic ( 
		DATA_WIDTH : natural; 
		EXTRA_INPUT_REGISTER : boolean := false;
		USE_GRAY_CODE : boolean := true
	);
	Port ( 
		CLKA   : in std_logic;
		DA     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		CLKB   : in  std_logic;
		DB     : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RESETB : in std_logic
	);
	end component;


	signal push_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal push_we : std_logic := '0';
	


	-- The last part of the signal name indicates what clock domain it's in.
	-- push_addr is modified in the write domain, pop_addr is modified in the read domain
	signal push_addr_w : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal push_addr_r : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal pop_addr_w : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal pop_addr_r : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal reset_r : std_logic;

	signal int_free : std_logic_vector(ADDR_WIDTH-1 downto 0);
	signal int_used : std_logic_vector(ADDR_WIDTH-1 downto 0);
	
	constant zero : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	constant maxsize : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '1');
	
	signal resetmask_w : std_logic;
	signal resetmask_r : std_logic;
begin

	RAM_WADDR <= push_addr_w;
	RAM_WDATA <= push_data;
	RAM_WE <= push_we;
	RAM_RESET <= RESET;
	
	RAM_RADDR <= pop_addr_r;
	DOUT <= RAM_RDATA;
	
	
	
	
	-- In a FIFO some amount of information must be shared across the two clock domains.
	-- The most basic piece of information is the pair of addresses, since they are used
	-- to determine whether pushes and pops are allowed.
	crossings : block is
		COMPONENT pulse_cross_fast2slow
		PORT(
			CLKFAST : IN  std_logic;
			TRIGIN : IN  std_logic;
			CLKSLOW : IN  std_logic;
			TRIGOUT : OUT  std_logic
		  );
		END COMPONENT;
		
 	begin
	
		reset_cross : pulse_cross_fast2slow PORT MAP(
			CLKFAST => WRITE_CLK,
			TRIGIN => RESET,
			CLKSLOW => READ_CLK,
			TRIGOUT => reset_r
		);

		cross_w_to_r : synchronizer_2ff 
		generic map( DATA_WIDTH => push_addr_w'length, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => WRITE_CLK,
			DA => push_addr_w,
			CLKB => READ_CLK,
			DB => push_addr_r,
			RESETB => '0'
		);
		
		cross_r_to_w : synchronizer_2ff 
		generic map( DATA_WIDTH => pop_addr_r'length, EXTRA_INPUT_REGISTER => false, USE_GRAY_CODE => true )
		PORT MAP(
			CLKA => READ_CLK,
			DA => pop_addr_r,
			CLKB => WRITE_CLK,
			DB => pop_addr_w,
			RESETB => '0'
		);
	
	end block;
	
	
	
	
	-- The number of elements in the FIFO is determined by doing math on the pair of addresses.
	-- The write side wants to know how much space is available, and the read side wants to
	-- know how many items are available. Due to the clock domain crossing these computed
	-- values won't always be self-consistent.
	process(WRITE_CLK) is
		variable n_maxsize : natural;
		variable n_push : natural;
		variable n_pop : natural;
		variable count : natural;
	begin
	if(rising_edge(WRITE_CLK)) then
		n_maxsize := to_integer(unsigned(maxsize));
		n_push := to_integer(unsigned(push_addr_w));
		n_pop := to_integer(unsigned(pop_addr_w));
	
		if(push_addr_w >= pop_addr_w) then
			count := n_push - n_pop;
			int_free <= std_logic_vector(to_unsigned(   n_maxsize - count   , FREE'length));
		else
			int_free <= std_logic_vector(to_unsigned(   n_pop - n_push   , FREE'length));
		end if;
	end if;
	end process;
	

	process(READ_CLK) is
		constant maxsize : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '1');
		variable n_maxsize : natural;
		variable n_push : natural;
		variable n_pop : natural;
		variable op1 : natural;
	begin
	if(rising_edge(READ_CLK)) then
		n_maxsize := to_integer(unsigned(maxsize));
		n_push := to_integer(unsigned(push_addr_r));
		n_pop := to_integer(unsigned(pop_addr_r));
	
		if(push_addr_r >= pop_addr_r) then
			int_used <= std_logic_vector(to_unsigned(   n_push - n_pop   , USED'length));
		else
			op1 := n_maxsize - n_pop;
			int_used <= std_logic_vector(to_unsigned(   op1 + n_push   , USED'length));
		end if;
	end if;
	end process;
	
	
	-- Due to the different clock domains, the two addresses are not perfectly
	-- in sync in either clock domain. This creates trouble for the reset logic,
	-- since we would like not to have a clock tick where the fifo size or space
	-- available are completely wrong. To prevent such glitches, below I create
	-- a mask lasting several clocks after the reset pulse that kills the
	-- USED and FREE outputs while it lasts.
		
	with resetmask_r select USED <=
		int_used when '0',
		zero when others;
		
	with resetmask_w select FREE <=
		int_free when '0',
		maxsize when others;

	wmask : block is
		signal d1 : std_logic := '0';
		signal d2 : std_logic := '0';
		signal d3 : std_logic := '0';
		signal d4 : std_logic := '0';
		signal d5 : std_logic := '0';
	begin
		process(WRITE_CLK) is
		begin
		if(rising_edge(WRITE_CLK)) then
			d1 <= RESET;
			d2 <= d1;
			d3 <= d2;
			d4 <= d3;
			d5 <= d4;
		end if;
		end process;
		
		resetmask_w <= d1 or d2 or d3 or d4 or d5;
	end block;
	
	rmask : block is
		signal d1 : std_logic := '0';
		signal d2 : std_logic := '0';
		signal d3 : std_logic := '0';
		signal d4 : std_logic := '0';
		signal d5 : std_logic := '0';
	begin
		process(READ_CLK) is
		begin
		if(rising_edge(READ_CLK)) then
			d1 <= reset_r;
			d2 <= d1;
			d3 <= d2;
			d4 <= d3;
			d5 <= d4;
		end if;
		end process;

		resetmask_r <= d1 or d2 or d3 or d4 or d5;
	end block;
	
	
	
	
	
	
	push_we <= PUSH;
	push_data <= DIN;
	
	writer : process(WRITE_CLK) is
	begin
	if(rising_edge(WRITE_CLK)) then
		if(RESET = '1') then
			push_addr_w <= (others => '0');
		else
			if(PUSH = '1') then
				push_addr_w <= std_logic_vector(to_unsigned(to_integer(unsigned(push_addr_w)) + 1, push_addr_w'length));
			else
			end if;
		end if;
	end if;
	end process;
	
	
	
	
	
	reader : process(READ_CLK) is
	begin
	if(rising_edge(READ_CLK)) then
		if(reset_r = '1') then
			pop_addr_r <= (others => '0');
		else
			if(POP = '1') then
				pop_addr_r <= std_logic_vector(to_unsigned(to_integer(unsigned(pop_addr_r)) + 1, pop_addr_r'length));
				DVALID <= '1';
			else
				DVALID <= '0';
			end if;
		end if;
	end if;
	end process;
	
	

end Behavioral;

