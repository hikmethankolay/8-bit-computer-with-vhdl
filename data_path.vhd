-- Import necessary IEEE libraries for standard logic operations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  -- Provides std_logic and std_logic_vector data types
use IEEE.numeric_std.all;      -- Provides arithmetic operations for signed and unsigned vectors
use IEEE.std_logic_unsigned.all; -- Enables arithmetic operations on std_logic_vector

-- Define the entity `data_path`, which represents the datapath of a CPU or similar digital system
entity data_path is
    port(
        clk: in std_logic;            -- Clock signal
        rst: in std_logic;            -- Reset signal (active high)
        IR_load: in std_logic;        -- Control signal to load the Instruction Register (IR)
        MAR_load: in std_logic;       -- Control signal to load the Memory Address Register (MAR)
        PC_load: in std_logic;        -- Control signal to load the Program Counter (PC)
        PC_Inc: in std_logic;         -- Control signal to increment the Program Counter
        A_Load: in std_logic;         -- Control signal to load register A
        B_Load: in std_logic;         -- Control signal to load register B
        ALU_Sel: in std_logic_vector(2 downto 0); -- ALU operation selector
        CCR_Load: in std_logic;       -- Control signal to load the Condition Code Register (CCR)
        BUS1_Sel: in std_logic_vector(1 downto 0); -- Selector for multiplexer BUS1
        BUS2_Sel: in std_logic_vector(1 downto 0); -- Selector for multiplexer BUS2
        from_memory: in std_logic_vector(7 downto 0); -- Input data from memory

        --- Outputs
        IR: out std_logic_vector(7 downto 0);      -- Instruction Register output
        adress: out std_logic_vector(7 downto 0);  -- Address output for memory access
        CCR_Result: out std_logic_vector(3 downto 0); -- Condition Code Register output (NZVC flags)
        to_memory: out std_logic_vector(7 downto 0)  -- Data output to memory
    );
end data_path;

-- Architecture definition for the datapath
architecture arch of data_path is

    -- ALU component declaration, responsible for arithmetic and logic operations
    component ALU is
        port(
            A, B: in std_logic_vector(7 downto 0); -- ALU operands
            ALU_Sel: in std_logic_vector(2 downto 0); -- ALU operation selector
            NZVC: out std_logic_vector(3 downto 0); -- ALU output condition flags (Negative, Zero, Overflow, Carry)
            ALU_Result: out std_logic_vector(7 downto 0) -- Result of the ALU operation
        );
    end component;

    -- Internal signals (registers and buses)
    signal BUS1: std_logic_vector(7 downto 0);      -- First internal data bus
    signal BUS2: std_logic_vector(7 downto 0);      -- Second internal data bus
    signal ALU_Result: std_logic_vector(7 downto 0); -- Output of the ALU
    signal IR_Signal: std_logic_vector(7 downto 0);        -- Instruction Register
    signal MAR: std_logic_vector(7 downto 0);       -- Memory Address Register
    signal PC: std_logic_vector(7 downto 0);        -- Program Counter
    signal A_Reg: std_logic_vector(7 downto 0);     -- Register A
    signal B_Reg: std_logic_vector(7 downto 0);     -- Register B
    signal CCR_In: std_logic_vector(3 downto 0);    -- Condition Code Register (input)
    signal CCR: std_logic_vector(3 downto 0);       -- Condition Code Register (stores status flags)

begin

    -- Multiplexer for selecting the source of BUS1
    BUS1 <= PC when BUS1_Sel = "00" else   -- Selects the Program Counter (PC)
            A_Reg when BUS1_Sel = "01" else -- Selects register A
            B_Reg when BUS1_Sel = "10" else -- Selects register B
            (others => '0');               -- Default case (all zeros)

    -- Multiplexer for selecting the source of BUS2
    BUS2 <= ALU_Result when BUS2_Sel = "00" else  -- Selects ALU result
            BUS1 when BUS2_Sel = "01" else        -- Selects BUS1
            from_memory when BUS2_Sel = "10" else -- Selects data from memory
            (others => '0');                      -- Default case (all zeros)

    -- Instruction Register (IR) update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            IR_Signal <= (others => '0'); -- Reset the IR to all zeros
        elsif(rising_edge(clk)) then
            if(IR_load = '1') then
                IR_Signal <= from_memory; -- Load instruction from memory
            end if;
        end if;
    end process;
    IR <= IR_Signal; -- Output the instruction stored in IR_Signal

    -- Memory Address Register (MAR) update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            MAR <= (others => '0'); -- Reset MAR
        elsif(rising_edge(clk)) then
            if(MAR_load = '1') then
                MAR <= BUS2; -- Load MAR with the value from BUS2
            end if;
        end if;
    end process;
    adress <= MAR; -- Output the address stored in MAR

    -- Program Counter (PC) update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            PC <= (others => '0'); -- Reset PC
        elsif(rising_edge(clk)) then
            if(PC_load = '1') then
                PC <= BUS2; -- Load PC from BUS2
            elsif (PC_Inc = '1') then
                PC <= PC + x"01"; -- Increment PC by 1
            end if;
        end if;
    end process;

    -- Register A update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            A_Reg <= (others => '0'); -- Reset A register
        elsif(rising_edge(clk)) then
            if(A_Load = '1') then
                A_Reg <= BUS2; -- Load A register from BUS2
            end if;
        end if;
    end process;

    -- Register B update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            B_Reg <= (others => '0'); -- Reset B register
        elsif(rising_edge(clk)) then
            if(B_Load = '1') then
                B_Reg <= BUS2; -- Load B register from BUS2
            end if;
        end if;
    end process;

    --- ALU instantiation and connection
    ALU_U: ALU port map(
        A => B_Reg,    -- First operand from Register B
        B => BUS1,     -- Second operand from BUS1
        ALU_Sel => ALU_Sel, -- ALU operation selection signal
        NZVC => CCR_In, -- ALU status flags (Negative, Zero, Overflow, Carry)
        ALU_Result => ALU_Result -- ALU result
    );

    -- Condition Code Register (CCR) update logic
    process(clk, rst)
    begin
        if (rst = '1') then
            CCR <= (others => '0'); -- Reset CCR
        elsif(rising_edge(clk)) then
            if(CCR_Load = '1') then
                CCR <= CCR_In; -- Load CCR with ALU status flags
            end if;
        end if;
    end process;
    CCR_Result <= CCR; -- Output CCR

    -- Data output to memory
    to_memory <= BUS1; -- The value on BUS1 is sent to memory

end arch;
