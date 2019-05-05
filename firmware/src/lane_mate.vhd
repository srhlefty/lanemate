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
use IEEE.NUMERIC_STD.ALL;

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
	
	SDI_PCLK : in std_logic;
	SDI_HS : in std_logic;
	SDI_VS : in std_logic;
	SDI_INT : in std_logic;
	SDV : in std_logic_vector(7 downto 0);
	
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

	COMPONENT clk_hd
	PORT(
		CLK100 : IN std_logic;
		RST : IN std_logic;          
		CLK74p25 : OUT std_logic;
		CLK148p5 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT clk_sd
	PORT(
		CLK100 : IN std_logic;
		RST : IN std_logic;          
		CLK27 : OUT std_logic;
		CLK54 : OUT std_logic;
		LOCKED : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT timing_gen
	PORT(
		CLK : IN std_logic;
		RST : IN std_logic;
		VIC : IN std_logic_vector(7 downto 0);          
		VS : OUT std_logic;
		HS : OUT std_logic;
		DE : OUT std_logic;
		D : OUT std_logic_vector(23 downto 0)
		);
	END COMPONENT;
	
	COMPONENT timing_inspect
	PORT(
		PCLK : IN std_logic;
		VS : IN std_logic;
		HS : IN std_logic;          
		HCOUNT : OUT natural;
		HSYNC_WIDTH : OUT natural;
		VCOUNT : OUT natural;
		VSYNC_WIDTH : OUT natural
		);
	END COMPONENT;
	
	COMPONENT generate_sd_de
	PORT(
		PCLK : IN std_logic;
		FIELD : IN std_logic;
		HSIN : IN std_logic;          
		HS : OUT std_logic;          
		VS : OUT std_logic;
		DE : OUT std_logic
		);
	END COMPONENT;

	component clock_forwarding is
	 Generic( INVERT : boolean);
    Port ( CLK : in  STD_LOGIC;
           CLKO : out  STD_LOGIC);
	end component;
	
	COMPONENT bt656_decode
	PORT(
		D : IN std_logic_vector(7 downto 0);
		CLK : IN std_logic;          
		VS : OUT std_logic;
		HS : OUT std_logic;
		DE : OUT std_logic;
		DOUT : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;
	
	type video_in_t is (HDMI, COMPOSITE);
	signal video_input_source : video_in_t := COMPOSITE;
	
begin

--	bt656 : block is
--		signal data : std_logic_vector(7 downto 0);
--	begin
--	
--		Inst_bt656_decode: bt656_decode PORT MAP(
--			D => SDV,
--			CLK => SDI_PCLK,
--			VS => HDO_VS,
--			HS => HDO_HS,
--			DE => HDO_DE,
--			DOUT => data
--		);
--		
--		RGB_OUT(23 downto 8) <= (others => '0');
--		RGB_OUT(7 downto 0) <= data;
--
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => SDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--	end block;







--	synth : block is
--		signal clk148 : std_logic;
--		signal clk74 : std_logic;
--		signal clk27 : std_logic;
--		signal clk54 : std_logic;
--		signal rst : std_logic := '1';
--		signal once : std_logic := '0';
--		signal field_old : std_logic := '0';
--		signal d1 : std_logic_vector(7 downto 0);
--		signal d2 : std_logic_vector(7 downto 0);
--		signal d3 : std_logic_vector(7 downto 0);
--	begin
--
--		Inst_clk_hd: clk_hd PORT MAP(
--			CLK100 => SYSCLK,
--			CLK74p25 => clk74,
--			CLK148p5 => clk148,
--			RST => '0',
--			LOCKED => open
--		);
--		Inst_clk_sd: clk_sd PORT MAP(
--			CLK100 => SYSCLK,
--			CLK27 => clk27,
--			CLK54 => clk54,
--			RST => '0',
--			LOCKED => open
--		);
--	
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			--CLK => clk27,
--			--CLK => SDI_PCLK,
--			CLK => clk74,
--			CLKO => HDO_PCLK
--		);
--		
--		Inst_timing_gen: timing_gen PORT MAP(
--			--CLK => clk27,
--			--CLK => SDI_PCLK,
--			CLK => clk74,
--			RST => '0',
--			VIC => x"00",
--			VS => HDO_VS,
--			HS => HDO_HS,
--			DE => HDO_DE,
--			D => RGB_OUT
--		);
		
		
--		process(SDI_PCLK) is
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			field_old <= SDI_VS; -- 7180 sends me FIELD by default but this still works if it's configured to send VS instead
--			if(SDI_VS = '1' and field_old = '0') then
--				-- on rising edge of FIELD, trigger the timing generator (which begins with VSYNC)
--				rst <= '1';
--			else
--				rst <= '0';
--			end if;
--			
--			-- shift data by 4 to account for the time it takes for an incoming VSYNC to trigger the replaced VSYNC
--			d1 <= SDV;
--			d2 <= d1;
--			d3 <= d2;
--		end if;
--		end process;
--			RGB_OUT(23 downto 8) <= (others => '0');
--			RGB_OUT(7 downto 0) <= SDV;
		
		
--	end block;









--	sd_shunt : block is
--		signal idata : std_logic_vector(23 downto 0) := (others => '0');
--		signal ifield : std_logic := '0';
--		signal ihs : std_logic := '0';
--		signal ide : std_logic := '0';
--		signal odata : std_logic_vector(23 downto 0);
--		signal ovs : std_logic := '0';
--		signal ohs : std_logic := '0';
--		signal ode : std_logic := '0';
--		signal hcount : natural range 0 to 65535;
--		signal vcount : natural range 0 to 65535;
--	begin
--		process(SDI_PCLK) is
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			idata(7 downto 0) <= SDV;
--			ifield <= SDI_VS; -- 7180 sends me FIELD by default
--			ihs <= SDI_HS;
--			ide <= '0';
--			
--			odata <= idata;
--			--ovs <= ivs;
--			--ohs <= ihs;
--			--ode <= ide;
--			
--			RGB_OUT <= odata;
--			--HDO_VS <= ovs;
--			HDO_HS <= ohs;
--			--HDO_DE <= ode;
--			HDO_VS <= '0';
--			--HDO_HS <= '0';
--			HDO_DE <= '0';
--		end if;
--		end process;
--		
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => SDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--		
--		Inst_generate_sd_de: generate_sd_de PORT MAP(
--			PCLK => SDI_PCLK,
--			FIELD => ifield,
--			HSIN => ihs,
--			HS => ohs,
--			VS => ovs,
--			DE => ode
--		);
--		
--		Inst_timing_inspect: timing_inspect PORT MAP(
--			PCLK => SDI_PCLK,
--			VS => ovs,
--			HS => ohs,
--			HCOUNT => hcount,
--			HSYNC_WIDTH => open,
--			VCOUNT => vcount,
--			VSYNC_WIDTH => open
--		);
--		
--		process(SDI_PCLK) is
--			variable count : std_logic_vector(15 downto 0);
--		begin
--		if(rising_edge(SDI_PCLK)) then
--			count := std_logic_vector(to_unsigned(vcount, count'length));
--			B0_GPIO0 <= count(0);
--			B1_GPIO1 <= count(1);
--			B1_GPIO2 <= count(2);
--			B1_GPIO3 <= count(3);
--			B1_GPIO4 <= count(4);
--			B1_GPIO5 <= count(5);
--			B1_GPIO6 <= count(6);
--			B1_GPIO7 <= count(7);
--			B1_GPIO8 <= count(8);
--			B1_GPIO9 <= count(9);
--			B1_GPIO10 <= count(10);
--			B1_GPIO11 <= count(11);
--			B1_GPIO12 <= count(12);
--			B1_GPIO13 <= count(13);
--			B1_GPIO14 <= count(14);
--			B1_GPIO15 <= count(15);
--		end if;
--		end process;
--		
--	end block;





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
		
		-- By inverting the clock here I'm putting the rising
		-- edge in the middle of the data eye
		Inst_clock_forwarding: clock_forwarding 
		GENERIC MAP(
			INVERT => true
		)
		PORT MAP(
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

