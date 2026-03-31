library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity timing_subsystem_boundary_formal is
  port (
    clk_axi     : in std_logic;
    resetn_axi  : in std_logic;
    timing_ctrl : in timing_control_t;
    timing_stat : in timing_status_t
  );
end entity timing_subsystem_boundary_formal;

architecture formal of timing_subsystem_boundary_formal is
  signal timing_stat_o  : timing_status_t;
  signal timing_ready_o : std_logic;
begin
  dut : entity work.timing_subsystem_boundary
    port map (
      clk_axi        => clk_axi,
      resetn_axi     => resetn_axi,
      timing_ctrl_i  => timing_ctrl,
      timing_stat_i  => timing_stat,
      timing_stat_o  => timing_stat_o,
      timing_ready_o => timing_ready_o
    );

  assert timing_stat_o = timing_stat
    report "timing boundary must pass through raw timing status"
    severity failure;

  assert timing_ready_o = (
    resetn_axi and
    timing_stat.mmcm0_locked and
    timing_stat.mmcm1_locked and
    (
      (not timing_ctrl.use_endpoint_clock) or
      (timing_stat.endpoint_ready and timing_stat.timestamp_valid)
    )
  )
    report "timing_ready_o must match the documented readiness formula"
    severity failure;

  assert (resetn_axi = '1') or (timing_ready_o = '0')
    report "timing_ready_o must stay low while reset is asserted"
    severity failure;

  assert (timing_stat.mmcm0_locked = '1') or (timing_ready_o = '0')
    report "timing_ready_o must stay low until MMCM0 locks"
    severity failure;

  assert (timing_stat.mmcm1_locked = '1') or (timing_ready_o = '0')
    report "timing_ready_o must stay low until MMCM1 locks"
    severity failure;

  assert (timing_ctrl.use_endpoint_clock = '0') or
         (timing_stat.endpoint_ready = '1') or
         (timing_ready_o = '0')
    report "endpoint-clock mode requires endpoint_ready"
    severity failure;

  assert (timing_ctrl.use_endpoint_clock = '0') or
         (timing_stat.timestamp_valid = '1') or
         (timing_ready_o = '0')
    report "endpoint-clock mode requires timestamp_valid"
    severity failure;
end architecture formal;
