library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Entity declaration for Program Memory
entity program_memory is
    Port ( 
        clk : in  STD_LOGIC;  -- Clock signal
        address : in  STD_LOGIC_VECTOR (7 downto 0);  -- 8-bit memory address
        data_out : out  STD_LOGIC_VECTOR (7 downto 0)  -- 8-bit data output (instruction)
    );
end program_memory;

-- Architecture definition
architecture arch of program_memory is

    -- Instruction Set (Operation Codes)

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

    -- ROM Definition (Program Instructions)
    type rom_type is array (0 to 127) of std_logic_vector(7 downto 0);

    -- Hardcoded Instructions in ROM
    constant ROM: rom_type := (
        0 => LDA_IMM,  -- Load A with  Immediate Value
        1 => x"0F",    -- Operand: A = 0x0F
        2 => STA_DIR,  -- Store A into memory at address 0x80
        3 => x"80",    -- Memory Address 0x80
        4 => BRA,      -- Unconditional Branch
        5 => x"00",    -- Memory Address 0x00
        others => x"00" -- Initialize remaining ROM with 0
    );

    -- Internal signal for memory enable
    signal enable : std_logic;

begin

    -- Address Range Checking Process
    -- Enables access only if the address is within the valid range (0x00 - 0x7F)
    process(address)
    begin
        if(address >= x"00" and address <= x"7F") then 
            enable <= '1';  -- Enable ROM access
        else
            enable <= '0';  -- Disable ROM access
        end if;
    end process;

    ----------------------------------------------------------------

    -- Process for Synchronous ROM Read
    process(clk)
    begin
        if(rising_edge(clk)) then  -- Execute on rising edge of the clock
            if(enable = '1') then  -- Read only if address is within range
                data_out <= ROM(to_integer(unsigned(address)));  -- Read instruction from ROM
            end if;
        end if;
    end process;

end arch;
