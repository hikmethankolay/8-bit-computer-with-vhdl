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

    ------------------------------------------------------------------------------
-- Define the state type for the finite state machine (FSM)
-- The states include the fetch cycle, decode phase, and various execution 
-- states for different instructions.
------------------------------------------------------------------------------
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

    -- Load B Immediate instruction states
    S_LDB_IMM_4,   -- Set up for LDB_IMM: prepare addressing
    S_LDB_IMM_5,   -- Increment PC after addressing immediate data
    S_LDB_IMM_6,   -- Load the immediate value into register B

    -- Load B Direct instruction states
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

    -- Store B Direct instruction states (Missing, added)
    S_STB_DIR_4,   -- Set up for STB_DIR: load address into MAR
    S_STB_DIR_5,   -- Increment PC after addressing
    S_STB_DIR_6,   -- Read effective address from memory
    S_STB_DIR_7,   -- Write the data from register B to memory

    -- Data Manipulation Instruction states
    S_ADD_AB_4,    -- Execute addition: add register A and B
    S_SUB_AB_4,    -- Execute subtraction: subtract register B from A
    S_AND_AB_4,    -- Execute bitwise AND: A and B
    S_OR_AB_4,     -- Execute bitwise OR: A or B
    S_INC_A_4,     -- Execute increment: increase register A
    S_INC_B_4,     -- Execute increment: increase register B
    S_DEC_A_4,     -- Execute decrement: decrease register A
    S_DEC_B_4,     -- Execute decrement: decrease register B

    -- Branch instructions states
    S_BRA_4,       -- Set up for BRA: load branch address into MAR (Unconditional)
    S_BRA_5,       -- Wait state: waiting for memory read (branch target)
    S_BRA_6,       -- Load branch address into PC

    S_BEQ_4,       -- Set up for BEQ: if branch condition met, prepare branch address
    S_BEQ_5,       -- Wait state: waiting for memory read (branch target)
    S_BEQ_6,       -- Load branch address into PC if condition true
    S_BEQ_7,       -- Increment PC if condition is false (do not branch)

    -- Branch if Negative (BMI) instruction states
    S_BMI_4,    -- Set up for BMI: load branch address into MAR if negative condition met
    S_BMI_5,    -- Wait state: waiting for memory read (branch target for BMI)
    S_BMI_6,    -- Load branch address into PC if negative condition is met
    S_BMI_7,    -- Increment PC if negative condition not met

    -- Branch if Positive (BPL) instruction states
    S_BPL_4,    -- Set up for BPL: load branch address into MAR if positive condition met
    S_BPL_5,    -- Wait state: waiting for memory read (branch target for BPL)
    S_BPL_6,    -- Load branch address into PC if positive condition is met
    S_BPL_7,    -- Increment PC if positive condition not met

    -- Branch if Not Equal (BNE) instruction states
    S_BNE_4,    -- Set up for BNE: load branch address into MAR if not equal condition met
    S_BNE_5,    -- Wait state: waiting for memory read (branch target for BNE)
    S_BNE_6,    -- Load branch address into PC if not equal condition is met
    S_BNE_7,    -- Increment PC if not equal condition not met

    -- Branch if Overflow Set (BVS) instruction states
    S_BVS_4,    -- Set up for BVS: load branch address into MAR if overflow set condition met
    S_BVS_5,    -- Wait state: waiting for memory read (branch target for BVS)
    S_BVS_6,    -- Load branch address into PC if overflow set condition is met
    S_BVS_7,    -- Increment PC if overflow set condition not met

    -- Branch if Overflow Clear (BVC) instruction states
    S_BVC_4,    -- Set up for BVC: load branch address into MAR if overflow clear condition met
    S_BVC_5,    -- Wait state: waiting for memory read (branch target for BVC)
    S_BVC_6,    -- Load branch address into PC if overflow clear condition is met
    S_BVC_7,    -- Increment PC if overflow clear condition not met

    -- Branch if Carry Set (BCS) instruction states
    S_BCS_4,    -- Set up for BCS: load branch address into MAR if carry set condition met
    S_BCS_5,    -- Wait state: waiting for memory read (branch target for BCS)
    S_BCS_6,    -- Load branch address into PC if carry set condition is met
    S_BCS_7,    -- Increment PC if carry set condition not met

    -- Branch if Carry Clear (BCC) instruction states
    S_BCC_4,    -- Set up for BCC: load branch address into MAR if carry clear condition met
    S_BCC_5,    -- Wait state: waiting for memory read (branch target for BCC)
    S_BCC_6,    -- Load branch address into PC if carry clear condition is met
    S_BCC_7     -- Increment PC if carry clear condition not met
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

    ------------------------------------------------------------------------------
    -- Process: Next State Logic
    -- Determines the next state of the FSM based on the current state, the
    -- instruction (IR), and the condition code register result (CCR_Result).
    ------------------------------------------------------------------------------
    process(current_state, IR, CCR_Result)
    begin
        case current_state is
            --------------------------------------------------------------------
            -- Fetch Cycle States
            --------------------------------------------------------------------
            when S_FETHCH_0 =>
                next_state <= S_FETHCH_1;  -- After setting MAR, go to PC increment

            when S_FETHCH_1 =>
                next_state <= S_FETHCH_2;  -- After PC increment, load instruction

            when S_FETHCH_2 =>
                next_state <= S_DECODE_3;  -- After loading instruction, decode it

            --------------------------------------------------------------------
            -- Decode State: Determine next state based on the opcode in IR
            --------------------------------------------------------------------
            when S_DECODE_3 =>
                if IR = LDA_IMM then
                    next_state <= S_LDA_IMM_4;  -- Begin immediate load of register A
                elsif IR = LDA_DIR then
                    next_state <= S_LDA_DIR_4;  -- Begin direct load of register A
                elsif IR = LDB_IMM then
                    next_state <= S_LDB_IMM_4;  -- Begin immediate load of register B
                elsif IR = LDB_DIR then
                    next_state <= S_LDB_DIR_4;  -- Begin direct load of register B
                elsif IR = STA_DIR then
                    next_state <= S_STA_DIR_4;  -- Begin direct store of register A
                elsif IR = STB_DIR then
                    next_state <= S_STB_DIR_4;  -- Begin direct store of register B
                elsif IR = ADD_AB then
                    next_state <= S_ADD_AB_4;   -- Begin addition of A and B
                elsif IR = SUB_AB then
                    next_state <= S_SUB_AB_4;   -- Begin subtraction (A - B)
                elsif IR = AND_AB then
                    next_state <= S_AND_AB_4;   -- Begin bitwise AND of A and B
                elsif IR = OR_AB then
                    next_state <= S_OR_AB_4;    -- Begin bitwise OR of A and B
                elsif IR = INC_A then
                    next_state <= S_INC_A_4;    -- Begin incrementing A
                elsif IR = INC_B then
                    next_state <= S_INC_B_4;    -- Begin incrementing B
                elsif IR = DEC_A then
                    next_state <= S_DEC_A_4;    -- Begin decrementing A
                elsif IR = DEC_B then
                    next_state <= S_DEC_B_4;    -- Begin decrementing B
                elsif IR = BRA then
                    next_state <= S_BRA_4;      -- Begin unconditional branch
                elsif IR = BMI then
                    if CCR_Result(3) = '1' then
                        next_state <= S_BMI_4;  -- Negative flag set: branch to target
                    else
                        next_state <= S_BMI_7;  -- Negative flag not set: condition not met, continue sequentially
                    end if;
                elsif IR = BPL then
                    if CCR_Result(3) = '0' then
                        next_state <= S_BPL_4;  -- Negative flag clear: branch to target
                    else
                        next_state <= S_BPL_7;  -- Negative flag set: condition not met, continue sequentially
                    end if;
                elsif IR = BEQ then
                    if CCR_Result(2) = '1' then
                        next_state <= S_BEQ_4;  -- Zero flag set: condition met, branch to target
                    else
                        next_state <= S_BEQ_7;  -- Zero flag not set: condition not met, continue sequentially
                    end if;
                elsif IR = BNE then
                    if CCR_Result(2) = '0' then
                        next_state <= S_BNE_4;  -- Zero flag clear: condition met, branch to target
                    else
                        next_state <= S_BNE_7;  -- Zero flag set: condition not met, continue sequentially
                    end if;
                elsif IR = BVS then
                    if CCR_Result(1) = '1' then
                        next_state <= S_BVS_4;  -- Overflow flag set: condition met, branch to target
                    else
                        next_state <= S_BVS_7;  -- Overflow flag not set: condition not met, continue sequentially
                    end if;
                elsif IR = BVC then
                    if CCR_Result(1) = '0' then
                        next_state <= S_BVC_4;  -- Overflow flag clear: condition met, branch to target
                    else
                        next_state <= S_BVC_7;  -- Overflow flag set: condition not met, continue sequentially
                    end if;
                elsif IR = BCS then
                    if CCR_Result(0) = '1' then
                        next_state <= S_BCS_4;  -- Carry flag set: condition met, branch to target
                    else
                        next_state <= S_BCS_7;  -- Carry flag not set: condition not met, continue sequentially
                    end if;
                elsif IR = BCC then
                    if CCR_Result(0) = '0' then
                        next_state <= S_BCC_4;  -- Carry flag clear: condition met, branch to target
                    else
                        next_state <= S_BCC_7;  -- Carry flag set: condition not met, continue sequentially
                    end if;    
                else
                    next_state <= S_FETHCH_0;   -- Default: return to fetch cycle
                end if;

            --------------------------------------------------------------------
            -- States for LDA_IMM (Load A Immediate)
            --------------------------------------------------------------------
            when S_LDA_IMM_4 =>
                next_state <= S_LDA_IMM_5;      -- Move to PC increment
            when S_LDA_IMM_5 =>
                next_state <= S_LDA_IMM_6;      -- Load immediate data into A
            when S_LDA_IMM_6 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

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
                next_state <= S_LDA_DIR_8;      -- Wait for memory read completion
            when S_LDA_DIR_8 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for LDB_IMM (Load B Immediate)
            --------------------------------------------------------------------
            when S_LDB_IMM_4 =>
                next_state <= S_LDB_IMM_5;      -- Move to PC increment
            when S_LDB_IMM_5 =>
                next_state <= S_LDB_IMM_6;      -- Load immediate data into B
            when S_LDB_IMM_6 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

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
                next_state <= S_LDB_DIR_8;      -- Wait for memory read completion
            when S_LDB_DIR_8 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for STA_DIR (Store A Direct)
            --------------------------------------------------------------------
            when S_STA_DIR_4 =>
                next_state <= S_STA_DIR_5;      -- Load effective address into MAR
            when S_STA_DIR_5 =>
                next_state <= S_STA_DIR_6;      -- Increment PC after addressing
            when S_STA_DIR_6 =>
                next_state <= S_STA_DIR_7;      -- Write data from register A to memory
            when S_STA_DIR_7 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for STB_DIR (Store B Direct)
            --------------------------------------------------------------------
            when S_STB_DIR_4 =>
                next_state <= S_STB_DIR_5;      -- Load effective address into MAR
            when S_STB_DIR_5 =>
                next_state <= S_STB_DIR_6;      -- Increment PC after addressing
            when S_STB_DIR_6 =>
                next_state <= S_STB_DIR_7;      -- Write data from register B to memory
            when S_STB_DIR_7 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for ADD_AB (Addition of A and B)
            --------------------------------------------------------------------
            when S_ADD_AB_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for SUB_AB (Subtract B from A)
            --------------------------------------------------------------------
            when S_SUB_AB_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for AND_AB (Bitwise AND of A and B)
            --------------------------------------------------------------------
            when S_AND_AB_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for OR_AB (Bitwise OR of A and B)
            --------------------------------------------------------------------
            when S_OR_AB_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for INC_A (Increment A)
            --------------------------------------------------------------------
            when S_INC_A_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for INC_B (Increment B)
            --------------------------------------------------------------------
            when S_INC_B_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for DEC_A (Decrement A)
            --------------------------------------------------------------------
            when S_DEC_A_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for DEC_B (Decrement B)
            --------------------------------------------------------------------
            when S_DEC_B_4 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for BRA (Unconditional Branch)
            --------------------------------------------------------------------
            when S_BRA_4 =>
                next_state <= S_BRA_5;          -- Set up branch address
            when S_BRA_5 =>
                next_state <= S_BRA_6;          -- Wait for memory read (branch target)
            when S_BRA_6 =>
                next_state <= S_FETHCH_0;       -- Return to fetch cycle

            --------------------------------------------------------------------
            -- States for BEQ (Branch if Equal)
            --------------------------------------------------------------------
            when S_BEQ_4 =>
                next_state <= S_BEQ_5;          -- Set up branch address when condition is true
            when S_BEQ_5 =>
                next_state <= S_BEQ_6;          -- Wait for memory read
            when S_BEQ_6 =>
                next_state <= S_BEQ_7;          -- Load branch target address into PC
            when S_BEQ_7 =>
                next_state <= S_FETHCH_0;       -- Continue sequentially (no branch)

            --------------------------------------------------------------------
            -- States for BMI (Branch if Negative)
            --------------------------------------------------------------------
            when S_BMI_4 =>
                next_state <= S_BMI_5;
            when S_BMI_5 =>
                next_state <= S_BMI_6;
            when S_BMI_6 =>
                next_state <= S_BMI_7;
            when S_BMI_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BPL (Branch if Positive)
            --------------------------------------------------------------------
            when S_BPL_4 =>
                next_state <= S_BPL_5;
            when S_BPL_5 =>
                next_state <= S_BPL_6;
            when S_BPL_6 =>
                next_state <= S_BPL_7;
            when S_BPL_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BNE (Branch if Not Equal)
            --------------------------------------------------------------------
            when S_BNE_4 =>
                next_state <= S_BNE_5;
            when S_BNE_5 =>
                next_state <= S_BNE_6;
            when S_BNE_6 =>
                next_state <= S_BNE_7;
            when S_BNE_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BVS (Branch if Overflow Set)
            --------------------------------------------------------------------
            when S_BVS_4 =>
                next_state <= S_BVS_5;
            when S_BVS_5 =>
                next_state <= S_BVS_6;
            when S_BVS_6 =>
                next_state <= S_BVS_7;
            when S_BVS_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BVC (Branch if Overflow Clear)
            --------------------------------------------------------------------
            when S_BVC_4 =>
                next_state <= S_BVC_5;
            when S_BVC_5 =>
                next_state <= S_BVC_6;
            when S_BVC_6 =>
                next_state <= S_BVC_7;
            when S_BVC_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BCS (Branch if Carry Set)
            --------------------------------------------------------------------
            when S_BCS_4 =>
                next_state <= S_BCS_5;
            when S_BCS_5 =>
                next_state <= S_BCS_6;
            when S_BCS_6 =>
                next_state <= S_BCS_7;
            when S_BCS_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- States for BCC (Branch if Carry Clear)
            --------------------------------------------------------------------
            when S_BCC_4 =>
                next_state <= S_BCC_5;
            when S_BCC_5 =>
                next_state <= S_BCC_6;
            when S_BCC_6 =>
                next_state <= S_BCC_7;
            when S_BCC_7 =>
                next_state <= S_FETHCH_0;

            --------------------------------------------------------------------
            -- Default state: return to fetch cycle
            --------------------------------------------------------------------
            when others =>
                next_state <= S_FETHCH_0;
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
                BUS1_Sel <= "00";     -- Select source for BUS1 
                BUS2_Sel <= "01";     -- Select source for BUS2
                MAR_load <= '1';      -- Load MAR with the address from BUS2

            when S_FETHCH_1 =>
                PC_Inc <= '1';        -- Increment the Program Counter

            when S_FETHCH_2 =>
                BUS2_Sel <= "10";     -- Select data from memory
                IR_load  <= '1';      -- Load the fetched instruction into the IR

            when S_DECODE_3 =>
                -- No direct output signal; next state logic handles decoding

            ----------------------------------------------------------------------------
            -- LDA_IMM (Load A Immediate) States
            ----------------------------------------------------------------------------
            when S_LDA_IMM_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDA_IMM_5 =>
                PC_Inc <= '1';

            when S_LDA_IMM_6 =>
                BUS2_Sel <= "10";
                A_Load   <= '1';

            ----------------------------------------------------------------------------
            -- LDA_DIR (Load A Direct) States
            ----------------------------------------------------------------------------
            when S_LDA_DIR_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDA_DIR_5 =>
                PC_Inc <= '1';

            when S_LDA_DIR_6 =>
                BUS2_Sel <= "10";
                MAR_load <= '1';

            when S_LDA_DIR_7 =>
                -- Waiting for memory read (no control signals defined)

            when S_LDA_DIR_8 =>
                BUS2_Sel <= "10";
                A_Load   <= '1';

            ----------------------------------------------------------------------------
            -- LDB_IMM (Load B Immediate) States
            ----------------------------------------------------------------------------
            when S_LDB_IMM_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDB_IMM_5 =>
                PC_Inc <= '1';

            when S_LDB_IMM_6 =>
                BUS2_Sel <= "10";
                B_Load   <= '1';

            ----------------------------------------------------------------------------
            -- LDB_DIR (Load B Direct) States
            ----------------------------------------------------------------------------
            when S_LDB_DIR_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_LDB_DIR_5 =>
                PC_Inc <= '1';

            when S_LDB_DIR_6 =>
                BUS2_Sel <= "10";
                MAR_load <= '1';

            when S_LDB_DIR_7 =>
                -- Waiting for memory read (no control signals defined)

            when S_LDB_DIR_8 =>
                BUS2_Sel <= "10";
                B_Load   <= '1';

            ----------------------------------------------------------------------------
            -- STA_DIR (Store A Direct) States
            ----------------------------------------------------------------------------
            when S_STA_DIR_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_STA_DIR_5 =>
                PC_Inc <= '1';

            when S_STA_DIR_6 =>
                BUS2_Sel <= "10";
                MAR_load <= '1';

            when S_STA_DIR_7 =>
                BUS1_Sel <= "01";
                write_en <= '1';

            ----------------------------------------------------------------------------
            -- STB_DIR (Store B Direct) States
            ----------------------------------------------------------------------------
            when S_STB_DIR_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_STB_DIR_5 =>
                PC_Inc <= '1';

            when S_STB_DIR_6 =>
                BUS2_Sel <= "10";
                MAR_load <= '1';

            when S_STB_DIR_7 =>
                BUS1_Sel <= "10";
                write_en <= '1';

            ----------------------------------------------------------------------------
            -- ADD_AB (Addition of A and B) State
            ----------------------------------------------------------------------------
            when S_ADD_AB_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "000";     -- ALU configured for addition
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- SUB_AB (Subtract B from A) State
            ----------------------------------------------------------------------------
            when S_SUB_AB_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "001";     -- ALU configured for subtraction
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- AND_AB (Bitwise AND of A and B) State
            ----------------------------------------------------------------------------
            when S_AND_AB_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "010";     -- ALU configured for bitwise AND
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- OR_AB (Bitwise OR of A and B) State
            ----------------------------------------------------------------------------
            when S_OR_AB_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "011";     -- ALU configured for bitwise OR
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- INC_A (Increment A) State
            ----------------------------------------------------------------------------
            when S_INC_A_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "101";     -- ALU configured for increment
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- INC_B (Increment B) State
            ----------------------------------------------------------------------------
            when S_INC_B_4 =>
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "100";     -- ALU configured for increment
                B_Load   <= '1';      -- Load result into register B
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- DEC_A (Decrement A) State
            ----------------------------------------------------------------------------
            when S_DEC_A_4 =>
                BUS1_Sel <= "01";     -- Operand from register A
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "111";     -- ALU configured for increment
                A_Load   <= '1';      -- Load result into register A
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- DEC_B (Decrement B) State
            ----------------------------------------------------------------------------
            when S_DEC_B_4 =>
                BUS2_Sel <= "00";     -- Transfer ALU result to BUS2
                ALU_Sel  <= "110";     -- ALU configured for increment
                B_Load   <= '1';      -- Load result into register B
                CCR_Load <= '1';      -- Update condition code register

            ----------------------------------------------------------------------------
            -- BRA (Unconditional Branch) States
            ----------------------------------------------------------------------------
            when S_BRA_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BRA_5 =>
                -- Waiting for branch target address (no control signals defined)

            when S_BRA_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            ----------------------------------------------------------------------------
            -- BMI (Branch if Negative) States
            ----------------------------------------------------------------------------
            when S_BMI_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BMI_5 =>
                -- Waiting for branch target address

            when S_BMI_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BMI_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BPL (Branch if Positive) States
            ----------------------------------------------------------------------------
            when S_BPL_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BPL_5 =>
                -- Waiting for branch target address

            when S_BPL_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BPL_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BEQ (Branch if Equal) States
            ----------------------------------------------------------------------------
            when S_BEQ_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BEQ_5 =>
                -- Waiting for branch target address

            when S_BEQ_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BEQ_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BNE (Branch if Not Equal) States
            ----------------------------------------------------------------------------
            when S_BNE_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BNE_5 =>
                -- Waiting for branch target address

            when S_BNE_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BNE_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BVS (Branch if Overflow Set) States
            ----------------------------------------------------------------------------
            when S_BVS_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BVS_5 =>
                -- Waiting for branch target address

            when S_BVS_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BVS_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BVC (Branch if Overflow Clear) States
            ----------------------------------------------------------------------------
            when S_BVC_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BVC_5 =>
                -- Waiting for branch target address

            when S_BVC_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BVC_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BCS (Branch if Carry Set) States
            ----------------------------------------------------------------------------
            when S_BCS_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BCS_5 =>
                -- Waiting for branch target address

            when S_BCS_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BCS_7 =>
                PC_Inc <= '1';

            ----------------------------------------------------------------------------
            -- BCC (Branch if Carry Clear) States
            ----------------------------------------------------------------------------
            when S_BCC_4 =>
                BUS1_Sel <= "00";
                BUS2_Sel <= "01";
                MAR_load <= '1';

            when S_BCC_5 =>
                -- Waiting for branch target address

            when S_BCC_6 =>
                BUS2_Sel <= "10";
                PC_load  <= '1';

            when S_BCC_7 =>
                PC_Inc <= '1';

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
