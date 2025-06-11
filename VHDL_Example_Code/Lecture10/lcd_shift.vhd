library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity LCD_SHIFT is 
port(	CLOCK_50:in std_logic;
		KEY:in std_logic_vector(2 downto 0);
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
signal LINE1:DDRAM;
signal LINE2:DDRAM;
signal TEMP:std_logic_vector(7 downto 0);
signal LCM_RS, LCM_RW, LCM_EN :std_logic;
signal LCM_DB:std_logic_vector(7 downto 0);

signal CLK_1khz, CLK_500hz, CLK_1hz:std_logic; 
signal Buttons, shift_dir: std_logic_vector(1 downto 0);
constant RIGHT: std_logic_vector(1 downto 0) := "01";
constant LEFT:  std_logic_vector(1 downto 0) := "10";

begin
--------------- comment1 ------------------ 
-- **The following code gets the error "Error (10028): Can't resolve multiple constant drivers for net"
-- **Reason: shift_dir is assigned in two different processes
----check if key1 is pressed
--process(Buttons(0))
--begin
--	if Buttons(0)'event and Buttons(0)='1' then
--		shift_dir <= RIGHT;
--   end if;
--end process;
--
----check if key2 is pressed
--process(Buttons(1))
--begin
--	if Buttons(1)'event and Buttons(1)='1' then
--		shift_dir <= LEFT;
--   end if;
--end process;

--------------- comment2 ------------------
-- **The following code gets the error "Error (10822): couldn't implement registers for assignments on this clock edge"
-- **Reason: cannot synthesize two different edge-trigger registers in one process.
--process(Buttons)
--begin
--	if Buttons(0)'event and Buttons(0)='1' then
--		shift_dir <= LEFT; 
--	elsif Buttons(1)'event and Buttons(1)='1' then     -- KEY(1) is pushed, shift right
--		shift_dir <= RIGHT;
--   end if;
--end process;

--------------- comment3 ------------------
-- **The following code is for shifting LINE2 by pressing the key "continuously"  
----generate 500hz and 1hz clock
--  CLK_U1: CLK_GEN generic map(divisor => 100_000) port map(CLOCK_50, CLK_500hz); 
--  CLK_U2: CLK_GEN generic map(divisor => 50_000_000) port map(CLOCK_50, CLK_1hz);
----debounce push buttons
--  debounce_key1: debounce PORT MAP(clk => CLOCK_50, button => KEY(1), result => Buttons(0));
--  debounce_key2: debounce PORT MAP(clk => CLOCK_50, button => KEY(2), result => Buttons(1));
--
--LCM_CLK<= CLK_500hz;  -- 2ms
--LCM_EN<=LCM_CLK;
--RESET <= KEY(0);
--
----check shift direction, every 1 second
--process(CLK_1hz,RESET)
--begin
--	if(RESET='0') then 
--		LINE2(0) <="00100000";				--
--		LINE2(1) <="00100000";				--
--		LINE2(2) <="00100000";				--
--		LINE2(3) <="01001001";				--I
--		LINE2(4) <="00100000";				--
--		LINE2(5) <="01001100";				--L
--		LINE2(6) <="01001111";				--O
--		LINE2(7) <="01010110";				--V
--		LINE2(8) <="01000101";				--E
--		LINE2(9) <="00100000";				--
--		LINE2(10)<="01001100";				--L
--		LINE2(11)<="01000011";				--C
--		LINE2(12)<="01000100";				--D
--		LINE2(13)<="00100000";				--
--		LINE2(14)<="00100000";				--
--		LINE2(15)<="00100000";				--
--	elsif CLK_1hz'event and CLK_1hz='1' then
--		if Buttons = "01" then       -- KEY(2) is pushed, shift left
--			TEMP<=LINE2(15);
--			for i in 14 downto 0 loop
--				LINE2(i+1)<=LINE2(i);
--			end loop;
--			LINE2(0)<=TEMP;
--		elsif Buttons = "10" then     -- KEY(1) is pushed, shift right
--			TEMP<=LINE2(0);
--			for i in 14 downto 0 loop
--				LINE2(i)<=LINE2(i+1);
--			end loop;
--			LINE2(15)<=TEMP;
--		end if;
--   end if;
--end process;
	
	
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
RESET <= KEY(0);

--sample buttons 
	process(CLK_1khz, RESET)
	begin
		if RESET='0' then
			shift_dir <= "00";
		elsif CLK_1khz'event and CLK_1khz='1' then
			if (Buttons = "10" or Buttons = "01") then   -- check if KEY(1) or KEY(2) is pressed
				shift_dir <= NOT Buttons;                 -- complement the status of keys, to make the meaning of shift_dir more intuitive
			end if;
		end if;
	end process; 

--check shift direction, every 1 second
process(CLK_1hz,RESET)
begin
	if(RESET='0') then 
--		shift_dir <= INIT;
		LINE2(0) <="00100000";				--
		LINE2(1) <="00100000";				--
		LINE2(2) <="00100000";				--
		LINE2(3) <="01001001";				--I
		LINE2(4) <="00100000";				--
		LINE2(5) <="01001100";				--L
		LINE2(6) <="01001111";				--O
		LINE2(7) <="01010110";				--V
		LINE2(8) <="01000101";				--E
		LINE2(9) <="00100000";				--
		LINE2(10)<="01001100";				--L
		LINE2(11)<="01000011";				--C
		LINE2(12)<="01000100";				--D
		LINE2(13)<="00100000";				--
		LINE2(14)<="00100000";				--
		LINE2(15)<="00100000";				--
	elsif CLK_1hz'event and CLK_1hz='1' then
		if shift_dir = RIGHT then       -- KEY(1) is pushed, shift right
			TEMP<=LINE2(15);
			for i in 14 downto 0 loop
				LINE2(i+1)<=LINE2(i);
			end loop;
			LINE2(0)<=TEMP;
		elsif shift_dir = LEFT then     -- KEY(2) is pushed, shift left
			TEMP<=LINE2(0);
			for i in 14 downto 0 loop
				LINE2(i)<=LINE2(i+1);
			end loop;
			LINE2(15)<=TEMP;
		end if;
   end if;
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
process(LCM_CLK,RESET)
begin
	if(RESET='0') then 
		LINE1(0) <="01001100";				--L
		LINE1(1) <="01000011";				--C
		LINE1(2) <="01001101";				--M
		LINE1(3) <="00100000";				--
		LINE1(4) <="01000100";				--D
		LINE1(5) <="01001001";				--I
		LINE1(6) <="01010011";				--S
		LINE1(7) <="01010000";				--P
		LINE1(8) <="01001100";				--L
		LINE1(9) <="01000001";				--A
		LINE1(10)<="01011001";				--Y
		LINE1(11)<="00100000";				--
		LINE1(12)<="01010100";				--T
		LINE1(13)<="01000101";				--E
		LINE1(14)<="01010011";				--S
		LINE1(15)<="01010100";				--T
--		LINE2(0) <="00100000";				--     *** The following initialization will be done in process(CLK_1hz,RESET) ***
--		LINE2(1) <="00100000";				--
--		LINE2(2) <="00100000";				--
--		LINE2(3) <="01001001";				--I
--		LINE2(4) <="00100000";				--
--		LINE2(5) <="01001100";				--L
--		LINE2(6) <="01001111";				--O
--		LINE2(7) <="01010110";				--V
--		LINE2(8) <="01000101";				--E
--		LINE2(9) <="00100000";				--
--		LINE2(10)<="01001100";				--L
--		LINE2(11)<="01000011";				--C
--		LINE2(12)<="01000100";				--D
--		LINE2(13)<="00100000";				--
--		LINE2(14)<="00100000";				--
--		LINE2(15)<="00100000";				--
	elsif(LCM_CLK'event and LCM_CLK='0') then	
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

