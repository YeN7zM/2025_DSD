Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


ENTITY RGB_display IS   
	PORT(  video_on:IN std_logic;
        Red,Green,Blue: IN std_logic;
		 Rout, Gout, Bout: out std_logic);
END RGB_display;

ARCHITECTURE arch OF RGB_display IS
begin

process(video_on) 
begin
If video_on='1' then    --video time範圍內，RGB色彩依外界輸入設定而顯示
    Rout<=Red;
    Gout<=Green;
    Bout<=Blue;
else 
    Rout<='0';Gout<='0';Bout<='0';    --video time以外，螢幕顯示全黑
end if;

end process;

END arch;


