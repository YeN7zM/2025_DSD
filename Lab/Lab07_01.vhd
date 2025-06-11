library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY lab71 IS
PORT (
    CLOCK_50       : IN STD_LOGIC;                     -- 輸入時脈
    KEY             : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- 按鈕，使用 KEY[1] 作為重設
    LEDG            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- LED 輸出
    --HEX0          : OUT STD_LOGIC_VECTOR(0 TO 6)      -- 七段顯示器輸出
);
END lab71;

ARCHITECTURE Behavioral OF lab71 IS
    SIGNAL clk_div : INTEGER RANGE 0 TO 49999999 := 0; -- 用於生成 1Hz 的計時器
    SIGNAL led_counter : INTEGER RANGE 0 TO 7 := 0;     -- LED 計數器
BEGIN
    PROCESS (CLOCK_50, KEY)
    BEGIN
        IF KEY(1) = '0' THEN                         -- 當按鈕按下（有效低）時重設
            led_counter <= 7;                        -- LED 計數器重置為 7
            LEDG <= "10000000";                      -- 重置 LED 點亮狀態為 LEDG(7)
            clk_div <= 0;                            -- 計時器重置
        ELSIF rising_edge(CLOCK_50) THEN                  -- 在時脈的上升沿
            clk_div <= clk_div + 1;                  -- 計時器加 1
            
            IF clk_div = 49999999 THEN                -- 每 50MHz 時脈下 25000000 次，即 1Hz
                clk_div <= 0;                        -- 重置計時器
                
                -- 使 led_counter 倒數
                IF led_counter = 0 THEN               -- 當計數器為 0 時重置到 7
                    led_counter <= 7;
                ELSE
                    led_counter <= led_counter - 1;   -- 否則減 1
                END IF;

                LEDG <= (others => '0');             -- 先將所有 LED 熄滅
                LEDG(led_counter) <= '1';             -- 點亮當前計數的 LED
            END IF;
        END IF;
    END PROCESS;

END Behavioral;