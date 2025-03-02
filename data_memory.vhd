library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Entity declaration for Data Memory
entity data_memory is
    Port (
        clk : in  STD_LOGIC;  -- Clock signal
        address : in  STD_LOGIC_VECTOR (7 downto 0);  -- 8-bit memory address
        data_in : in  STD_LOGIC_VECTOR (7 downto 0);  -- 8-bit data input
        write_en : in  STD_LOGIC;  -- Write enable signal (1 for write, 0 for read)
        data_out : out  STD_LOGIC_VECTOR (7 downto 0)  -- 8-bit data output
    );
end data_memory;

-- Architecture definition
architecture arch of data_memory is

    -- Declare RAM as an array from addresses 128 (0x80) to 223 (0xDF)
    type ram_type is array (128 to 223) of std_logic_vector(7 downto 0);

    -- Internal signals
    signal RAM : ram_type := (others => x"00");  -- Initialize RAM with all zeros
    signal enable : std_logic;  -- Enable signal for valid address range

begin

    -- Address range checking process
    -- Enables memory access only for addresses in the valid range (0x80 to 0xDF)
    process(address)
    begin
        if(address >= x"80" and address <= x"DF") then
            enable <= '1';  -- Enable memory access
        else
            enable <= '0';  -- Disable memory access
        end if;
    end process;

    ----------------------------------------------------------------

    -- Memory read/write process
    process(clk)
    begin
        if(rising_edge(clk)) then  -- Trigger on the rising edge of the clock
            if(enable = '1' and write_en = '1') then
                -- Write operation: Store data_in at the given address
                RAM(to_integer(unsigned(address))) <= data_in;
            elsif(enable = '1' and write_en = '0') then
                -- Read operation: Retrieve data from memory and output it
                data_out <= RAM(to_integer(unsigned(address)));
            end if;
        end if;
    end process;

end arch;
