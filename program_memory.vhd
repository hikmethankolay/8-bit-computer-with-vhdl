library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity program_memory is
    Port ( clk : in  STD_LOGIC;
           address : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0));
end program_memory;


architecture arch of program_memory is

-- Loads and stores
constant LDA_IMM : std_logic_vector(7 downto 0) := x"86";
constant LDA_DIR : std_logic_vector(7 downto 0) := x"87";
constant LDB_IMM : std_logic_vector(7 downto 0) := x"88";
constant LDB_DIR : std_logic_vector(7 downto 0) := x"89";
constant STA_DIR : std_logic_vector(7 downto 0) := x"96";
constant STB_DIR : std_logic_vector(7 downto 0) := x"97";

-- Data manipulation
constant ADD_AB : std_logic_vector(7 downto 0) := x"42";
constant SUB_AB : std_logic_vector(7 downto 0) := x"43";
constant AND_AB : std_logic_vector(7 downto 0) := x"44";
constant OR_AB : std_logic_vector(7 downto 0) := x"45";
constant INC_A : std_logic_vector(7 downto 0) := x"46";
constant INC_B : std_logic_vector(7 downto 0) := x"47";
constant DEC_A : std_logic_vector(7 downto 0) := x"48";
constant DEC_B : std_logic_vector(7 downto 0) := x"49";

-- Branches
constant BRA : std_logic_vector(7 downto 0) := x"20";
constant BMI : std_logic_vector(7 downto 0) := x"21";
constant BPL : std_logic_vector(7 downto 0) := x"22";
constant BEQ : std_logic_vector(7 downto 0) := x"23";
constant BNE : std_logic_vector(7 downto 0) := x"24";
constant BVS : std_logic_vector(7 downto 0) := x"25";
constant BVC : std_logic_vector(7 downto 0) := x"26";
constant BCS : std_logic_vector(7 downto 0) := x"27";
constant BCC : std_logic_vector(7 downto 0) := x"28";


type rom_type is array  (0 to 127) of std_logic_vector(7 downto 0);

constant ROM: rom_type := (
    0 => LDA_IMM,
    1 => x"00",
    2 => STA_DIR,
    3 => x"80",
    4 => BRA,
    others => x"00"
);


--Signals
signal enable : std_logic;

begin

    --Processes
    process(address)
    begin
        if(address >= x"00" and address <= x"7F") then --0 ile 127 aralığında ise
            enable <= '1';
        else
            enable <= '0';
        end if;
    end process;

    ----------------------------------------------------------------

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(enable = '1') then
                data_out <= ROM(to_integer(unsigned(address)));
            end if;
        end if;
    end process;

end arch;