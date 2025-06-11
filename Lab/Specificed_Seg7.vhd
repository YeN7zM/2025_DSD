LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Lab03_02 IS
    PORT (  SW : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6);
            HEX1 : OUT STD_LOGIC_VECTOR(0 TO 6);
            HEX2 : OUT STD_LOGIC_VECTOR(0 TO 6);
            HEX3 : OUT STD_LOGIC_VECTOR(0 TO 6));
END Lab03_02;

ARCHITECTURE Structure OF Lab03_02 IS
    SIGNAL Sel : STD_LOGIC;
    SIGNAL W, X, Y, Z : STD_LOGIC;
BEGIN 
    PROCESS(SW)
    BEGIN    
        CASE SW IS --
                WHEN "00" => HEX3 <= "1000010"; HEX0 <= "1111111"; HEX1 <= "1111111"; HEX2 <= "1111111";
                WHEN "01" => HEX2 <= "0110000"; HEX0 <= "1111111"; HEX1 <= "1111111"; HEX3 <= "1111111";
                WHEN "10" => HEX1 <= "0000001"; HEX0 <= "1111111"; HEX3 <= "1111111"; HEX2 <= "1111111";
                WHEN "11" => HEX0 <= "1111111"; HEX1 <= "1111111"; HEX2 <= "1111111"; HEX3 <= "1111111";
                
            END CASE;
        END PROCESS;
END Structure;