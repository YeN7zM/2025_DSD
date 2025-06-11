library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab121 is port(
    --VGA_sync
    CLOCK_50: IN std_logic;--記得除頻25
    KEY: IN std_logic_vector(1 downto 1);
    VGA_HS,VGA_VS: OUT std_logic;
    --rgb
    VGA_R, VGA_G, VGA_B:  out std_logic_vector(3 downto 0)
);
end ;

architecture a of lab121 is
    --VGA_sync\rgb
    signal RESET: std_logic;
    signal video_on: std_logic;
    signal row, col: integer;--row_counter\col_counter
    signal CLK_25Mhz: std_logic;

    signal RGB: std_logic_vector(11 downto 0);

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

    type BITMAP is array(0 to 15) of std_logic_vector(0 to 31);--32col*16row (10*20放大)->320*320
    constant kirby: BITMAP := (--00=0 01=1 10=2 11=3
        "00000000000001010101010000000000",
        "00000000010110111111100101000000",
        "00000001101111111111111110010000",
        "00000110111111111111111111010000",
        "00000111111111111111111111100100",
        "00011111111111111101110111100100",
        "01101111111111111101110111111101",
        "01111111111111111101110111111101",
        "01111111111110101111111110101101",
        "01101111101111111111111111101101",
        "00011011011111111111011111011000",
        "00000101101111111111111110010100",
        "00000001011010111111111001010000",
        "00000110100101010101010110100100",
        "00011010101010010101011010101001",
        "00000101010101010000000101010100"
    );

    constant WHITE: std_logic_vector(11 downto 0) := x"FFF";
    constant BLACK: std_logic_vector(11 downto 0) := x"000";
    constant MOMO_PINK: std_logic_vector(11 downto 0) := x"F69";
    constant PINK: std_logic_vector(11 downto 0) := x"F9B";

begin
    RESET<=KEY(1);
    CLK_U1: CLK_GEN generic map(divisor => 2) port map(CLOCK_50, CLK_25Mhz);
    --VGA_sync
    VGA_sync_U1: VGA_sync port map(CLOCK => CLK_25Mhz,RESET=>KEY(1),HOR_SYN=>VGA_HS,VER_SYN=>VGA_VS,video_on=>video_on,row_counter=>row,col_counter=>col);

    process(video_on, row, col)
       variable kirby_row: std_logic_vector(0 to 31);
        --
        variable idx     : integer ;
        variable pattern : std_logic_vector(0 to 1);
    begin
        if(video_on = '0') then
            RGB <= BLACK;
        elsif(row >= 80 and row < 400 and col >= 160 and col < 480) then
            kirby_row := kirby((row-80)/ 20);
				idx:= ((col - 160)/ 20) * 2;
				pattern:= kirby_row(idx)&kirby_row(idx+1);
            case pattern is
                when "00" => RGB <= WHITE;
                when "01" => RGB <= BLACK;
                when "10" => RGB <= MOMO_PINK;
                when "11" => RGB <= PINK;
            end case;
        else
            RGB <= BLACK;
        end if;
    end process;
    VGA_R <= RGB(11 downto 8);
    VGA_G <= RGB(7 downto 4);
    VGA_B <= RGB(3 downto 0);
end architecture;

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
        row_counter:out INTEGER RANGE 0 TO 524;		
        col_counter:out INTEGER RANGE 0 TO 799	);
END VGA_sync ;

ARCHITECTURE arch OF VGA_sync IS
SIGNAL h_count: INTEGER RANGE 0 TO 799;			
SIGNAL v_count: INTEGER RANGE 0 TO 524;		
BEGIN

--Generate Horizontal and Vertical Timing Signals for Video Signal
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

--Generate Horizontal Sync Signal using h_count	
  PROCESS (h_count)  
    BEGIN
		IF h_count >=660 and h_count<=755 THEN HOR_SYN <= '0';
		ELSE  HOR_SYN <= '1';
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