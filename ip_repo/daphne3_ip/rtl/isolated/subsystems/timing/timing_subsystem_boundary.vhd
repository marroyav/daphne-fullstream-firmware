library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity timing_subsystem_boundary is
  port (
    clk_axi        : in  std_logic;
    resetn_axi     : in  std_logic;
    timing_ctrl_i  : in  timing_control_t;
    timing_stat_i  : in  timing_status_t;
    timing_stat_o  : out timing_status_t;
    timing_ready_o : out std_logic
  );
end entity timing_subsystem_boundary;

architecture rtl of timing_subsystem_boundary is
begin
  timing_stat_o <= timing_stat_i;
  timing_ready_o <= resetn_axi and
                    timing_stat_i.mmcm0_locked and
                    timing_stat_i.mmcm1_locked and
                    (
                      (not timing_ctrl_i.use_endpoint_clock) or
                      (timing_stat_i.endpoint_ready and timing_stat_i.timestamp_valid)
                    );
end architecture rtl;
