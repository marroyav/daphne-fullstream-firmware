library ieee;
use ieee.std_logic_1164.all;
use work.daphne_fullstream_subsystem_types_pkg.all;

entity stream_pipeline_boundary_formal is
  port (
    clk       : in std_logic;
    reset     : in std_logic;
    readiness : in acquisition_readiness_t
  );
end entity stream_pipeline_boundary_formal;

architecture formal of stream_pipeline_boundary_formal is
  signal stream_enable : std_logic;
begin
  dut : entity work.stream_pipeline_boundary
    port map (
      clk             => clk,
      reset           => reset,
      readiness_i     => readiness,
      stream_enable_o => stream_enable
    );

  assert stream_enable = (
    (not reset) and
    readiness.config_ready and
    readiness.timing_ready and
    readiness.alignment_ready
  )
    report "stream_enable_o must match the readiness conjunction"
    severity failure;

  assert (reset = '0') or (stream_enable = '0')
    report "stream_enable_o must stay low while reset is asserted"
    severity failure;

  assert (readiness.config_ready = '1') or (stream_enable = '0')
    report "stream_enable_o must stay low until configuration is ready"
    severity failure;

  assert (readiness.timing_ready = '1') or (stream_enable = '0')
    report "stream_enable_o must stay low until timing is ready"
    severity failure;

  assert (readiness.alignment_ready = '1') or (stream_enable = '0')
    report "stream_enable_o must stay low until alignment is ready"
    severity failure;
end architecture formal;
