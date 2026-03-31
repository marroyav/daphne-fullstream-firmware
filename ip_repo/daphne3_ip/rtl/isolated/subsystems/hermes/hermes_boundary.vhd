library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity hermes_boundary is
  port (
    clk           : in  std_logic;
    reset         : in  std_logic;
    readiness_i   : in  acquisition_readiness_t;
    lanes_i       : in  stream_lane_array_t;
    lanes_o       : out stream_lane_array_t;
    hermes_stat_o : out hermes_boundary_status_t
  );
end entity hermes_boundary;

architecture rtl of hermes_boundary is
  signal hermes_ready_s : std_logic;
begin
  hermes_ready_s <= (not reset) and
                    readiness_i.config_ready and
                    readiness_i.timing_ready and
                    readiness_i.alignment_ready;

  hermes_stat_o.ready          <= hermes_ready_s;
  hermes_stat_o.backpressure   <= '0';
  hermes_stat_o.link_up        <= '0';
  hermes_stat_o.transport_busy <= '0';

  gate_proc : process(all)
    variable gated_lanes_v : stream_lane_array_t;
  begin
    gated_lanes_v := STREAM_LANE_ARRAY_NULL;
    if hermes_ready_s = '1' then
      gated_lanes_v := lanes_i;
    end if;
    lanes_o <= gated_lanes_v;
  end process gate_proc;
end architecture rtl;
