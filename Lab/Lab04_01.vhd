LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY Lab04_01 IS
    PORT (  SW : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6);
            HEX1 : OUT STD_LOGIC_VECTOR(0 TO 6)
    );
END Lab04_01;

ARCHITECTURE Structure OF Lab04_01 IS
BEGIN 
    PROCESS(SW)
    BEGIN    
        CASE SW IS --
                WHEN "0000" => HEX0 <= not("1111110" ); HEX1 <= not("1111110"); --00
                WHEN "0001" => HEX0 <= not("0110000" ); HEX1 <= not("1111110"); --01
                WHEN "0010" => HEX0 <= not("1101101" ); HEX1 <= not("1111110"); --02
                WHEN "0011" => HEX0 <= not("1111001" ); HEX1 <= not("1111110"); --03
                WHEN "0100" => HEX0 <= not("0110011" ); HEX1 <= not("1111110"); --04
                WHEN "0101" => HEX0 <= not("1011011" ); HEX1 <= not("1111110"); --05
                WHEN "0110" => HEX0 <= not("1011111" ); HEX1 <= not("1111110"); --06
                WHEN "0111" => HEX0 <= not("1110000" ); HEX1 <= not("1111110"); --07
                WHEN "1000" => HEX0 <= not("1111111" ); HEX1 <= not("1111110"); --08
                WHEN "1001" => HEX0 <= not("1111011" ); HEX1 <= not("1111110"); --09
                WHEN "1010" => HEX0 <= not("1111110" ); HEX1 <= not("0110000"); --10
                WHEN "1011" => HEX0 <= not("0110000" ); HEX1 <= not("0110000"); --11
                WHEN "1100" => HEX0 <= not("1101101" ); HEX1 <= not("0110000"); --12
                WHEN "1101" => HEX0 <= not("1111001" ); HEX1 <= not("0110000"); --13
                WHEN "1110" => HEX0 <= not("0110011" ); HEX1 <= not("0110000"); --14
                WHEN "1111" => HEX0 <= not("1011011" ); HEX1 <= not("0110000"); --15
            END CASE;
        END PROCESS;
END Structure;