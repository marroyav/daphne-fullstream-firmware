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
end package daphne_fullstream_subsystem_types_pkg;

package body daphne_fullstream_subsystem_types_pkg is
end package body daphne_fullstream_subsystem_types_pkg;
