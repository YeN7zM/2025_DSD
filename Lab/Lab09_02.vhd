library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   

entity lab09_02 is
    port (
        CLOCK_50  : in  std_logic;
        KEY       : in  std_logic_vector(2 downto 0);  
        GPIO_0    : out std_logic_vector(21 downto 9); 
        GPIO_1    : out std_logic_vector(21 downto 9)
    );
end lab09_02;

architecture rtl of lab09_02 is

    type LED8x8_type is array(1 to 8) of std_logic_vector(1 to 8);
    type DiceROM_t is array(1 to 8) of LED8x8_type;
    constant DICE_ROM : DiceROM_t := (
    1 => (
        "00111000",  --  
        "00110000",  --  
        "00011000",  --  
        "00011000",  --  
        "00011000",  --  
        "00001000",  --  
        "00010100",  --  
        "00010100"   --  
    ),
    2 => (
        "00111000",  --  
        "00110000",  --  
        "00011000",  --  
        "00011100",  --  
        "00111000",  --  
        "00010100",  --  
        "00010100",  --  
        "00100000"   --  
    ),
    3 => (
        "00111000",  --  
        "00110000",  --  
        "00011100",  --  
        "00111010",  --  
        "00001000",  --  
        "00010100",  --  
        "00100100",  --  
        "00100010"   --  
    ),
    4 => (
        "00111000",  -- 
        "00110000",  --  
        "00011100",  --  
        "00111010",  --  
        "01001001",  --  
        "00010100",  --  
        "00100010",  --  
        "00100010"   --  
    ),
    5 => (
        "00111000",  -- 
        "00110000",  --  
        "00011110",  --  
        "00111001",  --  
        "01001000",  --  
        "00010100",  --  
        "00100010",  --  
        "01000010"   --  
    ),
    6 => (
        "00111000",  -- 
        "00110000",  --  
        "00011100",  --  
        "00111010",  --  
        "01001001",  --  
        "00010100",  --  
        "00100010",  --  
        "00100010"   --  
    ),
     7 => (
        "00111000",  -- 
        "00110000",  --  
        "00011100",  --  
        "00111010",  --  
        "00001000",  --  
        "00010100",  --  
        "00100100",  --  
        "00100010"   --  
    ),
     8 => (
        "00111000",  -- 
        "00110000",  --  
        "00011000",  --  
        "00011100",  --  
        "00111001",  --  
        "00010100",  --  
        "00010100",  --  
        "00100100"   --  
    )
);


    constant divisor : INTEGER :=49999999 ;
    signal count : INTEGER range 0 to divisor:=0;
	 signal count2 : INTEGER range 0 to divisor:=0;
    signal clk_1k  : std_logic := '0';
    signal clk_10  : std_logic := '0';
    signal scanline : integer range 0 to 7 := 0;
    signal ROW, COL : std_logic_vector(1 to 8);
    signal LEDmap   : LED8x8_type;
	 signal pause     : std_logic := '0';  
    signal key0_prev : std_logic := '1';  
    signal dice_cnt : integer range 1 to 8 := 1;
    signal reset_n  : std_logic;
    signal dice_btn : std_logic;

begin

    process(CLOCK_50)
    begin
        if CLOCK_50'event and CLOCK_50 = '1' then
            if count < divisor / 2000 - 1  then
                 count <= count + 1;
            else 
                 count <= 0;
                 clk_1k <= not clk_1k;
            end if;
            if count2 < divisor / 4 - 1  then
                 count2 <= count2 + 1;
            else 
                 count2 <= 0;
                 clk_10 <= not clk_10;
            end if;
				
				if key0_prev = '1' and KEY(2) = '0' then  
					pause <= not pause;
				end if;
				key0_prev <= KEY(2);
        end if;
    end process;

    process(clk_1k, reset_n)
    begin
        if reset_n = '0' then
            scanline <= 0;
        elsif rising_edge(clk_1k) then
            if scanline = 7 then
                scanline <= 0;
            else
                scanline <= scanline + 1;
            end if;
        end if;
    end process;

    with scanline select
        ROW <=
          "01111111" when 0, "10111111" when 1,
          "11011111" when 2, "11101111" when 3,
          "11110111" when 4, "11111011" when 5,
          "11111101" when 6, "11111110" when 7,
          (others => '1') when others;

    with scanline select
        COL <=
          LEDmap(1) when 0, LEDmap(2) when 1,
          LEDmap(3) when 2, LEDmap(4) when 3,
          LEDmap(5) when 4, LEDmap(6) when 5,
          LEDmap(7) when 6, LEDmap(8) when 7,
          (others => '0') when others;
	process(clk_10, reset_n)
    begin
        if reset_n = '0' then
            dice_cnt <= 1;
        elsif rising_edge(clk_10) then
				if pause = '0' then
                if dice_cnt = 8 then
                    dice_cnt <= 1;
                else
                    dice_cnt <= dice_cnt + 1;
                end if;
				end if;
        end if;
    end process;
    
    process(dice_cnt)
    begin
        LEDmap <= DICE_ROM(dice_cnt);
    end process;	
	 
    GPIO_0(21) <= COL(8); GPIO_0(19) <= COL(7);
    GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
    GPIO_0(14) <= ROW(4); GPIO_0(13) <= COL(6);
    GPIO_0(11) <= COL(4); GPIO_0(9)  <= ROW(1);
    GPIO_1(21) <= ROW(5); GPIO_1(19) <= ROW(7);
    GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
    GPIO_1(14) <= ROW(8); GPIO_1(13) <= COL(5);
    GPIO_1(11) <= ROW(6); GPIO_1(9)  <= ROW(3);

end architecture;