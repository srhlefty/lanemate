----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:17:06 02/19/2019 
-- Design Name: 
-- Module Name:    bt656_decode - Behavioral 
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

entity bt656_decode is
    Port ( D : in  STD_LOGIC_VECTOR (7 downto 0);
           CLK : in  STD_LOGIC;
           VS : out  STD_LOGIC;
           HS : out  STD_LOGIC;
           DE : out  STD_LOGIC;
           DOUT : out  STD_LOGIC_VECTOR (7 downto 0));
end bt656_decode;

architecture Behavioral of bt656_decode is
	signal d4 : std_logic_vector(7 downto 0) := x"00";
	signal d3 : std_logic_vector(7 downto 0) := x"00";
	signal d2 : std_logic_vector(7 downto 0) := x"00";
	signal d1 : std_logic_vector(7 downto 0) := x"00";

	signal de_out : std_logic := '0';
	signal trig_de : std_logic := '0';
	
	signal hs_out : std_logic := '1';
	signal trig_hs : std_logic := '0';
	
	signal vs_out : std_logic := '1';
	signal trig_vs_field1 : std_logic := '0';
	signal trig_vs_field2 : std_logic := '0';
	signal vs_count : natural;
	signal vblank_old : std_logic := '0';

	signal field : std_logic := '0';
	signal line : natural range 0 to 1023 := 0;
	signal de_mask : std_logic := '0';
	
	constant active_line_length : natural := 1440;
	constant total_horizontal_line_length              : natural := 1716;
	constant horizontal_front_porch                    : natural :=   38;
	constant horizontal_back_porch                     : natural :=  114;
	constant horizontal_sync_pulse_width               : natural :=  124;
	constant total_number_of_vertical_lines_in_field_0 : natural :=  262;
	constant vertical_front_porch_field_0              : natural :=    4;
	constant vertical_back_porch_field_0               : natural :=   15;
	constant vertical_sync_pulse_in_field_0            : natural :=    3;
	constant HV_offset_field_0                         : natural :=    0;
	constant total_number_of_vertical_lines_in_field_1 : natural :=  263;
	constant vertical_front_porch_field_1              : natural :=    4;
	constant vertical_back_porch_field_1               : natural :=   16;
	constant vertical_sync_pulse_in_field_1            : natural :=    3;
	constant HV_offset_field_1                         : natural :=  858;

begin

	process(CLK) is
		variable F : std_logic;
		variable V : std_logic;
		variable H : std_logic;
		variable P3 : std_logic;
		variable P2 : std_logic;
		variable P1 : std_logic;
		variable P0 : std_logic;
	begin
	if(rising_edge(CLK)) then
		d1 <= D;
		d2 <= d1;
		d3 <= d2;
		d4 <= d3;
		
		if(d4 = x"FF" and d3 = x"00" and d2 = x"00" and d1(7) = '1') then -- code preamble
			F := d1(6); -- field
			V := d1(5); -- 1 during vblank
			H := d1(4); -- 0=SAV, 1=EAV
			P3 := d1(3);
			P2 := d1(2);
			P1 := d1(1);
			P0 := d1(0);
			
			field <= F;
			
			if(H = '0' and V = '0') then
				trig_de <= '1';
			end if;
			
			if(H = '1') then
				-- HSYNC
				trig_hs <= '1';
				
				-- VSYNC
				-- Here I'm essentially looking for the rising edge of vblank
				-- where the "clock" is EAV.
				-- This is because V is high for the first 20 or so lines of each field.
				vblank_old <= V;
				if(vblank_old = '0' and V = '1') then
					if(F = '1') then
						-- the first 3 lines are left over from the previous frame
						trig_vs_field1 <= '1';
						line <= 1;
					else
						trig_vs_field2 <= '1';
						line <= 264;
					end if;
				else
					line <= line + 1;
				end if;
			end if;
		else
			trig_de <= '0';
			trig_hs <= '0';
			trig_vs_field1 <= '0';
			trig_vs_field2 <= '0';
		end if;
	end if;
	end process;
	
	
	
	
	gen_de : block is
		signal de_count : natural range 0 to 1800 := 0;
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if(trig_de = '1') then
				de_out <= '1';
				de_count <= 1440-1;
			else
				if(de_count = 0) then
					de_out <= '0';
				else
					de_count <= de_count - 1;
				end if;
			end if;
		end if;
		end process;
	end block;

	gen_de_mask : block is
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if((line >= 22 and line <= 261) or (line >= 285 and line <= 524)) then
				de_mask <= '1';
			else
				de_mask <= '0';
			end if;
		end if;
		end process;
	end block;


	gen_hs : block is
		type state_t is (WAITING, SYNC, COUNTING);
		signal state : state_t := WAITING;
		signal ret : state_t := WAITING;
		signal hs_count : natural range 0 to 255 := 0;
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
		case state is
		
		when WAITING =>
			hs_out <= '1';
			if(trig_hs = '1') then
				hs_count <= horizontal_front_porch - 6; -- the extra 4 is due to the preamble being 4 bytes
				state <= COUNTING;
				ret <= SYNC;
			end if;
			
		when SYNC =>
			hs_out <= '0';
			hs_count <= horizontal_sync_pulse_width - 2;
			state <= COUNTING;
			ret <= WAITING;
			
		when COUNTING =>
			if(hs_count = 0) then
				state <= ret;
			else
				hs_count <= hs_count - 1;
			end if;
		end case;
		end if;
		end process;
	end block;
	




	gen_vs : block is
		type state_t is (WAITING, SYNC, COUNTING);
		signal state : state_t := WAITING;
		signal ret : state_t := WAITING;
		signal vs_count : natural range 0 to 65535 := 0;
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
		case state is
		
		when WAITING =>
			vs_out <= '1';
			if(trig_vs_field1 = '1') then
				-- trigger happens at the start of line 1
				vs_count <= 3*total_horizontal_line_length - 6; -- the extra 4 is due to the preamble being 4 bytes
				state <= COUNTING;
				ret <= SYNC;
			end if;
			if(trig_vs_field2 = '1') then
				-- trigger happens at the start of line 264
				vs_count <= 2*total_horizontal_line_length + 858 - 6; -- the extra 4 is due to the preamble being 4 bytes
				state <= COUNTING;
				ret <= SYNC;
			end if;
			
		when SYNC =>
			vs_out <= '0';
			vs_count <= total_horizontal_line_length * vertical_sync_pulse_in_field_0 - 2;
			state <= COUNTING;
			ret <= WAITING;
			
		when COUNTING =>
			if(vs_count = 0) then
				state <= ret;
			else
				vs_count <= vs_count - 1;
			end if;
		end case;
		end if;
		end process;
	end block;
	
	VS <= vs_out;
	HS <= hs_out;
	DE <= de_out and de_mask;
	DOUT <= d2; -- should be d2

end Behavioral;

