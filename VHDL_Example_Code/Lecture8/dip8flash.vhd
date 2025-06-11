library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DIP8FLASH is
	port 
	(	CLOCK_50:in std_logic;		
		KEY:in std_logic_vector(2 downto 0);
		SW:in std_logic_vector(7 downto 0);
		LEDG:out std_logic_vector(7 downto 0));
end DIP8FLASH;

architecture arch of DIP8FLASH is

	constant divisor: integer := 5_000_000;
	signal CLK, RESET, round: std_logic;
	signal count_10hz, count_1hz: integer range 0 to 5000000 := 0;
	signal CLK_10hz, CLK_5hz, CLK_1hz : std_logic;
	signal FLASH, DIP: std_logic_vector(7 downto 0);
begin
	CLK <= CLOCK_50;
	RESET <= KEY(1);
	DIP <= SW;
	
-- clock divider => 10Hz
	process(CLK)
	begin
		IF CLK'event and CLK='1' THEN
			IF count_10hz <  divisor/2-1 THEN
				count_10hz <= count_10hz + 1;
			ELSE
				count_10hz <= 0;
				CLK_10hz <= NOT CLK_10hz;
			END IF;
		END IF;
	end process;
	
-- clock divider => 5Hz , divide by 2
	process(CLK)
	begin
		IF CLK_10hz'event and CLK_10hz='1' THEN
			CLK_5hz <= NOT CLK_5hz;
		END IF;
	end process;
	
-- clock divider => 1Hz , divide by 10
	process(CLK)
	begin
		IF CLK_10hz'event and CLK_10hz='1' THEN
			IF count_1hz < 4  THEN
				count_1hz <= count_1hz + 1;
			ELSE
				count_1hz <= 0;
				CLK_1hz <= NOT CLK_1hz;
			END IF;
		END IF;
	end process;
	
--flash circuit
	process(CLK_1hz,RESET)
	begin
		if RESET ='0' then 
			FLASH <= "00000000";
			round <= '0';
		elsif CLK_1hz'event and CLK_1hz='1' then
			if round = '1' then
				FLASH <= DIP;
			else
				FLASH <= "00000000";
			end if;
			round <= NOT round;
		end if;	
	end process;
	
	LEDG<=FLASH;
	
end arch;
