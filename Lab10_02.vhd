library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity Lab10_02 is 
port(	CLOCK_50:in std_logic;
		KEY:in std_logic_vector(2 downto 0);
		GPIO_0:out std_logic_vector(21 downto 9);      -- connect to lcd pin8 to pin1
		GPIO_1:out std_logic_vector(21 downto 9) );    -- connect to lcd pin16 to pin9  
end Lab10_02;

architecture arch of Lab10_02 is
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
signal LINE1:DDRAM:= (x"20", x"20", x"20", x"20", x"44", x"31", x"30", x"31", x"38", x"36", x"31", x"34", x"20", x"20", x"20", x"20");
signal LINE_TEMP:DDRAM:= (x"20", x"20", x"20", x"20", x"44", x"31", x"30", x"31", x"38", x"36", x"31", x"34", x"20", x"20", x"20", x"20");
signal LINE2:DDRAM:=(x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20");
signal LINE_EMP:DDRAM:=(x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20");
signal TEMP:std_logic_vector(7 downto 0);
signal LCM_RS, LCM_RW, LCM_EN :std_logic;
signal LCM_DB:std_logic_vector(7 downto 0);
signal shift_counter: integer range 0 to 1:= 0; -- take shifr 2 for example
signal L_R: std_logic;
signal CLK_1khz, CLK_500hz, CLK_1hz:std_logic; 
signal Buttons, shift_dir: std_logic_vector(1 downto 0);
signal mode: std_LOGIC:= '1';

		
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

-- mode controler
process(KEY)
begin
	if KEY(1) = '0' then
		mode <= '0';
	elsif KEY(2) = '0' then
		mode <= '1';
	end if;
end process;


process(CLK_1hz, mode)
begin
		if mode = '0' then
			LINE1 <= LINE_EMP;
		else
			if CLK_1hz'event and CLK_1hz='1' then
					if L_R = '1' then
						for i in 14 downto 0 loop
							LINE_TEMP(i+1)<=LINE_TEMP(i);
						end loop;
						shift_counter <= shift_counter + 1;
					else 
						for i in 14 downto 0 loop
							LINE_TEMP(i)<=LINE_TEMP(i+1);
						end loop;
						shift_counter <= shift_counter + 1;
					end if;
					if shift_counter = 1 theN
						shift_counter <= 0;
						L_R <= not L_R;
					end if;
			LINE1 <= LINE_TEMP;
			end if;
		end if;
end process;
	
--counter
process(LCM_CLK,RESET)
begin
	if RESET='0' then
		COUNTER<=0;
	elsif LCM_CLK'event and LCM_CLK='0' then
		if COUNTER>=41 then
			COUNTER<=25;
		else
			COUNTER<=COUNTER+1;
		end if;
   end if;
end process;

--display circuit
process(LCM_CLK,RESET)
begin
	if(LCM_CLK'event and LCM_CLK='1') then	
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
				LCM_DB<="00000110";		--entry mode set ----------------------	
			when 8=>
				LCM_RS<='0';
				LCM_DB<="11000000";		--set position 	
			when 9=>
				LCM_RS<='1';
				LCM_DB<=LINE2(0);
			when 10=>
				LCM_DB<=LINE2(1);
			when 11=>
				LCM_DB<=LINE2(2);
			when 12=>
				LCM_DB<=LINE2(3);
			when 13=>
				LCM_DB<=LINE2(4);
			when 14=>
				LCM_DB<=LINE2(5);
			when 15=>
				LCM_DB<=LINE2(6);
			when 16=>
				LCM_DB<=LINE2(7);
			when 17=>
				LCM_DB<=LINE2(8);
			when 18=>
				LCM_DB<=LINE2(9);
			when 19=>
				LCM_DB<=LINE2(10);
			when 20=>
				LCM_DB<=LINE2(11);
			when 21=>
				LCM_DB<=LINE2(12);
			when 22=>
				LCM_DB<=LINE2(13);
			when 23=>
				LCM_DB<=LINE2(14);
			when 24=>
				LCM_DB<=LINE2(15);
			when 25=>
				LCM_RS<='0';			--set position
				LCM_DB<="10000000";
			when 26=>
				LCM_RS<='1';
				LCM_DB<=LINE1(0);
			when 27=>
				LCM_DB<=LINE1(1);
			when 28=>
				LCM_DB<=LINE1(2);
			when 29=>
				LCM_DB<=LINE1(3);
			when 30=>
				LCM_DB<=LINE1(4);
			when 31=>
				LCM_DB<=LINE1(5);
			when 32=>
				LCM_DB<=LINE1(6);
			when 33=>
				LCM_DB<=LINE1(7);
			when 34=>
				LCM_DB<=LINE1(8);
			when 35=>
				LCM_DB<=LINE1(9);
			when 36=>
				LCM_DB<=LINE1(10);
			when 37=>
				LCM_DB<=LINE1(11);
			when 38=>
				LCM_DB<=LINE1(12);
			when 39=>
				LCM_DB<=LINE1(13);
			when 40=>
				LCM_DB<=LINE1(14);
			when 41=>
				LCM_DB<=LINE1(15);
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

