--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package pkg_types is

	type vic_settings is record
		total_horizontal_line_length              : std_logic_vector(11 downto 0);
		horizontal_front_porch                    : std_logic_vector(11 downto 0);
		horizontal_back_porch                     : std_logic_vector(11 downto 0);
		horizontal_sync_pulse_width               : std_logic_vector(11 downto 0);
		total_number_of_vertical_lines_in_field_0 : std_logic_vector(11 downto 0);
		vertical_front_porch_field_0              : std_logic_vector(11 downto 0);
		vertical_back_porch_field_0               : std_logic_vector(11 downto 0);
		vertical_sync_pulse_in_field_0            : std_logic_vector(11 downto 0);
		HV_offset_field_0                         : std_logic_vector(11 downto 0);
		total_number_of_vertical_lines_in_field_1 : std_logic_vector(11 downto 0);
		vertical_front_porch_field_1              : std_logic_vector(11 downto 0);
		vertical_back_porch_field_1               : std_logic_vector(11 downto 0);
		vertical_sync_pulse_in_field_1            : std_logic_vector(11 downto 0);
		HV_offset_field_1                         : std_logic_vector(11 downto 0);
		interlaced                                : std_logic;
	end record;
	
	type burst_t is array(natural range <>) of std_logic_vector(3 downto 0);

-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end pkg_types;

package body pkg_types is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end pkg_types;
