library ieee;
use ieee.std_logic_1164.all;

use work.daphne3_package.all;

entity stream_mux_select_formal is
end entity stream_mux_select_formal;

architecture formal of stream_mux_select_formal is
  attribute anyconst : boolean;

  signal din     : array_5x9x16_type;
  signal muxctrl : std_logic_vector(7 downto 0);
  signal counter : std_logic_vector(13 downto 0);
  signal rand    : std_logic_vector(13 downto 0);
  signal dout    : std_logic_vector(13 downto 0);

  attribute anyconst of din     : signal is true;
  attribute anyconst of muxctrl : signal is true;
  attribute anyconst of counter : signal is true;
  attribute anyconst of rand    : signal is true;

  function expected_mux_value(
    din_i     : array_5x9x16_type;
    muxctrl_i : std_logic_vector(7 downto 0);
    counter_i : std_logic_vector(13 downto 0);
    rand_i    : std_logic_vector(13 downto 0)
  ) return std_logic_vector is
    variable result : std_logic_vector(13 downto 0) := (others => '0');
  begin
    case muxctrl_i is
      when X"00" => result := din_i(0)(0)(15 downto 2);
      when X"01" => result := din_i(0)(1)(15 downto 2);
      when X"02" => result := din_i(0)(2)(15 downto 2);
      when X"03" => result := din_i(0)(3)(15 downto 2);
      when X"04" => result := din_i(0)(4)(15 downto 2);
      when X"05" => result := din_i(0)(5)(15 downto 2);
      when X"06" => result := din_i(0)(6)(15 downto 2);
      when X"07" => result := din_i(0)(7)(15 downto 2);
      when X"08" => result := din_i(0)(8)(15 downto 2);

      when X"10" => result := din_i(4)(0)(15 downto 2);
      when X"11" => result := din_i(4)(1)(15 downto 2);
      when X"12" => result := din_i(4)(2)(15 downto 2);
      when X"13" => result := din_i(4)(3)(15 downto 2);
      when X"14" => result := din_i(4)(4)(15 downto 2);
      when X"15" => result := din_i(4)(5)(15 downto 2);
      when X"16" => result := din_i(4)(6)(15 downto 2);
      when X"17" => result := din_i(4)(7)(15 downto 2);
      when X"18" => result := din_i(4)(8)(15 downto 2);

      when X"20" => result := din_i(3)(0)(15 downto 2);
      when X"21" => result := din_i(3)(1)(15 downto 2);
      when X"22" => result := din_i(3)(2)(15 downto 2);
      when X"23" => result := din_i(3)(3)(15 downto 2);
      when X"24" => result := din_i(3)(4)(15 downto 2);
      when X"25" => result := din_i(3)(5)(15 downto 2);
      when X"26" => result := din_i(3)(6)(15 downto 2);
      when X"27" => result := din_i(3)(7)(15 downto 2);
      when X"28" => result := din_i(3)(8)(15 downto 2);

      when X"30" => result := din_i(2)(0)(15 downto 2);
      when X"31" => result := din_i(2)(1)(15 downto 2);
      when X"32" => result := din_i(2)(2)(15 downto 2);
      when X"33" => result := din_i(2)(3)(15 downto 2);
      when X"34" => result := din_i(2)(4)(15 downto 2);
      when X"35" => result := din_i(2)(5)(15 downto 2);
      when X"36" => result := din_i(2)(6)(15 downto 2);
      when X"37" => result := din_i(2)(7)(15 downto 2);
      when X"38" => result := din_i(2)(8)(15 downto 2);

      when X"40" => result := din_i(1)(0)(15 downto 2);
      when X"41" => result := din_i(1)(1)(15 downto 2);
      when X"42" => result := din_i(1)(2)(15 downto 2);
      when X"43" => result := din_i(1)(3)(15 downto 2);
      when X"44" => result := din_i(1)(4)(15 downto 2);
      when X"45" => result := din_i(1)(5)(15 downto 2);
      when X"46" => result := din_i(1)(6)(15 downto 2);
      when X"47" => result := din_i(1)(7)(15 downto 2);
      when X"48" => result := din_i(1)(8)(15 downto 2);

      when X"50" => result := "11111111111111";
      when X"51" => result := "00000011111111";
      when X"52" => result := "11111100000000";
      when X"53" => result := "11000000000011";
      when X"54" => result := counter_i;
      when X"55" => result := rand_i;
      when others => result := (others => '0');
    end case;

    return result;
  end function;
begin
  dut : entity work.stream_mux_select
    port map (
      din     => din,
      muxctrl => muxctrl,
      counter => counter,
      rand    => rand,
      dout    => dout
    );

  assert dout = expected_mux_value(din, muxctrl, counter, rand)
    report "stream mux selector output must match the documented decode table"
    severity failure;
end architecture formal;
