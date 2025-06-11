library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity PILI1BIT is
port(	RESET,CLK:in std_logic;
		INV_OUT:out std_logic_vector(7 downto 0));
end PILI1BIT;

architecture arch of PILI1BIT is
signal DIVIDER:std_logic_vector(9 downto 0);
signal COUNT_CLK:std_logic;
signal COUNTER:integer range 0 to 15;
begin

--(1)除頻電路
process(CLK,RESET)
begin
	if RESET='0' then 
		DIVIDER<="0000000000";
	elsif CLK'event and CLK='1' then
		DIVIDER<=DIVIDER+1;
	end if;
end process;
COUNT_CLK<=DIVIDER(8);

--(2)除16計數電路
process(COUNT_CLK,RESET)
begin
	if RESET='0' then
		COUNTER<=0;
	elsif COUNT_CLK'event and COUNT_CLK='1' then
		COUNTER<=COUNTER+1;
    end if;
end process;

--(3)解碼電路
with COUNTER select
INV_OUT<=	"01111111" when 0,
			"10111111" when 1,
			"11011111" when 2,
			"11101111" when 3,
			"11110111" when 4,
			"11111011" when 5,
			"11111101" when 6,
			"11111110" when 7,
			"11111110" when 8,
			"11111101" when 9,
			"11111011" when 10,
			"11110111" when 11,
			"11101111" when 12,
			"11011111" when 13,
			"10111111" when 14,
			"01111111" when others;
end arch;

