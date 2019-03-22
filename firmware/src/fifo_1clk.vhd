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

-- The POP line, when held high, will similarly stream data out of the FIFO.
-- But due to ram latency, the output data is valid a couple clocks after
-- POP. The DVALID line transitions with the output data just like PUSH, above:
-- DVALID _____|-----------|_____
--        _____ ___ ___ ___ _____
-- DOUT   _____X_a_X_b_X_c_X_____

-- When the FIFO is full, further PUSHes are rejected: the data at that clock
-- is lost. This condition is indicated by the OVERFLOW output.

-- It is easy to empty the FIFO without knowing how many elements it contains.
-- Simply pull POP high until EMPTY goes high, then release POP.

entity fifo_1clk is
	generic (
		ADDR_WIDTH : natural := 8;
		DATA_WIDTH : natural := 8
	);
    Port ( 
		CLK : in std_logic;
		
		DIN  : in std_logic_vector (DATA_WIDTH-1 downto 0);
		PUSH : in std_logic;
		
		POP  : in std_logic;
		DOUT : out  std_logic_vector (DATA_WIDTH-1 downto 0);
		DVALID : out std_logic;
		
		RESET : in std_logic;
		
		EMPTY : out std_logic;
		OVERFLOW : out std_logic;
		
		-- dual port ram interface
		
		RAM_WADDR1 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_WDATA1 : out std_logic_vector(DATA_WIDTH-1 downto 0);
		RAM_WE1    : out std_logic;
		
		RAM_RADDR2 : out std_logic_vector(ADDR_WIDTH-1 downto 0);
		RAM_RDATA2 : in std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end fifo_1clk;

architecture Behavioral of fifo_1clk is

	signal push_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
	signal push_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal push_we : std_logic := '0';
	
	signal pop_addr : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');

	signal valid_d : std_logic := '0';
	
begin

	RAM_WADDR1 <= push_addr;
	RAM_WDATA1 <= push_data;
	RAM_WE1 <= push_we;
	
	RAM_RADDR2 <= pop_addr;
	DOUT <= RAM_RDATA2;
	
	process(CLK) is
		variable next_push_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
		variable next_pop_addr : std_logic_vector(ADDR_WIDTH-1 downto 0);
		variable is_empty : boolean;
		variable is_full : boolean;
		variable is_normal : boolean;
		variable push_accepted : boolean;
		variable pop_accepted : boolean;
	begin
	if(rising_edge(CLK)) then
	
		if(RESET = '1') then
			push_addr <= (others => '0');
			pop_addr <= (others => '0');
			EMPTY <= '1';
		else
			next_push_addr := std_logic_vector(to_unsigned(to_integer(unsigned(push_addr)) + 1, push_addr'length));
			next_pop_addr := std_logic_vector(to_unsigned(to_integer(unsigned(pop_addr)) + 1, pop_addr'length));
			
			-- Define push_addr = pop_addr to be the empty state.
			is_empty := (push_addr = pop_addr);
			
			-- Define push_addr = pop_addr-1 to be the full state.
			is_full := (next_push_addr = pop_addr);
			
			is_normal := (not is_empty) and (not is_full);
			
			-- A push is valid when normal or empty, but not full
			if(PUSH = '1' and (is_normal or is_empty)) then
				push_accepted := true;
			else
				push_accepted := false;
			end if;
			
			-- A pop is valid when normal or full, but not empty
			if(POP = '1' and (is_normal or is_full)) then
				pop_accepted := true;
			else
				pop_accepted := false;
			end if;
			
			-- When a push is accepted, transition the address, data, and enable lines together
			if(push_accepted) then
				push_addr <= next_push_addr;
				push_data <= DIN;
				push_we <= '1';
			else
				push_addr <= push_addr;
				push_data <= (others => '0');
				push_we <= '0';
			end if;

			-- When a pop is accepted, transition the address now and the valid line on the following clock
			if(pop_accepted) then
				pop_addr <= next_pop_addr;
				valid_d <= '1';
			else
				pop_addr <= pop_addr;
				valid_d <= '0';
			end if;
			
			DVALID <= valid_d;
			
			
			if(is_empty) then
				EMPTY <= '1';
			else
				EMPTY <= '0';
			end if;
			
			-- Data loss occurs when a push is rejected
			if(PUSH = '1' and not push_accepted) then
				OVERFLOW <= '1';
			else
				OVERFLOW <= '0';
			end if;
			
		end if;
	end if;
	end process;

end Behavioral;

