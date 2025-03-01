library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity data_memeory is
    Port ( clk : in  STD_LOGIC;
           address : in  STD_LOGIC_VECTOR (7 downto 0);
           data_in : in  STD_LOGIC_VECTOR (7 downto 0);
           write_en : in  STD_LOGIC;
           data_out : out  STD_LOGIC_VECTOR (7 downto 0));
end data_memeory;


architecture arch of data_memeory is

type ram_type is array  (128 to 223) of std_logic_vector(7 downto 0);

-- Signals
signal RAM : ram_type := (others => "0");
signal enable : std_logic;

begin
    --Processes
    process(address)
    begin
        if(address >= x"80" and address <= x"DF") then
            enable <= '1';
        else
            enable <= '0';
        end if;
    end process;

    ----------------------------------------------------------------

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(enable = '1' and write_en = '1') then
                RAM(to_integer(unsigned(address))) <= data_in;
            elsif(enable = '1' and write_en = '0') then
                data_out <= RAM(to_integer(unsigned(address)));
            end if;
        end if;
    end process;

end arch;