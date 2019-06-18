----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:57:57 06/08/2019 
-- Design Name: 
-- Module Name:    internal_mcb - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity internal_mcb is
	Port ( 
		MCLK : in std_logic;
		MTRANSACTION_SIZE : in std_logic_vector(7 downto 0); -- number of fifo elements to read/write at once
		MAVAIL : in std_logic_vector(8 downto 0);
		MFLUSH : in std_logic;
		
		-- interface to data-to-write fifo
		MPOP_W : out std_logic;
		MADDR_W : in std_logic_vector(26 downto 0);   -- ddr address, high 27 bits
		MDATA_W : in std_logic_vector(255 downto 0);  -- half-burst data (4 high speed clocks worth of data)
		MDVALID_W : in std_logic;                      -- data valid
		
		-- interface to data-to-read fifo
		MPOP_R : out std_logic;
		MADDR_R : in std_logic_vector(26 downto 0);   -- ddr address, high 27 bits
		MDVALID_R : in std_logic;
		
		-- interface to data-just-read fifo
		MPUSH_R : out std_logic;
		MDATA_R : out std_logic_vector(255 downto 0)
	);
end internal_mcb;

architecture Behavioral of internal_mcb is

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

	constant ram_addr_width : natural := 9;
	constant ram_data_width : natural := 256;
	signal ram_waddr1 : std_logic_vector(ram_addr_width-1 downto 0) := (others => '0');
	signal ram_wdata1 : std_logic_vector(ram_data_width-1 downto 0) := (others => '0');
	signal ram_raddr2 : std_logic_vector(ram_addr_width-1 downto 0) := (others => '0');
	signal ram_rdata2 : std_logic_vector(ram_data_width-1 downto 0);
	signal ram_we : std_logic := '0';

	
	type state_t is (NOP, OPEN_ROW_W, DELAY1W, WRITE_STREAM, CLOSE_ROW_W, OPEN_ROW_R, CLOSE_ROW_R, DELAY1R, READ_STREAM);
	signal state : state_t := NOP;
	signal count : natural range 0 to 255 := 0;
	signal limit : natural range 0 to 255 := 0;
	signal pop_w : std_logic := '0';
	signal pop_r : std_logic := '0';
	signal mpush : std_logic := '0';
	
	signal wdata : std_logic_vector(255 downto 0) := (others => '0');
	signal waddr : std_logic_vector(26 downto 0) := (others => '0');
	signal raddr : std_logic_vector(26 downto 0) := (others => '0');
	signal data_just_read : std_logic_vector(ram_data_width-1 downto 0) := (others => '0');
	signal we_d : std_logic := '0';

	-- There are 2 elements per burst since DDR3 burst length is 8.
	-- MTRANSACTION_SIZE / MAVAIL could be odd, in which case I have
	-- to pad the burst out to the full size on write, and cut off
	-- the remainder on read. This signal captures whether we're
	-- in that situation.
	signal half_burst : std_logic := '0';
	signal burst_addr : std_logic := '0';
begin

	MPOP_W <= pop_w;
	MPOP_R <= pop_r;
	MPUSH_R <= mpush;

	process(MCLK) is
		variable transaction : natural;
		variable available : natural;
	begin
	if(rising_edge(MCLK)) then
	case state is
		when NOP =>
			mpush <= '0';
			pop_w <= '0';
			pop_r <= '0';
			burst_addr <= '0';
			count <= 0;
			transaction := to_integer(unsigned(MTRANSACTION_SIZE));
			available := to_integer(unsigned(MAVAIL));

			-- Determine whether to start a transaction. This can happen
			-- automatically, in the case where the fifo contains more
			-- elements than MTRANSACTION_SIZE, or manually if MFLUSH
			-- is pulled high. Normal operation is for the transaction
			-- to contain an even number of fifo elements. If the count
			-- is odd, the burst is not full and so I have to forcibly
			-- fill it with junk data.
			if(available >= transaction) then
				if(MTRANSACTION_SIZE(0) = '1') then
					half_burst <= '1';
					limit <= transaction + 1;
				else
					half_burst <= '0';
					limit <= transaction;
				end if;
				state <= OPEN_ROW_W;
			elsif(MFLUSH = '1' and available > 0) then
				if(MAVAIL(0) = '1') then
					half_burst <= '1';
					limit <= available + 1;
				else
					half_burst <= '0';
					limit <= available;
				end if;
				state <= OPEN_ROW_W;
			end if;
			
		when OPEN_ROW_W =>
			pop_w <= '1';
			state <= DELAY1W;
			
		when DELAY1W =>
			state <= WRITE_STREAM;
			
		when WRITE_STREAM =>
			-- Turn off popping input data. During a half burst,
			-- there's one extra cycle but no real fifo element
			-- to read so I have to shut off pop one clock early
			if( (half_burst = '0' and count = limit-2) or
             (half_burst = '1' and count = limit-3)) then
				pop_w <= '0';
			end if;
			
			if(count = 0) then
				wdata <= MDATA_W;
				waddr <= MADDR_W;
				count <= count + 1;
			elsif(count = limit+1) then
				ram_we <= '0';
				count <= 0;
				state <= CLOSE_ROW_W;
			else
				-- in a half burst the last data is repeated
				if((half_burst = '1' and count < limit-1) or half_burst = '0') then
					wdata <= MDATA_W;
					waddr <= MADDR_W;
				end if;
				ram_wdata1(255 downto 0) <= wdata;
				ram_waddr1 <= waddr(7 downto 0) & burst_addr;
				ram_we <= '1';
				count <= count + 1;
				burst_addr <= not burst_addr;
			end if;
			
		when CLOSE_ROW_W =>
			state <= OPEN_ROW_R;
			
		when OPEN_ROW_R =>
			pop_r <= '1';
			burst_addr <= '0';
			count <= 0;
			state <= DELAY1R;
		
		
		when DELAY1R =>
			state <= READ_STREAM;
			
		when READ_STREAM =>
			-- Turn off popping input data. During a half burst,
			-- there's one extra cycle but no real fifo element
			-- to read so I have to shut off pop one clock early
			if( (half_burst = '0' and count = limit-2) or
             (half_burst = '1' and count = limit-3)) then
				pop_r <= '0';
			end if;
			
			if(count = 0) then
				raddr <= MADDR_R;
				count <= count + 1;
			elsif((half_burst = '0' and count = limit+3) or 
			      (half_burst = '1' and count = limit+2)) then
				mpush <= '0';
				count <= 0;
				state <= CLOSE_ROW_R;
			else
				-- in a half burst the last data is repeated
				if((half_burst = '1' and count < limit-1) or half_burst = '0') then
					raddr <= MADDR_R;
				end if;
				ram_raddr2 <= raddr(7 downto 0) & burst_addr;
				if(count > 2) then
					data_just_read <= ram_rdata2; -- note the data is 2 clocks behind the address change
					mpush <= '1';
				end if;
				count <= count + 1;
				burst_addr <= not burst_addr;
			end if;
			
		when CLOSE_ROW_R =>
			state <= NOP;
			
			
	end case;
	end if;
	end process;
	
	MDATA_R <= data_just_read;
	
	bram_inst: bram_simple_dual_port 
	generic map(
		ADDR_WIDTH => ram_addr_width,
		DATA_WIDTH => ram_data_width
	)
	PORT MAP(
		CLK1 => MCLK,
		WADDR1 => ram_waddr1,
		WDATA1 => ram_wdata1,
		WE1 => ram_we,
		CLK2 => MCLK,
		RADDR2 => ram_raddr2,
		RDATA2 => ram_rdata2
	);
	

end Behavioral;

