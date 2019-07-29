library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_baudrate_generator is
  generic(
    BAUDRATE     : integer := 115200;
	MAIN_CLK_MHZ : integer := 50
  );

  port(
    clk  : in  std_logic;
    rst  : in  std_logic;
    tick : out std_logic
  );

end uart_baudrate_generator;

architecture behavioral of uart_baudrate_generator is
  constant DIVISOR : integer := integer(round(real(MAIN_CLK_MHZ*1000000)/real(BAUDRATE*16)));
  signal   counter : unsigned(16 downto 0) := (others => '0');
begin
  process(clk, rst) is
  begin
    if rst = '1' then
      counter <= (others => '0');
      tick  <= '0';
    elsif rising_edge(clk) then
      if counter = DIVISOR - 1 then
        tick  <= '1';
        counter <= (others => '0');
      else
        tick  <= '0';
        counter <= counter + 1;
      end if;
    end if;
  end process;

end behavioral;