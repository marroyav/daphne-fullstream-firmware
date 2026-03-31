library ieee;
use ieee.std_logic_1164.all;

package daphne_fullstream_subsystem_types_pkg is
  subtype subsystem_flag_t is std_logic;

  type subsystem_status_t is record
    enabled : subsystem_flag_t;
    ready   : subsystem_flag_t;
    error   : subsystem_flag_t;
  end record;

  constant SUBSYSTEM_STATUS_IDLE_C : subsystem_status_t := (
    enabled => '0',
    ready   => '0',
    error   => '0'
  );

  type frontend_tap_array_t is array (4 downto 0) of std_logic_vector(8 downto 0);
  type frontend_bitslip_array_t is array (4 downto 0) of std_logic_vector(3 downto 0);

  type frontend_alignment_control_t is record
    idelayctrl_reset : std_logic;
    iserdes_reset    : std_logic;
    idelay_en_vtc    : std_logic;
    idelay_tap       : frontend_tap_array_t;
    iserdes_bitslip  : frontend_bitslip_array_t;
  end record;

  type frontend_alignment_status_t is record
    idelayctrl_ready : std_logic;
    format_ok        : std_logic;
    training_ok      : std_logic;
    alignment_valid  : std_logic;
  end record;

  type frontend_prereq_t is record
    config_ready : std_logic;
    timing_ready : std_logic;
  end record;

  type timing_control_t is record
    use_endpoint_clock : std_logic;
    mmcm0_reset        : std_logic;
    mmcm1_reset        : std_logic;
    endpoint_reset     : std_logic;
    endpoint_addr      : std_logic_vector(15 downto 0);
  end record;

  type timing_status_t is record
    mmcm0_locked    : std_logic;
    mmcm1_locked    : std_logic;
    endpoint_ready  : std_logic;
    endpoint_state  : std_logic_vector(3 downto 0);
    timestamp_valid : std_logic;
  end record;

  type acquisition_readiness_t is record
    config_ready    : std_logic;
    timing_ready    : std_logic;
    alignment_ready : std_logic;
  end record;

  type stream_lane_t is record
    data  : std_logic_vector(63 downto 0);
    valid : std_logic;
    last  : std_logic;
  end record;

  type stream_lane_array_t is array (7 downto 0) of stream_lane_t;

  type hermes_boundary_status_t is record
    ready          : std_logic;
    backpressure   : std_logic;
    link_up        : std_logic;
    transport_busy : std_logic;
  end record;

  constant FRONTEND_ALIGNMENT_CONTROL_NULL : frontend_alignment_control_t := (
    idelayctrl_reset => '0',
    iserdes_reset    => '0',
    idelay_en_vtc    => '0',
    idelay_tap       => (others => (others => '0')),
    iserdes_bitslip  => (others => (others => '0'))
  );

  constant FRONTEND_ALIGNMENT_STATUS_NULL : frontend_alignment_status_t := (
    idelayctrl_ready => '0',
    format_ok        => '0',
    training_ok      => '0',
    alignment_valid  => '0'
  );

  constant FRONTEND_PREREQ_NULL : frontend_prereq_t := (
    config_ready => '0',
    timing_ready => '0'
  );

  constant TIMING_CONTROL_NULL : timing_control_t := (
    use_endpoint_clock => '0',
    mmcm0_reset        => '0',
    mmcm1_reset        => '0',
    endpoint_reset     => '0',
    endpoint_addr      => (others => '0')
  );

  constant TIMING_STATUS_NULL : timing_status_t := (
    mmcm0_locked    => '0',
    mmcm1_locked    => '0',
    endpoint_ready  => '0',
    endpoint_state  => (others => '0'),
    timestamp_valid => '0'
  );

  constant ACQUISITION_READINESS_NULL : acquisition_readiness_t := (
    config_ready    => '0',
    timing_ready    => '0',
    alignment_ready => '0'
  );

  constant STREAM_LANE_NULL : stream_lane_t := (
    data  => (others => '0'),
    valid => '0',
    last  => '0'
  );

  constant STREAM_LANE_ARRAY_NULL : stream_lane_array_t := (
    others => STREAM_LANE_NULL
  );

  constant HERMES_BOUNDARY_STATUS_NULL : hermes_boundary_status_t := (
    ready          => '0',
    backpressure   => '0',
    link_up        => '0',
    transport_busy => '0'
  );
end package daphne_fullstream_subsystem_types_pkg;

package body daphne_fullstream_subsystem_types_pkg is
end package body daphne_fullstream_subsystem_types_pkg;
