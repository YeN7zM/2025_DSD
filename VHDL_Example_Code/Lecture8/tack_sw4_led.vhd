library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TACK_SW4_LED is
	port 
	(	RESET,CLK:in std_logic;
		SW:in std_logic_vector(3 downto 0);
		LED:out std_logic_vector(7 downto 0));
end TACK_SW4_LED;

architecture arch of TACK_SW4_LED is
signal DIVIDER:std_logic_vector(9 downto 0);
signal SHIFT_CLK:std_logic;
signal SAMPLE_CLK:std_logic;
signal DEBOUNCE_SW:std_logic_vector(3 downto 0);
signal SEL:std_logic_vector(3 downto 0);
signal CNT0:std_logic_vector(4 downto 0);
signal CNT1:std_logic_vector(4 downto 0);
signal CNT2:std_logic_vector(4 downto 0);
signal CNT3:std_logic_vector(4 downto 0);
signal LED0:std_logic_vector(7 downto 0);
signal LED1:std_logic_vector(7 downto 0);
signal LED2:std_logic_vector(7 downto 0);
signal LED3:std_logic_vector(7 downto 0);
signal DIRECT:std_logic;
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
SHIFT_CLK<=DIVIDER(9);
SAMPLE_CLK<=DIVIDER(2);

--debounce circuit
process(SAMPLE_CLK,RESET)
begin
	if RESET='0' then
		DEBOUNCE_SW<="1111";
		SEL<="0000";
	elsif SAMPLE_CLK'event and SAMPLE_CLK='1' then
		CNT0<=CNT0(3 downto 0)&SW(0);
		if (CNT0="00000" and DEBOUNCE_SW(0)='1') then
			DEBOUNCE_SW(0)<='0';
			SEL<="0001";
		end if;
		if (CNT0="11111") then
			DEBOUNCE_SW(0)<='1';
		end if;
		CNT1<=CNT1(3 downto 0)&SW(1);
		if (CNT1="00000" and DEBOUNCE_SW(1)='1') then
			DEBOUNCE_SW(1)<='0';
			SEL<="0010";
		end if;
		if (CNT1="11111") then
			DEBOUNCE_SW(1)<='1';
		end if;
		CNT2<=CNT2(3 downto 0)&SW(2);
		if (CNT2="00000" and DEBOUNCE_SW(2)='1') then
			DEBOUNCE_SW(2)<='0';
			SEL<="0100";
		end if;
		if (CNT2="11111") then
			DEBOUNCE_SW(2)<='1';
		end if;
		CNT3<=CNT3(3 downto 0)&SW(3);
		if (CNT3="00000" and DEBOUNCE_SW(3)='1') then
			DEBOUNCE_SW(3)<='0';
			SEL<="1000";
		end if;
		if (CNT3="11111") then
			DEBOUNCE_SW(3)<='1';
		end if;	
	end if;
end process;

--shift right circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		LED0<="01111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
			LED0<=LED0(0)&LED0(7 downto 1);
	end if;	
end process;

--shift left circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		LED1<="11111110";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		LED1<=LED1(6 downto 0)&LED1(7);
	end if;	
end process;

--flash circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		LED2<="11111111";
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		LED2<=not LED2;
	end if;	
end process;

--pili circuit
process(SHIFT_CLK,RESET)
begin
	if RESET='0' then 
		LED3<="01111111";
		DIRECT<='0';
	elsif SHIFT_CLK'event and SHIFT_CLK='1' then
		if DIRECT<='0' then
			if (LED3="11111110") then
			    DIRECT<='1';
			else
				LED3<=LED3(0)&LED3(7 downto 1);
			end if;
		else
			if (LED3="01111111") then
				DIRECT<='0';
			else
				LED3<=LED3(6 downto 0)&LED3(7);
			end if;
		end if;
    end if;
end process;

--mulplexer circuit
with SEL select
LED<=	LED0 when "0001",
		LED1 when "0010",
		LED2 when "0100",
		LED3 when "1000",
		"11111111" when others;
end arch;
