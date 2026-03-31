library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity hermes_boundary_formal is
  port (
    clk       : in std_logic;
    reset     : in std_logic;
    readiness : in acquisition_readiness_t;
    lanes_i   : in stream_lane_array_t
  );
end entity hermes_boundary_formal;

architecture formal of hermes_boundary_formal is
  signal lanes_o     : stream_lane_array_t;
  signal hermes_stat : hermes_boundary_status_t;
begin
  dut : entity work.hermes_boundary
    port map (
      clk           => clk,
      reset         => reset,
      readiness_i   => readiness,
      lanes_i       => lanes_i,
      lanes_o       => lanes_o,
      hermes_stat_o => hermes_stat
    );

  assert hermes_stat.backpressure = '0'
    report "Hermes boundary must keep backpressure neutral"
    severity failure;

  assert hermes_stat.link_up = '0'
    report "Hermes boundary must not assert link_up from the wrapper alone"
    severity failure;

  assert hermes_stat.transport_busy = '0'
    report "Hermes boundary must keep transport_busy neutral"
    severity failure;

  assert hermes_stat.ready = (
    (not reset) and
    readiness.config_ready and
    readiness.timing_ready and
    readiness.alignment_ready
  )
    report "Hermes ready must match the readiness conjunction"
    severity failure;

  assert (hermes_stat.ready = '1') or (lanes_o = STREAM_LANE_ARRAY_NULL)
    report "disabled Hermes boundary must drive a null lane array"
    severity failure;

  lane_passthrough_gen : for i in lanes_o'range generate
  begin
    assert (hermes_stat.ready = '0') or (lanes_o(i) = lanes_i(i))
      report "enabled Hermes boundary must pass each lane through unchanged"
      severity failure;
  end generate lane_passthrough_gen;
end architecture formal;
