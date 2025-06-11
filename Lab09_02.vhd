library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;   -- 建議用 numeric_std

entity lab09_02 is
    port (
        CLOCK_50  : in  std_logic;
        KEY       : in  std_logic_vector(2 downto 0);  -- KEY(0)=reset, KEY(1)=dice
        GPIO_0    : out std_logic_vector(21 downto 9); -- 背側 Row/Col
        GPIO_1    : out std_logic_vector(21 downto 9)  -- 前側 Row/Col
    );
end lab09_02;

architecture rtl of lab09_02 is

    -- 8×8 點陣：每列 8 bit
    type LED8x8_type is array(1 to 8) of std_logic_vector(1 to 8);

    -- 骰子 1~6 的點陣 ROM (common-anode, '1' 代表亮)
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
        "00100100"   --  
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
        "00111000",  --  
        "00010100",  --  
        "00010100",  --  
        "00100100"   --  
    )
);


    -- 分頻計數器
    signal div1k   : integer range 0 to 49999    := 0;
    signal div2   : integer range 0 to 24999999  := 0;
    signal clk_1k  : std_logic := '0';
    signal clk_2  : std_logic := '0';

    -- 掃描列號、ROW/COL、點陣映射
    signal scanline : integer range 0 to 7 := 0;
    signal ROW, COL : std_logic_vector(1 to 8);
    signal LEDmap   : LED8x8_type;

    -- 骰子計數與按鍵
    signal dice_cnt : integer range 1 to 8 := 1;
    signal reset_n  : std_logic;
    signal op  : std_logic := '1';


begin

    -- 連接按鍵
    reset_n <= KEY(2);    -- active-low dice，放開('1')才跑

    -- 分頻產生 1 kHz、2 Hz
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            div1k <= div1k + 1;
            div2 <= div2 + 1;
            if div1k = 49999 then
                div1k <= 0; clk_1k <= not clk_1k;
            end if;
				--5000000
				-- 50000000
				-- 25000000
            if div2 = 12499999 then
                div2 <= 0; clk_2 <= not clk_2;
            end if;
        end if;
    end process;

    -- 掃描行產生器 (1 kHz)
    process(clk_1k)
    begin
        if rising_edge(clk_1k) then
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
    process(clk_2, reset_n)
    begin
        if rising_edge(clk_2)and op = '1' then
                if dice_cnt = 8 then
                    dice_cnt <= 1;
                else
                    dice_cnt <= dice_cnt + 1;
                end if;
        end if;
		  if  reset_n'EVENT and reset_n = '0' then
            op <= not op;
		  end if;
    end process;

    -- 依當前 dice_cnt 選擇要顯示的點陣
    process(dice_cnt)
    begin
        LEDmap <= DICE_ROM(dice_cnt);
    end process;

    -- 腳位對應 (請依實際走線調整下列索引)
    -- 背側
    GPIO_0(21) <= COL(8); GPIO_0(19) <= COL(7);
    GPIO_0(17) <= ROW(2); GPIO_0(15) <= COL(1);
    GPIO_0(14) <= ROW(4); GPIO_0(13) <= COL(6);
    GPIO_0(11) <= COL(4); GPIO_0(9)  <= ROW(1);
    -- 前側
    GPIO_1(21) <= ROW(5); GPIO_1(19) <= ROW(7);
    GPIO_1(17) <= COL(2); GPIO_1(15) <= COL(3);
    GPIO_1(14) <= ROW(8); GPIO_1(13) <= COL(5);
    GPIO_1(11) <= ROW(6); GPIO_1(9)  <= ROW(3);

end architecture;