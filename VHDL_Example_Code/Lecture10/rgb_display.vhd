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
If video_on='1' then    --video time�d�򤺡ARGB��m�̥~�ɿ�J�]�w�����
    Rout<=Red;
    Gout<=Green;
    Bout<=Blue;
else 
    Rout<='0';Gout<='0';Bout<='0';    --video time�H�~�A�ù���ܥ���
end if;

end process;

END arch;


