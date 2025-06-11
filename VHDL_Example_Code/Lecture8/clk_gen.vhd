--
-- Generate the user-specified clock signal (setting by divisor)
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CLK_GEN is
	generic( divisor: integer := 50_000_000 );
	port 
	(	
		clock_in				: IN	STD_LOGIC;
		clock_out			: OUT	STD_LOGIC); 
end CLK_GEN;

architecture arch of CLK_GEN is
	signal count: integer range 0 to divisor := 0;
	signal CLK_out: STD_LOGIC;
begin
	
	process(clock_in)
	begin
		IF clock_in'event and clock_in='1' THEN
			IF count <  divisor/2-1 THEN
				count <= count + 1;
			ELSE
				count <= 0;
				CLK_out <= NOT CLK_out;
			END IF;
		END IF;
		clock_out <= CLK_out;
	end process;
	
end arch;