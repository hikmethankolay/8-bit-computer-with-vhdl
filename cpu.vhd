library IEEE;
use IEEE.STD_LOGIC_1164.ALL;         -- Standard logic package
use IEEE.numeric_std.all;            -- Provides numeric operations on std_logic_vector types
use IEEE.std_logic_unsigned.all;     -- Allows arithmetic operations on std_logic_vector

entity CPU is
    port(
        clk: in std_logic;            -- Clock signal
        rst: in std_logic;            -- Reset signal
        from_memory: in std_logic_vector(7 downto 0); -- Input data from memory
        to_memory: out std_logic_vector(7 downto 0);  -- Data output to memory
        write_en: out std_logic;   -- Write enable signal for memory
        address: out std_logic_vector(7 downto 0) -- Address output for memory access
    );

end CPU;


architecture arch of CPU is

    component control_unit is
        port(
            clk: in std_logic;         -- Clock signal for synchronous operation
            rst: in std_logic;         -- Asynchronous reset signal (active high)
            IR: in std_logic_vector(7 downto 0);       -- Instruction Register (holds the current instruction)
            CCR_Result: in std_logic_vector(3 downto 0); -- Condition Code Register result for branch conditions
    
            --- Output signals used to control other parts of the processor
            IR_load: out std_logic;        -- Signal to load the Instruction Register (IR)
            MAR_load: out std_logic;       -- Signal to load the Memory Address Register (MAR)
            PC_load: out std_logic;        -- Signal to load the Program Counter (PC)
            PC_Inc: out std_logic;         -- Signal to increment the Program Counter
            A_Load: out std_logic;         -- Signal to load data into register A
            B_Load: out std_logic;         -- Signal to load data into register B
            ALU_Sel: out std_logic_vector(2 downto 0); -- Selector for ALU operations
            CCR_Load: out std_logic;       -- Signal to load the Condition Code Register (CCR)
            BUS1_Sel: out std_logic_vector(1 downto 0); -- Multiplexer selector for BUS1
            BUS2_Sel: out std_logic_vector(1 downto 0); -- Multiplexer selector for BUS2
            write_en : out std_logic;      -- Write enable signal for memory operations
        );
    end component;

    component data_path is
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
    end component;


signal IR_load:  std_logic;        -- Control signal to load the Instruction Register (IR)
signal IR:  std_logic_vector(7 downto 0);      -- Instruction Register output
signal MAR_load:  std_logic;       -- Control signal to load the Memory Address Register (MAR)
signal PC_load:  std_logic;        -- Control signal to load the Program Counter (PC)
signal PC_Inc:  std_logic;         -- Control signal to increment the Program Counter
signal A_Load:  std_logic;         -- Control signal to load register A
signal B_Load:  std_logic;         -- Control signal to load register B
signal ALU_Sel:  std_logic_vector(2 downto 0); -- ALU operation selector
signal CCR_Load:  std_logic;       -- Control signal to load the Condition Code Register (CCR)
signal CCR_Result:  std_logic_vector(3 downto 0); -- Condition Code Register output (NZVC flags)
signal BUS1_Sel:  std_logic_vector(1 downto 0); -- Selector for multiplexer BUS1
signal BUS2_Sel:  std_logic_vector(1 downto 0); -- Selector for multiplexer BUS2


begin


    control_unit_port_map: control_unit port map(
        clk => clk,
        rst => rst,
        IR => IR,
        CCR_Result => CCR_Result,
        IR_load => IR_load,
        MAR_load => MAR_load,
        PC_load => PC_load,
        PC_Inc => PC_Inc,
        A_Load => A_Load,
        B_Load => B_Load,
        ALU_Sel => ALU_Sel,
        CCR_Load => CCR_Load,
        BUS1_Sel => BUS1_Sel,
        BUS2_Sel => BUS2_Sel,
        write_en => write_en
    );

    data_path_port_map: data_path port map(
        clk => clk,
        rst => rst,
        IR_load => IR_load,
        MAR_load => MAR_load,
        PC_load => PC_load,
        PC_Inc => PC_Inc,
        A_Load => A_Load,
        B_Load => B_Load,
        ALU_Sel => ALU_Sel,
        CCR_Load => CCR_Load,
        BUS1_Sel => BUS1_Sel,
        BUS2_Sel => BUS2_Sel,
        from_memory => from_memory,
        IR => IR,
        adress => address,
        CCR_Result => CCR_Result,
        to_memory => to_memory
    );


end architecture;