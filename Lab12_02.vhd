library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab122 is
    GENERIC(
        clk_freq                  : INTEGER := 50_000_000;
        ps2_debounce_counter_size : INTEGER := 8);
    PORT(
        --VGA_sync
        CLOCK_50: IN std_logic;--記得除頻25
        KEY: IN std_logic_vector(0 downto 0);
        VGA_HS,VGA_VS: OUT std_logic;
        --rgb
        VGA_R, VGA_G, VGA_B: out std_logic_vector(3 downto 0);
        --keyboard
        PS2_KBCLK    : IN  STD_LOGIC;
        PS2_KBDAT   : IN  STD_LOGIC
);
end lab122;

architecture a of lab122 is
    --VGA_sync\rgb
    signal RESET: std_logic;
    signal video_on: std_logic;
    signal row, col: integer;--row_counter\col_counter
    signal CLK_25Mhz: std_logic;
    signal col_position: integer := 320;
    signal row_position: integer := 240;
    --display
    signal RGB: std_logic_vector(11 downto 0);
    --keyboard
    SIGNAL ascii_new         : STD_LOGIC;
    SIGNAL ascii_code        : STD_LOGIC_VECTOR(6 DOWNTO 0);
   --signal self_ascii: STD_LOGIC_VECTOR(7 DOWNTO 0);--暫存讀取到的ascii
    
    component VGA_sync is
        port
        (	
            CLOCK,RESET: IN std_logic;
            HOR_SYN,VER_SYN,video_on: OUT std_logic;
            row_counter:out INTEGER RANGE 0 TO 524;
            col_counter:out INTEGER RANGE 0 TO 799
            ); 
	end component;

    component CLK_GEN is
        generic( divisor: integer := 50_000_000 ); 
        port 
        (	
            clock_in				: IN	STD_LOGIC;
            clock_out			: OUT	STD_LOGIC); 
    end component;
    
    COMPONENT ps2_keyboard_to_ascii IS --(ps2_keyboard.vhd)
        GENERIC(
            clk_freq              : INTEGER;  --system clock frequency in Hz
            ps2_debounce_counter_size : INTEGER); --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
        PORT(
            clk          : IN  STD_LOGIC;                     --system clock
            ps2_clk      : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
            ps2_data     : IN  STD_LOGIC;                     --data signal from PS2 keyboard
            ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
            ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0));
    END COMPONENT;

    constant WHITE: std_logic_vector(11 downto 0) := x"FFF";
    constant BLACK: std_logic_vector(11 downto 0) := x"000";
	 signal ascii_new_d : std_logic := '0'; -- 延遲暫存，偵測上升緣

begin
    RESET<=KEY(0);
    --除頻
    CLK_U1: CLK_GEN generic map(divisor => 2) port map(CLOCK_50, CLK_25Mhz);
    --VGA_sync
    VGA_sync_U1: VGA_sync port map(CLOCK => CLK_25Mhz,RESET=>KEY(0),HOR_SYN=>VGA_HS,VER_SYN=>VGA_VS,video_on=>video_on,row_counter=>row,col_counter=>col);
    --keyboard
    ps2_keyboard_0:  ps2_keyboard_to_ascii
    GENERIC MAP(clk_freq => clk_freq, ps2_debounce_counter_size => ps2_debounce_counter_size)
    PORT MAP(clk => CLOCK_50, ps2_clk => PS2_KBCLK, ps2_data => PS2_KBDAT, ascii_new => ascii_new, ascii_code => ascii_code);

--reset self_ascii<=X"00"; and move
    process(CLOCK_50,RESET)
        variable self_ascii: std_logic_vector(7 downto 0);
    begin
        if RESET='0' then
            col_position<=320;
            row_position<=240;
            self_ascii := "00000000";
            ascii_new_d <= '0';
        elsif CLOCK_50'event and CLOCK_50='1' then
            ascii_new_d <= ascii_new;  -- 紀錄上一個時鐘週期ascii_new狀態
            if ascii_new = '1' and ascii_new_d = '0' then  -- ascii_new 上升緣觸發
            --if ascii_new='1' then
                self_ascii := '0'&ascii_code;
                if (self_ascii=X"26")then--up
                    if ((row_position-20)>=10) then
                        row_position<=row_position-20;
                    elsif  ((row_position-20)<10) then
                        row_position<=10;
                    end if;
                elsif (self_ascii=X"28") then--down
                    if ((row_position+20)<=470) then
                        row_position<=row_position+20;
                    elsif  ((row_position+20)>470) then
                        row_position<=470;
                    end if;
                elsif (self_ascii=X"25") then--left
                    if ((col_position-20)>=10) then
                        col_position<=col_position-20;
                    elsif  ((col_position-20)<10) then
                        col_position<=10;
                    end if;
                elsif (self_ascii=X"27") then--right
                    if ((col_position+20)<=630) then
                        col_position<=col_position+20;
                    elsif  ((col_position+20)>630) then
                        col_position<=630;
                    end if;
                end if;
            end if;
        end if;
    end process;
--display
    process(video_on, row, col,row_position,col_position)
    begin
        if(video_on = '0') then
            RGB <= BLACK;
        elsif(row >= (row_position-10) and row < (row_position+10) and col >= (col_position-10) and col < (col_position+10)) then
            RGB <= WHITE;
        else
            RGB <= BLACK;
        end if;
    end process;
    VGA_R <= RGB(11 downto 8);
    VGA_G <= RGB(7 downto 4);
    VGA_B <= RGB(3 downto 0);
end architecture;
--在self_ascii更新時 立即move
--ps2_keyboard_to_ascii 補方向鍵（arrows）

Library ieee;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Module Generates Video Sync Signals for Video Montor Interface
-- RGB and Sync outputs tie directly to monitor conector pins
ENTITY VGA_sync IS   
	PORT(
		CLOCK,RESET: IN std_logic;
		HOR_SYN,VER_SYN,video_on: OUT std_logic;
        row_counter:out INTEGER RANGE 0 TO 524;--525 lines	
        col_counter:out INTEGER RANGE 0 TO 799--800 dots
		);
END VGA_sync ;

ARCHITECTURE arch OF VGA_sync IS
SIGNAL h_count: INTEGER RANGE 0 TO 799; --h_sync	
SIGNAL v_count: INTEGER RANGE 0 TO 524;	--v_sync(line=row counter)	
BEGIN

--Generate Horizontal Timing Signals for Video Signal
-- 
--  Horiz_sync  ------------------------------------__________--------
--  h_count     0                 639              660      755      799
--
	PROCESS(CLOCK,RESET)   
	BEGIN				  						
		IF RESET = '0' THEN  h_count <=0;
		ELSIF CLOCK'EVENT AND CLOCK='1' THEN 
			IF h_count = 799 then h_count<=0;          
			ELSE h_count <= h_count + 1;
			END IF;
		END IF;
	END PROCESS;

--Generate Horizontal Sync Signal using h_count	
  	PROCESS (h_count)  
    BEGIN
		IF h_count >=660 and h_count<=755 THEN HOR_SYN <= '0';
		ELSE  HOR_SYN <= '1';
		END IF;  	
  	END PROCESS;

--Generate Vertical Timing Signals for Video Signal
--  Vert_sync   ----------------------------------_______------------
--  v_count         0             479            493   494         524
--
   PROCESS(CLOCK,RESET)    
	BEGIN				  						
     IF RESET = '0' THEN v_count <=0;
     ELSIF CLOCK'EVENT AND CLOCK='1' THEN 
         IF h_count = 799 then 
			IF v_count = 524 THEN v_count <=0;
			ELSE v_count <= v_count+1;     
			END IF;
         END IF;
    END IF;
	END PROCESS;
  
--Generate Vertical Sync Signal using v_count
   PROCESS (v_count)  
 	BEGIN
		IF (v_count >= 493 AND v_count <=494) THEN VER_SYN <= '0';
		ELSE VER_SYN <= '1';
		END IF;  	
	END PROCESS; 

-- Generate Video on Screen Signals for Pixel Data
-- Video on = 1 indicates pixel are being displayed
  process (h_count, v_count)  
	begin
		 IF v_count >=480 and v_count<=524 THEN video_on<='0';  
         ELSE 
			IF h_count >=640 and h_count<=799 THEN video_on<='0';
			ELSE video_on<='1';
			END IF;
     	END IF;
end process;

row_counter<=v_count;
col_counter<=h_count;

END arch;

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

--------------------------------------------------------------------------------
--
--   FileName:         ps2_keyboard_to_ascii.vhd
--   Dependencies:     ps2_keyboard.vhd, debounce.vhd
--   Design Software:  Quartus II 32-bit Version 12.1 Build 177 SJ Full Version
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
--   Version 1.0 11/29/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ps2_keyboard_to_ascii IS --(lec10 p42)
  GENERIC(
      clk_freq                  : INTEGER := 50_000_000; --system clock frequency in Hz
      ps2_debounce_counter_size : INTEGER := 8);         --set such that 2^size/clk_freq = 5us (size = 8 for 50MHz)
  PORT(
      clk        : IN  STD_LOGIC;                     --system clock input
      ps2_clk    : IN  STD_LOGIC;                     --clock signal from PS2 keyboard
      ps2_data   : IN  STD_LOGIC;                     --data signal from PS2 keyboard
      ascii_new  : OUT STD_LOGIC;                     --output flag indicating new ASCII value
      ascii_code : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)); --ASCII value
END ps2_keyboard_to_ascii;
-------------------------------------------------------------------------------------
ARCHITECTURE behavior OF ps2_keyboard_to_ascii IS
  TYPE machine IS(ready, new_code, translate, output);              --needed states (lec10 p47)
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

  --declare PS2 keyboard interface component
  COMPONENT ps2_keyboard IS --(ps2_keyboard.vhd)
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

BEGIN

  --instantiate PS2 keyboard interface logic
  ps2_keyboard_0:  ps2_keyboard
    GENERIC MAP(clk_freq => clk_freq, debounce_counter_size => ps2_debounce_counter_size)
    PORT MAP(clk => clk, ps2_clk => ps2_clk, ps2_data => ps2_data, ps2_code_new => ps2_code_new, ps2_code => ps2_code);
  --(lec10 p42 的user logic部分)
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT AND clk = '1') THEN
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
                --方向鍵（arrows）
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
                  WHEN x"45" => ascii <= x"30"; --0
                  WHEN x"16" => ascii <= x"31"; --1
                  WHEN x"1E" => ascii <= x"32"; --2
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

END behavior;


--------------------------------------------------------------------------------
--
--   FileName:         ps2_keyboard.vhd
--   Dependencies:     debounce.vhd
--   Design Software:  Quartus II 32-bit Version 12.1 Build 177 SJ Full Version
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
--   Version 1.0 11/25/2013 Scott Larson
--     Initial Public Release
--    
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
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
--   Version 1.0 3/26/2012 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

--當按鈕狀態改變時，開始一段計時；只有當按鈕狀態持續穩定一段時間後，才把該狀態輸出。這樣可以忽略短時間的彈跳干擾。
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
  SIGNAL flipflops   : STD_LOGIC_VECTOR(1 DOWNTO 0); --input flip flops -- 雙緩衝器，同步輸入訊號
  SIGNAL counter_set : STD_LOGIC;                    --sync reset to zero  --若輸入狀態改變則為 1，用於重設計數器
  SIGNAL counter_out : STD_LOGIC_VECTOR(counter_size DOWNTO 0) := (OTHERS => '0'); --counter output -- 計數器
BEGIN

  counter_set <= flipflops(0) xor flipflops(1);   --determine when to start/reset counter
  
  PROCESS(clk)
  BEGIN
    IF(clk'EVENT and clk = '1') THEN
      flipflops(0) <= button; -- 同步第一級 flipflop
      flipflops(1) <= flipflops(0);-- 第二級 flipflop，延遲一拍
      If(counter_set = '1') THEN                  --reset counter because input is changing
        counter_out <= (OTHERS => '0');
      ELSIF(counter_out(counter_size) = '0') THEN --stable input time is not yet met
        counter_out <= counter_out + 1;
      ELSE                                        --stable input time is met
        result <= flipflops(1); --沒按也會傳沒按按鈕的值
      END IF;    
    END IF;
  END PROCESS;
END logic;
-- counter_size = 19，對於 50MHz 時脈來說，相當於 2^19}/ 50*10^6大約10.5ms，也就是需要按鈕輸入連續穩定 10.5ms才會改變輸出。
-- 適合機械按鈕，因為通常彈跳時間 < 5ms。