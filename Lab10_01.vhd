LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Lab10_01 IS
PORT ( CLOCK_50:in std_logic;
		KEY:in std_logic_vector(2 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
		GPIO_1:out std_logic_vector(21 downto 9) );    -- connect to lcd pin16 to pin9  
END Lab10_01;

ARCHITECTURE a OF Lab10_01 IS

component CLK_GEN is
		generic( divisor: integer := 50_000_000 );
		port 
		(	
			clock_in				: IN	STD_LOGIC;
			clock_out			: OUT	STD_LOGIC); 
end component;
	
TYPE state_type IS
 (init1,init2,s10,s11,s12,s13,s20,s21,s22,s23,hold);
SIGNAL state: state_type;

signal RESET, LCM_CLK, CLK_500hz:std_logic;
signal LCM_RS, LCM_RW, LCM_EN :std_logic;
signal LCM_DB:std_logic_vector(7 downto 0);
TYPE INIT_Array IS ARRAY(0 to 7) OF std_logic_vector(7 downto 0);
	-- LCD initialization procedure codes
	-- 0x38 init four times
	-- 0x08 Display control: Display OFF; Cursor OFF; Blink OFF
	-- 0x01 Display clear
	-- 0x0C Display control: Display ON; Cursor OFF; Blink OFF
	-- 0x06 Entry mode set: Increment One; No Shift
	
Signal Init_LCM: Init_Array := (x"38",x"38",x"38",x"38",x"08",x"01",x"0C",x"06");

TYPE DDRAM IS ARRAY(0 to 15) OF std_logic_vector(7 downto 0);
--"IECS Digital...."
signal LINE1:DDRAM:=(x"49",x"45",x"43",x"53",x"20",x"44",x"69",x"67",x"69", x"74",x"61",x"6C",x"2E",x"2E",x"2E",x"2E");
--"System Design..."
signal LINE2:DDRAM:=(x"53",x"79",x"73",x"74",x"65",x"6D",x"20",x"44",x"65",x"73",x"69",x"67",x"6E",x"2E",x"2E",x"2E");
signal LINE3:DDRAM:=(x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20");
signal LINE4:DDRAM:=(x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20");
signal TEMP:std_logic_vector(7 downto 0);
signal STATE_NUM: integer range 0 to 1:= 1;

----------------------------------------------------------------
--             ASCII Character Generator ROM Pattern
--                            Lower 4 bit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
----------------------------------------------------------------

SIGNAL index: Integer;

BEGIN
--generate 500hz clock
CLK_U1: CLK_GEN generic map(divisor => 100_000) port map(CLOCK_50, CLK_500hz); 
  
LCM_CLK<= CLK_500hz;  -- 2ms

PROCESS(LCM_CLK, KEY)
BEGIN
IF(KEY(1) = '0') THEN
	index <= 0;
	STATE_NUM <= 0;
	state <= init1;
ELSIF(KEY(2) = '0') THEN
	index <= 0;
	STATE_NUM <= 1;
	state <= init1;
ELSIF(LCM_CLK'EVENT AND LCM_CLK = '1') THEN
	IF STATE_NUM = 1 THEN
	CASE state IS
		-- LCD initialization procedure
		-- Toggle E line - falling edge loads inst/data to LCD controller
		WHEN init1 =>
			LCM_DB <= Init_LCM (index);
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= init2;
		WHEN init2 =>
			LCM_EN <= '0';	-- set EN=0;
			index <= index + 1;
			IF index + 1 <= 7 THEN
		state <= init1;
			ELSE
				state <= s10;
			END IF;

		-- Move cursor to the first row
		WHEN s10 =>
			LCM_DB <= x"80";	-- x80 is the address of the 1st character of the first row
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= s11;
		WHEN s11 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= 0;
			state <= s12;

		-- show characters on 1st row
		WHEN s12 =>
			LCM_DB <= LINE1(index);
			LCM_EN <= '1';	LCM_RS <= '1';	LCM_RW <= '0';	
			state <= s13;
		WHEN s13 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= index + 1;
			IF index + 1 <= 15 THEN
				state <= s12;
			ELSE
				state <= s20;
			END IF;

		-- Move cursor to the second row
		WHEN s20 =>
			LCM_DB <= x"C0";	-- xC0 is the address of the 1st character of the second row
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= s21;
		WHEN s21 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= 0;
			state <= s22;

		-- show characters on 2nd row
		WHEN s22 =>
			LCM_DB <= LINE2(index);
			LCM_EN <= '1';	LCM_RS <= '1';	LCM_RW <= '0';
			state <= s23;
		WHEN s23 =>
			LCM_EN <= '0';	-- set EN=0;
			index <= index + 1;
			IF index + 1 <= 15 THEN
				state <= s22;
			ELSE
				state <= hold;
			END IF;
		WHEN hold =>
			state <= hold;
		WHEN OTHERS =>
			state <= hold;
		END CASE;
		ELSIF STATE_NUM = 0 THEN
			CASE state IS
		-- LCD initialization procedure
		-- Toggle E line - falling edge loads inst/data to LCD controller
		WHEN init1 =>
			LCM_DB <= Init_LCM (index);
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= init2;
		WHEN init2 =>
			LCM_EN <= '0';	-- set EN=0;
			index <= index + 1;
			IF index + 1 <= 7 THEN
		state <= init1;
			ELSE
				state <= s10;
			END IF;

		-- Move cursor to the first row
		WHEN s10 =>
			LCM_DB <= x"80";	-- x80 is the address of the 1st character of the first row
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= s11;
		WHEN s11 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= 0;
			state <= s12;

		-- show characters on 1st row
		WHEN s12 =>
			LCM_DB <= LINE3(index);
			LCM_EN <= '1';	LCM_RS <= '1';	LCM_RW <= '0';	
			state <= s13;
		WHEN s13 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= index + 1;
			IF index + 1 <= 15 THEN
				state <= s12;
			ELSE
				state <= s20;
			END IF;

		-- Move cursor to the second row
		WHEN s20 =>
			LCM_DB <= x"C0";	-- xC0 is the address of the 1st character of the second row
			LCM_EN <= '1';	LCM_RS <= '0';	LCM_RW <= '0';	
			state <= s21;
		WHEN s21 =>
			LCM_EN <= '0';	-- EN=0; toggle EN
			index <= 0;
			state <= s22;

		-- show characters on 2nd row
		WHEN s22 =>
			LCM_DB <= LINE3(index);
			LCM_EN <= '1';	LCM_RS <= '1';	LCM_RW <= '0';
			state <= s23;
		WHEN s23 =>
			LCM_EN <= '0';	-- set EN=0;
			index <= index + 1;
			IF index + 1 <= 15 THEN
				state <= s22;
			ELSE
				state <= hold;
			END IF;
		WHEN hold =>
			state <= hold;
		WHEN OTHERS =>
			state <= hold;
		END CASE;
		END IF;
END IF;
END PROCESS;

-- lcd pin3 to pin6
	GPIO_0(13) <= '0';   GPIO_0(14) <= LCM_RS;  GPIO_0(15) <= LCM_RW;  GPIO_0(17) <= LCM_EN; 	  	 	
-- lcd pin7 to pin14	(DB0 ~ DB7)
	GPIO_0(19) <= LCM_DB(0);  GPIO_0(21) <= LCM_DB(1);  GPIO_1(9) <= LCM_DB(2);   GPIO_1(11) <= LCM_DB(3);
	GPIO_1(13) <= LCM_DB(4);  GPIO_1(14) <= LCM_DB(5);  GPIO_1(15) <= LCM_DB(6);  GPIO_1(17) <= LCM_DB(7);
-- lcd pin15 to pin16
	GPIO_1(19) <= '1';     GPIO_1(21) <= '0';   -- turn on backlight
	   
END a;

--
-- Generate the user-specified clock signal (setting by divisor)
-- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity CLK_GEN is
	generic( divisor: integer := 50_000_000 );
	port 
	(	
		clock_in				: IN	STD_LOGIC;
		clock_out			: OUT	STD_LOGIC); 
end CLK_GEN;

architecture arch of CLK_GEN is
	signal count: integer range 0 to divisor := 0;
	signal CLK_out: STD_LOGIC;
begin
	
	process(clock_in)
	begin
		IF clock_in'event and clock_in='1' THEN
			IF count <  divisor/2-1 THEN
				count <= count + 1;
			ELSE
				count <= 0;
				CLK_out <= NOT CLK_out;
			END IF;
		END IF;
		clock_out <= CLK_out;
	end process;
	
end arch;