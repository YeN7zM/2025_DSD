library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity Lab08_01 is
	port(
		KEY : in std_logic_vector(2 downto 1);
		SW : in std_logic_vector(0 downto 0);
		LEDG : out std_logic_vector(9 downto 5));
end Lab08_01;

architecture arch of Lab08_01 is
	type STATE is (S0, S1, S2, S3, S4);
	signal present_state : STATE:= S0;
	signal next_state : STATE:= S0;
	signal x, clk, rst : std_logic;
	signal op : std_logic;
	begin
		clk <= KEY(2);
		rst <= KEY(1);
		x <= SW(0);
		
		-- this process if for building the FSM of Lab08_01
		-- FSM is according to the "Lab08_instruction.ppt -p.11 -Figure 1"
		state_comp:process(present_state, x)
		begin
			case present_state is
				when S0 => LEDG(7 downto 5) <= "000";
					if x = '0' then
						next_state <= S0;
					else
						next_state <= S1;
					end if;
					op <= '0';
				when S1 => LEDG(7 downto 5) <= "001";
					if x = '0' then
						next_state <= S2;
					else
						next_state <= S1;
					end if;
					op <= '0';
				when S2 => LEDG(7 downto 5) <= "010";
					if x = '0' then
						next_state <= S0;
					else
						next_state <= S3;
					end if;
					op <= '0';
				when S3 => LEDG(7 downto 5) <= "011";
					if x = '0' then
						next_state <= S2;
					else
						next_state <= S4;
					end if;
					op <= '0';
				when S4 => LEDG(7 downto 5) <= "100";
					if x = '0' then
						next_state <= S2;
					else
						next_state <= S1;
					end if;
					op <= '1';
			end case;
		end process state_comp; 
		
		-- this process is for reset and state update
		state_clocking:process(clk, rst)
		begin
			if rst = '0' then
				present_state <= S0;
			elsif clk'event and clk = '1' then
				present_state <= next_state;
			end if;
		LEDG(9) <= op;
		end process state_clocking;
end arch;