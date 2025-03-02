library IEEE;
use IEEE.STD_LOGIC_1164.ALL;         -- Standard logic package
use IEEE.numeric_std.all;            -- Provides numeric operations on std_logic_vector types
use IEEE.std_logic_unsigned.all;     -- Allows arithmetic operations on std_logic_vector

--------------------------------------------------------------------------------
-- Entity Declaration: control_unit
-- This entity defines the input and output ports used by the control unit.
--------------------------------------------------------------------------------
entity control_unit is
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
        write_en : out std_logic      -- Write enable signal for memory operations
    );
end control_unit;

--------------------------------------------------------------------------------
-- Architecture Declaration: arch
-- Implements the FSM with states for instruction fetch, decode, and execute.
--------------------------------------------------------------------------------
architecture arch of control_unit is

    ----------------------------------------------------------------------------
    -- Define the state type for the finite state machine (FSM)
    -- The states include the fetch cycle, decode phase, and various execution 
    -- states for different instructions.
    ----------------------------------------------------------------------------
    type state_type is (
        S_FETHCH_0,    -- Initial fetch state: load memory address to MAR
        S_FETHCH_1,    -- Increment the PC during fetch
        S_FETHCH_2,    -- Load the instruction from memory into IR
        S_DECODE_3,    -- Decode the fetched instruction

        -- Load A Immediate instruction states
        S_LDA_IMM_4,   -- Set up for LDA_IMM: prepare addressing
        S_LDA_IMM_5,   -- Increment PC after addressing immediate data
        S_LDA_IMM_6,   -- Load the immediate value into register A

        -- Load A Direct instruction states
        S_LDA_DIR_4,   -- Set up for LDA_DIR: load effective address into MAR
        S_LDA_DIR_5,   -- Increment PC for direct addressing
        S_LDA_DIR_6,   -- Read effective address from memory
        S_LDA_DIR_7,   -- Wait state: waiting for memory read to complete
        S_LDA_DIR_8,   -- Load the data from memory into register A

        -- Load A Immediate instruction states
        S_LDB_IMM_4,   -- Set up for LDB_IMM: prepare addressing
        S_LDB_IMM_5,   -- Increment PC after addressing immediate data
        S_LDB_IMM_6,   -- Load the immediate value into register B

        -- Load A Direct instruction states
        S_LDB_DIR_4,   -- Set up for LDB_DIR: load effective address into MAR
        S_LDB_DIR_5,   -- Increment PC for direct addressing
        S_LDB_DIR_6,   -- Read effective address from memory
        S_LDB_DIR_7,   -- Wait state: waiting for memory read to complete
        S_LDB_DIR_8,   -- Load the data from memory into register B

        -- Store A Direct instruction states
        S_STA_DIR_4,   -- Set up for STA_DIR: load address into MAR
        S_STA_DIR_5,   -- Increment PC after addressing
        S_STA_DIR_6,   -- Read effective address from memory
        S_STA_DIR_7,   -- Write the data from register A to memory
        
        -- Data Manipulation Instruction state
        S_ADD_AB_4,    -- Execute addition: add register A and B

        -- Branch instructions states (unconditional and conditional)
        S_BRA_4,       -- Set up for BRA: load branch address into MAR
        S_BRA_5,       -- Wait state: waiting for memory read (branch target)
        S_BRA_6,       -- Load branch address into PC

        S_BEQ_4,       -- Set up for BEQ: if branch condition met, prepare branch address
        S_BEQ_5,       -- Wait state: waiting for memory read (branch target)
        S_BEQ_6,       -- Load branch address into PC if condition true
        S_BEQ_7        -- Increment PC if condition is false (do not branch)
    );

    ----------------------------------------------------------------------------
    -- Signal Declarations
    -- current_state: holds the present state of the FSM.
    -- next_state: determines the next state of the FSM based on inputs.
    ----------------------------------------------------------------------------
    signal current_state, next_state : state_type;

    ----------------------------------------------------------------------------
    -- Constant Definitions for Instruction Codes
    -- These constants represent the opcodes for various instructions.
    ----------------------------------------------------------------------------
    -- Load and Store Instructions
    constant LDA_IMM : std_logic_vector(7 downto 0) := x"86";  -- Load A Immediate
    constant LDA_DIR : std_logic_vector(7 downto 0) := x"87";  -- Load A Direct
    constant LDB_IMM : std_logic_vector(7 downto 0) := x"88";  -- Load B Immediate
    constant LDB_DIR : std_logic_vector(7 downto 0) := x"89";  -- Load B Direct
    constant STA_DIR : std_logic_vector(7 downto 0) := x"96";  -- Store A Direct
    constant STB_DIR : std_logic_vector(7 downto 0) := x"97";  -- Store B Direct

    -- Data Manipulation Instructions
    constant ADD_AB : std_logic_vector(7 downto 0) := x"42";  -- Add A + B
    constant SUB_AB : std_logic_vector(7 downto 0) := x"43";  -- Subtract A - B
    constant AND_AB : std_logic_vector(7 downto 0) := x"44";  -- Bitwise AND A & B
    constant OR_AB  : std_logic_vector(7 downto 0) := x"45";  -- Bitwise OR A | B
    constant INC_A  : std_logic_vector(7 downto 0) := x"46";  -- Increment A
    constant INC_B  : std_logic_vector(7 downto 0) := x"47";  -- Increment B
    constant DEC_A  : std_logic_vector(7 downto 0) := x"48";  -- Decrement A
    constant DEC_B  : std_logic_vector(7 downto 0) := x"49";  -- Decrement B

    -- Branch Instructions (Conditional Jumps)
    constant BRA  : std_logic_vector(7 downto 0) := x"20";  -- Unconditional Branch
    constant BMI  : std_logic_vector(7 downto 0) := x"21";  -- Branch if Negative
    constant BPL  : std_logic_vector(7 downto 0) := x"22";  -- Branch if Positive
    constant BEQ  : std_logic_vector(7 downto 0) := x"23";  -- Branch if Equal
    constant BNE  : std_logic_vector(7 downto 0) := x"24";  -- Branch if Not Equal
    constant BVS  : std_logic_vector(7 downto 0) := x"25";  -- Branch if Overflow Set
    constant BVC  : std_logic_vector(7 downto 0) := x"26";  -- Branch if Overflow Clear
    constant BCS  : std_logic_vector(7 downto 0) := x"27";  -- Branch if Carry Set
    constant BCC  : std_logic_vector(7 downto 0) := x"28";  -- Branch if Carry Clear

begin

    ----------------------------------------------------------------------------
    -- Process: Current State Logic
    -- This process updates the current state of the FSM on each rising clock edge.
    -- If reset (rst) is asserted, the FSM is returned to the initial fetch state.
    ----------------------------------------------------------------------------
    process(clk, rst)
    begin
        if (rst = '1') then
            current_state <= S_FETHCH_0;  -- Reset state: restart fetch cycle
        elsif rising_edge(clk) then
            current_state <= next_state;  -- Move to the next state on clock edge
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Process: Next State Logic
    -- Determines the next state of the FSM based on the current state, the
    -- instruction (IR), and the condition code register result (CCR_Result).
    ----------------------------------------------------------------------------
    process(current_state, IR, CCR_Result)
    begin
        case current_state is
            when S_FETHCH_0 =>
                next_state <= S_FETHCH_1;  -- After setting MAR, go to PC increment

            when S_FETHCH_1 =>
                next_state <= S_FETHCH_2;  -- After PC increment, load instruction

            when S_FETHCH_2 =>
                next_state <= S_DECODE_3;  -- After loading instruction, decode it

            when S_DECODE_3 =>
                -- Determine next state based on the opcode in the instruction register
                if IR = LDA_IMM then
                    next_state <= S_LDA_IMM_4;  -- Begin immediate load of register A
                elsif IR = LDA_DIR then
                    next_state <= S_LDA_DIR_4;  -- Begin direct load of register A
                elsif IR = LDA_DIR then
                    next_state <= S_LDB_IMM_4;  -- Begin immediate load of register A
                elsif IR = LDA_DIR then
                    next_state <= S_LDB_DIR_4;  -- Begin direct load of register B
                elsif IR = STA_DIR then
                    next_state <= S_STA_DIR_4;  -- Begin direct store of register A
                elsif IR = ADD_AB then
                    next_state <= S_ADD_AB_4;   -- Begin addition of register A and B
                elsif IR = BRA then
                    next_state <= S_BRA_4;      -- Begin unconditional branch
                elsif IR = BEQ then
                    -- For branch if equal, check the condition flag (CCR_Result(2))
                    if CCR_Result(2) = '1' then
                        next_state <= S_BEQ_4;  -- Condition met: branch to target
                    else
                        next_state <= S_BEQ_7;  -- Condition not met: continue sequentially
                    end if;
                else
                    next_state <= S_FETHCH_0;   -- Default: return to fetch cycle
                end if;

            --------------------------------------------------------------------
            -- States for LDA_IMM (Load A Immediate)
            --------------------------------------------------------------------
            when S_LDA_IMM_4 =>
                next_state <= S_LDA_IMM_5;      -- Move to next stage (PC increment)

            when S_LDA_IMM_5 =>
                next_state <= S_LDA_IMM_6;      -- Next, prepare to load immediate data into A

            when S_LDA_IMM_6 =>
                next_state <= S_FETHCH_0;       -- After execution, return to fetch cycle

            --------------------------------------------------------------------
            -- States for LDA_DIR (Load A Direct)
            --------------------------------------------------------------------
            when S_LDA_DIR_4 =>
                next_state <= S_LDA_DIR_5;      -- Set up direct addressing

            when S_LDA_DIR_5 =>
                next_state <= S_LDA_DIR_6;      -- Increment PC after addressing

            when S_LDA_DIR_6 =>
                next_state <= S_LDA_DIR_7;      -- Prepare to read effective address

            when S_LDA_DIR_7 =>
                next_state <= S_LDA_DIR_8;      -- Wait state for memory read completion

            when S_LDA_DIR_8 =>
                next_state <= S_FETHCH_0;       -- After loading data into A, return to fetch cycle


            --------------------------------------------------------------------
            -- States for LDB_IMM (Load B Immediate)
            --------------------------------------------------------------------
            when S_LDB_IMM_4 =>
                next_state <= S_LDB_IMM_5;      -- Move to next stage (PC increment)

            when S_LDB_IMM_5 =>
                next_state <= S_LDB_IMM_6;      -- Next, prepare to load immediate data into B

            when S_LDB_IMM_6 =>
                next_state <= S_FETHCH_0;       -- After execution, return to fetch cycle

            --------------------------------------------------------------------
            -- States for LDB_DIR (Load B Direct)
            --------------------------------------------------------------------
            when S_LDB_DIR_4 =>
                next_state <= S_LDB_DIR_5;      -- Set up direct addressing

            when S_LDB_DIR_5 =>
                next_state <= S_LDB_DIR_6;      -- Increment PC after addressing

            when S_LDB_DIR_6 =>
                next_state <= S_LDB_DIR_7;      -- Prepare to read effective address

            when S_LDB_DIR_7 =>
                next_state <= S_LDB_DIR_8;      -- Wait state for memory read completion

            when S_LDB_DIR_8 =>
                next_state <= S_FETHCH_0;       -- After loading data into B, return to fetch cycle

            --------------------------------------------------------------------
            -- States for STA_DIR (Store A Direct)
            --------------------------------------------------------------------
            when S_STA_DIR_4 =>
                next_state <= S_STA_DIR_5;      -- Set up for storing A: load effective address

            when S_STA_DIR_5 =>
                next_state <= S_STA_DIR_6;      -- Increment PC after addressing

            when S_STA_DIR_6 =>
                next_state <= S_STA_DIR_7;      -- Prepare to write data to memory

            when S_STA_DIR_7 =>
                next_state <= S_FETHCH_0;       -- After store operation, return to fetch cycle

            --------------------------------------------------------------------
            -- State for ADD_AB (Addition of A and B)
            --------------------------------------------------------------------
            when S_ADD_AB_4 =>
                next_state <= S_FETHCH_0;       -- After addition, return to fetch cycle

            --------------------------------------------------------------------
            -- States for BRA (Unconditional Branch)
            --------------------------------------------------------------------
            when S_BRA_4 =>
                next_state <= S_BRA_5;          -- Set up branch address

            when S_BRA_5 =>
                next_state <= S_BRA_6;          -- Wait for memory read (branch target address)

            when S_BRA_6 =>
                next_state <= S_FETHCH_0;       -- After branching, return to fetch cycle

            --------------------------------------------------------------------
            -- States for BEQ (Branch if Equal)
            --------------------------------------------------------------------
            when S_BEQ_4 =>
                next_state <= S_BEQ_5;          -- Set up branch address when condition is true

            when S_BEQ_5 =>
                next_state <= S_BEQ_6;          -- Wait state for memory read

            when S_BEQ_6 =>
                next_state <= S_BEQ_7;          -- Load branch target address into PC

            when S_BEQ_7 =>
                next_state <= S_FETHCH_0;       -- If condition false, simply increment PC and fetch next instruction

            when others =>
                next_state <= S_FETHCH_0;       -- Default state: return to fetch cycle
        end case;
    end process;

    ----------------------------------------------------------------------------
    -- Process: Output Logic
    -- This process generates the control signals for the processor based on the
    -- current state of the FSM. Default values are set at the beginning of the process.
    ----------------------------------------------------------------------------
    process(current_state)
    begin
        -- Initialize all control signals to their default inactive states
        IR_load   <= '0';
        MAR_load  <= '0';
        PC_load   <= '0';
        PC_Inc    <= '0';
        A_Load    <= '0';
        B_Load    <= '0';
        ALU_Sel   <= (others => '0');
        CCR_Load  <= '0';
        BUS1_Sel  <= (others => '0');
        BUS2_Sel  <= (others => '0');
        write_en  <= '0';

        ----------------------------------------------------------------------------
        -- Output signal assignments based on the current state of the FSM
        ----------------------------------------------------------------------------
        case current_state is
            ----------------------------------------------------------------------------
            -- Fetch Cycle States
            ----------------------------------------------------------------------------
            when S_FETHCH_0 =>
                -- Set up the memory address bus and load MAR with the address from BUS2
                BUS1_Sel <= "00";     -- Select source for BUS1 
                BUS2_Sel <= "01";     -- Select source for BUS2
                MAR_load <= '1';      -- Enable loading of MAR with the address

            when S_FETHCH_1 =>
                PC_Inc <= '1';        -- Increment the Program Counter

            when S_FETHCH_2 =>
                BUS2_Sel <= "10";     -- Select data from memory
                IR_load  <= '1';      -- Load the fetched instruction into the IR

            when S_DECODE_3 =>
                -- No direct output signal is generated here; the next state logic handles decoding

            ----------------------------------------------------------------------------
            -- LDA_IMM (Load A Immediate) States
            ----------------------------------------------------------------------------
            when S_LDA_IMM_4 =>
                -- Prepare to load immediate data: set up MAR with address for immediate data
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDA_IMM_5 =>
                PC_Inc <= '1';        -- Increment PC to point to the immediate data

            when S_LDA_IMM_6 =>
                BUS2_Sel <= "10";     -- Select immediate data from memory
                A_Load   <= '1';      -- Load immediate data into register A

            ----------------------------------------------------------------------------
            -- LDA_DIR (Load A Direct) States
            ----------------------------------------------------------------------------
            when S_LDA_DIR_4 =>
                -- Prepare for direct addressing: load effective address into MAR
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDA_DIR_5 =>
                PC_Inc <= '1';        -- Increment PC to move to the next part of the address

            when S_LDA_DIR_6 =>
                BUS2_Sel <= "10";     -- Select the second part of the effective address
                MAR_load <= '1';      -- Load the complete effective address into MAR

            when S_LDA_DIR_7 =>
                -- Wait state: waiting for the memory to output the data at the effective address

            when S_LDA_DIR_8 =>
                -- After memory read, load the data from memory into register A.
                BUS2_Sel <= "10";     -- Select the data from memory
                A_Load   <= '1';      -- Load the data into register A

            ----------------------------------------------------------------------------
            -- LDA_IMM (Load A Immediate) States
            ----------------------------------------------------------------------------
            when S_LDB_IMM_4 =>
                -- Prepare to load immediate data: set up MAR with address for immediate data
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDB_IMM_5 =>
                PC_Inc <= '1';        -- Increment PC to point to the immediate data

            when S_LDB_IMM_6 =>
                BUS2_Sel <= "10";     -- Select immediate data from memory
                A_Load   <= '1';      -- Load immediate data into register B

            ----------------------------------------------------------------------------
            -- LDA_DIR (Load A Direct) States
            ----------------------------------------------------------------------------
            when S_LDB_DIR_4 =>
                -- Prepare for direct addressing: load effective address into MAR
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDB_DIR_5 =>
                PC_Inc <= '1';        -- Increment PC to move to the next part of the address

            when S_LDB_DIR_6 =>
                BUS2_Sel <= "10";     -- Select the second part of the effective address
                MAR_load <= '1';      -- Load the complete effective address into MAR

            when S_LDB_DIR_7 =>
                -- Wait state: waiting for the memory to output the data at the effective address

            when S_LDB_DIR_8 =>
                -- After memory read, load the data from memory into register B.
                BUS2_Sel <= "10";     -- Select the data from memory
                B_Load   <= '1';      -- Load the data into register B

            ----------------------------------------------------------------------------
            -- STA_DIR (Store A Direct) States
            ----------------------------------------------------------------------------
            when S_STA_DIR_4 =>
                -- Set up for storing data: load the target memory address into MAR
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_STA_DIR_5 =>
                PC_Inc <= '1';        -- Increment PC after fetching the address

            when S_STA_DIR_6 =>
                BUS2_Sel <= "10";     -- Select the address part from memory
                MAR_load <= '1';      -- Update MAR with the effective address

            when S_STA_DIR_7 =>
                BUS1_Sel <= "01";     -- Select register A data to be sent to memory
                write_en <= '1';      -- Enable memory write operation

            ----------------------------------------------------------------------------
            -- ADD_AB (Addition of A and B) State
            ----------------------------------------------------------------------------
            when S_ADD_AB_4 =>
                BUS1_Sel <= "01";     -- Select register A as one operand
                BUS2_Sel <= "00";     -- Select register B as the other operand
                ALU_Sel  <= "000";     -- Configure the ALU for addition operation
                A_Load   <= '1';      -- Load the ALU result back into register A
                CCR_Load <= '1';      -- Update the condition code register based on the result

            ----------------------------------------------------------------------------
            -- BRA (Unconditional Branch) States
            ----------------------------------------------------------------------------
            when S_BRA_4 =>
                -- Set up branch address: load the branch target address into MAR
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BRA_5 =>
                -- Wait state: waiting for the branch target address to be read from memory

            when S_BRA_6 =>
                BUS2_Sel <= "10";     -- Select branch target address from memory
                PC_load  <= '1';      -- Load the branch target address into the PC

            ----------------------------------------------------------------------------
            -- BEQ (Branch if Equal) States
            ----------------------------------------------------------------------------
            when S_BEQ_4 =>
                -- Set up branch address for BEQ if condition is met
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BEQ_5 =>
                -- Wait state: waiting for memory to provide branch target address

            when S_BEQ_6 =>
                BUS2_Sel <= "10";     -- Select branch target address from memory
                PC_load  <= '1';      -- Load the branch target address into the PC

            when S_BEQ_7 =>
                PC_Inc <= '1';        -- If branch condition not met, simply increment PC

            ----------------------------------------------------------------------------
            -- Default Case
            ----------------------------------------------------------------------------
            when others =>
                -- Ensure all control signals remain inactive for undefined states
                IR_load   <= '0';
                MAR_load  <= '0';
                PC_load   <= '0';
                PC_Inc    <= '0';
                A_Load    <= '0';
                B_Load    <= '0';
                ALU_Sel   <= (others => '0');
                CCR_Load  <= '0';
                BUS1_Sel  <= (others => '0');
                BUS2_Sel  <= (others => '0');
                write_en  <= '0';
        end case;
    end process;

end arch;
