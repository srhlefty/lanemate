----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:58:53 06/13/2019 
-- Design Name: 
-- Module Name:    gearbox24to256 - Behavioral 
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

entity gearbox24to256 is
	Port ( 
		PCLK : in std_logic;
		-- input data
		PDATA : in std_logic_vector(23 downto 0);
		PPUSH : in std_logic;                             -- DE
		
		-- address management
		PFRAME_ADDR_W : in std_logic_vector(23 downto 0); -- DDR write pointer
		PFRAME_ADDR_R : in std_logic_vector(23 downto 0); -- DDR read pointer
		PNEW_FRAME : in std_logic;                        -- pulse to capture write/read pointers
		
		-- output to write-transaction address & data fifos
		PADDR_W : out std_logic_vector(23 downto 0);
		PDATA_W : out std_logic_vector(255 downto 0);
		PPUSH_W : out std_logic;
		
		-- output to read-transaction address fifo
		PADDR_R : out std_logic_vector(23 downto 0);
		PPUSH_R : out std_logic;
		
		-- signal that a group of 3 pushes has just completed
		-- (this is used downstream as a 'done' signal to flush a queue
		PPUSHED : out std_logic
	);
end gearbox24to256;

architecture Behavioral of gearbox24to256 is

		type shift_t is array(integer range <>) of std_logic_vector(23 downto 0);
		signal shifter : shift_t(0 to 31) := (others => (others => '0'));
		signal word1 : std_logic_vector(255 downto 0) := (others => '0');
		signal word2 : std_logic_vector(255 downto 0) := (others => '0');
		signal word3 : std_logic_vector(255 downto 0) := (others => '0');
		signal count : natural range 0 to 32 := 0;
		type pusher_state_t is (IDLE, P1, P2, P3);
		signal pusher_state : pusher_state_t := IDLE;
		
		signal base_addr_w : std_logic_vector(23 downto 0) := (others => '0');
		signal base_addr_r : std_logic_vector(23 downto 0) := (others => '0');
		-- 1080p has 1080 lines, 180 elements per line, so max address offset is 1080*180/2 = 97,200
		-- with the /2 because it takes 2 elements to do one burst at the same address. Thus a 17-bit number.
		signal addr_offset_w : std_logic_vector(16 downto 0) := (others => '0');
		signal addr_offset_r : std_logic_vector(16 downto 0) := (others => '0');
		
		signal addr_out_w : std_logic_vector(23 downto 0) := (others => '0');
		signal data_out_w : std_logic_vector(255 downto 0) := (others => '0');
		signal addr_out_r : std_logic_vector(23 downto 0) := (others => '0');
		signal fifo_push : std_logic := '0';
		
		signal done_d : std_logic := '0';
		signal done : std_logic := '0';
		
		type offset_mode_t is (EVEN, ODD);
		signal offset_mode : offset_mode_t := EVEN;
		
		signal waddr_plus_0 : std_logic_vector(23 downto 0) := (others => '0');
		signal raddr_plus_0 : std_logic_vector(23 downto 0) := (others => '0');
		signal waddr_plus_1 : std_logic_vector(23 downto 0) := (others => '0');
		signal raddr_plus_1 : std_logic_vector(23 downto 0) := (others => '0');
		signal woffset_plus_1 : std_logic_vector(16 downto 0) := (others => '0');
		signal roffset_plus_1 : std_logic_vector(16 downto 0) := (others => '0');
		signal woffset_plus_2 : std_logic_vector(16 downto 0) := (others => '0');
		signal roffset_plus_2 : std_logic_vector(16 downto 0) := (others => '0');
		
		-- I push 3 elements into the fifo at a time, but the address only increments
		-- every other. So the mechanism for computing the address is slightly nontrivial.
		-- If the starting address is 'A', then the actual addresses pushed should look
		-- like this: A,A,A+1,  A+1,A+2,A+2,  A+3,A+3,A+4, etc.
		-- The pattern repeats after every other group of 3 writes. The offset_mode signal
		-- keeps track of whether we're going to store using the first pattern (+0,+0,+1)
		-- or the second pattern (+0,+1,+1). After the 3rd push, I save the new address offset
		-- and switch the pattern.

begin

		PADDR_W <= addr_out_w;
		PDATA_W <= data_out_w;
		PADDR_R <= addr_out_r;
		PPUSH_W <= fifo_push;
		PPUSH_R <= fifo_push;
		PPUSHED <= done;

		process(PCLK) is
		begin
		if(rising_edge(PCLK)) then
		
			if(PNEW_FRAME = '1') then
				base_addr_w <= PFRAME_ADDR_W;
				base_addr_r <= PFRAME_ADDR_R;
				addr_offset_w <= (others => '0');
				addr_offset_r <= (others => '0');
				offset_mode <= EVEN;
			else
			
		
				if(PPUSH = '1') then
					shifter(31) <= PDATA;
					for i in 0 to 30 loop
						shifter(i) <= shifter(i+1);
					end loop;
					
					if(count = 32) then
						-- we've just done a shift so there's already 1
						count <= 1;
					else
						count <= count + 1;
					end if;
				else
					if(count = 32) then
						count <= 0;
					end if;
				end if;
				
				-- I need to add the base address to the offset as well as get that value plus 1.
				-- That's a significant amount of propagation delay, so here I spread out those
				-- two add operations over 2 clocks.
				if(count = 31) then
					waddr_plus_0 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_w)) + to_integer(unsigned(addr_offset_w)) , waddr_plus_0'length));
					raddr_plus_0 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_r)) + to_integer(unsigned(addr_offset_r)) , raddr_plus_0'length));
					woffset_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_w)) + 1 , woffset_plus_1'length));
					roffset_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_r)) + 1 , roffset_plus_1'length));
					woffset_plus_2 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_w)) + 2 , woffset_plus_2'length));
					roffset_plus_2 <= std_logic_vector(to_unsigned( to_integer(unsigned(addr_offset_r)) + 2 , roffset_plus_2'length));
				end if;
				
				if(count = 32) then
					-- this should happen once by design
					word1 <= shifter(10)(15 downto 0) & shifter(9) & shifter(8) & shifter(7) & shifter(6) & shifter(5) & shifter(4) & shifter(3) & shifter(2) & shifter(1) & shifter(0);
					word2 <= shifter(21)(7 downto 0) & shifter(20) & shifter(19) & shifter(18) & shifter(17) & shifter(16) & shifter(15) & shifter(14) & shifter(13) & shifter(12) & shifter(11) & shifter(10)(23 downto 16);
					word3 <= shifter(31) & shifter(30) & shifter(29) & shifter(28) & shifter(27) & shifter(26) & shifter(25) & shifter(24) & shifter(23) & shifter(22) & shifter(21)(23 downto 8);
					waddr_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_w)) + to_integer(unsigned(woffset_plus_1)) , waddr_plus_1'length));
					raddr_plus_1 <= std_logic_vector(to_unsigned( to_integer(unsigned(base_addr_r)) + to_integer(unsigned(roffset_plus_1)) , raddr_plus_1'length));
					pusher_state <= P1;
				else
					case pusher_state is
						when IDLE =>
							fifo_push <= '0';
							pusher_state <= IDLE;
						when P1 =>
							fifo_push <= '1';
							addr_out_w <= waddr_plus_0;
							data_out_w <= word1;
							addr_out_r <= raddr_plus_0;
							pusher_state <= P2;
						when P2 =>
							fifo_push <= '1';
							if(offset_mode = EVEN) then
								addr_out_w <= waddr_plus_0;
								data_out_w <= word2;
								addr_out_r <= raddr_plus_0;
							else
								addr_out_w <= waddr_plus_1;
								data_out_w <= word2;
								addr_out_r <= raddr_plus_1;
							end if;
							pusher_state <= P3;
						when P3 =>
							fifo_push <= '1';
							addr_out_w <= waddr_plus_1;
							data_out_w <= word3;
							addr_out_r <= raddr_plus_1;
							pusher_state <= IDLE;
							
							if(offset_mode = EVEN) then
								addr_offset_w <= woffset_plus_1;
								addr_offset_r <= roffset_plus_1;
								offset_mode <= ODD;
							else
								addr_offset_w <= woffset_plus_2;
								addr_offset_r <= roffset_plus_2;
								offset_mode <= EVEN;
							end if;
					end case;
				end if;
			
				if(pusher_state = P3) then
					done_d <= '1';
				else
					done_d <= '0';
				end if;
				done <= done_d;
			
			end if;
		end if;
		end process;

end Behavioral;

