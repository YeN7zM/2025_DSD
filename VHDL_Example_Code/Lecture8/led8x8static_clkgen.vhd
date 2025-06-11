library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity LED8X8STATIC_CLKGEN is
	port 
	(	
		CLOCK_50:in std_logic;		
		KEY:in std_logic_vector(2 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to back-side pin16~pin9 of 8x8 led
		GPIO_1:out std_logic_vector(21 downto 9)  );   -- connect to front-side pin1~pin8 of 8x8 led
end LED8X8STATIC_CLKGEN;

architecture arch of LED8X8STATIC_CLKGEN is
	component CLK_GEN is
		generic( divisor: integer := 50_000_000 );
		port 
		(	
			clock_in				: IN	STD_LOGIC;
			clock_out			: OUT	STD_LOGIC); 
	end component;
	
--	constant divisor: integer := 50000;
	signal CLK, RESET: std_logic;
--	signal counter: integer range 0 to 50000 := 0;
	signal CLK_1khz, SCAN_CLK: std_logic;
	signal SCANLINE:integer range 0 to 7;
	signal ROW, COL: std_logic_vector(1 to 8);

begin
	CLK_U1: CLK_GEN generic map(divisor => 50_000) port map(CLOCK_50, CLK_1khz); 
	SCAN_CLK <= CLK_1khz;
	
	RESET <= KEY(1);
	
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

--display circuit, for 1088AS 8x8 leds
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
	COL <=	"00011000" when 0,
				"00100100" when 1,
				"01000010" when 2,
				"01000010" when 3,
				"01111110" when 4,
				"01000010" when 5,
				"01000010" when 6,
				"01000010" when 7,
				"00000000" when others;

-- back-side
	GPIO_0(21) <= COL(8);  GPIO_0(19) <= COL(7);	GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
	GPIO_0(14) <= ROW(4);  GPIO_0(13) <= COL(6);	GPIO_0(11) <= COL(4); GPIO_0(9) <= ROW(1);
-- front-side	
	GPIO_1(21) <= ROW(5);  GPIO_1(19) <= ROW(7);	GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
	GPIO_1(14) <= ROW(8);  GPIO_1(13) <= COL(5);	GPIO_1(11) <= ROW(6); GPIO_1(9) <= ROW(3);
	
end arch;