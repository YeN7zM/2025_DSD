library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TACK_SW1_LED is
port 
(	RESET,CLK:in std_logic;
	SW:in std_logic;
	LED:out std_logic_vector(7 downto 0));
end TACK_SW1_LED;

architecture arch of TACK_SW1_LED is
signal DIVIDER:std_logic_vector(9 downto 0);
signal SHIFT_CLK:std_logic;
signal SAMPLE_CLK:std_logic;
signal DEBOUNCE_SW:std_logic;
signal CNT:std_logic_vector(4 downto 0);
signal DIRECT:std_logic;
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
SAMPLE_CLK<=DIVIDER(2);
SHIFT_CLK<=DIVIDER(9);

--debounce circuit
process(SAMPLE_CLK,RESET)
begin
	if RESET='0' then
		DEBOUNCE_SW<='1';
	elsif SAMPLE_CLK'event and SAMPLE_CLK='1' then
		CNT<=CNT(3 downto 0)&SW;
		if (CNT="00000") then
			DEBOUNCE_SW<='0';
		else
			DEBOUNCE_SW<='1';
		end if;
	end if;
end process;

--direction circuit
process(DEBOUNCE_SW,RESET)
begin
	if RESET='0' then
		DIRECT<='0';
	elsif DEBOUNCE_SW'event and DEBOUNCE_SW='0' then
		DIRECT<=not DIRECT;
	end if;
end process;

--shift circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		PATTERN<="01111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
			if DIRECT='0' then
				PATTERN<=PATTERN(0)&PATTERN(7 downto 1);
			else
				PATTERN<=PATTERN(6 downto 0)&PATTERN(7);
			end if;
	end if;	
end process;
LED<=PATTERN;
end arch;
