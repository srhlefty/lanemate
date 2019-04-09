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
	
	
	component i2c_master is
	Port ( 
		CLK : in  STD_LOGIC;
		SLAVE_ADDR : in std_logic_vector(6 downto 0);
		SLAVE_REG : in std_logic_vector(7 downto 0);
		
		CMD_WRITE : in std_logic;
		WRITE_DATA : in std_logic_vector(7 downto 0);

		CMD_READ : in std_logic;
		
		REPLY_ACK : out std_logic;
		REPLY_NACK : out std_logic;
		REPLY_DATA : out std_logic_vector(7 downto 0);
		REPLY_VALID : out std_logic;
		
		SDA : inout  STD_LOGIC;
		SCL : inout  STD_LOGIC
	);
	end component;
	
	
	type video_in_t is (HDMI, COMPOSITE);
	signal video_input_source : video_in_t := COMPOSITE;
	
begin

	HDO_PCLK <= '0';
	HDO_VS <= '0';
	HDO_HS <= '0';
	HDO_DE <= '0';
	RGB_OUT <= (others => '0');

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
--		signal rst : std_logic := '0';
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
--			CLK => clk74,
--			CLKO => HDO_PCLK
--		);
--		
--		Inst_timing_gen: timing_gen PORT MAP(
--			CLK => clk74,
--			RST => rst,
--			VIC => x"00",
--			VS => HDO_VS,
--			HS => HDO_HS,
--			DE => HDO_DE,
--			D => RGB_OUT
--		);
--		
--		process(clk74) is
--		begin
--		if(rising_edge(clk74)) then
--			if(once = '0') then
--				rst <= '1';
--				once <= '1';
--			else
--				rst <= '0';
--			end if;
--		end if;
--		end process;
--		
--		
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





--	hd_shunt : block is
--		signal idata : std_logic_vector(23 downto 0) := (others => '0');
--		signal ivs : std_logic := '0';
--		signal ihs : std_logic := '0';
--		signal ide : std_logic := '0';
--		signal odata : std_logic_vector(23 downto 0);
--		signal ovs : std_logic := '0';
--		signal ohs : std_logic := '0';
--		signal ode : std_logic := '0';
--		
--		signal clk74 : std_logic;
--		signal clk148 : std_logic;
--	begin
--	
--		Inst_clk_hd: clk_hd PORT MAP(
--			CLK100 => SYSCLK,
--			CLK74p25 => clk74,
--			CLK148p5 => clk148,
--			RST => '0',
--			LOCKED => open
--		);
--	
--	
--		process(HDI_PCLK) is
--		begin
--		if(rising_edge(HDI_PCLK)) then
--			idata <= RGB_IN;
--			ivs <= HDI_VS;
--			ihs <= HDI_HS;
--			ide <= HDI_DE;
--			
--			odata <= idata;
--			ovs <= ivs;
--			ohs <= ihs;
--			ode <= ide;
--			
--			RGB_OUT <= odata;
--			HDO_VS <= ovs;
--			HDO_HS <= ohs;
--			HDO_DE <= ode;
--		end if;
--		end process;
--		
--		-- By inverting the clock here I'm putting the rising
--		-- edge in the middle of the data eye
--		Inst_clock_forwarding: clock_forwarding 
--		GENERIC MAP(
--			INVERT => true
--		)
--		PORT MAP(
--			CLK => HDI_PCLK,
--			CLKO => HDO_PCLK
--		);
--	
--	end block;
--










--   iobuf1 : IOBUF
--   generic map (
--      DRIVE => 12,
--      IOSTANDARD => "I2C",
--      SLEW => "SLOW")
--   port map (
--      O => open,     -- Buffer output
--      IO => I2C_SDA,   -- Buffer inout port (connect directly to top-level port)
--      I => '1',     -- Buffer input
--      T => '1'      -- 3-state enable input, high=input, low=output 
--   );
--
--   iobuf2 : IOBUF
--   generic map (
--      DRIVE => 12,
--      IOSTANDARD => "I2C",
--      SLEW => "SLOW")
--   port map (
--      O => open,     -- Buffer output
--      IO => I2C_SCL,   -- Buffer inout port (connect directly to top-level port)
--      I => '1',     -- Buffer input
--      T => '1'      -- 3-state enable input, high=input, low=output 
--   );

	timer : block is
		signal reg : std_logic_vector(7 downto 0) := x"00";
		signal write_data : std_logic_vector(7 downto 0) := x"00";
		signal reply_data : std_logic_vector(7 downto 0);
		signal cmd_write : std_logic := '0';
		signal cmd_read : std_logic := '0';
		signal reply_ack : std_logic;
		signal reply_nack : std_logic;
		signal reply_valid : std_logic;
		
		type state_t is (STARTUP, SEND, WAIT_FOR_REPLY, NORMAL, WAIT_FOR_REPLY_N, DELAY, HALT);
		signal state : state_t := STARTUP;
		signal ret : state_t := STARTUP;
		signal count : natural := 0;
		
		type char_t is array(natural range <>) of std_logic_vector(7 downto 0);
		signal startup_reg  : char_t(0 to 7) := ( x"07", x"06", x"05", x"04", x"03", x"02", x"01", x"00" );
		signal startup_data : char_t(0 to 7) := ( x"10", x"00", x"00", x"00", x"00", x"00", x"00", x"00" );
		signal startup_index : natural range 0 to 7 := 0;
		
		signal lights : std_logic_vector(15 downto 0) := x"0000";
		
		-- For simulation
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
		signal i2c_debug_sda : std_logic;
		signal i2c_debug_scl : std_logic;
		signal RAM_ADDR : std_logic_vector(7 downto 0);
		signal RAM_WDATA : std_logic_vector(7 downto 0);
		signal RAM_RDATA : std_logic_vector(7 downto 0);
		signal RAM_WE : std_logic;
		
	begin
	
		Inst_i2c_master: i2c_master PORT MAP(
			CLK => SYSCLK,
			SLAVE_ADDR => "1101000",
			SLAVE_REG => reg,
			CMD_WRITE => cmd_write,
			WRITE_DATA => write_data,
			CMD_READ => cmd_read,
			REPLY_ACK => reply_ack,
			REPLY_NACK => reply_nack,
			REPLY_DATA => reply_data,
			REPLY_VALID => reply_valid,
			SDA => I2C_SDA,
			SCL => I2C_SCL
--			SDA => i2c_debug_sda,
--			SCL => i2c_debug_scl
		);
		
		
		
		
		-- Simulation only!
--		ram : block is
--		
--			type ram_t is array(0 to 10) of std_logic_vector(7 downto 0);
--			signal ram_data : ram_t := 
--			(
--				0 => x"12",
--				1 => x"34",
--				2 => x"56",
--				3 => x"78",
--				4 => x"33",
--				5 => x"FF",
--				6 => x"FF",
--				7 => x"FF",
--				others => x"00"
--			);
--		
--		begin
--			process(SYSCLK) is
--			begin
--			if(rising_edge(SYSCLK)) then
--				if(RAM_WE = '1') then
--					ram_data(to_integer(unsigned(RAM_ADDR))) <= RAM_WDATA;
--				end if;
--				RAM_RDATA <= ram_data(to_integer(unsigned(RAM_ADDR)));
--			end if;
--			end process;
--		end block;
--		
--		Inst_i2c_slave: i2c_slave 
--		generic map (
--			SLAVE_ADDRESS => "1101001"
--		)
--		PORT MAP(
--			CLK => SYSCLK,
--			SDA => i2c_debug_sda,
--			SCL => i2c_debug_scl,
--			RAM_ADDR => RAM_ADDR,
--			RAM_WDATA => RAM_WDATA,
--			RAM_WE => RAM_WE,
--			RAM_RDATA => RAM_RDATA
--		);
		
		
		
		
		
		
		
		
		
		process(SYSCLK) is
		begin
		if(rising_edge(SYSCLK)) then
		case state is
			when STARTUP =>
				-- wait 1 second before continuing
				count <= 100000000;
				--count <= 10;
				state <= DELAY;
				ret <= SEND;
				
			when SEND =>
				reg <= startup_reg(startup_index);
				write_data <= startup_data(startup_index);
				cmd_write <= '1';
				state <= WAIT_FOR_REPLY;
				--state <= HALT;
			
			when HALT =>
				cmd_write <= '0';
				
			when WAIT_FOR_REPLY =>
				cmd_write <= '0';
				if(reply_valid = '1') then
					if(reply_ack = '1') then
						if(startup_index = startup_reg'high) then
							-- finished
							state <= NORMAL;
						else
							startup_index <= startup_index + 1;
							state <= SEND;
						end if;
					else
						-- Notice that I'm not incrementing on NACK.
						-- This will cause the same message to be attempted
						-- forever, which is useful for debugging on the scope
						count <= 100000000;
						state <= DELAY;
						ret <= SEND;
					end if;
				end if;
				
			when NORMAL =>
				-- read register 00, which is the seconds
				reg <= x"00";
				cmd_read <= '1';
				state <= WAIT_FOR_REPLY_N;
			
			when WAIT_FOR_REPLY_N =>
				cmd_read <= '0';
				if(reply_valid = '1') then
					if(reply_ack = '1') then
						lights(7 downto 0) <= x"0" & reply_data(3 downto 0);
						lights(15 downto 8) <= x"0" & reply_data(7 downto 4);
					else
						lights <= (others => '1');
					end if;
					
					-- wait for 1 ms so I don't go too crazy
					count <= 100000;
					state <= DELAY;
					ret <= NORMAL;
				end if;
				
					
				
			when DELAY =>
				if(count = 0) then
					state <= ret;
				else
					count <= count - 1;
				end if;
		end case;
		end if;
		end process;
		
		
		B0_GPIO0 <= lights(0);
		B1_GPIO1 <= lights(1);
		B1_GPIO2 <= lights(2);
		B1_GPIO3 <= lights(3);
		B1_GPIO4 <= lights(4);
		B1_GPIO5 <= lights(5);
		B1_GPIO6 <= lights(6);
		B1_GPIO7 <= lights(7);
		B1_GPIO8 <= lights(8);
		B1_GPIO9 <= lights(9);
		B1_GPIO10 <= lights(10);
		B1_GPIO11 <= lights(11);
		B1_GPIO12 <= lights(12);
		B1_GPIO13 <= lights(13);
		B1_GPIO14 <= lights(14);
		B1_GPIO15 <= lights(15);
	
	end block;


	blinker : block is
		signal val : std_logic_vector(15 downto 0) := x"0001";
		signal count : natural := 0;
	begin
	
--		process(SYSCLK) is
--		begin
--		if(rising_edge(SYSCLK)) then
--			if(count = 100000000 / 16) then
--				count <= 0;
--				val(15 downto 1) <= val(14 downto 0);
--				val(0) <= val(15);
--			else
--				count <= count + 1;
--			end if;
--		end if;
--		end process;
--		
--		B0_GPIO0 <= val(0);
--		B1_GPIO1 <= val(1);
--		B1_GPIO2 <= val(2);
--		B1_GPIO3 <= val(3);
--		B1_GPIO4 <= val(4);
--		B1_GPIO5 <= val(5);
--		B1_GPIO6 <= val(6);
--		B1_GPIO7 <= val(7);
--		B1_GPIO8 <= val(8);
--		B1_GPIO9 <= val(9);
--		B1_GPIO10 <= val(10);
--		B1_GPIO11 <= val(11);
--		B1_GPIO12 <= val(12);
--		B1_GPIO13 <= val(13);
--		B1_GPIO14 <= val(14);
--		B1_GPIO15 <= val(15);

		B1_GPIO24 <= '0';
		B1_GPIO25 <= '0';
	
	end block;

end Behavioral;

