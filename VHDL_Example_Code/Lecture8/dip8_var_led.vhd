library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity DIP8_VAR_LED2 is
	port 
	(	RESET,CLK:in std_logic;
		DIP:in std_logic_vector(3 downto 0);
		LED:out std_logic_vector(7 downto 0));
end DIP8_VAR_LED2;

architecture arch of DIP8_VAR_LED2 is
signal DIVIDER:std_logic_vector(9 downto 0);
signal SHIFT_CLK:std_logic;
signal PATTERN0:std_logic_vector(7 downto 0);
signal PATTERN1:std_logic_vector(7 downto 0);
signal PATTERN2:std_logic_vector(7 downto 0);
signal PATTERN3:std_logic_vector(7 downto 0);
signal COUNTER:integer range 0 to 15;
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
SHIFT_CLK<=DIVIDER(8);

--shift right circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		PATTERN0<="01111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
			PATTERN0<=PATTERN0(0)&PATTERN0(7 downto 1);
	end if;	
end process;

--shift left circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		PATTERN1<="11111110";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		PATTERN1<=PATTERN1(6 downto 0)&PATTERN1(7);
	end if;	
end process;

--flash circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		PATTERN2<="11111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		PATTERN2<=not PATTERN2;
	end if;	
end process;

--pili circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		COUNTER<=0;
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		COUNTER<=COUNTER+1;
    end if;
end process;
--pili
with COUNTER select
PATTERN3<=	"01111111" when 0,
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
				
--mulplexer circuit
with DIP select
LED<=	PATTERN3 when "0111",
		PATTERN2 when "1011",
		PATTERN1 when "1101",
		PATTERN0 when "1110",
		"11111111" when others;
end arch;
