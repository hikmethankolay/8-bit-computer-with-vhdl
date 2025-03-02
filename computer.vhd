-- Import necessary IEEE libraries for standard logic operations
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;  -- Provides std_logic and std_logic_vector data types
use IEEE.numeric_std.all;      -- Provides arithmetic operations for signed and unsigned vectors
use IEEE.std_logic_unsigned.all; -- Enables arithmetic operations on std_logic_vector


entity computer is
    port(
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
end computer;

architecture arch of computer is

    component CPU is
        port(
            clk: in std_logic;            -- Clock signal
            rst: in std_logic;            -- Reset signal
            from_memory: in std_logic_vector(7 downto 0); -- Input data from memory
            to_memory: out std_logic_vector(7 downto 0);  -- Data output to memory
            write_en: out std_logic;   -- Write enable signal for memory
            address: out std_logic_vector(7 downto 0) -- Address output for memory access
        );
    end component;

    component memory is
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
    end component;

    signal address: std_logic_vector(7 downto 0);
    signal data_in: std_logic_vector(7 downto 0);
    signal data_out: std_logic_vector(7 downto 0);
    signal write_en: std_logic;

begin

    cpu_module: CPU port map(
        clk => clk,
        rst => rst,
        from_memory => data_out,
        to_memory => data_in,
        write_en => write_en,
        address => address
    );

    memory_port_map: memory port map(
        clk => clk,
        rst => rst,
        address => address,
        data_in => data_in,
        write_en => write_en,
        data_out => data_out,
        port_in_00 => port_in_00,
        port_in_01 => port_in_01,
        port_in_02 => port_in_02,
        port_in_03 => port_in_03,
        port_in_04 => port_in_04,
        port_in_05 => port_in_05,
        port_in_06 => port_in_06,
        port_in_07 => port_in_07,
        port_in_08 => port_in_08,
        port_in_09 => port_in_09,
        port_in_10 => port_in_10,
        port_in_11 => port_in_11,
        port_in_12 => port_in_12,
        port_in_13 => port_in_13,
        port_in_14 => port_in_14,
        port_in_15 => port_in_15,
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


end arch;