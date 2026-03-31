-- stream_mux_select.vhd
-- Select one 14-bit streaming payload from the 5x9x16 frontend input space
-- or from the built-in diagnostic patterns.

library ieee;
use ieee.std_logic_1164.all;

use work.daphne3_package.all;

entity stream_mux_select is
port(
    din: in array_5x9x16_type;
    muxctrl: in std_logic_vector(7 downto 0);
    counter: in std_logic_vector(13 downto 0);
    rand: in std_logic_vector(13 downto 0);
    dout: out std_logic_vector(13 downto 0)
  );
end stream_mux_select;

architecture stream_mux_select_arch of stream_mux_select is
begin

    dout <= din(0)(0)(15 downto 2) when (muxctrl=X"00") else
            din(0)(1)(15 downto 2) when (muxctrl=X"01") else
            din(0)(2)(15 downto 2) when (muxctrl=X"02") else
            din(0)(3)(15 downto 2) when (muxctrl=X"03") else
            din(0)(4)(15 downto 2) when (muxctrl=X"04") else
            din(0)(5)(15 downto 2) when (muxctrl=X"05") else
            din(0)(6)(15 downto 2) when (muxctrl=X"06") else
            din(0)(7)(15 downto 2) when (muxctrl=X"07") else
            din(0)(8)(15 downto 2) when (muxctrl=X"08") else

            din(1)(0)(15 downto 2) when (muxctrl=X"10") else
            din(1)(1)(15 downto 2) when (muxctrl=X"11") else
            din(1)(2)(15 downto 2) when (muxctrl=X"12") else
            din(1)(3)(15 downto 2) when (muxctrl=X"13") else
            din(1)(4)(15 downto 2) when (muxctrl=X"14") else
            din(1)(5)(15 downto 2) when (muxctrl=X"15") else
            din(1)(6)(15 downto 2) when (muxctrl=X"16") else
            din(1)(7)(15 downto 2) when (muxctrl=X"17") else
            din(1)(8)(15 downto 2) when (muxctrl=X"18") else

            din(2)(0)(15 downto 2) when (muxctrl=X"20") else
            din(2)(1)(15 downto 2) when (muxctrl=X"21") else
            din(2)(2)(15 downto 2) when (muxctrl=X"22") else
            din(2)(3)(15 downto 2) when (muxctrl=X"23") else
            din(2)(4)(15 downto 2) when (muxctrl=X"24") else
            din(2)(5)(15 downto 2) when (muxctrl=X"25") else
            din(2)(6)(15 downto 2) when (muxctrl=X"26") else
            din(2)(7)(15 downto 2) when (muxctrl=X"27") else
            din(2)(8)(15 downto 2) when (muxctrl=X"28") else

            din(3)(0)(15 downto 2) when (muxctrl=X"30") else
            din(3)(1)(15 downto 2) when (muxctrl=X"31") else
            din(3)(2)(15 downto 2) when (muxctrl=X"32") else
            din(3)(3)(15 downto 2) when (muxctrl=X"33") else
            din(3)(4)(15 downto 2) when (muxctrl=X"34") else
            din(3)(5)(15 downto 2) when (muxctrl=X"35") else
            din(3)(6)(15 downto 2) when (muxctrl=X"36") else
            din(3)(7)(15 downto 2) when (muxctrl=X"37") else
            din(3)(8)(15 downto 2) when (muxctrl=X"38") else

            din(4)(0)(15 downto 2) when (muxctrl=X"40") else
            din(4)(1)(15 downto 2) when (muxctrl=X"41") else
            din(4)(2)(15 downto 2) when (muxctrl=X"42") else
            din(4)(3)(15 downto 2) when (muxctrl=X"43") else
            din(4)(4)(15 downto 2) when (muxctrl=X"44") else
            din(4)(5)(15 downto 2) when (muxctrl=X"45") else
            din(4)(6)(15 downto 2) when (muxctrl=X"46") else
            din(4)(7)(15 downto 2) when (muxctrl=X"47") else
            din(4)(8)(15 downto 2) when (muxctrl=X"48") else

            "11111111111111" when (muxctrl=X"50") else
            "00000011111111" when (muxctrl=X"51") else
            "11111100000000" when (muxctrl=X"52") else
            "11000000000011" when (muxctrl=X"53") else
            counter          when (muxctrl=X"54") else
            rand             when (muxctrl=X"55") else
            (others => '0');

end stream_mux_select_arch;
