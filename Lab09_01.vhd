library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity lab09_01 is
    port (
        CLOCK_50  : in  std_logic;
        KEY       : in  std_logic_vector(2 downto 0);  
        GPIO_0    : out std_logic_vector(21 downto 9); 
        GPIO_1    : out std_logic_vector(21 downto 9)  
    );
end lab09_01;

architecture rtl of lab09_01 is


    type LED8x8_type is array(1 to 8) of std_logic_vector(1 to 8);

    type DiceROM_t is array(1 to 6) of LED8x8_type;
    constant DICE_ROM : DiceROM_t := (
    1 => (
        "00000000",   
        "00000000",   
        "00000000",  
        "00011000",   
        "00011000",   
        "00000000",   
        "00000000",   
        "00000000"    
    ),
    2 => (
        "00000000",  
        "01100000",  
        "01100000",   
        "00000000",   
        "00000000",  
        "00000110",   
        "00000110",  
        "00000000"    
    ),
    3 => (
        "00000000",  
        "01100000", 
        "01100000",   
        "00011000",  
        "00011000",   
        "00000110",   
        "00000110",   
        "00000000"     
    ),
    4 => (
        "01100110",  
        "01100110",  
        "00000000",  
        "00000000",   
        "00000000",   
        "00000000",  
        "01100110",    
        "01100110"    
    ),
    5 => (
        "01100110",  
        "01100110",  
        "00000000",  
        "00011000",  
        "00011000",  
        "00000000",  
        "01100110",  
        "01100110"   
    ),
    6 => (
        "01100110",  
        "01100110",  
        "00000000",  
        "01100110",  
        "01100110",  
        "00000000",  
        "01100110",  
        "01100110"   
    )
);


    -- 分頻計數器
    signal div1k   : integer range 0 to 49999    := 0;
    signal div10   : integer range 0 to 4999999  := 0;
    signal clk_1k  : std_logic := '0';
    signal clk_10  : std_logic := '0';

    -- 掃描列號、ROW/COL、點陣映射
    signal scanline : integer range 0 to 7 := 0;
    signal ROW, COL : std_logic_vector(1 to 8);
    signal LEDmap   : LED8x8_type;

    -- 骰子計數與按鍵
    signal dice_cnt : integer range 1 to 6 := 1;
    signal reset_n  : std_logic;
    signal dice_btn : std_logic;

begin

    -- 連接按鍵
    reset_n  <= KEY(1);    -- active-low reset
    dice_btn <= KEY(2);    -- active-low dice，放開('1')才跑

    -- 分頻產生 1 kHz、10 Hz
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            div1k <= div1k + 1;
            div10 <= div10 + 1;
            if div1k = 49999 then
                div1k <= 0; clk_1k <= not clk_1k;
            end if;
            if div10 = 499999 then
                div10 <= 0; clk_10 <= not clk_10;
            end if;
        end if;
    end process;

    -- 掃描行產生器 (1 kHz)
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

    -- ROW one-hot (低有效)
    with scanline select
        ROW <=
          "01111111" when 0, "10111111" when 1,
          "11011111" when 2, "11101111" when 3,
          "11110111" when 4, "11111011" when 5,
          "11111101" when 6, "11111110" when 7,
          (others => '1') when others;

    -- 根據 scanline 取出對應的 COL
    with scanline select
        COL <=
          LEDmap(1) when 0, LEDmap(2) when 1,
          LEDmap(3) when 2, LEDmap(4) when 3,
          LEDmap(5) when 4, LEDmap(6) when 5,
          LEDmap(7) when 6, LEDmap(8) when 7,
          (others => '0') when others;

    -- 骰子計數器 (10 Hz)：reset → 1，放開 dice 才 +1，6→1 迴圈
    process(clk_10, reset_n)
    begin
        if reset_n = '0' then
            dice_cnt <= 1;
        elsif rising_edge(clk_10) then
            if dice_btn = '0' then
                if dice_cnt = 6 then
                    dice_cnt <= 1;
                else
                    dice_cnt <= dice_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- 依當前 dice_cnt 選擇要顯示的點陣
    process(dice_cnt)
    begin
        LEDmap <= DICE_ROM(dice_cnt);
    end process;
	
	
	-- back-side
	GPIO_0(21) <= COL(8);  GPIO_0(19) <= COL(7);	GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
	GPIO_0(14) <= ROW(4);  GPIO_0(13) <= COL(6);	GPIO_0(11) <= COL(4); GPIO_0(9) <= ROW(1);
	-- front-side	
	GPIO_1(21) <= ROW(5);  GPIO_1(19) <= ROW(7);	GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
	GPIO_1(14) <= ROW(8);  GPIO_1(13) <= COL(5);	GPIO_1(11) <= ROW(6); GPIO_1(9) <= ROW(3);
end architecture;