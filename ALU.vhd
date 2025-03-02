library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Entity declaration for the Arithmetic Logic Unit (ALU)
entity ALU is
    port(
        A, B: in std_logic_vector(7 downto 0);  -- 8-bit input operands
        ALU_Sel: in std_logic_vector(2 downto 0); -- 3-bit control signal to select the ALU operation
        NZVC: out std_logic_vector(3 downto 0);  -- Status flags: Negative, Zero, Overflow, Carry
        ALU_Result: out std_logic_vector(7 downto 0)  -- 8-bit ALU output
    );
end ALU;

-- Architecture definition
architecture arch of ALU is

    -- Internal signals
    signal sum_unsigned: std_logic_vector(8 downto 0);  -- 9-bit signal to store sum (to check carry)
    signal alu_signal : std_logic_vector(7 downto 0);  -- ALU result before assigning to output
    signal add_overflow : std_logic;  -- Overflow flag for addition
    signal sub_overflow : std_logic;  -- Overflow flag for subtraction

begin

    -- ALU process: Implements the arithmetic and logical operations
    process(A, B, ALU_Sel)
    begin
        case ALU_Sel is
            when "000" =>  -- Addition: A + B
                alu_signal <= A + B;  -- Perform addition
                sum_unsigned <= ('0' & A) + ('0' & B);  -- Extend for carry detection
            
            when "001" =>  -- Subtraction: A - B
                alu_signal <= A - B;  -- Perform subtraction
                sum_unsigned <= ('0' & A) - ('0' & B);  -- Extend for carry detection

            when "010" =>  -- Bitwise AND: A AND B
                alu_signal <= A and B;

            when "011" =>  -- Bitwise OR: A OR B
                alu_signal <= A or B;

            when "100" =>  -- Increment A: A + 1
                alu_signal <= A + X"01";

            when "101" =>  -- Increment B: B + 1
                alu_signal <= B + X"01";

            when "110" =>  -- Decrement A: A - 1
                alu_signal <= A - X"01";

            when "111" =>  -- Decrement B: B - 1
                alu_signal <= B - X"01";

            when others =>  -- Default case: Output zero
                alu_signal <= (others => '0');
                sum_unsigned <= (others => '0');
        end case;

    end process;

    -- Assign the computed ALU result to the output
    ALU_Result <= alu_signal(7 downto 0);

    -- NZVC Flags (Negative, Zero, Overflow, Carry)

    -- Negative flag (N): Set if the result is negative (MSB is 1)
    NZVC(3) <= alu_signal(7);

    -- Zero flag (Z): Set if the result is zero
    NZVC(2) <= '1' when alu_signal = x"00" else '0';

    -- Overflow flag (V): Detects overflow in signed addition/subtraction
    add_overflow <= (not(A(7) and not (B(7)) and not alu_signal(7)) or (A(7) and B(7) and not (alu_signal(7))));
    sub_overflow <= (not(A(7)) and B(7) and alu_signal(7)) or (A(7) and not (B(7)) and not (alu_signal(7)));

    -- Set overflow flag based on operation
    NZVC(1) <= add_overflow when (ALU_Sel = "000") else  -- Overflow in addition
               sub_overflow when (ALU_Sel = "001") else  -- Overflow in subtraction
               '0';  -- No overflow for other operations

    -- Carry flag (C): Set if there is a carry in addition/subtraction
    NZVC(0) <= sum_unsigned(8) when (ALU_Sel = "000" or ALU_Sel = "001") else '0';

end arch;
