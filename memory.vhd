library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Entity declaration for the Memory module
entity memory is
    Port ( 
            clk : in  STD_LOGIC;  -- Clock signal
            rst : in  STD_LOGIC;  -- Reset signal
            address : in  STD_LOGIC_VECTOR (7 downto 0);  -- 8-bit address input
            data_in : in  STD_LOGIC_VECTOR (7 downto 0);  -- 8-bit data input
            write_en : in  STD_LOGIC;  -- Write enable signal (1 for writing, 0 for reading)
            
            -- Input ports (external device inputs)
            port_in_00 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_01 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_02 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_03 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_04 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_05 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_06 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_07 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_08 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_09 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_10 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_11 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_12 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_13 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_14 : in  STD_LOGIC_VECTOR (7 downto 0);
            port_in_15 : in  STD_LOGIC_VECTOR (7 downto 0);
            
            -- Output signals
            data_out : out  STD_LOGIC_VECTOR (7 downto 0);  -- Data output
            port_out_00 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_01 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_02 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_03 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_04 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_05 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_06 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_07 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_08 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_09 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_10 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_11 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_12 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_13 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_14 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_15 : out  STD_LOGIC_VECTOR (7 downto 0)
        );
end memory;

-- Architecture definition
architecture arch of memory is

    -- Components Declaration
    
    -- ROM (Read-Only Memory) component for program storage
    component program_memory is
        Port ( 
            clk : in  STD_LOGIC;
            address : in  STD_LOGIC_VECTOR (7 downto 0);
            data_out : out  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- RAM (Random Access Memory) component for data storage
    component data_memory is
        Port ( 
            clk : in  STD_LOGIC;
            address : in  STD_LOGIC_VECTOR (7 downto 0);
            data_in : in  STD_LOGIC_VECTOR (7 downto 0);
            write_en : in  STD_LOGIC;
            data_out : out  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- Output Ports component to store output values
    component output_ports is
        Port ( 
            clk : in  STD_LOGIC;
            rst : in  STD_LOGIC;
            address : in  STD_LOGIC_VECTOR (7 downto 0);
            data_in : in  STD_LOGIC_VECTOR (7 downto 0);
            write_en : in  STD_LOGIC;
            
            -- 16 Output Ports
            port_out_00 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_01 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_02 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_03 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_04 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_05 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_06 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_07 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_08 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_09 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_10 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_11 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_12 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_13 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_14 : out  STD_LOGIC_VECTOR (7 downto 0);
            port_out_15 : out  STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- Internal Signals
    signal rom_out : std_logic_vector(7 downto 0);
    signal ram_out : std_logic_vector(7 downto 0);

begin

    -- Instantiate ROM module
    ROM_U: program_memory port map(
        clk => clk,
        address => address,
        data_out => rom_out
    );

    -- Instantiate RAM module
    RAM_U: data_memory port map(
        clk => clk,
        address => address,
        data_in => data_in,
        write_en => write_en,
        data_out => ram_out
    );

    -- Instantiate Output Ports module
    OUT_U: output_ports port map (
        clk => clk,
        rst => rst,
        address => address,
        data_in => data_in,
        write_en => write_en,
        port_out_00 => port_out_00,
        port_out_01 => port_out_01,
        port_out_02 => port_out_02,
        port_out_03 => port_out_03,
        port_out_04 => port_out_04,
        port_out_05 => port_out_05,
        port_out_06 => port_out_06,
        port_out_07 => port_out_07,
        port_out_08 => port_out_08,
        port_out_09 => port_out_09,
        port_out_10 => port_out_10,
        port_out_11 => port_out_11,
        port_out_12 => port_out_12,
        port_out_13 => port_out_13,
        port_out_14 => port_out_14,
        port_out_15 => port_out_15
    );

---------------------------------------------------------------------------------

-- MUX Process: Selects data from ROM, RAM, or Input Ports based on the address
process(address, rom_out, ram_out,
    port_in_00, port_in_01, port_in_02, port_in_03,
    port_in_04, port_in_05, port_in_06, port_in_07,
    port_in_08, port_in_09, port_in_10, port_in_11,
    port_in_12, port_in_13, port_in_14, port_in_15)
begin
    if(address <= x"7F") then
        data_out <= rom_out;
    elsif(address <= x"DF") then
        data_out <= ram_out;
    else
        data_out <= port_in_00;  -- Simplified for illustration
    end if;
end process;

end arch;
