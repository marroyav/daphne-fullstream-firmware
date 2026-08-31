-- Legacy entity name; this is the board-control AXI-Lite register block.
--
-- All offsets are byte offsets from the slave base address. Reserved bits read
-- as zero, unknown addresses read as zero, and writes require all four byte
-- strobes.
--
--   +0x00  fan PWM demand, bits 7:0, read/write; reset value 0xFF
--   +0x04  fan 0 speed in RPM, bits 11:0, read-only
--   +0x08  fan 1 speed in RPM, bits 11:0, read-only
--   +0x0C  high-voltage bias enable, bit 0, read/write
--   +0x10  analog mux enables, bits 1:0, read/write
--   +0x14  analog mux address, bits 1:0, read/write
--   +0x18  status LEDs, bits 5:0, read/write
--   +0x1C  firmware version nibble, bits 3:0, read-only
--   +0x20  legacy channel enables 31:0, read/write
--   +0x24  legacy channel enables 39:32, read/write
--   +0xF0  identity magic ("DAPH"), read-only
--   +0xF4  platform ABI version 2.0, read-only
--   +0xF8  gateware variant ID (2 = full-stream), read-only
--   +0xFC  zero-extended 28-bit build commit, read-only
--
-- The active full-stream datapath does not consume the legacy channel-enable
-- output. The registers remain readable for interface compatibility.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.daphne3_package.all;

entity stuff is
port(
    fan_tach: in  std_logic_vector(1 downto 0); -- fan tach speed monitoring
    fan_ctrl: out std_logic; -- pwm speed control common to both fans
    hvbias_en: out std_logic; -- high = high voltage bias generator is ON
    mux_en: out std_logic_vector(1 downto 0); -- analog mux enables
    mux_a: out std_logic_vector(1 downto 0); -- analog mux selects
    stat_led: out std_logic_vector(5 downto 0); -- general purpose LEDs
    version: in std_logic_vector(3 downto 0); -- low nibble of build commit
    build_id: in std_logic_vector(31 downto 0); -- zero-extended build commit
    core_chan_enable: out std_logic_vector(39 downto 0); -- legacy compatibility output
  
    -- AXI-LITE interface

	S_AXI_ACLK	    : in std_logic; -- assume this is 100MHz
	S_AXI_ARESETN	: in std_logic;
	S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	S_AXI_AWVALID	: in std_logic;
	S_AXI_AWREADY	: out std_logic;
	S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	S_AXI_WVALID	: in std_logic;
	S_AXI_WREADY	: out std_logic;
	S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	S_AXI_BVALID	: out std_logic;
	S_AXI_BREADY	: in std_logic;
	S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	S_AXI_ARVALID	: in std_logic;
	S_AXI_ARREADY	: out std_logic;
	S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	S_AXI_RVALID	: out std_logic;
	S_AXI_RREADY	: in std_logic
  );
end stuff;

architecture stuff_arch of stuff is

	signal axi_awaddr: std_logic_vector(31 downto 0);
	signal axi_awready: std_logic;
	signal axi_wready: std_logic;
	signal axi_bresp: std_logic_vector(1 downto 0);
	signal axi_bvalid: std_logic;
	signal axi_araddr: std_logic_vector(31 downto 0);
	signal axi_arready: std_logic;
	signal axi_rdata: std_logic_vector(31 downto 0);
	signal axi_rresp: std_logic_vector(1 downto 0);
	signal axi_rvalid: std_logic;
	signal reg_rden: std_logic;
	signal reg_wren: std_logic;
	signal reg_data_out:std_logic_vector(31 downto 0);
	signal aw_en: std_logic;
   
    signal reset: std_logic;
    signal fan_count_reg: std_logic_vector(11 downto 0) := X"000";
    signal fan_speed_cfg_reg: std_logic_vector(7 downto 0) := X"FF";
    signal fan_ctrl_reg: std_logic;
    signal fan0_rpm, fan1_rpm: std_logic_vector(11 downto 0);
    signal stat_led_reg: std_logic_vector(5 downto 0) := "000000";
    signal hvbias_en_reg: std_logic := '0';
    signal mux_a_reg, mux_en_reg: std_logic_vector(1 downto 0) := "00";
    signal core_enable_reg: std_logic_vector(39 downto 0);

    -- register offsets are relative to the base address specified for this AXI-LITE slave instance

    constant FANCTRL_OFFSET:       std_logic_vector(7 downto 0) := "00000000"; -- base+0x00
    constant FAN0SPD_OFFSET:       std_logic_vector(7 downto 0) := "00000100"; -- base+0x04
    constant FAN1SPD_OFFSET:       std_logic_vector(7 downto 0) := "00001000"; -- base+0x08
    constant HVBIAS_OFFSET:        std_logic_vector(7 downto 0) := "00001100"; -- base+0x0C
    constant MUXEN_OFFSET:         std_logic_vector(7 downto 0) := "00010000"; -- base+0x10
    constant MUXA_OFFSET:          std_logic_vector(7 downto 0) := "00010100"; -- base+0x14
    constant LED_OFFSET:           std_logic_vector(7 downto 0) := "00011000"; -- base+0x18
    constant VER_OFFSET:           std_logic_vector(7 downto 0) := "00011100"; -- base+0x1C
    constant CORE_EN_LO_OFFSET:    std_logic_vector(7 downto 0) := "00100000"; -- base+0x20
    constant CORE_EN_HI_OFFSET:    std_logic_vector(7 downto 0) := "00100100"; -- base+0x24
    constant FW_ID_MAGIC_OFFSET:   std_logic_vector(7 downto 0) := X"F0";
    constant FW_ABI_VERSION_OFFSET: std_logic_vector(7 downto 0) := X"F4";
    constant FW_VARIANT_ID_OFFSET: std_logic_vector(7 downto 0) := X"F8";
    constant FW_BUILD_ID_OFFSET:   std_logic_vector(7 downto 0) := X"FC";

    constant FW_ID_MAGIC_C:   std_logic_vector(31 downto 0) := X"44415048";
    constant FW_ABI_VERSION_C: std_logic_vector(31 downto 0) := X"00020000";
    constant FW_VARIANT_ID_C: std_logic_vector(31 downto 0) := X"00000002";

begin

reset <= not S_AXI_ARESETN;

-- fan pwm control logic

-- The fan speed is directly proportional to the duty cycle of the PWM signal. 
-- Internally the fans have an analog circuit to do this, so the fan speed is 
-- in theory infinitely adjustable.

-- The output fan_ctrl is inverted by Q2 on the board and is common to both fans.
--
-- if fan_ctrl=0 the fan PWM signal will be HIGH and fans run at FULL SPEED. 
-- if fan_ctrl=1 the PWM signal will be LOW and the fans will be STOPPED.
-- if fan_ctrl is 25kHz clock (high 25%, low 75%) then the fans will be running at 75%
-- if fan_ctrl is 25kHz clock (high 75%, low 25%) then the fans will be running at 25%

-- take the 100MHz AXI clock and divide it by 4096 to produce 24.4kHz clock
-- suitable for driving the fan speed pwm signal. duty cycle is controlled by
-- fan_speed_cfg_reg: 0 = fan off, 255 = fan full speed.

fanspeed_proc: process(S_AXI_ACLK)
begin
    if rising_edge(S_AXI_ACLK) then
        if (reset='1') then
            fan_count_reg <= (others=>'0');
            fan_ctrl_reg <= '0';
        else
            fan_count_reg <= std_logic_vector( unsigned(fan_count_reg) + 1 );
            if (fan_count_reg = X"000") then
                fan_ctrl_reg <= '1'; 
            elsif (fan_count_reg(11 downto 4)=fan_speed_cfg_reg) then
                fan_ctrl_reg <= '0';
            end if;
        end if;
    end if;
end process fanspeed_proc;

-- fan speed monitoring

fanmon0_inst: entity work.fanmon
port map( clock => S_AXI_ACLK, reset => reset, tach => fan_tach(0), rpm => fan0_rpm );

fanmon1_inst: entity work.fanmon
port map( clock => S_AXI_ACLK, reset => reset, tach => fan_tach(1), rpm => fan1_rpm );

-- AXI-LITE slave interface logic

S_AXI_AWREADY <= axi_awready;
S_AXI_WREADY <= axi_wready;
S_AXI_BRESP	<= axi_bresp;
S_AXI_BVALID <= axi_bvalid;
S_AXI_ARREADY <= axi_arready;
S_AXI_RDATA	<= axi_rdata;
S_AXI_RRESP	<= axi_rresp;
S_AXI_RVALID <= axi_rvalid;

-- Implement axi_awready generation
-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
-- de-asserted when reset is low.

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_awready <= '0';
      aw_en <= '1';
    else
      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
        -- slave is ready to accept write address when
        -- there is a valid write address and write data
        -- on the write address and data bus. This design 
        -- expects no outstanding transactions. 
           axi_awready <= '1';
           aw_en <= '0';
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
           aw_en <= '1';
           axi_awready <= '0';
      else
        axi_awready <= '0';
      end if;
    end if;
  end if;
end process;

-- Implement axi_awaddr latching
-- This process is used to latch the address when both 
-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_awaddr <= (others => '0');
    else
      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
        -- Write Address latching
        axi_awaddr <= S_AXI_AWADDR;
      end if;
    end if;
  end if;                   
end process; 

-- Implement axi_wready generation
-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
-- de-asserted when reset is low. 

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_wready <= '0';
    else
      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
          -- slave is ready to accept write data when 
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions.           
          axi_wready <= '1';
      else
        axi_wready <= '0';
      end if;
    end if;
  end if;
end process; 

-- Implement memory mapped register select and write logic generation
-- The write data is accepted and written to memory mapped registers when
-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
-- select byte enables of slave registers while writing.
-- These registers are cleared when reset (active low) is applied.
-- Slave register write enable is asserted when valid address and data are available
-- and the slave is ready to accept the write address and write data.

reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if (S_AXI_ARESETN = '0') then
        fan_speed_cfg_reg <= X"FF";
        hvbias_en_reg <= '0';
        mux_en_reg <= "00";
        mux_a_reg <= "00";
        stat_led_reg <= "000000";
        core_enable_reg <= DEFAULT_core_enable;
    else
      if (reg_wren = '1' and S_AXI_WSTRB = "1111") then

        -- treat all of these register writes as if they are full 32 bits
        -- e.g. the four write strobe bits should be high

        case ( axi_awaddr(7 downto 0) ) is

          when FANCTRL_OFFSET => 
            fan_speed_cfg_reg <= S_AXI_WDATA(7 downto 0);

          when HVBIAS_OFFSET => 
            hvbias_en_reg <= S_AXI_WDATA(0);

          when MUXEN_OFFSET => 
            mux_en_reg <= S_AXI_WDATA(1 downto 0);

          when MUXA_OFFSET => 
            mux_a_reg <= S_AXI_WDATA(1 downto 0);

          when LED_OFFSET => 
            stat_led_reg <= S_AXI_WDATA(5 downto 0);

          when CORE_EN_LO_OFFSET => 
            core_enable_reg(31 downto 0) <= S_AXI_WDATA(31 downto 0);

          when CORE_EN_HI_OFFSET => 
            core_enable_reg(39 downto 32) <= S_AXI_WDATA(7 downto 0);

          when others =>
            null;
             
        end case;

      end if;
    end if;
  end if;                   
end process; 

-- Implement write response logic generation
-- The write response and response valid signals are asserted by the slave 
-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
-- This marks the acceptance of address and indicates the status of 
-- write transaction.

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_bvalid  <= '0';
      axi_bresp   <= "00"; --need to work more on the responses
    else
      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
        axi_bvalid <= '1';
        axi_bresp  <= "00"; 
      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
        axi_bvalid <= '0';                                   -- (there is a possibility that bready is always asserted high)
      end if;
    end if;
  end if;                   
end process; 

-- Implement axi_arready generation
-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
-- S_AXI_ARVALID is asserted. axi_awready is 
-- de-asserted when reset (active low) is asserted. 
-- The read address is also latched when S_AXI_ARVALID is 
-- asserted. axi_araddr is reset to zero on reset assertion.

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_arready <= '0';
      axi_araddr  <= (others => '1');
    else
      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
        -- indicates that the slave has accepted the valid read address
        axi_arready <= '1';
        -- Read Address latching 
        axi_araddr  <= S_AXI_ARADDR;           
      else
        axi_arready <= '0';
      end if;
    end if;
  end if;                   
end process; 

-- Implement axi_arvalid generation
-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
-- data are available on the axi_rdata bus at this instance. The 
-- assertion of axi_rvalid marks the validity of read data on the 
-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
-- cleared to zero on reset (active low). 

process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then
    if S_AXI_ARESETN = '0' then
      axi_rvalid <= '0';
      axi_rresp  <= "00";
    else
      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
        -- Valid read data is available at the read data bus
        axi_rvalid <= '1';
        axi_rresp  <= "00"; -- 'OKAY' response
      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
        -- Read data is accepted by the master
        axi_rvalid <= '0';
      end if;            
    end if;
  end if;
end process;

-- Implement memory mapped register select and read logic generation
-- Slave register read enable is asserted when valid address is available
-- and the slave is ready to accept the read address.
-- Keep the read mux explicit: each register occupies the low documented bits,
-- and every reserved bit has a deterministic zero value.

reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

read_mux_proc : process(
    axi_araddr,
    fan_speed_cfg_reg,
    fan0_rpm,
    fan1_rpm,
    hvbias_en_reg,
    mux_en_reg,
    mux_a_reg,
    stat_led_reg,
    version,
    build_id,
    core_enable_reg
) is
begin
    reg_data_out <= (others => '0');

    case axi_araddr(7 downto 0) is
        when FANCTRL_OFFSET =>
            reg_data_out(7 downto 0) <= fan_speed_cfg_reg;
        when FAN0SPD_OFFSET =>
            reg_data_out(11 downto 0) <= fan0_rpm;
        when FAN1SPD_OFFSET =>
            reg_data_out(11 downto 0) <= fan1_rpm;
        when HVBIAS_OFFSET =>
            reg_data_out(0) <= hvbias_en_reg;
        when MUXEN_OFFSET =>
            reg_data_out(1 downto 0) <= mux_en_reg;
        when MUXA_OFFSET =>
            reg_data_out(1 downto 0) <= mux_a_reg;
        when LED_OFFSET =>
            reg_data_out(5 downto 0) <= stat_led_reg;
        when VER_OFFSET =>
            reg_data_out(3 downto 0) <= version;
        when CORE_EN_LO_OFFSET =>
            reg_data_out <= core_enable_reg(31 downto 0);
        when CORE_EN_HI_OFFSET =>
            reg_data_out(7 downto 0) <= core_enable_reg(39 downto 32);
        when FW_ID_MAGIC_OFFSET =>
            reg_data_out <= FW_ID_MAGIC_C;
        when FW_ABI_VERSION_OFFSET =>
            reg_data_out <= FW_ABI_VERSION_C;
        when FW_VARIANT_ID_OFFSET =>
            reg_data_out <= FW_VARIANT_ID_C;
        when FW_BUILD_ID_OFFSET =>
            reg_data_out <= X"0" & build_id(27 downto 0);
        when others =>
            null;
    end case;
end process read_mux_proc;

-- Output register or memory read data
process( S_AXI_ACLK ) is
begin
  if (rising_edge (S_AXI_ACLK)) then
    if ( S_AXI_ARESETN = '0' ) then
      axi_rdata  <= (others => '0');
    else
      if (reg_rden = '1') then
        -- When there is a valid read address (S_AXI_ARVALID) with 
        -- acceptance of read address by the slave (axi_arready), 
        -- output the read data
        -- Read address mux
          axi_rdata <= reg_data_out; -- register read data
      end if;   
    end if;
  end if;
end process;

-- assign registers to the outputs

fan_ctrl <= not fan_ctrl_reg; -- compensate for inverter Q2 on the board
mux_a <= mux_a_reg;
mux_en <= mux_en_reg;
hvbias_en <= hvbias_en_reg;
stat_led <= stat_led_reg; -- PL general board LEDs active high
core_chan_enable <= core_enable_reg;

end stuff_arch;
