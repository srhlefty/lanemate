----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:00:03 02/17/2019 
-- Design Name: 
-- Module Name:    timing_gen - Behavioral 
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

use work.pkg_types.all;

entity timing_gen is
    Port ( CLK : in  STD_LOGIC;
	        RST : in std_logic;
           SEL : in  STD_LOGIC_VECTOR (1 downto 0);
           VS : out  STD_LOGIC;
           HS : out  STD_LOGIC;
           DE : out  STD_LOGIC;
           D : out  STD_LOGIC_VECTOR (23 downto 0));
end timing_gen;

architecture Behavioral of timing_gen is

	COMPONENT sync_vg
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		interlaced : IN std_logic;
		v_total_0 : IN std_logic_vector(11 downto 0);
		v_fp_0 : IN std_logic_vector(11 downto 0);
		v_bp_0 : IN std_logic_vector(11 downto 0);
		v_sync_0 : IN std_logic_vector(11 downto 0);
		v_total_1 : IN std_logic_vector(11 downto 0);
		v_fp_1 : IN std_logic_vector(11 downto 0);
		v_bp_1 : IN std_logic_vector(11 downto 0);
		v_sync_1 : IN std_logic_vector(11 downto 0);
		h_total : IN std_logic_vector(11 downto 0);
		h_fp : IN std_logic_vector(11 downto 0);
		h_bp : IN std_logic_vector(11 downto 0);
		h_sync : IN std_logic_vector(11 downto 0);
		hv_offset_0 : IN std_logic_vector(11 downto 0);
		hv_offset_1 : IN std_logic_vector(11 downto 0);          
		vs_out : OUT std_logic;
		hs_out : OUT std_logic;
		de_out : OUT std_logic;
		v_count_out : OUT std_logic_vector(12 downto 0);
		h_count_out : OUT std_logic_vector(11 downto 0);
		x_out : OUT std_logic_vector(11 downto 0);
		y_out : OUT std_logic_vector(12 downto 0);
		field_out : OUT std_logic;
		clk_out : OUT std_logic
		);
	END COMPONENT;
	
	

	-- These constants are derived from the values listed in the CEA861D standard.
	-- VFP + VSYNC + VBP = # of blanking lines listed in the spec.
	-- VFP is number of HSYNC spaces before VSYNC.

	-- 1080p 148.5MHz pclk
	constant vic16 : vic_settings := 
	(
		total_horizontal_line_length              => std_logic_vector(to_unsigned(2200, 12)),
		horizontal_front_porch                    => std_logic_vector(to_unsigned(  88, 12)),
		horizontal_back_porch                     => std_logic_vector(to_unsigned( 148, 12)),
		horizontal_sync_pulse_width               => std_logic_vector(to_unsigned(  44, 12)),
		total_number_of_vertical_lines_in_field_0 => std_logic_vector(to_unsigned(1125, 12)),
		vertical_front_porch_field_0              => std_logic_vector(to_unsigned(   4, 12)),
		vertical_back_porch_field_0               => std_logic_vector(to_unsigned(  36, 12)),
		vertical_sync_pulse_in_field_0            => std_logic_vector(to_unsigned(   5, 12)),
		HV_offset_field_0                         => std_logic_vector(to_unsigned(   0, 12)),
		total_number_of_vertical_lines_in_field_1 => std_logic_vector(to_unsigned(   0, 12)),
		vertical_front_porch_field_1              => std_logic_vector(to_unsigned(   0, 12)),
		vertical_back_porch_field_1               => std_logic_vector(to_unsigned(   0, 12)),
		vertical_sync_pulse_in_field_1            => std_logic_vector(to_unsigned(   0, 12)),
		HV_offset_field_1                         => std_logic_vector(to_unsigned(   0, 12)),
		interlaced                                => '0'
	);

	-- 1080i 74.25MHz pclk
	constant vic5 : vic_settings := 
	(
		total_horizontal_line_length              => std_logic_vector(to_unsigned(2200, 12)),
		horizontal_front_porch                    => std_logic_vector(to_unsigned(  88, 12)),
		horizontal_back_porch                     => std_logic_vector(to_unsigned( 148, 12)),
		horizontal_sync_pulse_width               => std_logic_vector(to_unsigned(  44, 12)),
		total_number_of_vertical_lines_in_field_0 => std_logic_vector(to_unsigned( 562, 12)),
		vertical_front_porch_field_0              => std_logic_vector(to_unsigned(   2, 12)),
		vertical_back_porch_field_0               => std_logic_vector(to_unsigned(  15, 12)),
		vertical_sync_pulse_in_field_0            => std_logic_vector(to_unsigned(   5, 12)),
		HV_offset_field_0                         => std_logic_vector(to_unsigned(   0, 12)),
		total_number_of_vertical_lines_in_field_1 => std_logic_vector(to_unsigned( 563, 12)),
		vertical_front_porch_field_1              => std_logic_vector(to_unsigned(   2, 12)),
		vertical_back_porch_field_1               => std_logic_vector(to_unsigned(  16, 12)),
		vertical_sync_pulse_in_field_1            => std_logic_vector(to_unsigned(   5, 12)),
		HV_offset_field_1                         => std_logic_vector(to_unsigned(1100, 12)),
		interlaced                                => '1'
	);

	-- 720p 74.25MHz pclk
	constant vic4 : vic_settings := 
	(
		total_horizontal_line_length              => std_logic_vector(to_unsigned(1650, 12)),
		horizontal_front_porch                    => std_logic_vector(to_unsigned( 110, 12)),
		horizontal_back_porch                     => std_logic_vector(to_unsigned( 220, 12)),
		horizontal_sync_pulse_width               => std_logic_vector(to_unsigned(  40, 12)),
		total_number_of_vertical_lines_in_field_0 => std_logic_vector(to_unsigned( 750, 12)),
		vertical_front_porch_field_0              => std_logic_vector(to_unsigned(   5, 12)),
		vertical_back_porch_field_0               => std_logic_vector(to_unsigned(  20, 12)),
		vertical_sync_pulse_in_field_0            => std_logic_vector(to_unsigned(   5, 12)),
		HV_offset_field_0                         => std_logic_vector(to_unsigned(   0, 12)),
		total_number_of_vertical_lines_in_field_1 => std_logic_vector(to_unsigned(   0, 12)),
		vertical_front_porch_field_1              => std_logic_vector(to_unsigned(   0, 12)),
		vertical_back_porch_field_1               => std_logic_vector(to_unsigned(   0, 12)),
		vertical_sync_pulse_in_field_1            => std_logic_vector(to_unsigned(   0, 12)),
		HV_offset_field_1                         => std_logic_vector(to_unsigned(   0, 12)),
		interlaced                                => '0'
	);
	
	-- 720x480p 27MHz pclk
	constant vic2 : vic_settings := 
	(
		total_horizontal_line_length              => std_logic_vector(to_unsigned( 858, 12)),
		horizontal_front_porch                    => std_logic_vector(to_unsigned(  16, 12)),
		horizontal_back_porch                     => std_logic_vector(to_unsigned(  60, 12)),
		horizontal_sync_pulse_width               => std_logic_vector(to_unsigned(  62, 12)),
		total_number_of_vertical_lines_in_field_0 => std_logic_vector(to_unsigned( 525, 12)),
		vertical_front_porch_field_0              => std_logic_vector(to_unsigned(   9, 12)),
		vertical_back_porch_field_0               => std_logic_vector(to_unsigned(  30, 12)),
		vertical_sync_pulse_in_field_0            => std_logic_vector(to_unsigned(   6, 12)),
		HV_offset_field_0                         => std_logic_vector(to_unsigned(   0, 12)),
		total_number_of_vertical_lines_in_field_1 => std_logic_vector(to_unsigned(   0, 12)),
		vertical_front_porch_field_1              => std_logic_vector(to_unsigned(   0, 12)),
		vertical_back_porch_field_1               => std_logic_vector(to_unsigned(   0, 12)),
		vertical_sync_pulse_in_field_1            => std_logic_vector(to_unsigned(   0, 12)),
		HV_offset_field_1                         => std_logic_vector(to_unsigned(   0, 12)),
		interlaced                                => '0'
	);
	
	-- 720(1440)x480i 27MHz pclk
	constant vic6 : vic_settings := 
	(
		total_horizontal_line_length              => std_logic_vector(to_unsigned(1716, 12)),
		horizontal_front_porch                    => std_logic_vector(to_unsigned(  38, 12)),
		horizontal_back_porch                     => std_logic_vector(to_unsigned( 114, 12)),
		horizontal_sync_pulse_width               => std_logic_vector(to_unsigned( 124, 12)),
		total_number_of_vertical_lines_in_field_0 => std_logic_vector(to_unsigned( 262, 12)),
		vertical_front_porch_field_0              => std_logic_vector(to_unsigned(   4, 12)),
		vertical_back_porch_field_0               => std_logic_vector(to_unsigned(  15, 12)),
		vertical_sync_pulse_in_field_0            => std_logic_vector(to_unsigned(   3, 12)),
		HV_offset_field_0                         => std_logic_vector(to_unsigned(   0, 12)),
		total_number_of_vertical_lines_in_field_1 => std_logic_vector(to_unsigned( 263, 12)),
		vertical_front_porch_field_1              => std_logic_vector(to_unsigned(   4, 12)),
		vertical_back_porch_field_1               => std_logic_vector(to_unsigned(  16, 12)),
		vertical_sync_pulse_in_field_1            => std_logic_vector(to_unsigned(   3, 12)),
		HV_offset_field_1                         => std_logic_vector(to_unsigned( 858, 12)),
		interlaced                                => '1'
	);
	
	alias VIC1080p : vic_settings is vic16;
	alias VIC1080i : vic_settings is vic5;
	alias VIC720p : vic_settings is vic4;
	alias VIC480p : vic_settings is vic2;
	alias VIC480i : vic_settings is vic6;
	
	signal output_vic : vic_settings := VIC720p;
	signal debug_field : std_logic;

	signal timing_reset : std_logic := '0';
	signal rst_boot : std_logic := '0';

begin

	wrapper : block is
		signal vs_tmp : std_logic;
		signal hs_tmp : std_logic;
		signal de_tmp : std_logic;
		signal d_tmp : std_logic_vector(7 downto 0);
		signal xout : std_logic_vector(11 downto 0);
		signal yout : std_logic_vector(12 downto 0);
		
		COMPONENT serializeYCbCr
		PORT(
			DE : IN std_logic;
			YCbCr1 : IN std_logic_vector(23 downto 0);
			Y2 : IN std_logic_vector(7 downto 0);
			CLK : IN std_logic;          
			D : OUT std_logic_vector(7 downto 0);
			DEout : OUT std_logic
			);
		END COMPONENT;
		
	begin

	oneshot : block is
		signal once : std_logic := '0';
	begin
		process(CLK) is
		begin
		if(rising_edge(CLK)) then
			if(once = '0') then
				rst_boot <= '1';
				once <= '1';
			else
				rst_boot <= '0';
			end if;
		end if;
		end process;
	end block;

	timing_reset <= RST or rst_boot;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		if(SEL = "00") then
			output_vic <= VIC720p;
		elsif(SEL = "01") then
			output_vic <= VIC480p;
		elsif(SEL = "10") then
			output_vic <= VIC720p;
		elsif(SEL = "11") then
			output_vic <= VIC1080p;
		end if;
	end if;
	end process;
	
	Inst_sync_vg: sync_vg PORT MAP(
		clk => CLK,
		reset => timing_reset,
		interlaced => output_vic.interlaced,
		v_total_0 => output_vic.total_number_of_vertical_lines_in_field_0,
		v_fp_0 => output_vic.vertical_front_porch_field_0,
		v_bp_0 => output_vic.vertical_back_porch_field_0,
		v_sync_0 => output_vic.vertical_sync_pulse_in_field_0,
		v_total_1 => output_vic.total_number_of_vertical_lines_in_field_1,
		v_fp_1 => output_vic.vertical_front_porch_field_1,
		v_bp_1 => output_vic.vertical_back_porch_field_1,
		v_sync_1 => output_vic.vertical_sync_pulse_in_field_1,
		h_total => output_vic.total_horizontal_line_length,
		h_fp => output_vic.horizontal_front_porch,
		h_bp => output_vic.horizontal_back_porch,
		h_sync => output_vic.horizontal_sync_pulse_width,
		hv_offset_0 => output_vic.HV_offset_field_0,
		hv_offset_1 => output_vic.HV_offset_field_1,
		vs_out => vs_tmp,
		hs_out => hs_tmp,
		de_out => de_tmp,
		v_count_out => open,
		h_count_out => open,
		x_out => xout,
		y_out => yout,
		field_out => debug_field,
		clk_out => open
	);

	-- 4:2:2 output: serialize the pixel data
--	Inst_serializeYCbCr: serializeYCbCr PORT MAP(
--		DE => de_tmp,
--		YCbCr1 => x"952B15",
--		Y2 => x"95",
--		D => d_tmp,
--		DEout => DE,
--		CLK => CLK
--	);
--	D(7 downto 0) <= d_tmp;
--	D(23 downto 8) <= (others => '0');
--	-- and delay HS and VS, because the serializer needs to delay DE by 1
--	process(CLK) is
--	begin
--	if(rising_edge(CLK)) then
--		VS <= not vs_tmp;
--		HS <= not hs_tmp;
--	end if;
--	end process;
	
	
	
	
	-- 4:4:4 output
	VS <= not vs_tmp;
	HS <= not hs_tmp;
	DE <= de_tmp;
	
	process(CLK) is
	begin
	if(rising_edge(CLK)) then
		D <= x"00" & yout(7 downto 0) & xout(7 downto 0);
		-- the bus for RGB goes RGB
		-- the bus for YCbCr goes CrYCb
		-- pure green: Y,Cb,Cr = 149,43,21
		-- if interpreted incorrectly as rgb, looks like a darker green
		--D <= x"15952B";
	end if;
	end process;
	
	end block;

	

end Behavioral;

