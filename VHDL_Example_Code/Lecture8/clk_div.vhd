--
-- Generate 1kHz, 100Hz, 10Hz, and 1Hz clock signals
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CLK_DIV is
	port 
	(	
		clock_50Mhz				: IN	STD_LOGIC;
		clock_1KHz				: OUT	STD_LOGIC;
		clock_100Hz				: OUT	STD_LOGIC;
		clock_10Hz				: OUT	STD_LOGIC;
		clock_1Hz				: OUT	STD_LOGIC); 
end CLK_DIV;

architecture arch of CLK_DIV is
	constant divisor: integer := 50000;
	signal count_1khz: integer range 0 to 25000 := 0;
	signal count_100hz, count_10hz, count_1hz: STD_LOGIC_VECTOR(2 DOWNTO 0);
	signal CLK_1khz, CLK_100hz, CLK_10hz, CLK_1hz: STD_LOGIC;
	
begin
	clock_1KHz <= CLK_1khz;
	clock_100Hz <= CLK_100hz;
	clock_10Hz <= CLK_10hz;
	clock_1Hz <= CLK_1hz;
	
-- Divide 50Mhz clock by 50000 => 1kHz
	process(clock_50Mhz)
	begin
		IF clock_50Mhz'event and clock_50Mhz='1' THEN
			IF count_1khz <  divisor/2-1 THEN
				count_1khz <= count_1khz + 1;
			ELSE
				count_1khz <= 0;
				CLK_1khz <= NOT CLK_1khz;
			END IF;
		END IF;
	end process;
	
-- Divide by 10 
	process(CLK_1khz)
	begin
		IF CLK_1khz'event and CLK_1khz='1' THEN
			IF count_100hz <  4 THEN
				count_100hz <= count_100hz + 1;
			ELSE
				count_100hz <= "000";
				CLK_100hz <= NOT CLK_100hz;
			END IF;
		END IF;
	end process;
	
	-- Divide by 10 
	process(CLK_100hz)
	begin
		IF CLK_100hz'event and CLK_100hz='1' THEN
			IF count_10hz <  4 THEN
				count_10hz <= count_10hz + 1;
			ELSE
				count_10hz <= "000";
				CLK_10hz <= NOT CLK_10hz;
			END IF;
		END IF;
	end process;
	
	-- Divide by 10 
	process(CLK_10hz)
	begin
		IF CLK_10hz'event and CLK_10hz='1' THEN
			IF count_1hz <  4 THEN
				count_1hz <= count_1hz + 1;
			ELSE
				count_1hz <= "000";
				CLK_1hz <= NOT CLK_1hz;
			END IF;
		END IF;
	end process;
	
end arch;