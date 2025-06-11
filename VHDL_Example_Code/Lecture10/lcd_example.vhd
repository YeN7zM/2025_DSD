--------------------------------------------------------------------------------
--
--   FileName:         lcd_example.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 32-bit Version 11.1 Build 173 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 6/13/2012 Scott Larson
--     Initial Public Release
--
--   Print "MCU Digital....." on 1st row, and "System Design..." on 2nd row, 
--   using the lcd_controller.vhd component.
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY lcd_example IS
  PORT(
      CLOCK_50  : IN  STD_LOGIC;  --system clock
      KEY:in std_logic_vector(2 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
		GPIO_1:out std_logic_vector(21 downto 9) );    -- connect to lcd pin16 to pin9  
END lcd_example;

ARCHITECTURE behavior OF lcd_example IS
  SIGNAL   lcd_enable : STD_LOGIC;
  SIGNAL   lcd_bus    : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   lcd_busy   : STD_LOGIC;
  signal   LCM_RS, LCM_RW, LCM_EN : std_logic;
  signal   LCM_DB: std_logic_vector(7 downto 0);
  
  COMPONENT lcd_controller IS
    PORT(
       clk        : IN  STD_LOGIC; --system clock
       reset_n    : IN  STD_LOGIC; --active low reinitializes lcd
       lcd_enable : IN  STD_LOGIC; --latches data into lcd controller
       lcd_bus    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0); --data and control signals
       busy       : OUT STD_LOGIC; --lcd controller busy/idle feedback
       rw, rs, e  : OUT STD_LOGIC; --read/write, setup/data, and enable for lcd
       lcd_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
  END COMPONENT;
BEGIN

  --instantiate the lcd controller
  dut: lcd_controller
    PORT MAP(clk => CLOCK_50, reset_n => '1', lcd_enable => lcd_enable, lcd_bus => lcd_bus, 
             busy => lcd_busy, rw => LCM_RW, rs => LCM_RS, e => LCM_EN, lcd_data => LCM_DB);
  
  PROCESS(CLOCK_50)
    VARIABLE char  :  INTEGER RANGE 0 TO 35 := 0;
  BEGIN
    IF(CLOCK_50'EVENT AND CLOCK_50 = '1') THEN
      IF(lcd_busy = '0' AND lcd_enable = '0') THEN
        lcd_enable <= '1';
        IF(char < 35) THEN
          char := char + 1;
        END IF;
		  CASE char IS
          WHEN 1 => lcd_bus <= "00"&x"80";  --command, x80 is the address of the 1st character of the first row
          WHEN 2 => lcd_bus <= "10"&x"4D";  --M
          WHEN 3 => lcd_bus <= "10"&x"43";  --C
          WHEN 4 => lcd_bus <= "10"&x"55";  --U
          WHEN 5 => lcd_bus <= "10"&x"20";  --space
          WHEN 6 => lcd_bus <= "10"&x"44";  --D
          WHEN 7 => lcd_bus <= "10"&x"69";  --i
          WHEN 8 => lcd_bus <= "10"&x"67";  --g
          WHEN 9 => lcd_bus <= "10"&x"69";  --i
			 WHEN 10 => lcd_bus <= "10"&x"74"; --t
			 WHEN 11 => lcd_bus <= "10"&x"61"; --a
          WHEN 12 => lcd_bus <= "10"&x"6C"; --l
          WHEN 13 => lcd_bus <= "10"&x"2E"; --.
          WHEN 14 => lcd_bus <= "10"&x"2E"; --.
          WHEN 15 => lcd_bus <= "10"&x"2E"; --.
          WHEN 16 => lcd_bus <= "10"&x"2E"; --.
			 WHEN 17 => lcd_bus <= "10"&x"2E"; --.
			 WHEN 18 => lcd_bus <= "00"&x"C0"; --command, xC0 is the address of the 1st character of the second row
          WHEN 19 => lcd_bus <= "10"&x"53"; --S
			 WHEN 20 => lcd_bus <= "10"&x"79"; --y
			 WHEN 21 => lcd_bus <= "10"&x"73"; --s
          WHEN 22 => lcd_bus <= "10"&x"74"; --t
          WHEN 23 => lcd_bus <= "10"&x"65"; --e
          WHEN 24 => lcd_bus <= "10"&x"6D"; --m
          WHEN 25 => lcd_bus <= "10"&x"20"; --space
          WHEN 26 => lcd_bus <= "10"&x"44"; --D
			 WHEN 27 => lcd_bus <= "10"&x"65"; --e
			 WHEN 28 => lcd_bus <= "10"&x"73"; --s
          WHEN 29 => lcd_bus <= "10"&x"69"; --i
			 WHEN 30 => lcd_bus <= "10"&x"67"; --g
			 WHEN 31 => lcd_bus <= "10"&x"6E"; --n
          WHEN 32 => lcd_bus <= "10"&x"2E"; --.
          WHEN 33 => lcd_bus <= "10"&x"2E"; --.
          WHEN 34 => lcd_bus <= "10"&x"2E"; --.
          WHEN OTHERS => lcd_enable <= '0';
        END CASE;
      ELSE
        lcd_enable <= '0';
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
	   	
END behavior;
