library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity spy_buffer_boundary is
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    readiness_i  : in  acquisition_readiness_t;
    spy_enable_o : out std_logic
  );
end entity spy_buffer_boundary;

architecture rtl of spy_buffer_boundary is
begin
  spy_enable_o <= (not reset) and
                  readiness_i.config_ready and
                  readiness_i.timing_ready and
                  readiness_i.alignment_ready;
end architecture rtl;
