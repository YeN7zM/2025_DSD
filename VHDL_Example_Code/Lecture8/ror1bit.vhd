library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ROR1BIT is
port(	RESET,CLK:in std_logic;
		INV_OUT:out std_logic_vector(7 downto 0));
end ROR1BIT;

architecture arch of ROR1BIT is
signal DIVIDER:std_logic_vector(9 downto 0);
signal SHIFT_CLK:std_logic;
signal SHIFT_OUT:std_logic_vector(7 downto 0);
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
SHIFT_CLK<=DIVIDER(9);

--(2)LED 移位電路 
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then
		SHIFT_OUT<="10000000";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		SHIFT_OUT<=SHIFT_OUT(0)&SHIFT_OUT(7 downto 1);
	end if;
end process;

--(3)反向電路
INV_OUT<=not(SHIFT_OUT);
end arch;

