library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Lab08_02 is 
	port (
		KEY : in std_logic_vector(2 downto 1);
		SW : in std_logic_vector(0 downto 0);
		LEDG : out std_logic_vector(9 downto 4));
end Lab08_02;

architecture arch of Lab08_02 is 
	type STATE is (S0, S1, S2, S3, S4, S5, S6, S7, S8);
	signal present_state : STATE := S0;
	signal next_state : STATE := S0;
	signal op : std_logic;
	signal CLK : std_logic;
	signal x : std_logic;
	signal rst : std_logic;
begin
	CLK <= KEY(2);
	x <= SW(0);
	rst <= KEY(1);
	
	-- this process is for building the FSM of Lab08_02 for detecting the consistent 4th '1' or '0'
	state_comp:process(present_state, x)
	begin
		case present_state is
			when s0 => LEDG(7 downto 4) <= "0000";
				if x = '0' then 
					next_state <= S1;
				else
					next_state <= S5;
				end if;
				op <= '0';
			when s1 => LEDG(7 downto 4) <= "0001";
				if x = '0' then 
					next_state <= S2;
				else
					next_state <= S5;
				end if;
				op <= '0';
			when s2 => LEDG(7 downto 4) <= "0010";
				if x = '0' then 
					next_state <= S3;
				else
					next_state <= S5;
				end if;
				op <= '0';
			when s3 => LEDG(7 downto 4) <= "0011";
				if x = '0' then 
					next_state <= S4;
				else
					next_state <= S5;
				end if;
				op <= '0';
			when s4 => LEDG(7 downto 4) <= "0100";
				if x = '0' then 
					next_state <= S4;
				else
					next_state <= S5;
				end if;
				op <= '1';
			when s5 => LEDG(7 downto 4) <= "0101";
				if x = '0' then 
					next_state <= S1;
				else
					next_state <= S6;
				end if;
				op <= '0';
			when s6 => LEDG(7 downto 4) <= "0110";
				if x = '0' then 
					next_state <= S1;
				else
					next_state <= S7;
				end if;
				op <= '0';
			when s7 => LEDG(7 downto 4) <= "0111";
				if x = '0' then 
					next_state <= S1;
				else
					next_state <= S8;
				end if;
				op <= '0';
			when s8 => LEDG(7 downto 4) <= "1000";
				if x = '0' then 
					next_state <= S1;
				else
					next_state <= S8;
				end if;
				op <= '1';
		end case;
	end process state_comp;
	
	state_clock:process(clk, rst)
	begin
		if rst = '0' then
			present_state <= S0;
		elsif clk'event and clk = '1' then
			present_state <= next_state;
		end if;
		LEDG(9) <= op ;
	end process state_clock;
end architecture;