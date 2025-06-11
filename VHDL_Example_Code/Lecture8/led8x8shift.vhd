--
-- Display character 'A' on an 8x8 led matrix (1088AS common anode)
-- Press button(0) to reset 
-- Press button(1) once to continuously shift right
-- Press button(2) once to continuously shift left
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity LED8X8SHIFT is
	port 
	(	
		CLOCK_50:in std_logic;		
		KEY:in std_logic_vector(2 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to back-side pin16~pin9 of 8x8 led
		GPIO_1:out std_logic_vector(21 downto 9)  );   -- connect to front-side pin1~pin8 of 8x8 led
end LED8X8SHIFT;

architecture arch of LED8X8SHIFT is
	type LED8x8_type is array (1 to 8) of std_logic_vector(1 to 8);   -- each array stores the pattern of a row
	constant CHAR_ROM : LED8x8_type := (1 => "00011000",         	   -- . . . * * . . .             
												   2 => "00100100",					-- . . * . . * . .
													3 => "01000010",					-- . * . . . . * .
													4 => "01000010",					-- . * . . . . * .
													5 => "01111110",					-- . * * * * * * .
													6 => "01000010",					-- . * . . . . * .
													7 => "01000010",					-- . * . . . . * .
													8 => "01000010");					-- . * . . . . * .
	constant divisor: integer := 50000;
	
	signal CLK, RESET: std_logic;
	signal count_1khz, count_1hz: integer range 0 to 25000 := 0;
	signal CLK_1khz, CLK_1hz, SCAN_CLK, SHIFT_CLK: std_logic;
	signal SCANLINE:integer range 0 to 7;
	signal Buttons, shift_dir: std_logic_vector(1 downto 0);
	signal ROW, COL: std_logic_vector(1 to 8);
	signal LED8x8map: LED8x8_type;

begin

	CLK <= CLOCK_50;
	RESET <= KEY(0);
	Buttons <= KEY(2)&KEY(1);
	
-- Divide CLK by divisor => 1kHz
	process(CLK)
	begin
		IF CLK'event and CLK='1' THEN
			IF count_1khz <  divisor/2-1 THEN
				count_1khz <= count_1khz + 1;
			ELSE
				count_1khz <= 0;
				CLK_1khz <= NOT CLK_1khz;
			END IF;
		END IF;
	end process;
	
-- Divide CLK_1khz by 1000 => CLK_1hz
	process(CLK_1khz)
	begin
		IF CLK_1khz'event and CLK_1khz='1' THEN
			IF count_1hz <  499 THEN
				count_1hz <= count_1hz + 1;
			ELSE
				count_1hz <= 0;
				CLK_1hz <= NOT CLK_1hz;
			END IF;
		END IF;
	end process;
	
	SCAN_CLK <= CLK_1khz;
	SHIFT_CLK <= CLK_1hz;
	
--sample buttons 
	process(CLK_1khz, RESET)
	begin
		if RESET='0' then
			shift_dir <= "00";
		elsif CLK_1khz'event and CLK_1khz='1' then
			if (Buttons = "10" or Buttons = "01") then 
				shift_dir <= NOT Buttons;
			end if;
		end if;
	end process; 
	
--scan circuit
	process(SCAN_CLK, RESET)
	begin
		if RESET='0' then
			SCANLINE <= 0;
		elsif SCAN_CLK'event and SCAN_CLK='1' then
			if SCANLINE = 7 then 
				SCANLINE <= 0;
			else
				SCANLINE<=SCANLINE + 1;
			end if;
		end if;
	end process; 

--display circuit
	with SCANLINE select
	ROW <=	"01111111" when 0,
				"10111111" when 1,
				"11011111" when 2,
				"11101111" when 3,
				"11110111" when 4,
				"11111011" when 5,
				"11111101" when 6,
				"11111110" when 7,
				"11111111" when others;
		
	with SCANLINE select
	COL <=	LED8x8map(1) when 0,
				LED8x8map(2) when 1,
				LED8x8map(3) when 2,
				LED8x8map(4) when 3,
				LED8x8map(5) when 4,
				LED8x8map(6) when 5,
				LED8x8map(7) when 6,
				LED8x8map(8) when 7,
				"00000000" when others;

--shift circuit
	process(SHIFT_CLK, RESET)
	begin
		if RESET='0' then
			LED8x8map <= CHAR_ROM;
		elsif SHIFT_CLK'event and SHIFT_CLK='1' then
			case shift_dir is
				when "01" =>	 -- shift right
					for i in 1 TO 8 LOOP
						LED8x8map(i) <= LED8x8map(i)(8)& LED8x8map(i)(1 to 7);
					end loop ;
				when "10" =>	 -- shift left
					for i in 1 TO 8 LOOP
						LED8x8map(i) <= LED8x8map(i)(2 to 8)& LED8x8map(i)(1);
					end loop ;
				when others =>
					LED8x8map <= LED8x8map;
			end case;
		end if;
	end process; 
	
-- back-side
	GPIO_0(21) <= COL(8);  GPIO_0(19) <= COL(7);	GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
	GPIO_0(14) <= ROW(4);  GPIO_0(13) <= COL(6);	GPIO_0(11) <= COL(4); GPIO_0(9) <= ROW(1);
-- front-side	
	GPIO_1(21) <= ROW(5);  GPIO_1(19) <= ROW(7);	GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
	GPIO_1(14) <= ROW(8);  GPIO_1(13) <= COL(5);	GPIO_1(11) <= ROW(6); GPIO_1(9) <= ROW(3);
	
end arch;