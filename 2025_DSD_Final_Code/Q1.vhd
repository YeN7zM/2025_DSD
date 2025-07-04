-- Author : YeN7zM  2025/06/12
-- This project is for 2025 DSD_Fianl_Question1
-- Propose : Make a pet voting system for cat and dog, initally displayed 
--              "CAT 0"            "DOG 0"
-- when user typed '1' or '2' then the cat or dog number have to plus 1, when user typed '0' then clear all number
-- Scoring: 40/40

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
ENTITY Final_Q1 IS
  GENERIC(
      clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
      -- Fix the wrong naming here to match the DE0_pin_assignmeny.qsf
      KEY            : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      CLOCK_50       : IN  STD_LOGIC;                     --system clock input
      PS2_KBCLK      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      PS2_KBDAT      : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      GPIO_0			: out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
	   GPIO_1			: out std_logic_vector(21 downto 9);    -- connect to lcd pin16 to pin9
		HEX3				: OUT STD_LOGIC_VECTOR(0 to 6);
		HEX2				: OUT STD_LOGIC_VECTOR(0 to 6);
		HEX1				: OUT STD_LOGIC_VECTOR(0 to 6);
		HEX0				: OUT STD_LOGIC_VECTOR(0 to 6);
      ascii_new      : OUT STD_LOGIC;                     --output flag indicating new ASCII value
      ascii_code     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)); --ASCII value
END Final_Q1;

ARCHITECTURE behavior OF Final_Q1 IS
  TYPE machine IS(ready, new_code, translate, output);              --needed states
  SIGNAL state             : machine;                               --state machine
  SIGNAL ps2_code_new      : STD_LOGIC;                             --new PS2 code flag from ps2_keyboard component
  SIGNAL ps2_code          : STD_LOGIC_VECTOR(7 DOWNTO 0);          --PS2 code input form ps2_keyboard component
  SIGNAL prev_ps2_code_new : STD_LOGIC := '1';                      --value of ps2_code_new flag on previous clock
  SIGNAL break             : STD_LOGIC := '0';                      --'1' for break code, '0' for make code
  SIGNAL e0_code           : STD_LOGIC := '0';                      --'1' for multi-code commands, '0' for single code commands
  SIGNAL caps_lock         : STD_LOGIC := '0';                      --'1' if caps lock is active, '0' if caps lock is inactive
  SIGNAL control_r         : STD_LOGIC := '0';                      --'1' if right control key is held down, else '0'
  SIGNAL control_l         : STD_LOGIC := '0';                      --'1' if left control key is held down, else '0'
  SIGNAL shift_r           : STD_LOGIC := '0';                      --'1' if right shift is held down, else '0'
  SIGNAL shift_l           : STD_LOGIC := '0';                      --'1' if left shift is held down, else '0'
  SIGNAL ascii             : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"FF"; --internal value of ASCII translation
  SIGNAL cat_count : integer range 0 to 99 := 0;
  SIGNAL dog_count : integer range 0 to 99 := 0;
  SIGNAL H0, H1, H2, H3    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
  --shift type of the LCD_shift direction
  --declare PS2 keyboard interface component
  COMPONENT ps2_keyboard IS
    GENERIC(
      clk_freq              : INTEGER;  --system clock frequency in Hz
      debounce_counter_size : INTEGER); --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
    PORT(
      clk          : IN  STD_LOGIC;                     --system clock
      ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data     : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
      ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
  END COMPONENT;
  
  COMPONENT LCD_shift IS
    port(	CLOCK_50:in std_logic;
		KEY : in std_LOGIC_VECTOR(2 downto 0);
		cat_count : integer range 0 to 99 := 0;
		dog_count : integer range 0 to 99 := 0;
		H3, H2, H1, H0 : in std_LOGIC_VECTOR(3 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
		GPIO_1:out std_logic_vector(21 downto 9) );    -- connect to lcd pin16 to pin9  
  END COMPONENT;
  
  COMPONENT seg7 IS
	PORT (
			 bcd : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			 display : OUT STD_LOGIC_VECTOR(0 TO 6));
  END COMponent;
BEGIN

  --instantiate PS2 keyboard interface logic
  ps2_keyboard_0:  ps2_keyboard
    GENERIC MAP(clk_freq => clk_freq, debounce_counter_size => ps2_debounce_counter_size)
    PORT MAP(clk => CLOCK_50, ps2_clk => PS2_KBCLK, ps2_data => PS2_KBDAT, ps2_code_new => ps2_code_new, ps2_code => ps2_code);
  ascii_to_LCD : LCD_shift
    PORT MAP(CLOCK_50 => CLOCK_50, KEY => KEY, cat_count => cat_count , dog_count => dog_count , H3 => H3, H2 => H2, H1 => H1, H0 => H0, GPIO_0 => GPIO_0, GPIO_1 => GPIO_1);
  PROCESS(CLOCK_50)
  variable keyboard_h : std_LOGIC := '0';
  BEGIN
    IF(CLOCK_50'event and CLOCK_50 = '1') THEN
      prev_ps2_code_new <= ps2_code_new; --keep track of previous ps2_code_new values to determine low-to-high transitions
      CASE state IS
      
        --ready state: wait for a new PS2 code to be received
        WHEN ready =>
          IF(prev_ps2_code_new = '0' AND ps2_code_new = '1') THEN --new PS2 code received
            ascii_new <= '0';                                       --reset new ASCII code indicator
            state <= new_code;                                      --proceed to new_code state
          ELSE                                                    --no new PS2 code received yet
            state <= ready;                                         --remain in ready state
          END IF;
          
        --new_code state: determine what to do with the new PS2 code  
        WHEN new_code =>
          IF(ps2_code = x"F0") THEN    --code indicates that next command is break
            break <= '1';                --set break flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSIF(ps2_code = x"E0") THEN --code indicates multi-key command
            e0_code <= '1';              --set multi-code command flag
            state <= ready;              --return to ready state to await next PS2 code
          ELSE                         --code is the last PS2 code in the make/break code
            ascii(7) <= '1';             --set internal ascii value to unsupported code (for verification)
            state <= translate;          --proceed to translate state
          END IF;

        --translate state: translate PS2 code to ASCII value
        WHEN translate =>
            break <= '0';    --reset break flag
            e0_code <= '0';  --reset multi-code command flag
            
            --handle codes for control, shift, and caps lock
            CASE ps2_code IS
              WHEN x"58" =>                   --caps lock code
                IF(break = '0') THEN            --if make command
                  caps_lock <= NOT caps_lock;     --toggle caps lock
                END IF;
              WHEN x"14" =>                   --code for the control keys
                IF(e0_code = '1') THEN          --code for right control
                  control_r <= NOT break;         --update right control flag
                ELSE                            --code for left control
                  control_l <= NOT break;         --update left control flag
                END IF;
              WHEN x"12" =>                   --left shift code
                shift_l <= NOT break;           --update left shift flag
              WHEN x"59" =>                   --right shift code
                shift_r <= NOT break;           --update right shift flag
              WHEN OTHERS => NULL;
            END CASE;
        
            --translate control codes (these do not depend on shift or caps lock)
            IF(control_l = '1' OR control_r = '1') THEN
              CASE ps2_code IS
                WHEN x"1E" => ascii <= x"00"; --^@  NUL
                WHEN x"1C" => ascii <= x"01"; --^A  SOH
                WHEN x"32" => ascii <= x"02"; --^B  STX
                WHEN x"21" => ascii <= x"03"; --^C  ETX
                WHEN x"23" => ascii <= x"04"; --^D  EOT
                WHEN x"24" => ascii <= x"05"; --^E  ENQ
                WHEN x"2B" => ascii <= x"06"; --^F  ACK
                WHEN x"34" => ascii <= x"07"; --^G  BEL
                WHEN x"33" => ascii <= x"08"; --^H  BS
                WHEN x"43" => ascii <= x"09"; --^I  HT
                WHEN x"3B" => ascii <= x"0A"; --^J  LF
                WHEN x"42" => ascii <= x"0B"; --^K  VT
                WHEN x"4B" => ascii <= x"0C"; --^L  FF
                WHEN x"3A" => ascii <= x"0D"; --^M  CR
                WHEN x"31" => ascii <= x"0E"; --^N  SO
                WHEN x"44" => ascii <= x"0F"; --^O  SI
                WHEN x"4D" => ascii <= x"10"; --^P  DLE
                WHEN x"15" => ascii <= x"11"; --^Q  DC1
                WHEN x"2D" => ascii <= x"12"; --^R  DC2
                WHEN x"1B" => ascii <= x"13"; --^S  DC3
                WHEN x"2C" => ascii <= x"14"; --^T  DC4
                WHEN x"3C" => ascii <= x"15"; --^U  NAK
                WHEN x"2A" => ascii <= x"16"; --^V  SYN
                WHEN x"1D" => ascii <= x"17"; --^W  ETB
                WHEN x"22" => ascii <= x"18"; --^X  CAN
                WHEN x"35" => ascii <= x"19"; --^Y  EM
                WHEN x"1A" => ascii <= x"1A"; --^Z  SUB
                WHEN x"54" => ascii <= x"1B"; --^[  ESC
                WHEN x"5D" => ascii <= x"1C"; --^\  FS
                WHEN x"5B" => ascii <= x"1D"; --^]  GS
                WHEN x"36" => ascii <= x"1E"; --^^  RS
                WHEN x"4E" => ascii <= x"1F"; --^_  US
                WHEN x"4A" => ascii <= x"7F"; --^?  DEL
                WHEN OTHERS => NULL;
              END CASE;
            ELSE --if control keys are not pressed  
            
              --translate characters that do not depend on shift, or caps lock
              CASE ps2_code IS
                WHEN x"29" => ascii <= x"20"; --space
                WHEN x"66" => ascii <= x"08"; --backspace (BS control code)
                WHEN x"0D" => ascii <= x"09"; --tab (HT control code)
                WHEN x"5A" => ascii <= x"0D"; --enter (CR control code)
                WHEN x"76" => ascii <= x"1B"; --escape (ESC control code)
                WHEN x"71" => 
                  IF(e0_code = '1') THEN      --ps2 code for delete is a multi-key code
                    ascii <= x"7F";             --delete
                  END IF;
                -- Arrow's botton
                WHEN x"75" => 
                IF(e0_code = '1') THEN      --up
                    ascii <= x"26";           
                END IF;
                WHEN x"6B" => 
                IF(e0_code = '1') THEN      --left
                    ascii <= x"25";         
                END IF;
                WHEN x"72" => 
                IF(e0_code = '1') THEN      --down
                    ascii <= x"28";           
                END IF;
                WHEN x"74" => 
                IF(e0_code = '1') THEN      --right
                    ascii <= x"27";           
                END IF;
                WHEN OTHERS => NULL;
              END CASE;
              
              --translate letters (these depend on both shift and caps lock)
              IF((shift_r = '0' AND shift_l = '0' AND caps_lock = '0') OR
                ((shift_r = '1' OR shift_l = '1') AND caps_lock = '1')) THEN  --letter is lowercase
                CASE ps2_code IS              
                  WHEN x"1C" => ascii <= x"61"; --a
                  WHEN x"32" => ascii <= x"62"; --b
                  WHEN x"21" => ascii <= x"63"; --c
                  WHEN x"23" => ascii <= x"64"; --d
                  WHEN x"24" => ascii <= x"65"; --e
                  WHEN x"2B" => ascii <= x"66"; --f
                  WHEN x"34" => ascii <= x"67"; --g
                  WHEN x"33" => ascii <= x"68"; --h
                  WHEN x"43" => ascii <= x"69"; --i
                  WHEN x"3B" => ascii <= x"6A"; --j
                  WHEN x"42" => ascii <= x"6B"; --k
                  WHEN x"4B" => ascii <= x"6C"; --l
                  WHEN x"3A" => ascii <= x"6D"; --m
                  WHEN x"31" => ascii <= x"6E"; --n
                  WHEN x"44" => ascii <= x"6F"; --o
                  WHEN x"4D" => ascii <= x"70"; --p
                  WHEN x"15" => ascii <= x"71"; --q
                  WHEN x"2D" => ascii <= x"72"; --r
                  WHEN x"1B" => ascii <= x"73"; --s
                  WHEN x"2C" => ascii <= x"74"; --t
                  WHEN x"3C" => ascii <= x"75"; --u
                  WHEN x"2A" => ascii <= x"76"; --v
                  WHEN x"1D" => ascii <= x"77"; --w
                  WHEN x"22" => ascii <= x"78"; --x
                  WHEN x"35" => ascii <= x"79"; --y
                  WHEN x"1A" => ascii <= x"7A"; --z
                  WHEN OTHERS => NULL;
                END CASE;
              ELSE                                     --letter is uppercase
                CASE ps2_code IS            
                  WHEN x"1C" => ascii <= x"41"; --A
                  WHEN x"32" => ascii <= x"42"; --B
                  WHEN x"21" => ascii <= x"43"; --C
                  WHEN x"23" => ascii <= x"44"; --D
                  WHEN x"24" => ascii <= x"45"; --E
                  WHEN x"2B" => ascii <= x"46"; --F
                  WHEN x"34" => ascii <= x"47"; --G
                  WHEN x"33" => ascii <= x"48"; --H
                  WHEN x"43" => ascii <= x"49"; --I
                  WHEN x"3B" => ascii <= x"4A"; --J
                  WHEN x"42" => ascii <= x"4B"; --K
                  WHEN x"4B" => ascii <= x"4C"; --L
                  WHEN x"3A" => ascii <= x"4D"; --M
                  WHEN x"31" => ascii <= x"4E"; --N
                  WHEN x"44" => ascii <= x"4F"; --O
                  WHEN x"4D" => ascii <= x"50"; --P
                  WHEN x"15" => ascii <= x"51"; --Q
                  WHEN x"2D" => ascii <= x"52"; --R
                  WHEN x"1B" => ascii <= x"53"; --S
                  WHEN x"2C" => ascii <= x"54"; --T
                  WHEN x"3C" => ascii <= x"55"; --U
                  WHEN x"2A" => ascii <= x"56"; --V
                  WHEN x"1D" => ascii <= x"57"; --W
                  WHEN x"22" => ascii <= x"58"; --X
                  WHEN x"35" => ascii <= x"59"; --Y
                  WHEN x"1A" => ascii <= x"5A"; --Z
                  WHEN OTHERS => NULL;
                END CASE;
              END IF;
              
              --translate numbers and symbols (these depend on shift but not caps lock)
              IF(shift_l = '1' OR shift_r = '1') THEN  --key's secondary character is desired
                CASE ps2_code IS              
                  WHEN x"16" => ascii <= x"21"; --!
                  WHEN x"52" => ascii <= x"22"; --"
                  WHEN x"26" => ascii <= x"23"; --#
                  WHEN x"25" => ascii <= x"24"; --$
                  WHEN x"2E" => ascii <= x"25"; --%
                  WHEN x"3D" => ascii <= x"26"; --&              
                  WHEN x"46" => ascii <= x"28"; --(
                  WHEN x"45" => ascii <= x"29"; --)
                  WHEN x"3E" => ascii <= x"2A"; --*
                  WHEN x"55" => ascii <= x"2B"; --+
                  WHEN x"4C" => ascii <= x"3A"; --:
                  WHEN x"41" => ascii <= x"3C"; --<
                  WHEN x"49" => ascii <= x"3E"; -->
                  WHEN x"4A" => ascii <= x"3F"; --?
                  WHEN x"1E" => ascii <= x"40"; --@
                  WHEN x"36" => ascii <= x"5E"; --^
                  WHEN x"4E" => ascii <= x"5F"; --_
                  WHEN x"54" => ascii <= x"7B"; --{
                  WHEN x"5D" => ascii <= x"7C"; --|
                  WHEN x"5B" => ascii <= x"7D"; --}
                  WHEN x"0E" => ascii <= x"7E"; --~
                  WHEN OTHERS => NULL;
                END CASE;
              ELSE                                     --key's primary character is desired
                CASE ps2_code IS  
                  WHEN x"45" => ascii <= x"30"; keyboard_h := not keyboard_h;--0
							if keyboard_h = '1' then
								cat_count <= 0;
								dog_count <= 0;
							end if;
                  WHEN x"16" => ascii <= x"31"; keyboard_h := not keyboard_h;--1
							if keyboard_h = '1' then
								cat_count <= cat_count + 1;
							end if;
                  WHEN x"1E" => ascii <= x"32"; keyboard_h := not keyboard_h;--2
							if keyboard_h = '1' then
								dog_count <= dog_count + 1;
							end if;
                  WHEN x"26" => ascii <= x"33"; --3
                  WHEN x"25" => ascii <= x"34"; --4
                  WHEN x"2E" => ascii <= x"35"; --5
                  WHEN x"36" => ascii <= x"36"; --6
                  WHEN x"3D" => ascii <= x"37"; --7
                  WHEN x"3E" => ascii <= x"38"; --8
                  WHEN x"46" => ascii <= x"39"; --9
                  WHEN x"52" => ascii <= x"27"; --'
                  WHEN x"41" => ascii <= x"2C"; --,
                  WHEN x"4E" => ascii <= x"2D"; ---
                  WHEN x"49" => ascii <= x"2E"; --.
                  WHEN x"4A" => ascii <= x"2F"; --/
                  WHEN x"4C" => ascii <= x"3B"; --;
                  WHEN x"55" => ascii <= x"3D"; --=
                  WHEN x"54" => ascii <= x"5B"; --[
                  WHEN x"5D" => ascii <= x"5C"; --\
                  WHEN x"5B" => ascii <= x"5D"; --]
                  WHEN x"0E" => ascii <= x"60"; --`
                  WHEN OTHERS => NULL;
                END CASE;
              END IF;
              
            END IF;
          
          IF(break = '0') THEN  --the code is a make
            state <= output;      --proceed to output state
          ELSE                  --code is a break
            state <= ready;       --return to ready state to await next PS2 code
          END IF;
        
        --output state: verify the code is valid and output the ASCII value
        WHEN output =>
          IF(ascii(7) = '0') THEN            --the PS2 code has an ASCII output
            ascii_new <= '1';                  --set flag indicating new ASCII output
            ascii_code <= ascii(6 DOWNTO 0);   --output the ASCII value
          END IF;
          state <= ready;                    --return to ready state to await next PS2 code

      END CASE;
    END IF;
  END PROCESS;
  
  process(cat_count, dog_count)
  begin
	H3 <= std_LOGIC_VECTOR(to_signed((cat_count / 10), H3'length));
	H2 <= std_LOGIC_VECTOR(to_signed((cat_count rem 10), H2'length));
	H1 <= std_LOGIC_VECTOR(to_signed((dog_count / 10), H1'length));
	H0 <= std_LOGIC_VECTOR(to_signed((dog_count rem 10), H0'length));
  end process;
  
  digit3 : seg7 PORT MAP(H3, HEX3);
  digit2 : seg7 PORT MAP(H2, HEX2);
  digit1 : seg7 PORT MAP(H1, HEX1);
  digit0 : seg7 PORT MAP(H0, HEX0);
END behavior;






library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity LCD_SHIFT is 
 port(	CLOCK_50:in std_logic;
		KEY : in std_LOGIC_VECTOR(2 downto 0);
		cat_count : integer range 0 to 99 := 0;
		dog_count : integer range 0 to 99 := 0;
		H3, H2, H1, H0 : in std_LOGIC_VECTOR(3 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
		GPIO_1:out std_logic_vector(21 downto 9) );    -- connect to lcd pin16 to pin9 
		
end LCD_SHIFT;
architecture arch of LCD_SHIFT is
	component CLK_GEN is
		generic( divisor: integer := 50_000_000 );
		port 
		(	
			clock_in				: IN	STD_LOGIC;
			clock_out			: OUT	STD_LOGIC); 
	end component;

	COMPONENT debounce IS
 --   GENERIC(
 --     counter_size : INTEGER); --debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    PORT(
      clk    : IN  STD_LOGIC;  --input clock
      button : IN  STD_LOGIC;  --input signal to be debounced
      result : OUT STD_LOGIC); --debounced signal
	 END COMPONENT;
  
signal RESET, LCM_CLK:std_logic;
signal COUNTER:integer range 0 to 41;

TYPE DDRAM IS ARRAY(0 to 15) OF std_logic_vector(7 downto 0);
signal LINE1:DDRAM := (x"20",x"20",x"20",x"43",x"41",x"54",x"20",x"20",x"20",x"20",x"44",x"4F",x"47",x"20",x"20",x"20");
signal LINE2:DDRAM := (x"20", x"20", x"20", x"20", x"44", x"31", x"30", x"31", x"38", x"36", x"31", x"34", x"20", x"20", x"20", x"20");
-- "    D1018614    "
signal LINE_STDID:DDRAM := (x"20", x"20", x"20", x"20", x"44", x"31", x"30", x"31", x"38", x"36", x"31", x"34", x"20", x"20", x"20", x"20"); 
-- "                "
signal LINE_emp:DDRAM := (x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20");

signal TEMP:std_logic_vector(7 downto 0) := x"20";
signal LCM_RS, LCM_RW, LCM_EN :std_logic;
signal LCM_DB:std_logic_vector(7 downto 0);

signal CLK_1khz, CLK_500hz, CLK_1hz:std_logic; 
signal Buttons, shift_dir: std_logic_vector(1 downto 0);
constant RIGHT: std_logic_vector(1 downto 0) := "01";
constant LEFT:  std_logic_vector(1 downto 0) := "10";

begin
-- **The following code is for shifting LINE2 by pressing the key "once"  
-- generate 500hz and 1hz clock
  CLK_U0: CLK_GEN generic map(divisor => 50_000) port map(CLOCK_50, CLK_1khz);
  CLK_U1: CLK_GEN generic map(divisor => 100_000) port map(CLOCK_50, CLK_500hz); 
  CLK_U2: CLK_GEN generic map(divisor => 50_000_000) port map(CLOCK_50, CLK_1hz);
--debounce push buttons
  debounce_key1: debounce PORT MAP(clk => CLOCK_50, button => KEY(1), result => Buttons(0));
  debounce_key2: debounce PORT MAP(clk => CLOCK_50, button => KEY(2), result => Buttons(1));

LCM_CLK<= CLK_500hz;  -- 2ms
LCM_EN<=LCM_CLK;
RESET <= KEY(1);


--check shift direction, every 1 second
process(LINE2)
begin
	--		LINE2(0) <="00100000";				--
		LINE2(1) <=x"20";				--
		LINE2(2) <=x"20";				--
		LINE2(3) <=x"20";				--I
		LINE2(4) <="0011" & H3;				--
		LINE2(5) <="0011" & H2;				--L
		LINE2(6) <=x"20";				--O
		LINE2(7) <=x"20";				--V
		LINE2(8) <=x"20";				--E
		LINE2(9) <=x"20";				--
		LINE2(10)<=x"20";				--L
		LINE2(11)<="0011" & H1;				--C
		LINE2(12)<="0011" & H0;				--D
		LINE2(13)<=x"20";				--
		LINE2(14)<=x"20";				--
		LINE2(15)<=x"20";				--
end process;
	
--counter
process(LCM_CLK,RESET)
begin
	if RESET='0' then
		COUNTER<=0;
	elsif LCM_CLK'event and LCM_CLK='1' then
		if COUNTER>=41 then
			COUNTER<=25;
		else
			COUNTER<=COUNTER+1;
		end if;
   end if;
end process;

--display circuit
process(LCM_CLK)
begin
	if(LCM_CLK'event and LCM_CLK='0') then	
		case COUNTER is
			when 0 to 3=>
				LCM_RS<='0';
				LCM_RW<='0';
				LCM_DB<="00111000";		--function set
			when 4=>
				LCM_DB<="00001000";		--off screen
			when 5=>
				LCM_DB<="00000001";		--clear screen
			when 6=>
				LCM_DB<="00001100";		--on screen
			when 7=>
				LCM_DB<="00000110";		--entry mode set	
			when 8=>
				LCM_RS<='0';
				LCM_DB<="10000000";		--set position 	
			when 9=>
				LCM_RS<='1';
				LCM_DB<=LINE1(0);
			when 10=>
				LCM_DB<=LINE1(1);
			when 11=>
				LCM_DB<=LINE1(2);
			when 12=>
				LCM_DB<=LINE1(3);
			when 13=>
				LCM_DB<=LINE1(4);
			when 14=>
				LCM_DB<=LINE1(5);
			when 15=>
				LCM_DB<=LINE1(6);
			when 16=>
				LCM_DB<=LINE1(7);
			when 17=>
				LCM_DB<=LINE1(8);
			when 18=>
				LCM_DB<=LINE1(9);
			when 19=>
				LCM_DB<=LINE1(10);
			when 20=>
				LCM_DB<=LINE1(11);
			when 21=>
				LCM_DB<=LINE1(12);
			when 22=>
				LCM_DB<=LINE1(13);
			when 23=>
				LCM_DB<=LINE1(14);
			when 24=>
				LCM_DB<=LINE1(15);
			when 25=>
				LCM_RS<='0';			--set position
				LCM_DB<="11000000";
			when 26=>
				LCM_RS<='1';
				LCM_DB<=LINE2(0);
			when 27=>
				LCM_DB<=LINE2(1);
			when 28=>
				LCM_DB<=LINE2(2);
			when 29=>
				LCM_DB<=LINE2(3);
			when 30=>
				LCM_DB<=LINE2(4);
			when 31=>
				LCM_DB<=LINE2(5);
			when 32=>
				LCM_DB<=LINE2(6);
			when 33=>
				LCM_DB<=LINE2(7);
			when 34=>
				LCM_DB<=LINE2(8);
			when 35=>
				LCM_DB<=LINE2(9);
			when 36=>
				LCM_DB<=LINE2(10);
			when 37=>
				LCM_DB<=LINE2(11);
			when 38=>
				LCM_DB<=LINE2(12);
			when 39=>
				LCM_DB<=LINE2(13);
			when 40=>
				LCM_DB<=LINE2(14);
			when 41=>
				LCM_DB<=LINE2(15);
		end case;
	end if;
end process;

-- lcd pin3 to pin6
	GPIO_0(13) <= '0';   GPIO_0(14) <= LCM_RS;  GPIO_0(15) <= LCM_RW;  GPIO_0(17) <= LCM_EN; 	  	 	
-- lcd pin7 to pin14	(DB0 ~ DB7)
	GPIO_0(19) <= LCM_DB(0);  GPIO_0(21) <= LCM_DB(1);  GPIO_1(9) <= LCM_DB(2);   GPIO_1(11) <= LCM_DB(3);
	GPIO_1(13) <= LCM_DB(4);  GPIO_1(14) <= LCM_DB(5);  GPIO_1(15) <= LCM_DB(6);  GPIO_1(17) <= LCM_DB(7);
-- lcd pin15 to pin16
	GPIO_1(19) <= '1';     GPIO_1(21) <= '0';   -- turn on backlight
         	
end arch;

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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY debounce IS
  GENERIC(
    counter_size  :  INTEGER := 19); --counter size (19 bits gives 10.5ms with 50MHz clock)
  PORT(
    clk     : IN  STD_LOGIC;  --input clock
    button  : IN  STD_LOGIC;  --input signal to be debounced
    result  : OUT STD_LOGIC); --debounced signal
END debounce;

ARCHITECTURE logic OF debounce IS
  SIGNAL flipflops   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops
  SIGNAL counter_set : STD_LOGIC;                    --sync reset to zero
  SIGNAL counter_out : STD_LOGIC_VECTOR(counter_size DOWNTO 0) := (OTHERS => '0'); --counter output
BEGIN

  counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter
  
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT and clk = '1') THEN
      flipflops(0) <= button;
      flipflops(1) <= flipflops(0);
      If(counter_set = '1') THEN                  --reset counter because input is changing
        counter_out <= (OTHERS => '0');
      ELSIF(counter_out(counter_size) = '0') THEN --stable input time is not yet met
        counter_out <= counter_out + 1;
      ELSE                                        --stable input time is met
        result <= flipflops(1);
      END IF;    
    END IF;
  END PROCESS;
END logic;
-----------------------------------------------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ps2_keyboard IS
  GENERIC(
    clk_freq              : INTEGER := 50_000_000; --system clock frequency in Hz
    debounce_counter_size : INTEGER := 8);         --set such that (2^size)/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
    clk          : IN  STD_LOGIC;                     --system clock
    ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS/2 keyboard
    ps2_data     : IN  STD_LOGIC;                     --data signal from PS/2 keyboard
    ps2_code_new : OUT STD_LOGIC;                     --flag that new PS/2 code is available on ps2_code bus
    ps2_code     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --code received from PS/2
END ps2_keyboard;

ARCHITECTURE logic OF ps2_keyboard IS
  SIGNAL sync_ffs     : STD_LOGIC_VECTOR(1 DOWNTO 0);       --synchronizer flip-flops for PS/2 signals
  SIGNAL ps2_clk_int  : STD_LOGIC;                          --debounced clock signal from PS/2 keyboard
  SIGNAL ps2_data_int : STD_LOGIC;                          --debounced data signal from PS/2 keyboard
  SIGNAL ps2_word     : STD_LOGIC_VECTOR(10 DOWNTO 0);      --stores the ps2 data word
  SIGNAL error        : STD_LOGIC;                          --validate parity, start, and stop bits
  SIGNAL count_idle   : INTEGER RANGE 0 TO clk_freq/18_000; --counter to determine PS/2 is idle
  
  --declare debounce component for debouncing PS2 input signals
  COMPONENT debounce IS
    GENERIC(
      counter_size : INTEGER); --debounce period (in seconds) = 2^counter_size/(clk freq in Hz)
    PORT(
      clk    : IN  STD_LOGIC;  --input clock
      button : IN  STD_LOGIC;  --input signal to be debounced
      result : OUT STD_LOGIC); --debounced signal
  END COMPONENT;
BEGIN

  --synchronizer flip-flops
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN  --rising edge of system clock
      sync_ffs(0) <= ps2_clk;           --synchronize PS/2 clock signal
      sync_ffs(1) <= ps2_data;          --synchronize PS/2 data signal
    END IF;
  END PROCESS;

  --debounce PS2 input signals
  debounce_ps2_clk: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(0), result => ps2_clk_int);
  debounce_ps2_data: debounce
    GENERIC MAP(counter_size => debounce_counter_size)
    PORT MAP(clk => clk, button => sync_ffs(1), result => ps2_data_int);

  --input PS2 data
  PROCESS(ps2_clk_int)
  BEGIN
    IF(ps2_clk_int'EVENT AND ps2_clk_int = '0') THEN    --falling edge of PS2 clock
      ps2_word <= ps2_data_int & ps2_word(10 DOWNTO 1);   --shift in PS2 data bit
    END IF;
  END PROCESS;
    
  --verify that parity, start, and stop bits are all correct
  error <= NOT (NOT ps2_word(0) AND ps2_word(10) AND (ps2_word(9) XOR ps2_word(8) XOR
        ps2_word(7) XOR ps2_word(6) XOR ps2_word(5) XOR ps2_word(4) XOR ps2_word(3) XOR 
        ps2_word(2) XOR ps2_word(1)));  

  --determine if PS2 port is idle (i.e. last transaction is finished) and output result
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN           --rising edge of system clock
    
      IF(ps2_clk_int = '0') THEN                 --low PS2 clock, PS/2 is active
        count_idle <= 0;                           --reset idle counter
      ELSIF(count_idle /= clk_freq/18_000) THEN  --PS2 clock has been high less than a half clock period (<55us)
          count_idle <= count_idle + 1;            --continue counting
      END IF;
      
      IF(count_idle = clk_freq/18_000 AND error = '0') THEN  --idle threshold reached and no errors detected
        ps2_code_new <= '1';                                   --set flag that new PS/2 code is available
        ps2_code <= ps2_word(8 DOWNTO 1);                      --output new PS/2 code
      ELSE                                                   --PS/2 port active or error detected
        ps2_code_new <= '0';                                   --set flag that PS/2 transaction is in progress
      END IF;
      
    END IF;
  END PROCESS;
  
END logic;


-- component of 7 seg
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY seg7 IS
	PORT (
       bcd : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			 display : OUT STD_LOGIC_VECTOR(0 TO 6));
END seg7;

ARCHITECTURE Structure OF seg7 IS
BEGIN	


 PROCESS(bcd)
 BEGIN 
    CASE bcd IS 
      WHEN "0000" => display <= (not"1111110"); --0
      WHEN "0001" => display <= (not"0110000"); --1
      WHEN "0010" => display <= (not"1101101"); --2
      WHEN "0011" => display <= (not"1111001"); --3
      WHEN "0100" => display <= (not"0110011"); --4
      WHEN "0101" => display <= (not"1011011"); --5
      WHEN "0110" => display <= (not"1011111"); --6
      WHEN "0111" => display <= (not"1110000"); --7
      WHEN "1000" => display <= (not"1111111"); --8
      WHEN "1001" => display <= (not"1111011"); --9
		WHEN OTHERS => display <= (not"0000000"); 
    END CASE;
 END PROCESS;
END Structure;