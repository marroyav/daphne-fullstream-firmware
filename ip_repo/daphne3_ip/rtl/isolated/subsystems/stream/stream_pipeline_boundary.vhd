library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity stream_pipeline_boundary is
  port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    readiness_i     : in  acquisition_readiness_t;
    lanes_i         : in  stream_lane_array_t;
    lanes_o         : out stream_lane_array_t;
    stream_enable_o : out std_logic
  );
end entity stream_pipeline_boundary;

architecture rtl of stream_pipeline_boundary is
  signal stream_enable_s : std_logic;
begin
  stream_enable_s <= (not reset) and
                     readiness_i.config_ready and
                     readiness_i.timing_ready and
                     readiness_i.alignment_ready;
  stream_enable_o <= stream_enable_s;

  gate_proc : process(all)
    variable gated_lanes_v : stream_lane_array_t;
  begin
    gated_lanes_v := STREAM_LANE_ARRAY_NULL;
    if stream_enable_s = '1' then
      gated_lanes_v := lanes_i;
    end if;
    lanes_o <= gated_lanes_v;
  end process gate_proc;
end architecture rtl;
