library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity daphne_fullstream_boundary_top_formal is
  port (
    clk_axi       : in std_logic;
    resetn_axi    : in std_logic;
    clk           : in std_logic;
    reset         : in std_logic;
    analog_status : in subsystem_status_t;
    timing_ctrl   : in timing_control_t;
    timing_stat_i : in timing_status_t;
    align_ctrl    : in frontend_alignment_control_t;
    align_stat_i  : in frontend_alignment_status_t;
    ingress_lanes : in stream_lane_array_t
  );
end entity daphne_fullstream_boundary_top_formal;

architecture formal of daphne_fullstream_boundary_top_formal is
  signal timing_stat_o  : timing_status_t;
  signal timing_ready_o : std_logic;
  signal align_stat_o   : frontend_alignment_status_t;
  signal stream_lanes_o : stream_lane_array_t;
  signal stream_enable  : std_logic;
  signal spy_enable     : std_logic;
  signal hermes_lanes_o : stream_lane_array_t;
  signal hermes_stat_o  : hermes_boundary_status_t;
begin
  dut : entity work.daphne_fullstream_boundary_top
    port map (
      clk_axi         => clk_axi,
      resetn_axi      => resetn_axi,
      clk             => clk,
      reset           => reset,
      analog_status_i => analog_status,
      timing_ctrl_i   => timing_ctrl,
      timing_stat_i   => timing_stat_i,
      align_ctrl_i    => align_ctrl,
      align_stat_i    => align_stat_i,
      ingress_lanes_i => ingress_lanes,
      timing_stat_o   => timing_stat_o,
      timing_ready_o  => timing_ready_o,
      align_stat_o    => align_stat_o,
      stream_lanes_o  => stream_lanes_o,
      stream_enable_o => stream_enable,
      spy_enable_o    => spy_enable,
      hermes_lanes_o  => hermes_lanes_o,
      hermes_stat_o   => hermes_stat_o
    );

  assert timing_stat_o = timing_stat_i
    report "composed top must preserve raw timing status"
    severity failure;

  assert stream_enable = hermes_stat_o.ready
    report "stream and Hermes gates must agree in the composed top"
    severity failure;

  assert spy_enable = stream_enable
    report "spy enable must follow the same readiness gate as stream enable"
    severity failure;

  assert (stream_enable = '1') or (stream_lanes_o = STREAM_LANE_ARRAY_NULL)
    report "disabled composed stream handoff must drive null stream lanes"
    severity failure;

  assert (hermes_stat_o.ready = '1') or (hermes_lanes_o = STREAM_LANE_ARRAY_NULL)
    report "disabled composed Hermes handoff must drive null Hermes lanes"
    severity failure;

  lane_passthrough_gen : for i in ingress_lanes'range generate
  begin
    assert (stream_enable = '0') or (stream_lanes_o(i) = ingress_lanes(i))
      report "enabled composed top must pass stream lanes through unchanged"
      severity failure;

    assert (hermes_stat_o.ready = '0') or (hermes_lanes_o(i) = ingress_lanes(i))
      report "enabled composed top must pass Hermes lanes through unchanged"
      severity failure;
  end generate lane_passthrough_gen;
end architecture formal;
