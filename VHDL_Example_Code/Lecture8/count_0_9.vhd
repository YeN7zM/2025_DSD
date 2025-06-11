library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity COUNT_0_9 is
port(	CLOCK_50:in std_logic;		
		KEY:in std_logic_vector(2 downto 0);
		HEX0: out std_logic_vector(0 to 7)  );
end COUNT_0_9;

architecture arch of COUNT_0_9 is

constant divisor: integer := 5_000_000;
signal CLK, RESET: std_logic;
signal count_10hz:integer range 0 to divisor := 0; 
signal CLK_10hz, Button, prev_Button:std_logic;
signal COUNTER, fortune_number, display_number:integer range 0 to 9;
signal round:integer range 0 to 1 := 0;
signal SEGMENT:std_logic_vector(0 to 7);

begin
--
	CLK <= CLOCK_50;
	RESET <= KEY(0);
	Button <= KEY(1);
	HEX0 <= SEGMENT;
	
-- clock divider => 10Hz
	process(CLK)
	begin
		IF CLK'event and CLK='1' THEN
			IF count_10hz < divisor/2-1 THEN
				count_10hz <= count_10hz + 1;
			ELSE
				count_10hz <= 0;
				CLK_10hz <= NOT CLK_10hz;
			END IF;
		END IF;
	end process;
	
-- 0~9 counter
process(CLK_10hz,RESET)
begin
	if RESET='0' then
		COUNTER<=0;
		round <= 0;
	elsif CLK_10hz'event and CLK_10hz='1' then
		prev_Button<=Button;
		if(prev_Button = '1' AND Button = '0') THEN    -- check to see if KEY(1)is pressed
			round<=round+1;
			fortune_number <= COUNTER;                  
		elsif COUNTER=9 then 
			COUNTER<=0;
		else
			COUNTER<=COUNTER+1;
		end if;
    end if;
end process;

--Multiplexer
with round select
display_number <= fortune_number when 1,
					   COUNTER        when others;
	
-- seven-segment display	
with display_number select
SEGMENT<="00000011" when 0,
		 	"10011111" when 1,
		 	"00100101" when 2,
		 	"00001101" when 3,
		 	"10011001" when 4,
		 	"01001001" when 5,
		 	"01000001" when 6,
		 	"00011111" when 7,
			"00000001" when 8,
		 	"00001001" when 9,
		 	"11111111" when others;
end arch;

