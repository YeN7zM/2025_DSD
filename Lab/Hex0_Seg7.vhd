library ieee;
use ieee.std_logic_1164.all;
entity Hex0_Seg7 is 
    port( 
        SW : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6)
    ); 
end Hex0_Seg7;
architecture Dataflow of Hex0_Seg7 is 
    signal A, B, C, D : STD_LOGIC;
begin
	A <= SW(3);
	B <= SW(2);
	C <= SW(1);
	D <= SW(0);
    HEX0(0) <= not ( (not B and not D) or (not A and C) or (B and C) or (not A and B and D) or (A and not B and not C));
    HEX0(1) <= not ( (not A and not B) or (not A and not C and not D) or (not A and C and D) or (A and not C and D) or (not B and not D) or (A and not B and not C));
    HEX0(2) <= not ( (not A and not C and not D) or (not C and D) or (not A and C and D) or (not A and B) or (A and not B));
    HEX0(3) <= not ( (not A and not B and not D) or (not B and C and D) or (B and not C and D) or (B and C and not D) or (A and not C));
    HEX0(4) <= not ( (not B and not D) or (A and B) or (A and C) or (C and not D));
    HEX0(5) <= not ( (A and not B) or (A and C) or (not A and not C and not D) or (not A and B and not C) or (B and C and not D));
    HEX0(6) <= not ( (A and B) or (A and not B) or (B and not C) or (B and not D) or (not B and C));
end Dataflow;