library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debouncer is
  generic(
    counter_size : natural := 10
  );

  port(
    clk   : in  std_logic;
    rst   : in  std_logic;
    in_d  : in  std_logic;
    out_d : out std_logic
  );
end entity;

architecture arch of debouncer is
  signal ff          : std_logic_vector(1 downto 0);
  signal counter_set : std_logic;
  signal counter     : unsigned(counter_size downto 0);
begin
  counter_set <= ff(0) xor ff(1);

  process(clk, rst) is
  begin
    if rst = '1' then
      ff      <= (others => '0');
      counter <= (others => '0');
    elsif rising_edge(clk) then
      ff(0) <= in_d;
      ff(1) <= ff(0);

      -- input is changing
      if counter_set = '1' then
        counter <= (others => '0');
      elsif counter(counter_size - 1) = '0' then
        counter <= counter + 1;
      else
        out_d <= ff(1);
      end if;
    end if;
  end process;
end architecture arch;
