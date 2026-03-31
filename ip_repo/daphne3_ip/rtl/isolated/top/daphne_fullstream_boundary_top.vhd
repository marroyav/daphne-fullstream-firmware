library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity daphne_fullstream_boundary_top is
  port (
    clk_axi         : in  std_logic;
    resetn_axi      : in  std_logic;
    clk             : in  std_logic;
    reset           : in  std_logic;
    analog_status_i : in  subsystem_status_t;
    timing_ctrl_i   : in  timing_control_t;
    timing_stat_i   : in  timing_status_t;
    align_ctrl_i    : in  frontend_alignment_control_t;
    align_stat_i    : in  frontend_alignment_status_t;
    ingress_lanes_i : in  stream_lane_array_t;
    timing_stat_o   : out timing_status_t;
    timing_ready_o  : out std_logic;
    align_stat_o    : out frontend_alignment_status_t;
    stream_lanes_o  : out stream_lane_array_t;
    stream_enable_o : out std_logic;
    spy_enable_o    : out std_logic;
    hermes_lanes_o  : out stream_lane_array_t;
    hermes_stat_o   : out hermes_boundary_status_t
  );
end entity daphne_fullstream_boundary_top;

architecture rtl of daphne_fullstream_boundary_top is
  signal prereq_s       : frontend_prereq_t;
  signal readiness_s    : acquisition_readiness_t;
  signal timing_ready_s : std_logic;
  signal align_stat_s   : frontend_alignment_status_t;
  signal stream_lanes_s : stream_lane_array_t;
begin
  prereq_s.config_ready <= analog_status_i.ready;
  prereq_s.timing_ready <= timing_ready_s;

  readiness_s.config_ready    <= analog_status_i.ready;
  readiness_s.timing_ready    <= timing_ready_s;
  readiness_s.alignment_ready <= align_stat_s.alignment_valid;

  timing_boundary_inst : entity work.timing_subsystem_boundary
    port map (
      clk_axi        => clk_axi,
      resetn_axi     => resetn_axi,
      timing_ctrl_i  => timing_ctrl_i,
      timing_stat_i  => timing_stat_i,
      timing_stat_o  => timing_stat_o,
      timing_ready_o => timing_ready_s
    );

  frontend_boundary_inst : entity work.frontend_boundary
    port map (
      clk_axi      => clk_axi,
      resetn_axi   => resetn_axi,
      prereq_i     => prereq_s,
      align_ctrl_i => align_ctrl_i,
      align_stat_i => align_stat_i,
      align_stat_o => align_stat_s
    );

  stream_pipeline_boundary_inst : entity work.stream_pipeline_boundary
    port map (
      clk             => clk,
      reset           => reset,
      readiness_i     => readiness_s,
      lanes_i         => ingress_lanes_i,
      lanes_o         => stream_lanes_s,
      stream_enable_o => stream_enable_o
    );

  spy_buffer_boundary_inst : entity work.spy_buffer_boundary
    port map (
      clk          => clk,
      reset        => reset,
      readiness_i  => readiness_s,
      spy_enable_o => spy_enable_o
    );

  hermes_boundary_inst : entity work.hermes_boundary
    port map (
      clk           => clk,
      reset         => reset,
      readiness_i   => readiness_s,
      lanes_i       => stream_lanes_s,
      lanes_o       => hermes_lanes_o,
      hermes_stat_o => hermes_stat_o
    );

  timing_ready_o <= timing_ready_s;
  align_stat_o   <= align_stat_s;
  stream_lanes_o <= stream_lanes_s;
end architecture rtl;
