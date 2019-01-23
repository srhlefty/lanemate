library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VComponents.all;

-- This module allows you to route a clock signal to a non-clock pin.

entity clock_forwarding is
	Generic( INVERT : boolean);
    Port ( CLK : in  STD_LOGIC;
           CLKO : out  STD_LOGIC);
end clock_forwarding;

architecture Behavioral of clock_forwarding is

	signal clkinv : std_logic;

begin

	clkinv <= not CLK;

gen_inv: if (INVERT=true) generate

   ODDR2_inst : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0',             -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC")        -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => CLKO,    -- 1-bit output data
      C0 => clkinv,    -- 1-bit clock input
      C1 => CLK, -- 1-bit clock input
      CE => '1',    -- 1-bit clock enable input
      D0 => '1',    -- 1-bit data input (associated with C0)
      D1 => '0',    -- 1-bit data input (associated with C1)
      R => '0',     -- 1-bit reset input
      S => '0'      -- 1-bit set input
   );

end generate gen_inv;

gen_norm: if (INVERT=false) generate

   ODDR2_inst : ODDR2
   generic map(
      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
      INIT => '0',             -- Sets initial state of the Q output to '0' or '1'
      SRTYPE => "SYNC")        -- Specifies "SYNC" or "ASYNC" set/reset
   port map (
      Q => CLKO,    -- 1-bit output data
      C0 => CLK,    -- 1-bit clock input
      C1 => clkinv, -- 1-bit clock input
      CE => '1',    -- 1-bit clock enable input
      D0 => '1',    -- 1-bit data input (associated with C0)
      D1 => '0',    -- 1-bit data input (associated with C1)
      R => '0',     -- 1-bit reset input
      S => '0'      -- 1-bit set input
   );

end generate gen_norm;


end Behavioral;

