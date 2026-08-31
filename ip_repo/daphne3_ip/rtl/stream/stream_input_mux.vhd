-- stream_input_mux.vhd
-- For DAPHNE_MEZZ streaming sender
-- 5x9 input buses -> 8x4 output buses 
-- 32 8-bit registers for control, these are R/W
-- Jamieson Olsen <jamieson@fnal.gov>
--
-- axi-lite memory map:
--
-- address      description
--
-- base+0x00    select register for dout(0)(0)
-- base+0x04    select register for dout(0)(1)
-- base+0x08    select register for dout(0)(2)
-- base+0x0C    select register for dout(0)(3)
--
-- base+0x10    select register for dout(1)(0)
-- base+0x14    select register for dout(1)(1)
-- base+0x18    select register for dout(1)(2)
-- base+0x1C    select register for dout(1)(3)
--
-- base+0x20    select register for dout(2)(0)
-- base+0x24    select register for dout(2)(1)
-- base+0x28    select register for dout(2)(2)
-- base+0x2C    select register for dout(2)(3)
--
-- base+0x30    select register for dout(3)(0)
-- base+0x34    select register for dout(3)(1)
-- base+0x38    select register for dout(3)(2)
-- base+0x3C    select register for dout(3)(3)
--
-- base+0x40    select register for dout(4)(0)
-- base+0x44    select register for dout(4)(1)
-- base+0x48    select register for dout(4)(2)
-- base+0x4C    select register for dout(4)(3)
--
-- base+0x50    select register for dout(5)(0)
-- base+0x54    select register for dout(5)(1)
-- base+0x58    select register for dout(5)(2)
-- base+0x5C    select register for dout(5)(3)
--
-- base+0x60    select register for dout(6)(0)
-- base+0x64    select register for dout(6)(1)
-- base+0x68    select register for dout(6)(2)
-- base+0x6C    select register for dout(6)(3)
--
-- base+0x70    select register for dout(7)(0)
-- base+0x74    select register for dout(7)(1)
-- base+0x78    select register for dout(7)(2)
-- base+0x7C    select register for dout(7)(3)
-- base+0x80    activation control/status: bit 0 requested, bit 1 active
--
-- The select register (muxctrl_reg) is 8 bits: the upper nibble specifies
-- the AFE chip number (0 to 4) and the lower nibble specifies
-- the AFE channel number (0 to 8). Note that AFE channel 8 is the
-- fixed "frame" pattern. there are a few special diagnostic modes
-- in this module, write 0x5* to activate these modes
-- (scroll down for details on what these modes are).
-- The selector words are AXI-clock-domain shadow registers. They reset to
-- 0xFF and do not affect the streaming datapath until software writes 1 to
-- activation-control bit 0. Writing 0 requests a fail-closed disabled state.
--
-- some examples:
--   connect output(0)(3) to AFE3,ch3 --> write 0x33 to address base+0x0C
--   connect output(4)(2) to AFE4,ch2 --> write 0x42 to address base+0x48
--   generate random pattern on output(7)(1) --> write 0x55 to address base+0x74
--   generate counter on output(5)(3) --> write 0x54 to address base+0x5C
--   turn off output(3)(2) --> write 0xFF to address base+0x38
--
-- remember: in the streaming mode sender this module determines what data is sent
-- to the core. it does NOT control what the input spy buffers see!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.daphne3_package.all;

entity stream_input_mux is
port(
    clock: in std_logic; -- 62.5MHz master clock
    din: in array_5x9x16_type; -- from the front end
    dout: out array_8x4x14_type;
    muxctrl: out array_8x4x8_type;
    stream_enable: out std_logic; -- stream-domain committed/active state
    AXI_IN: in AXILITE_INREC;
    AXI_OUT: out AXILITE_OUTREC
  );
end stream_input_mux;

architecture stream_input_mux_arch of stream_input_mux is

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
signal axi_arready_reg: std_logic;
signal axi_arvalid: std_logic;    
signal reg_rden: std_logic;
signal reg_wren: std_logic;
signal reg_data_out:std_logic_vector(31 downto 0);
signal aw_en: std_logic;

-- AXI-domain configuration bank and enable request. The stream-domain bank is
-- captured as one bundled-data word only after the synchronized request rises.
signal muxctrl_reg: array_8x4x8_type; -- shadow: AFE number/channel nibble encoding
signal mux_enable_request_axi: std_logic;

signal mux_enable_request_meta: std_logic;
signal mux_enable_request_sync: std_logic;
signal mux_enable_request_sync_d: std_logic;
signal stream_resetn_meta: std_logic;
signal stream_resetn_sync: std_logic;
signal muxctrl_active_reg: array_8x4x8_type;
signal mux_active_stream: std_logic;

signal mux_active_ack_meta: std_logic;
signal mux_active_ack_sync: std_logic;

attribute ASYNC_REG: string;
attribute ASYNC_REG of mux_enable_request_meta: signal is "TRUE";
attribute ASYNC_REG of mux_enable_request_sync: signal is "TRUE";
attribute ASYNC_REG of stream_resetn_meta: signal is "TRUE";
attribute ASYNC_REG of stream_resetn_sync: signal is "TRUE";
attribute ASYNC_REG of mux_active_ack_meta: signal is "TRUE";
attribute ASYNC_REG of mux_active_ack_sync: signal is "TRUE";

signal counter_reg: std_logic_vector(13 downto 0) := "00000000000000";
signal rand_reg:    std_logic_vector(13 downto 0) := "00100111010101";

begin

-- make a few test counters for debugging
-- rand_reg is LFSR with taps selected for max run length

counter_proc: process(clock)
begin
    if rising_edge(clock) then
        counter_reg <= std_logic_vector( unsigned(counter_reg) + 1 );
        rand_reg  <= rand_reg(12 downto 0) & (rand_reg(13) xor rand_reg(12) xor rand_reg(10) xor rand_reg(7));
    end if;
end process counter_proc;

-- big old programmable mux: 5x9 inputs ---> 8x4 outputs
-- This is controlled by the active stream-domain selector bank. Software
-- reads and writes the separate AXI-domain shadow bank.
--
-- some examples:
-- if muxctrl(2)(3)=X"07" then dout(2)(3) is connected to din(0)(7)
-- if muxctrl(4)(1)=X"3B" then dout(4)(1) is forced to all zeros
-- if muxctrl(5)(1)=X"55" then dout(5)(1) is a pseudorandom pattern

-- do the 16->14 bit truncation here

gen_send: for s in 7 downto 0 generate
    gen_chan: for c in 3 downto 0 generate

        stream_mux_select_inst: entity work.stream_mux_select
        port map(
            din => din,
            muxctrl => muxctrl_active_reg(s)(c),
            counter => counter_reg,
            rand => rand_reg,
            dout => dout(s)(c)
          );

    end generate gen_chan;
end generate gen_send;

-- Assert fail-closed reset asynchronously and release it synchronously in the
-- stream domain. This prevents AXI reset deassertion from becoming another
-- asynchronous control input to the active selector bank.
stream_reset_sync_proc: process(clock, AXI_IN.ARESETN)
begin
  if AXI_IN.ARESETN = '0' then
    stream_resetn_meta <= '0';
    stream_resetn_sync <= '0';
  elsif rising_edge(clock) then
    stream_resetn_meta <= '1';
    stream_resetn_sync <= stream_resetn_meta;
  end if;
end process stream_reset_sync_proc;

-- Synchronize the level request into the 62.5 MHz stream domain. The 256-bit
-- selector bank intentionally uses a bundled-data CDC: software writes every
-- shadow word before asserting the request, and must leave the bank unchanged
-- until active acknowledgement returns. The two request synchronizer stages
-- provide settling time before the complete bank is captured on one stream
-- clock edge. To recommit, software must disable and wait for acknowledgement
-- before modifying the bank and asserting the request again.
stream_activation_proc: process(clock, stream_resetn_sync)
begin
  if stream_resetn_sync = '0' then
    mux_enable_request_meta <= '0';
    mux_enable_request_sync <= '0';
    mux_enable_request_sync_d <= '0';
    muxctrl_active_reg <= (others => (others => X"FF"));
    mux_active_stream <= '0';
  elsif rising_edge(clock) then
    mux_enable_request_meta <= mux_enable_request_axi;
    mux_enable_request_sync <= mux_enable_request_meta;
    mux_enable_request_sync_d <= mux_enable_request_sync;

    if mux_enable_request_sync = '0' then
      muxctrl_active_reg <= (others => (others => X"FF"));
      mux_active_stream <= '0';
    elsif mux_enable_request_sync_d = '0' then
      -- Atomic stream-domain capture; the shadow bank is stable by protocol.
      muxctrl_active_reg <= muxctrl_reg;
      mux_active_stream <= '1';
    end if;
  end if;
end process stream_activation_proc;

-- Return stream-domain active/disabled state through a conventional two-flop
-- synchronizer. Bit 1 at base+0x80 is authoritative before software starts or
-- stops data flow; bit 0 is only the AXI-domain request.
activation_ack_proc: process(AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then
    if AXI_IN.ARESETN = '0' then
      mux_active_ack_meta <= '0';
      mux_active_ack_sync <= '0';
    else
      mux_active_ack_meta <= mux_active_stream;
      mux_active_ack_sync <= mux_active_ack_meta;
    end if;
  end if;
end process activation_ack_proc;

-- AXI-LITE slave interface logic

--reset <= not AXI_IN.ARESETN;

AXI_OUT.AWREADY <= axi_awready;
AXI_OUT.WREADY <= axi_wready;
AXI_OUT.BRESP <= axi_bresp;
AXI_OUT.BVALID <= axi_bvalid;
AXI_OUT.ARREADY <= axi_arready;
AXI_OUT.RDATA <= axi_rdata;
AXI_OUT.RRESP <= axi_rresp;
AXI_OUT.RVALID <= axi_rvalid;

-- Implement axi_awready generation
-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
-- de-asserted when reset is low.

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if (AXI_IN.ARESETN = '0') then
      axi_awready <= '0';
      aw_en <= '1';
    else
      if (axi_awready = '0' and AXI_IN.AWVALID = '1' and AXI_IN.WVALID = '1' and aw_en = '1') then
        -- slave is ready to accept write address when
        -- there is a valid write address and write data
        -- on the write address and data bus. This design 
        -- expects no outstanding transactions. 
           axi_awready <= '1';
           aw_en <= '0';
        elsif (AXI_IN.BREADY = '1' and axi_bvalid = '1') then
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

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if (AXI_IN.ARESETN = '0') then
      axi_awaddr <= (others => '0');
    else
      if (axi_awready = '0' and AXI_IN.AWVALID = '1' and AXI_IN.WVALID = '1' and aw_en = '1') then
        -- Write Address latching
        axi_awaddr <= AXI_IN.AWADDR;
      end if;
    end if;
  end if;                   
end process; 

-- Implement axi_wready generation
-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
-- de-asserted when reset is low. 

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if (AXI_IN.ARESETN = '0') then
      axi_wready <= '0';
    else
      if (axi_wready = '0' and AXI_IN.WVALID = '1' and AXI_IN.AWVALID = '1' and aw_en = '1') then
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

reg_wren <= axi_wready and AXI_IN.WVALID and axi_awready and AXI_IN.AWVALID ;

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if (AXI_IN.ARESETN = '0') then 

        -- Fail-safe default: no frontend or diagnostic source is selected.
        muxctrl_reg(0)(0) <= X"FF";
        muxctrl_reg(0)(1) <= X"FF";
        muxctrl_reg(0)(2) <= X"FF";
        muxctrl_reg(0)(3) <= X"FF";

        muxctrl_reg(1)(0) <= X"FF";
        muxctrl_reg(1)(1) <= X"FF";
        muxctrl_reg(1)(2) <= X"FF";
        muxctrl_reg(1)(3) <= X"FF";

        muxctrl_reg(2)(0) <= X"FF";
        muxctrl_reg(2)(1) <= X"FF";
        muxctrl_reg(2)(2) <= X"FF";
        muxctrl_reg(2)(3) <= X"FF";

        muxctrl_reg(3)(0) <= X"FF";
        muxctrl_reg(3)(1) <= X"FF";
        muxctrl_reg(3)(2) <= X"FF";
        muxctrl_reg(3)(3) <= X"FF";

        muxctrl_reg(4)(0) <= X"FF";
        muxctrl_reg(4)(1) <= X"FF";
        muxctrl_reg(4)(2) <= X"FF";
        muxctrl_reg(4)(3) <= X"FF";

        muxctrl_reg(5)(0) <= X"FF";
        muxctrl_reg(5)(1) <= X"FF";
        muxctrl_reg(5)(2) <= X"FF";
        muxctrl_reg(5)(3) <= X"FF";

        muxctrl_reg(6)(0) <= X"FF";
        muxctrl_reg(6)(1) <= X"FF";
        muxctrl_reg(6)(2) <= X"FF";
        muxctrl_reg(6)(3) <= X"FF";

        muxctrl_reg(7)(0) <= X"FF";
        muxctrl_reg(7)(1) <= X"FF";
        muxctrl_reg(7)(2) <= X"FF";
        muxctrl_reg(7)(3) <= X"FF";

        mux_enable_request_axi <= '0';

    else
      if (reg_wren = '1' and AXI_IN.WSTRB = "1111") then

        -- treat all of these register WRITES as if they are full 32 bits
        -- e.g. the four write strobe bits should be high

        case ( axi_awaddr(7 downto 0) ) is

          when X"00" => muxctrl_reg(0)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"04" => muxctrl_reg(0)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"08" => muxctrl_reg(0)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"0C" => muxctrl_reg(0)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"10" => muxctrl_reg(1)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"14" => muxctrl_reg(1)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"18" => muxctrl_reg(1)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"1C" => muxctrl_reg(1)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"20" => muxctrl_reg(2)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"24" => muxctrl_reg(2)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"28" => muxctrl_reg(2)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"2C" => muxctrl_reg(2)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"30" => muxctrl_reg(3)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"34" => muxctrl_reg(3)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"38" => muxctrl_reg(3)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"3C" => muxctrl_reg(3)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"40" => muxctrl_reg(4)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"44" => muxctrl_reg(4)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"48" => muxctrl_reg(4)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"4C" => muxctrl_reg(4)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"50" => muxctrl_reg(5)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"54" => muxctrl_reg(5)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"58" => muxctrl_reg(5)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"5C" => muxctrl_reg(5)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"60" => muxctrl_reg(6)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"64" => muxctrl_reg(6)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"68" => muxctrl_reg(6)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"6C" => muxctrl_reg(6)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"70" => muxctrl_reg(7)(0) <= AXI_IN.WDATA(7 downto 0);
          when X"74" => muxctrl_reg(7)(1) <= AXI_IN.WDATA(7 downto 0);
          when X"78" => muxctrl_reg(7)(2) <= AXI_IN.WDATA(7 downto 0);
          when X"7C" => muxctrl_reg(7)(3) <= AXI_IN.WDATA(7 downto 0);

          when X"80" => mux_enable_request_axi <= AXI_IN.WDATA(0);

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

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if AXI_IN.ARESETN = '0' then
      axi_bvalid  <= '0';
      axi_bresp   <= "00"; --need to work more on the responses
    else
      if (axi_awready = '1' and AXI_IN.AWVALID = '1' and axi_wready = '1' and AXI_IN.WVALID = '1' and axi_bvalid = '0'  ) then
        axi_bvalid <= '1';
        axi_bresp  <= "00"; 
      elsif (AXI_IN.BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
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

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then 
    if (AXI_IN.ARESETN) = '0' then
      axi_arready <= '0';
      axi_araddr  <= (others => '1');
    else
      if (axi_arready = '0' and AXI_IN.ARVALID = '1') then
        -- indicates that the slave has accepted the valid read address
        axi_arready <= '1';
        -- Read Address latching 
        axi_araddr  <= AXI_IN.ARADDR;           
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

process (AXI_IN.ACLK)
begin
  if rising_edge(AXI_IN.ACLK) then
    if (AXI_IN.ARESETN = '0') then
      axi_rvalid <= '0';
      axi_rresp  <= "00";
    else
      if (axi_arready = '1' and AXI_IN.ARVALID = '1' and axi_rvalid = '0') then
        -- Valid read data is available at the read data bus
        axi_rvalid <= '1';
        axi_rresp  <= "00"; -- 'OKAY' response
      elsif (axi_rvalid = '1' and AXI_IN.RREADY = '1') then
        -- Read data is accepted by the master
        axi_rvalid <= '0';
      end if;            
    end if;
  end if;
end process;

-- Implement memory mapped register select and read logic generation
-- Slave register read enable is asserted when valid address is available
-- and the slave is ready to accept the read address.
-- reg_data_out is 32 bits

reg_rden <= axi_arready and AXI_IN.ARVALID and (not axi_rvalid) ;

reg_data_out <= (X"000000" & muxctrl_reg(0)(0)) when (axi_araddr(7 downto 0)=X"00") else
                (X"000000" & muxctrl_reg(0)(1)) when (axi_araddr(7 downto 0)=X"04") else
                (X"000000" & muxctrl_reg(0)(2)) when (axi_araddr(7 downto 0)=X"08") else
                (X"000000" & muxctrl_reg(0)(3)) when (axi_araddr(7 downto 0)=X"0C") else

                (X"000000" & muxctrl_reg(1)(0)) when (axi_araddr(7 downto 0)=X"10") else
                (X"000000" & muxctrl_reg(1)(1)) when (axi_araddr(7 downto 0)=X"14") else
                (X"000000" & muxctrl_reg(1)(2)) when (axi_araddr(7 downto 0)=X"18") else
                (X"000000" & muxctrl_reg(1)(3)) when (axi_araddr(7 downto 0)=X"1C") else

                (X"000000" & muxctrl_reg(2)(0)) when (axi_araddr(7 downto 0)=X"20") else
                (X"000000" & muxctrl_reg(2)(1)) when (axi_araddr(7 downto 0)=X"24") else
                (X"000000" & muxctrl_reg(2)(2)) when (axi_araddr(7 downto 0)=X"28") else
                (X"000000" & muxctrl_reg(2)(3)) when (axi_araddr(7 downto 0)=X"2C") else

                (X"000000" & muxctrl_reg(3)(0)) when (axi_araddr(7 downto 0)=X"30") else
                (X"000000" & muxctrl_reg(3)(1)) when (axi_araddr(7 downto 0)=X"34") else
                (X"000000" & muxctrl_reg(3)(2)) when (axi_araddr(7 downto 0)=X"38") else
                (X"000000" & muxctrl_reg(3)(3)) when (axi_araddr(7 downto 0)=X"3C") else

                (X"000000" & muxctrl_reg(4)(0)) when (axi_araddr(7 downto 0)=X"40") else
                (X"000000" & muxctrl_reg(4)(1)) when (axi_araddr(7 downto 0)=X"44") else
                (X"000000" & muxctrl_reg(4)(2)) when (axi_araddr(7 downto 0)=X"48") else
                (X"000000" & muxctrl_reg(4)(3)) when (axi_araddr(7 downto 0)=X"4C") else

                (X"000000" & muxctrl_reg(5)(0)) when (axi_araddr(7 downto 0)=X"50") else
                (X"000000" & muxctrl_reg(5)(1)) when (axi_araddr(7 downto 0)=X"54") else
                (X"000000" & muxctrl_reg(5)(2)) when (axi_araddr(7 downto 0)=X"58") else
                (X"000000" & muxctrl_reg(5)(3)) when (axi_araddr(7 downto 0)=X"5C") else

                (X"000000" & muxctrl_reg(6)(0)) when (axi_araddr(7 downto 0)=X"60") else
                (X"000000" & muxctrl_reg(6)(1)) when (axi_araddr(7 downto 0)=X"64") else
                (X"000000" & muxctrl_reg(6)(2)) when (axi_araddr(7 downto 0)=X"68") else
                (X"000000" & muxctrl_reg(6)(3)) when (axi_araddr(7 downto 0)=X"6C") else

                (X"000000" & muxctrl_reg(7)(0)) when (axi_araddr(7 downto 0)=X"70") else
                (X"000000" & muxctrl_reg(7)(1)) when (axi_araddr(7 downto 0)=X"74") else
                (X"000000" & muxctrl_reg(7)(2)) when (axi_araddr(7 downto 0)=X"78") else
                (X"000000" & muxctrl_reg(7)(3)) when (axi_araddr(7 downto 0)=X"7C") else

                (X"0000000" & "00" & mux_active_ack_sync & mux_enable_request_axi)
                                                   when (axi_araddr(7 downto 0)=X"80") else

                X"00000000";

-- Output register or memory read data
process( AXI_IN.ACLK ) is
begin
  if (rising_edge (AXI_IN.ACLK)) then
    if ( AXI_IN.ARESETN = '0' ) then
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

-- Export only the atomically captured stream-domain bank. Disabled/reset state
-- stores FF in every active selector, which also makes stream_mux_select drive
-- every payload output to zero.

muxctrl <= muxctrl_active_reg;
stream_enable <= mux_active_stream;

end stream_input_mux_arch;
