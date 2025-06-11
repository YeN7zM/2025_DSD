Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY Hbar_display IS   
	PORT( video_on:IN std_logic;
          r,c: IN std_logic_vector(9 downto 0);
		  Rout, Gout, Bout: out std_logic_vector(3 downto 0));
END Hbar_display;

ARCHITECTURE arch OF Hbar_display IS
begin
process(video_on,r,c) 
begin
If video_on='1' then         --設定行與列的範圍以顯示特定色彩
    IF (r>50 AND r<=150)and (c>0 and c<640) THEN
	   Rout<="1111"; Gout<="0000"; Bout<="0000";
    else 
       Rout<="0000"; Gout<="0000"; Bout<="0000";
    end if;

    IF (r>150 AND r<=250) and (c>0 and c<640) THEN
	   Rout<="1111"; Gout<="1111"; Bout<="1111";
    else
            null;
    End if;

    IF (r>250 AND r<350) and (c>0 and c<640)  THEN
	   Rout<="0000"; Gout<="0000"; Bout<="1111";
    else 
           null;
    End if;
else                            --video time範圍以外全不顯示
    Rout<="0000"; Gout<="0000"; Bout<="0000";
end if;
end process;

END arch;
