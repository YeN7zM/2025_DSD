library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity DIP8_VAR_SHIFT is
	port 
	(	RESET,CLK:in std_logic;
		DIP:in std_logic_vector(7 downto 0);
		LED:out std_logic_vector(7 downto 0));
end DIP8_VAR_SHIFT;

architecture arch of DIP8_VAR_SHIFT is
signal DIVIDER:std_logic_vector(9 downto 0);
signal SHIFT_CLK:std_logic;
signal PATTERN:std_logic_vector(7 downto 0);
begin

--divider
process(CLK,RESET)
begin
	if RESET='0' then 
		DIVIDER<="0000000000";
	elsif CLK'event and CLK='1' then
		DIVIDER<=DIVIDER+1;
	end if;
end process;

--multiplxer
with DIP select
SHIFT_CLK<=	DIVIDER(2)  when "01111111",
			DIVIDER(3)  when "10111111",
			DIVIDER(4) 	when "11011111",
			DIVIDER(5) 	when "11101111",
			DIVIDER(6) 	when "11110111",
			DIVIDER(7) 	when "11111011",
			DIVIDER(8) 	when "11111101",
			DIVIDER(9) 	when others;
				
--shift circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		PATTERN<="01111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		PATTERN<=PATTERN(0)&PATTERN(7 downto 1);
	end if;	
end process;

--buffer circuit
LED<=PATTERN;
end arch;
