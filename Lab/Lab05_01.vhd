LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY Lab05_01 IS
	PORT(
		SW: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		LEDG: OUT STD_LOGIC_VECTOR(9 DOWNTO 9);
		HEX1, HEX0: OUT STD_LOGIC_VECTOR(0 TO 6);
		KEY: IN STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
	
END LAb05_01;

ARCHITECTURE Behavior OF Lab05_01 IS
	-- Use component to invoke bcd7seg
	COMPONENT bcd7seg
		PORT(
			bcd: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			display: OUT STD_LOGIC_VECTOR(0 TO 6)
		);
	END COMPONENT;
	-- declare the SIGNAL                            
	SIGNAL A, B, F: INTEGER;
	SIGNAL H1, H0: STD_LOGIC_VECTOR(3 DOWNTO 0);
	-- Convert binary to integer
	BEGIN
		A <= to_integer(signed(SW(7 DOWNTO 4)));
		B <= to_integer(signed(SW(3 DOWNTO 0)));
		PROCESS (A, B, KEY)
		BEGIN
			CASE KEY IS
				WHEN "111" =>
					LEDG(9) <= '0';
					-- Use OTHERS to CANCEL the display of 7Seg
					H1 <= "1111";
					H0 <= "1111";
				WHEN "110" =>
					F <= A + B;
					IF (F < 0) THEN
						LEDG(9) <= '1';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					ELSE
						LEDG(9) <= '0';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					END IF;
				WHEN "101" =>
					F <= A - B;
					IF (F < 0) THEN
						LEDG(9) <= '1';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					ELSE
						LEDG(9) <= '0';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					END IF;
				WHEN "011" =>
					F <= A * B;
					IF (F < 0) THEN
						LEDG(9) <= '1';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					ELSE
						LEDG(9) <= '0';
						-- Convert back to signed
						H1 <= std_LOGIC_VECTOR(to_signed(abs(F)/10, H1'length));
						H0 <= std_LOGIC_VECTOR(to_signed(abs(F) rem 10, H0'length));
					END IF;
				WHEN OTHERS =>
					-- if more than 1 key been pressed, don't display
					LEDG(9) <= '0';
					-- Use OTHERS to CANCEL the display of 7Seg
					H1 <= "1111";
					H0 <= "1111";
			END CASE;
		END PROCESS;
		-- declare the display
		digit1: bcd7seg PORT MAP (H1, HEX1);
		digit0: bcd7seg PORT MAP (H0, HEX0);
END behavior;