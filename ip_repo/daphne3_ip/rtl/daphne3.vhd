-- DAPHNE3.vhd
--
-- Kria PL TOP LEVEL. This REPLACES the top level graphical block.
--
-- Build this with the TCL script from the command line (aka Vivado NON PROJECT MODE)
-- see the github README file for details

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  

library unisim;
use unisim.vcomponents.all;

use work.daphne3_package.all;

entity DAPHNE3 is
generic(


    N_SRC: positive  := 2;   -- each mux has 2 inputs
    N_MGT: positive  := 4;    -- four transceivers
    version: std_logic_vector(3 downto 0) := X"1" ;  -- low nibble of build commit
    build_id: std_logic_vector(31 downto 0) := X"01234567"; -- zero-extended build commit
    link_id: std_logic_vector(5 downto 0) := "000000";
    slot_id: std_logic_vector(3 downto 0) := X"2";
    crate_id: std_logic_vector(9 downto 0) := "0000000011";
    detector_id: std_logic_vector(5 downto 0) := "000010";
    threshold: in std_logic_vector(9 downto 0):= "1000000000";
    version_id: std_logic_vector(5 downto 0) := "000001");  -- build virsion - to be updated everytime we build a new image
port(
            
          
    -- misc PL external connections
    sysclk100:   in std_logic;
    sysclk_p, sysclk_n: in  std_logic; -- 100MHz system clock from the clock generator chip (LVDS)
    fan_tach: in std_logic_vector(1 downto 0); -- fan tach speed sensors
    fan_ctrl: out std_logic; -- pwm fan speed control
    stat_led: out std_logic_vector(5 downto 0); -- general status LEDs
    hvbias_en: out std_logic; -- enable HV bias source
    mux_en: out std_logic_vector(1 downto 0); -- analog mux enables
    mux_a: out std_logic_vector(1 downto 0); -- analog mux addr selects
    gpi: in std_logic; -- testpoint input

    -- optical timing endpoint interface signals

    sfp_tmg_los: in std_logic; -- loss of signal is active high
    rx0_tmg_p, rx0_tmg_n: in std_logic; -- received serial data "LVDS"
    sfp_tmg_tx_dis: out std_logic; -- high to disable timing SFP TX
    tx0_tmg_p, tx0_tmg_n: out std_logic; -- serial data to TX to the timing master

    -- AFE LVDS high speed data interface 

    afe0_p, afe0_n: in std_logic_vector(8 downto 0);
    afe1_p, afe1_n: in std_logic_vector(8 downto 0);
    afe2_p, afe2_n: in std_logic_vector(8 downto 0);
    afe3_p, afe3_n: in std_logic_vector(8 downto 0);
    afe4_p, afe4_n: in std_logic_vector(8 downto 0);

    -- 62.5MHz master clock sent to AFEs (LVDS)

    afe_clk_p, afe_clk_n: out std_logic; 

    -- I2C master (for many different devices)

  



    -- SPI master (for 3 DACs)

    dac_sclk:   out std_logic;
    dac_din:    out std_logic;
    dac_sync_n: out std_logic;
    dac_ldac_n: out std_logic;

    -- SPI master (for AFEs and associated DACs)

    afe_rst: out std_logic; -- high = hard reset all AFEs
    afe_pdn: out std_logic; -- low = power down all AFEs

    afe0_miso: in std_logic;
    afe0_sclk: out std_logic;
    afe0_mosi: out std_logic;

    afe12_miso: in std_logic;
    afe12_sclk: out std_logic;
    afe12_mosi: out std_logic;

    afe34_miso: in std_logic;
    afe34_sclk: out std_logic;
    afe34_mosi: out std_logic;

    afe_sen: out std_logic_vector(4 downto 0);
    trim_sync_n: out std_logic_vector(4 downto 0);
    trim_ldac_n: out std_logic_vector(4 downto 0);
    offset_sync_n: out std_logic_vector(4 downto 0);
    offset_ldac_n: out std_logic_vector(4 downto 0);
    
    -- front end AXI----------
    trig_IN: in std_logic;
    FRONT_END_S_AXI_ACLK: in std_logic;
    FRONT_END_S_AXI_ARESETN: in std_logic;
    FRONT_END_S_AXI_AWADDR: in std_logic_vector(31 downto 0);
    FRONT_END_S_AXI_AWPROT: in std_logic_vector(2 downto 0);
    FRONT_END_S_AXI_AWVALID: in std_logic;
    FRONT_END_S_AXI_AWREADY: out std_logic;
    FRONT_END_S_AXI_WDATA: in std_logic_vector(31 downto 0);
    FRONT_END_S_AXI_WSTRB: in std_logic_vector(3 downto 0);
    FRONT_END_S_AXI_WVALID: in std_logic;
    FRONT_END_S_AXI_WREADY: out std_logic;
    FRONT_END_S_AXI_BRESP: out std_logic_vector(1 downto 0);
    FRONT_END_S_AXI_BVALID: out std_logic;
    FRONT_END_S_AXI_BREADY: in std_logic;
    FRONT_END_S_AXI_ARADDR: in std_logic_vector(31 downto 0);
    FRONT_END_S_AXI_ARPROT: in std_logic_vector(2 downto 0);
    FRONT_END_S_AXI_ARVALID: in std_logic;
    FRONT_END_S_AXI_ARREADY: out std_logic;
    FRONT_END_S_AXI_RDATA: out std_logic_vector(31 downto 0);
    FRONT_END_S_AXI_RRESP: out std_logic_vector(1 downto 0);
    FRONT_END_S_AXI_RVALID: out std_logic;
    FRONT_END_S_AXI_RREADY: in std_logic;


-- SPY BUFF AXI

    SPY_BUF_S_S_AXI_ACLK: in std_logic;
    SPY_BUF_S_S_AXI_ARESETN: in std_logic;
	SPY_BUF_S_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	SPY_BUF_S_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	SPY_BUF_S_S_AXI_AWVALID	: in std_logic;
	SPY_BUF_S_S_AXI_AWREADY	: out std_logic;
	SPY_BUF_S_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	SPY_BUF_S_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	SPY_BUF_S_S_AXI_WVALID	: in std_logic;
	SPY_BUF_S_S_AXI_WREADY	: out std_logic;
	SPY_BUF_S_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	SPY_BUF_S_S_AXI_BVALID	: out std_logic;
	SPY_BUF_S_S_AXI_BREADY	: in std_logic;
	SPY_BUF_S_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	SPY_BUF_S_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	SPY_BUF_S_S_AXI_ARVALID	: in std_logic;
	SPY_BUF_S_S_AXI_ARREADY	: out std_logic;
	SPY_BUF_S_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	SPY_BUF_S_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	SPY_BUF_S_S_AXI_RVALID	: out std_logic;
	SPY_BUF_S_S_AXI_RREADY	: in std_logic;
	
	
	-- END POINT AXI
	
    END_P_S_AXI_ACLK: in std_logic;
    END_P_S_AXI_ARESETN: in std_logic;
	END_P_S_AXI_AWADDR    : in std_logic_vector(31 downto 0);
	END_P_S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
	END_P_S_AXI_AWVALID   : in std_logic;
	END_P_S_AXI_AWREADY   : out std_logic;
	END_P_S_AXI_WDATA     : in std_logic_vector(31 downto 0);
	END_P_S_AXI_WSTRB     : in std_logic_vector(3 downto 0);
	END_P_S_AXI_WVALID    : in std_logic;
	END_P_S_AXI_WREADY    : out std_logic;
	END_P_S_AXI_BRESP     : out std_logic_vector(1 downto 0);
	END_P_S_AXI_BVALID    : out std_logic;
	END_P_S_AXI_BREADY    : in std_logic;
	END_P_S_AXI_ARADDR    : in std_logic_vector(31 downto 0);
	END_P_S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
	END_P_S_AXI_ARVALID   : in std_logic;
	END_P_S_AXI_ARREADY   : out std_logic;
	END_P_S_AXI_RDATA     : out std_logic_vector(31 downto 0);
	END_P_S_AXI_RRESP     : out std_logic_vector(1 downto 0);
	END_P_S_AXI_RVALID    : out std_logic;
	END_P_S_AXI_RREADY    : in std_logic;
	
	

	
	-- DAC SPI AXI
	
	
    SPI_DAC_S_AXI_ACLK: in std_logic;
    SPI_DAC_S_AXI_ARESETN: in std_logic;
	SPI_DAC_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	SPI_DAC_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	SPI_DAC_S_AXI_AWVALID	: in std_logic;
	SPI_DAC_S_AXI_AWREADY	: out std_logic;
	SPI_DAC_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	SPI_DAC_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	SPI_DAC_S_AXI_WVALID	: in std_logic;
	SPI_DAC_S_AXI_WREADY	: out std_logic;
	SPI_DAC_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	SPI_DAC_S_AXI_BVALID	: out std_logic;
	SPI_DAC_S_AXI_BREADY	: in std_logic;
	SPI_DAC_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	SPI_DAC_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	SPI_DAC_S_AXI_ARVALID	: in std_logic;
	SPI_DAC_S_AXI_ARREADY	: out std_logic;
	SPI_DAC_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	SPI_DAC_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	SPI_DAC_S_AXI_RVALID	: out std_logic;
	SPI_DAC_S_AXI_RREADY	: in std_logic;
	

	
	-- AFE SPI AXI---
	
	
    AFE_SPI_S_AXI_ACLK: in std_logic;
    AFE_SPI_S_AXI_ARESETN: in std_logic;
	AFE_SPI_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	AFE_SPI_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	AFE_SPI_S_AXI_AWVALID	: in std_logic;
	AFE_SPI_S_AXI_AWREADY	: out std_logic;
	AFE_SPI_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	AFE_SPI_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	AFE_SPI_S_AXI_WVALID	: in std_logic;
	AFE_SPI_S_AXI_WREADY	: out std_logic;
	AFE_SPI_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	AFE_SPI_S_AXI_BVALID	: out std_logic;
	AFE_SPI_S_AXI_BREADY	: in std_logic;
	AFE_SPI_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	AFE_SPI_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	AFE_SPI_S_AXI_ARVALID	: in std_logic;
	AFE_SPI_S_AXI_ARREADY	: out std_logic;
	AFE_SPI_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	AFE_SPI_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	AFE_SPI_S_AXI_RVALID	: out std_logic;
	AFE_SPI_S_AXI_RREADY	: in std_logic;
	
	--TRIG AXI
	
    TRIRG_S_AXI_ACLK: in std_logic;
    TRIRG_S_AXI_ARESETN: in std_logic;
    TRIRG_S_AXI_AWADDR: in std_logic_vector(15 downto 0);
    TRIRG_S_AXI_AWPROT: in std_logic_vector(2 downto 0);
    TRIRG_S_AXI_AWVALID: in std_logic;
    TRIRG_S_AXI_AWREADY: out std_logic;
    TRIRG_S_AXI_WDATA: in std_logic_vector(31 downto 0);
    TRIRG_S_AXI_WSTRB: in std_logic_vector(3 downto 0);
    TRIRG_S_AXI_WVALID: in std_logic;
    TRIRG_S_AXI_WREADY: out std_logic;
    TRIRG_S_AXI_BRESP: out std_logic_vector(1 downto 0);
    TRIRG_S_AXI_BVALID: out std_logic;
    TRIRG_S_AXI_BREADY: in std_logic;
    TRIRG_S_AXI_ARADDR: in std_logic_vector(15 downto 0);
    TRIRG_S_AXI_ARPROT: in std_logic_vector(2 downto 0);
    TRIRG_S_AXI_ARVALID: in std_logic;
    TRIRG_S_AXI_ARREADY: out std_logic;
    TRIRG_S_AXI_RDATA: out std_logic_vector(31 downto 0);
    TRIRG_S_AXI_RRESP: out std_logic_vector(1 downto 0);
    TRIRG_S_AXI_RVALID: out std_logic;
    TRIRG_S_AXI_RREADY: in std_logic;
	
	
	-- STUFF AXI
	
    STUFF_S_AXI_ACLK: in std_logic;
    STUFF_S_AXI_ARESETN: in std_logic;
	STUFF_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	STUFF_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	STUFF_S_AXI_AWVALID	: in std_logic;
	STUFF_S_AXI_AWREADY	: out std_logic;
	STUFF_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	STUFF_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	STUFF_S_AXI_WVALID	: in std_logic;
	STUFF_S_AXI_WREADY	: out std_logic;
	STUFF_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	STUFF_S_AXI_BVALID	: out std_logic;
	STUFF_S_AXI_BREADY	: in std_logic;
	STUFF_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	STUFF_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	STUFF_S_AXI_ARVALID	: in std_logic;
	STUFF_S_AXI_ARREADY	: out std_logic;
	STUFF_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	STUFF_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	STUFF_S_AXI_RVALID	: out std_logic;
	STUFF_S_AXI_RREADY	: in std_logic;
	
	--OUTBUTT_AXI
	
    OUTBUFF_S_AXI_ACLK: in std_logic;
    OUTBUFF_S_AXI_ARESETN: in std_logic;
	OUTBUFF_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	OUTBUFF_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	OUTBUFF_S_AXI_AWVALID	: in std_logic;
	OUTBUFF_S_AXI_AWREADY	: out std_logic;
	OUTBUFF_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	OUTBUFF_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	OUTBUFF_S_AXI_WVALID	: in std_logic;
	OUTBUFF_S_AXI_WREADY	: out std_logic;
	OUTBUFF_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	OUTBUFF_S_AXI_BVALID	: out std_logic;
	OUTBUFF_S_AXI_BREADY	: in std_logic;
	OUTBUFF_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	OUTBUFF_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	OUTBUFF_S_AXI_ARVALID	: in std_logic;
	OUTBUFF_S_AXI_ARREADY	: out std_logic;
	OUTBUFF_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	OUTBUFF_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	OUTBUFF_S_AXI_RVALID	: out std_logic;
	OUTBUFF_S_AXI_RREADY	: in std_logic;	
	
	-- channel mux AXI
	
	MUX_S_AXI_ACLK: in std_logic;
    MUX_S_AXI_ARESETN: in std_logic;
	MUX_S_AXI_AWADDR	: in std_logic_vector(31 downto 0);
	MUX_S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
	MUX_S_AXI_AWVALID	: in std_logic;
	MUX_S_AXI_AWREADY	: out std_logic;
	MUX_S_AXI_WDATA	    : in std_logic_vector(31 downto 0);
	MUX_S_AXI_WSTRB	    : in std_logic_vector(3 downto 0);
	MUX_S_AXI_WVALID	: in std_logic;
	MUX_S_AXI_WREADY	: out std_logic;
	MUX_S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
	MUX_S_AXI_BVALID	: out std_logic;
	MUX_S_AXI_BREADY	: in std_logic;
	MUX_S_AXI_ARADDR	: in std_logic_vector(31 downto 0);
	MUX_S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
	MUX_S_AXI_ARVALID	: in std_logic;
	MUX_S_AXI_ARREADY	: out std_logic;
	MUX_S_AXI_RDATA	    : out std_logic_vector(31 downto 0);
	MUX_S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
	MUX_S_AXI_RVALID	: out std_logic; 
	MUX_S_AXI_RREADY	: in std_logic;
	
    -- 10G Ethernet sender interface to external MGT refclk LVDS 156.25MHz
 
    eth_clk_p: in std_logic; -- I/O for mgt refclk 156.25MHz
    eth_clk_n: in std_logic;
    -- 10G Ethernet sender interface to external SFP+ transceiver
    eth_rx_p: in std_logic_vector(N_MGT-1 downto 0); -- I/O for SFPs
    eth_rx_n: in std_logic_vector(N_MGT-1 downto 0);
    eth_tx_p: out std_logic_vector(N_MGT-1 downto 0);
    eth_tx_n: out std_logic_vector(N_MGT-1 downto 0);
    eth_tx_dis: out std_logic_vector(N_MGT-1 downto 0);
    
    

     
    --debugging signals
    out_buff_trig: out std_logic ;
    out_buff_clk: out std_logic ;
    out_buff_data: out std_logic_vector (63 downto 0);
    
    --gth0_debut: out std_logic ;
    --time_stamp_debug: out std_logic_vector(63 downto 0);
    --syclk_62p5: out std_logic;
    --ep_rx_tmg_debug: out std_logic;
    --mmcm0_locked: out std_logic;
    --mmcm1_locked: out std_logic;
    --mmcm1_62p5_ouput: out std_logic;
    FORCE_TRIG: IN std_logic ;
    DIN_DEBUG: out std_logic_vector (13 downto 0) ;
     VALID_DEBUG: out std_logic;
     LAST_DEBUG: out std_logic;
     Trigered_debug: out std_logic 
    --ep_mmcm1_reset: out std_logic
   
     
    
  
    

  );
end DAPHNE3;

architecture DAPHNE3_arch of DAPHNE3 is 

-- There are 9 AXI-LITE interfaces in this design:
--
-- 1. timing endpoint
-- 2. front end 
-- 3. spy buffers
-- 4. i2c master (multiple devices)
-- 5. spi master (current monitor)
-- 6. spi master (afe + dac)
-- 7. spi master (3 dacs)
-- 8. misc stuff (fans, vbias, mux control, leds, etc. etc.)
-- 9. core logic
--
-- MOAR NOTES: 
-- 1. all modules are written assuming S_AXI_ACLK is 100MHz
-- 2. most modules use S_AXI_ARESETN has an active low HARD RESET
-- 3. most modules have various SOFT RESET control bits that can be written via AXI registers
-- 4. most modules have a testbench for standalone simulation

-- front end data alignment logic

component front_end 
port(
    afe_p, afe_n: in array_5x9_type;
    afe_clk_p, afe_clk_n: out std_logic;
    clk500: in std_logic;
    clk125: in std_logic;
    clock: in std_logic;
    dout: out array_5x9x16_type;
    trig: out std_logic;
    trig_IN: IN std_logic ;
    S_AXI_ACLK: in std_logic;
    S_AXI_ARESETN: in std_logic;
    S_AXI_AWADDR: in std_logic_vector(31 downto 0);
    S_AXI_AWPROT: in std_logic_vector(2 downto 0);
    S_AXI_AWVALID: in std_logic;
    S_AXI_AWREADY: out std_logic;
    S_AXI_WDATA: in std_logic_vector(31 downto 0);
    S_AXI_WSTRB: in std_logic_vector(3 downto 0);
    S_AXI_WVALID: in std_logic;
    S_AXI_WREADY: out std_logic;
    S_AXI_BRESP: out std_logic_vector(1 downto 0);
    S_AXI_BVALID: out std_logic;
    S_AXI_BREADY: in std_logic;
    S_AXI_ARADDR: in std_logic_vector(31 downto 0);
    S_AXI_ARPROT: in std_logic_vector(2 downto 0);
    S_AXI_ARVALID: in std_logic;
    S_AXI_ARREADY: out std_logic;
    S_AXI_RDATA: out std_logic_vector(31 downto 0);
    S_AXI_RRESP: out std_logic_vector(1 downto 0);
    S_AXI_RVALID: out std_logic;
    S_AXI_RREADY: in std_logic
  );
end component;

-- Input Spy Buffers

component spybuffers
port(
    clock           : in std_logic;
    trig            : in std_logic;
    din             : in array_5x9x16_type;
    timestamp       : in std_logic_vector(63 downto 0);
	S_AXI_ACLK	    : in std_logic;
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
end component;

-- Timing Endpoint

component endpoint 
port(
   sysclk_p, sysclk_n:   in std_logic;  -- 100MHz constant system clock from PS or oscillator
    sysclk100:   in std_logic;  -- 100MHz constant system clock from PS or oscillator
    -- external optical timing SFP link interface

    sfp_tmg_los: in std_logic; -- loss of signal
    rx0_tmg_p, rx0_tmg_n: in std_logic; -- LVDS recovered serial data ACKCHYUALLY the clock!
    sfp_tmg_tx_dis: out std_logic; -- high to disable timing SFP TX
    tx0_tmg_p, tx0_tmg_n: out std_logic; -- send data upstream
    --rx_tmg_debug: out std_logic ;
    -- output clocks used by daphne3 logic
    mclk: out std_logic;  -- master clock 62.5MHz
    clock:   out std_logic;  -- master clock 62.5MHz
    clk500:  out std_logic;  -- front end clock 500MHz
    clk125:  out std_logic;  -- front end clock 125MHz
    sclk200: out std_logic; -- system clock 200MHz
    --sclk100: out std_logic; -- system clock 100MHz
    timestamp: out std_logic_vector(63 downto 0); -- sync to clock 
    --mmc0_locked_debug: out std_logic ;
    --mmc1_locked_debug: out std_logic;
    --ep_stat_debug: out std_logic_vector (3 downto 0);
    --mmcm1_reset_debug : out std_logic ;
    --ep_reset_debug : out std_logic ;
    -- AXI-Lite interface for the control/status registers

	S_AXI_ACLK: in std_logic;
	S_AXI_ARESETN: in std_logic;
	S_AXI_AWADDR: in std_logic_vector(31 downto 0);
	S_AXI_AWPROT: in std_logic_vector(2 downto 0);
	S_AXI_AWVALID: in std_logic;
	S_AXI_AWREADY: out std_logic;
	S_AXI_WDATA: in std_logic_vector(31 downto 0);
	S_AXI_WSTRB: in std_logic_vector(3 downto 0);
	S_AXI_WVALID: in std_logic;
	S_AXI_WREADY: out std_logic;
	S_AXI_BRESP: out std_logic_vector(1 downto 0);
	S_AXI_BVALID: out std_logic;
	S_AXI_BREADY: in std_logic;
	S_AXI_ARADDR: in std_logic_vector(31 downto 0);
	S_AXI_ARPROT: in std_logic_vector(2 downto 0);
	S_AXI_ARVALID: in std_logic;
	S_AXI_ARREADY: out std_logic;
	S_AXI_RDATA: out std_logic_vector(31 downto 0);
	S_AXI_RRESP: out std_logic_vector(1 downto 0);
	S_AXI_RVALID: out std_logic;
	S_AXI_RREADY: in std_logic
);
end component;



-- SPI master for 3 DAC chips 

component spim_dac
port(
    dac_sclk        : out std_logic;
    dac_din         : out std_logic;
    dac_sync_n      : out std_logic;
    dac_ldac_n      : out std_logic;
	S_AXI_ACLK	    : in std_logic;
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
end component;

-- current monitor



-- SPI master for AFE chips + Offset DACs + Trim DACs
-- plus two global AFE control signals

component spim_afe 
port(
    afe_rst: out std_logic;
    afe_pdn: out std_logic;
    afe0_miso: in std_logic;
    afe0_sclk: out std_logic;
    afe0_mosi: out std_logic;
    afe12_miso: in std_logic;
    afe12_sclk: out std_logic;
    afe12_mosi: out std_logic;
    afe34_miso: in std_logic;
    afe34_sclk: out std_logic;
    afe34_mosi: out std_logic;
    afe_sen: out std_logic_vector(4 downto 0);
    trim_sync_n: out std_logic_vector(4 downto 0);
    trim_ldac_n: out std_logic_vector(4 downto 0);
    offset_sync_n: out std_logic_vector(4 downto 0);
    offset_ldac_n: out std_logic_vector(4 downto 0);
	S_AXI_ACLK	    : in std_logic;
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
end component;

-- catch all module for misc signals

component stuff
port(
    fan_tach        : in  std_logic_vector(1 downto 0);
    fan_ctrl        : out std_logic;
    hvbias_en       : out std_logic;
    mux_en          : out std_logic_vector(1 downto 0);
    mux_a           : out std_logic_vector(1 downto 0);
    stat_led        : out std_logic_vector(5 downto 0);
    version         : in std_logic_vector(3 downto 0);
    build_id        : in std_logic_vector(31 downto 0);
    core_chan_enable: out std_logic_vector(39 downto 0);
	S_AXI_ACLK	    : in std_logic;
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
end component;



signal afe_p_array, afe_n_array: array_5x9_type;
signal din_full_array: array_5x9x16_type;
signal din_array: array_5x8x14_type;
signal trig: std_logic;
signal timestamp: std_logic_vector(63 downto 0);
signal clock, clk125, clk500: std_logic;
signal core_chan_enable: std_logic_vector(39 downto 0);

signal S_AXI_ACLK:    std_logic;
signal S_AXI_ARESETN: std_logic;

signal FE_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal FE_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal FE_AXI_AWVALID: std_logic;
signal FE_AXI_AWREADY: std_logic;
signal FE_AXI_WDATA:   std_logic_vector(31 downto 0);
signal FE_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal FE_AXI_WVALID:  std_logic;
signal FE_AXI_WREADY:  std_logic;
signal FE_AXI_BRESP:   std_logic_vector(1 downto 0);
signal FE_AXI_BVALID:  std_logic;
signal FE_AXI_BREADY:  std_logic;
signal FE_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal FE_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal FE_AXI_ARVALID: std_logic;
signal FE_AXI_ARREADY: std_logic;
signal FE_AXI_RDATA:   std_logic_vector(31 downto 0);
signal FE_AXI_RRESP:   std_logic_vector(1 downto 0);
signal FE_AXI_RVALID:  std_logic;
signal FE_AXI_RREADY:  std_logic;

signal SB_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal SB_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal SB_AXI_AWVALID: std_logic;
signal SB_AXI_AWREADY: std_logic;
signal SB_AXI_WDATA:   std_logic_vector(31 downto 0);
signal SB_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal SB_AXI_WVALID:  std_logic;
signal SB_AXI_WREADY:  std_logic;
signal SB_AXI_BRESP:   std_logic_vector(1 downto 0);
signal SB_AXI_BVALID:  std_logic;
signal SB_AXI_BREADY:  std_logic;
signal SB_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal SB_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal SB_AXI_ARVALID: std_logic;
signal SB_AXI_ARREADY: std_logic;
signal SB_AXI_RDATA:   std_logic_vector(31 downto 0);
signal SB_AXI_RRESP:   std_logic_vector(1 downto 0);
signal SB_AXI_RVALID:  std_logic;
signal SB_AXI_RREADY:  std_logic;

signal EP_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal EP_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal EP_AXI_AWVALID: std_logic;
signal EP_AXI_AWREADY: std_logic;
signal EP_AXI_WDATA:   std_logic_vector(31 downto 0);
signal EP_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal EP_AXI_WVALID:  std_logic;
signal EP_AXI_WREADY:  std_logic;
signal EP_AXI_BRESP:   std_logic_vector(1 downto 0);
signal EP_AXI_BVALID:  std_logic;
signal EP_AXI_BREADY:  std_logic;
signal EP_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal EP_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal EP_AXI_ARVALID: std_logic;
signal EP_AXI_ARREADY: std_logic;
signal EP_AXI_RDATA:   std_logic_vector(31 downto 0);
signal EP_AXI_RRESP:   std_logic_vector(1 downto 0);
signal EP_AXI_RVALID:  std_logic;
signal EP_AXI_RREADY:  std_logic;

signal AFE_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal AFE_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal AFE_AXI_AWVALID: std_logic;
signal AFE_AXI_AWREADY: std_logic;
signal AFE_AXI_WDATA:   std_logic_vector(31 downto 0);
signal AFE_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal AFE_AXI_WVALID:  std_logic;
signal AFE_AXI_WREADY:  std_logic;
signal AFE_AXI_BRESP:   std_logic_vector(1 downto 0);
signal AFE_AXI_BVALID:  std_logic;
signal AFE_AXI_BREADY:  std_logic;
signal AFE_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal AFE_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal AFE_AXI_ARVALID: std_logic;
signal AFE_AXI_ARREADY: std_logic;
signal AFE_AXI_RDATA:   std_logic_vector(31 downto 0);
signal AFE_AXI_RRESP:   std_logic_vector(1 downto 0);
signal AFE_AXI_RVALID:  std_logic;
signal AFE_AXI_RREADY:  std_logic;



signal DAC_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal DAC_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal DAC_AXI_AWVALID: std_logic;
signal DAC_AXI_AWREADY: std_logic;
signal DAC_AXI_WDATA:   std_logic_vector(31 downto 0);
signal DAC_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal DAC_AXI_WVALID:  std_logic;
signal DAC_AXI_WREADY:  std_logic;
signal DAC_AXI_BRESP:   std_logic_vector(1 downto 0);
signal DAC_AXI_BVALID:  std_logic;
signal DAC_AXI_BREADY:  std_logic;
signal DAC_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal DAC_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal DAC_AXI_ARVALID: std_logic;
signal DAC_AXI_ARREADY: std_logic;
signal DAC_AXI_RDATA:   std_logic_vector(31 downto 0);
signal DAC_AXI_RRESP:   std_logic_vector(1 downto 0);
signal DAC_AXI_RVALID:  std_logic;
signal DAC_AXI_RREADY:  std_logic;



signal STUFF_AXI_AWADDR:  std_logic_vector(31 downto 0);
signal STUFF_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal STUFF_AXI_AWVALID: std_logic;
signal STUFF_AXI_AWREADY: std_logic;
signal STUFF_AXI_WDATA:   std_logic_vector(31 downto 0);
signal STUFF_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal STUFF_AXI_WVALID:  std_logic;
signal STUFF_AXI_WREADY:  std_logic;
signal STUFF_AXI_BRESP:   std_logic_vector(1 downto 0);
signal STUFF_AXI_BVALID:  std_logic;
signal STUFF_AXI_BREADY:  std_logic;
signal STUFF_AXI_ARADDR:  std_logic_vector(31 downto 0);
signal STUFF_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal STUFF_AXI_ARVALID: std_logic;
signal STUFF_AXI_ARREADY: std_logic;
signal STUFF_AXI_RDATA:   std_logic_vector(31 downto 0);
signal STUFF_AXI_RRESP:   std_logic_vector(1 downto 0);
signal STUFF_AXI_RVALID:  std_logic;
signal STUFF_AXI_RREADY:  std_logic;

signal CORE_AXI_AWADDR:  std_logic_vector(15 downto 0);
signal CORE_AXI_AWPROT:  std_logic_vector(2 downto 0);
signal CORE_AXI_AWVALID: std_logic;
signal CORE_AXI_AWREADY: std_logic;
signal CORE_AXI_WDATA:   std_logic_vector(31 downto 0);
signal CORE_AXI_WSTRB:   std_logic_vector(3 downto 0);
signal CORE_AXI_WVALID:  std_logic;
signal CORE_AXI_WREADY:  std_logic;
signal CORE_AXI_BRESP:   std_logic_vector(1 downto 0);
signal CORE_AXI_BVALID:  std_logic;
signal CORE_AXI_BREADY:  std_logic;
signal CORE_AXI_ARADDR:  std_logic_vector(15 downto 0);
signal CORE_AXI_ARPROT:  std_logic_vector(2 downto 0);
signal CORE_AXI_ARVALID: std_logic;
signal CORE_AXI_ARREADY: std_logic;
signal CORE_AXI_RDATA:   std_logic_vector(31 downto 0);
signal CORE_AXI_RRESP:   std_logic_vector(1 downto 0);
signal CORE_AXI_RVALID:  std_logic;
signal CORE_AXI_RREADY:  std_logic;
signal eth0_p_buff: std_logic;
signal eth0_n_buff: std_logic ;


signal  clk_62p5_debug: std_logic ;
signal  ep_rx_debug: std_logic ;
signal ep_mmcm0_locked: std_logic ;
signal ep_mmcm1_locked: std_logic ;
signal ep_stat_debug: std_logic_vector (3 downto 0);
signal mmcm1_reset_debug: std_logic ;
signal ep_reset_debug: std_logic ;
signal eth0_tx_dis_debug: std_logic ;
--signal eth0_10g_debug:std_logic  ;
    --output_spybuff-----
signal out_buff_data_reg:  array_8x64_type;
signal out_buff_trig_reg:  std_logic ;
signal valid_debug_reg: std_logic_vector(7 downto 0) ;
signal  last_debug_reg :  std_logic_vector(7 downto 0) ; 
signal din_debug_reg: std_logic_vector (13 downto 0);
signal trigered_debug_reg: std_logic ;

signal input_mux:array_8x4x14_type;
signal input_mux_data: array_5x9x16_type;
signal channel_id:array_8x4x8_type;
signal stream_mux_enable: std_logic;
signal stream_core_dout:array_8x64_type;
signal stream_core_valid: std_logic_vector(7 downto 0);
signal stream_core_last: std_logic_vector(7 downto 0);

-- input_mux_AXI_REC

signal AXI_IN:AXILITE_INREC;
signal AXI_OUT:AXILITE_OUTREC;



signal AXI_IN_OUT_BUFF:AXILITE_INREC;
signal AXI_OUT_OUT_BUFF:AXILITE_OUTREC;

-- Don't know where to define these yet


signal       ext_mac_addr_0  :  std_logic_vector(47 downto 0);
 signal       ext_ip_addr_0   :  std_logic_vector(31 downto 0);
signal        ext_port_addr_0 :  std_logic_vector(15 downto 0);
        
signal        ext_mac_addr_1  :  std_logic_vector(47 downto 0);
signal        ext_ip_addr_1   :  std_logic_vector(31 downto 0);
signal        ext_port_addr_1 :  std_logic_vector(15 downto 0);
        
signal        ext_mac_addr_2  :  std_logic_vector(47 downto 0);
signal        ext_ip_addr_2   :  std_logic_vector(31 downto 0);
 signal       ext_port_addr_2 :  std_logic_vector(15 downto 0);
        
signal        ext_mac_addr_3  :  std_logic_vector(47 downto 0);
 signal       ext_ip_addr_3   :  std_logic_vector(31 downto 0);
signal        ext_port_addr_3 :  std_logic_vector(15 downto 0) ;

begin



din_debug_reg <=  din_array(1)(0);

     

   
     
-- pack SLV AFE LVDS signals into 5x9 2D arrays

afe_p_array(0)(8 downto 0) <= afe0_p(8 downto 0); 
afe_p_array(1)(8 downto 0) <= afe1_p(8 downto 0); 
afe_p_array(2)(8 downto 0) <= afe2_p(8 downto 0); 
afe_p_array(3)(8 downto 0) <= afe3_p(8 downto 0); 
afe_p_array(4)(8 downto 0) <= afe4_p(8 downto 0); 

afe_n_array(0)(8 downto 0) <= afe0_n(8 downto 0);
afe_n_array(1)(8 downto 0) <= afe1_n(8 downto 0);
afe_n_array(2)(8 downto 0) <= afe2_n(8 downto 0);
afe_n_array(3)(8 downto 0) <= afe3_n(8 downto 0);
afe_n_array(4)(8 downto 0) <= afe4_n(8 downto 0);

-- AXI ASSIGNMNT



-- FRONT END

 FE_AXI_AWADDR <=   FRONT_END_S_AXI_AWADDR;
 FE_AXI_AWPROT <= FRONT_END_S_AXI_AWPROT;
 FE_AXI_AWVALID <= FRONT_END_S_AXI_AWVALID;
 FRONT_END_S_AXI_AWREADY <= FE_AXI_AWREADY  ;
 FE_AXI_WDATA <= FRONT_END_S_AXI_WDATA;
 FE_AXI_WSTRB <= FRONT_END_S_AXI_WSTRB;
 FE_AXI_WVALID <= FRONT_END_S_AXI_WVALID;
 FRONT_END_S_AXI_WREADY <= FE_AXI_WREADY  ;
 FRONT_END_S_AXI_BRESP<= FE_AXI_BRESP  ;
 FRONT_END_S_AXI_BVALID <= FE_AXI_BVALID  ;
 FE_AXI_BREADY <= FRONT_END_S_AXI_BREADY;
 FE_AXI_ARADDR <= FRONT_END_S_AXI_ARADDR;
 FE_AXI_ARPROT <= FRONT_END_S_AXI_ARPROT;
 FE_AXI_ARVALID <= FRONT_END_S_AXI_ARVALID;
 FRONT_END_S_AXI_ARREADY<= FE_AXI_ARREADY  ;
 FRONT_END_S_AXI_RDATA <= FE_AXI_RDATA  ;
 FRONT_END_S_AXI_RRESP <= FE_AXI_RRESP  ;
 FRONT_END_S_AXI_RVALID<=  FE_AXI_RVALID  ;
 FE_AXI_RREADY <= FRONT_END_S_AXI_RREADY ;


-- SPY BUFF

 SB_AXI_AWADDR <= SPY_BUF_S_S_AXI_AWADDR;
 SB_AXI_AWPROT <= SPY_BUF_S_S_AXI_AWPROT;
 SB_AXI_AWVALID <= SPY_BUF_S_S_AXI_AWVALID;
  SPY_BUF_S_S_AXI_AWREADY<= SB_AXI_AWREADY;
 SB_AXI_WDATA <= SPY_BUF_S_S_AXI_WDATA;
 SB_AXI_WSTRB <= SPY_BUF_S_S_AXI_WSTRB;
 SB_AXI_WVALID <= SPY_BUF_S_S_AXI_WVALID;
  SPY_BUF_S_S_AXI_WREADY<= SB_AXI_WREADY;
  SPY_BUF_S_S_AXI_BRESP <= SB_AXI_BRESP;
  SPY_BUF_S_S_AXI_BVALID<= SB_AXI_BVALID;
 SB_AXI_BREADY <= SPY_BUF_S_S_AXI_BREADY;
 SB_AXI_ARADDR <= SPY_BUF_S_S_AXI_ARADDR;
 SB_AXI_ARPROT <= SPY_BUF_S_S_AXI_ARPROT;
 SB_AXI_ARVALID <= SPY_BUF_S_S_AXI_ARVALID;
  SPY_BUF_S_S_AXI_ARREADY<= SB_AXI_ARREADY;
  SPY_BUF_S_S_AXI_RDATA<= SB_AXI_RDATA;
  SPY_BUF_S_S_AXI_RRESP<= SB_AXI_RRESP;
 SPY_BUF_S_S_AXI_RVALID <= SB_AXI_RVALID;
 SB_AXI_RREADY <= SPY_BUF_S_S_AXI_RREADY;

-- END POINT 

  EP_AXI_AWADDR <= END_P_S_AXI_AWADDR; 
  EP_AXI_AWPROT <=  END_P_S_AXI_AWPROT;
  EP_AXI_AWVALID <=   END_P_S_AXI_AWVALID;
  END_P_S_AXI_AWREADY <=  EP_AXI_AWREADY   ;
  EP_AXI_WDATA <=   END_P_S_AXI_WDATA  ;
  EP_AXI_WSTRB   <=  END_P_S_AXI_WSTRB ;
  EP_AXI_WVALID   <= END_P_S_AXI_WVALID;
   END_P_S_AXI_WREADY<= EP_AXI_WREADY   ;
   END_P_S_AXI_BRESP<= EP_AXI_BRESP    ;
   END_P_S_AXI_BVALID<= EP_AXI_BVALID   ;
   EP_AXI_BREADY   <=  END_P_S_AXI_BREADY;
  EP_AXI_ARADDR  <=  END_P_S_AXI_ARADDR  ;
  EP_AXI_ARPROT  <=  END_P_S_AXI_ARPROT ;
  EP_AXI_ARVALID   <= END_P_S_AXI_ARVALID;
  END_P_S_AXI_ARREADY <= EP_AXI_ARREADY  ;
   END_P_S_AXI_RDATA <= EP_AXI_RDATA     ;
  END_P_S_AXI_RRESP<=  EP_AXI_RRESP     ;
  END_P_S_AXI_RVALID<=  EP_AXI_RVALID    ;
  EP_AXI_RREADY  <=  END_P_S_AXI_RREADY ;


-- AFE SPI

  AFE_AXI_AWADDR   <= AFE_SPI_S_AXI_AWADDR;
  AFE_AXI_AWPROT   <= AFE_SPI_S_AXI_AWPROT;
  AFE_AXI_AWVALID  <=  AFE_SPI_S_AXI_AWVALID;
  AFE_SPI_S_AXI_AWREADY  <= AFE_AXI_AWREADY ;
  AFE_AXI_WDATA   <= AFE_SPI_S_AXI_WDATA;
  AFE_AXI_WSTRB   <= AFE_SPI_S_AXI_WSTRB;
  AFE_AXI_WVALID   <= AFE_SPI_S_AXI_WVALID;
  AFE_SPI_S_AXI_WREADY  <= AFE_AXI_WREADY ;
  AFE_SPI_S_AXI_BRESP  <= AFE_AXI_BRESP ;
  AFE_SPI_S_AXI_BVALID <=  AFE_AXI_BVALID ;
  AFE_AXI_BREADY  <=  AFE_SPI_S_AXI_BREADY;
  AFE_AXI_ARADDR   <= AFE_SPI_S_AXI_ARADDR;
  AFE_AXI_ARPROT  <=  AFE_SPI_S_AXI_ARPROT;
  AFE_AXI_ARVALID  <=  AFE_SPI_S_AXI_ARVALID;
  AFE_SPI_S_AXI_ARREADY  <= AFE_AXI_ARREADY   ;
  AFE_SPI_S_AXI_RDATA  <= AFE_AXI_RDATA ;
  AFE_SPI_S_AXI_RRESP  <= AFE_AXI_RRESP ;
  AFE_SPI_S_AXI_RVALID  <= AFE_AXI_RVALID ;
  AFE_AXI_RREADY   <= AFE_SPI_S_AXI_RREADY;





-- DACs

 DAC_AXI_AWADDR <= SPI_DAC_S_AXI_AWADDR;
 DAC_AXI_AWPROT <=SPI_DAC_S_AXI_AWPROT;
 DAC_AXI_AWVALID <= SPI_DAC_S_AXI_AWVALID;
 SPI_DAC_S_AXI_AWREADY<= DAC_AXI_AWREADY ;
 DAC_AXI_WDATA <= SPI_DAC_S_AXI_WDATA;
 DAC_AXI_WSTRB <= SPI_DAC_S_AXI_WSTRB;
 DAC_AXI_WVALID <= SPI_DAC_S_AXI_WVALID;
 SPI_DAC_S_AXI_WREADY<= DAC_AXI_WREADY ;
 SPI_DAC_S_AXI_BRESP<= DAC_AXI_BRESP ;
 SPI_DAC_S_AXI_BVALID <= DAC_AXI_BVALID ;
 DAC_AXI_BREADY <= SPI_DAC_S_AXI_BREADY;
 DAC_AXI_ARADDR <= SPI_DAC_S_AXI_ARADDR;
 DAC_AXI_ARPROT <= SPI_DAC_S_AXI_ARPROT;
 DAC_AXI_ARVALID <= SPI_DAC_S_AXI_ARVALID;
 SPI_DAC_S_AXI_ARREADY <= DAC_AXI_ARREADY ;
 SPI_DAC_S_AXI_RDATA <= DAC_AXI_RDATA ;
SPI_DAC_S_AXI_RRESP  <= DAC_AXI_RRESP ;
 SPI_DAC_S_AXI_RVALID <= DAC_AXI_RVALID ;
 DAC_AXI_RREADY <= SPI_DAC_S_AXI_RREADY;






--STUF 

 STUFF_AXI_AWADDR   <= STUFF_S_AXI_AWADDR;
 STUFF_AXI_AWPROT   <= STUFF_S_AXI_AWPROT;
 STUFF_AXI_AWVALID   <= STUFF_S_AXI_AWVALID ;
 STUFF_S_AXI_AWREADY   <= STUFF_AXI_AWREADY ;
 STUFF_AXI_WDATA   <= STUFF_S_AXI_WDATA;
 STUFF_AXI_WSTRB   <= STUFF_S_AXI_WSTRB;
 STUFF_AXI_WVALID   <= STUFF_S_AXI_WVALID ;
 STUFF_S_AXI_WREADY   <= STUFF_AXI_WREADY  ;
 STUFF_S_AXI_BRESP   <= STUFF_AXI_BRESP  ;
 STUFF_S_AXI_BVALID   <= STUFF_AXI_BVALID  ;
 STUFF_AXI_BREADY   <= STUFF_S_AXI_BREADY  ;
 STUFF_AXI_ARADDR   <= STUFF_S_AXI_ARADDR  ;
 STUFF_AXI_ARPROT   <= STUFF_S_AXI_ARPROT;
 STUFF_AXI_ARVALID   <= STUFF_S_AXI_ARVALID ;
 STUFF_S_AXI_ARREADY  <= STUFF_AXI_ARREADY ;
 STUFF_S_AXI_RDATA   <= STUFF_AXI_RDATA;
 STUFF_S_AXI_RRESP   <= STUFF_AXI_RRESP;
 STUFF_S_AXI_RVALID   <= STUFF_AXI_RVALID  ;
 STUFF_AXI_RREADY   <= STUFF_S_AXI_RREADY  ;

	

	
	
--CORE


 CORE_AXI_AWADDR  <= TRIRG_S_AXI_AWADDR;
 CORE_AXI_AWPROT   <= TRIRG_S_AXI_AWPROT;
 CORE_AXI_AWVALID <=  TRIRG_S_AXI_AWVALID;
  TRIRG_S_AXI_AWREADY <= CORE_AXI_AWREADY ;
 CORE_AXI_WDATA   <= TRIRG_S_AXI_WDATA;
 CORE_AXI_WSTRB  <=   TRIRG_S_AXI_WSTRB;
 CORE_AXI_WVALID  <= TRIRG_S_AXI_WVALID;
  TRIRG_S_AXI_WREADY<= CORE_AXI_WREADY  ;
  TRIRG_S_AXI_BRESP<= CORE_AXI_BRESP ;
  TRIRG_S_AXI_BVALID<= CORE_AXI_BVALID  ;
 CORE_AXI_BREADY   <= TRIRG_S_AXI_BREADY;
 CORE_AXI_ARADDR   <=TRIRG_S_AXI_ARADDR ;
 CORE_AXI_ARPROT  <=  TRIRG_S_AXI_ARPROT;
 CORE_AXI_ARVALID <=  TRIRG_S_AXI_ARVALID;
 TRIRG_S_AXI_ARREADY <= CORE_AXI_ARREADY ;
  TRIRG_S_AXI_RDATA<= CORE_AXI_RDATA;
 TRIRG_S_AXI_RRESP <= CORE_AXI_RRESP;
  TRIRG_S_AXI_RVALID<= CORE_AXI_RVALID  ;
 CORE_AXI_RREADY <=  TRIRG_S_AXI_RREADY;


     -- threshould axi Input mappings
    AXI_IN.ACLK     <= MUX_S_AXI_ACLK;
    AXI_IN.ARESETN  <= MUX_S_AXI_ARESETN;
    AXI_IN.AWADDR   <= MUX_S_AXI_AWADDR;
    AXI_IN.AWPROT   <= MUX_S_AXI_AWPROT;
    AXI_IN.AWVALID  <= MUX_S_AXI_AWVALID;
    AXI_IN.WDATA    <= MUX_S_AXI_WDATA;
    AXI_IN.WSTRB    <= MUX_S_AXI_WSTRB;
    AXI_IN.WVALID   <= MUX_S_AXI_WVALID;
    AXI_IN.BREADY   <= MUX_S_AXI_BREADY;
    AXI_IN.ARADDR   <= MUX_S_AXI_ARADDR;
    AXI_IN.ARPROT   <= MUX_S_AXI_ARPROT;
    AXI_IN.ARVALID  <= MUX_S_AXI_ARVALID;
    AXI_IN.RREADY   <= MUX_S_AXI_RREADY;

    --  threshould axi Output mappings
    MUX_S_AXI_AWREADY <= AXI_OUT.AWREADY;
    MUX_S_AXI_WREADY  <= AXI_OUT.WREADY;
    MUX_S_AXI_BRESP   <= AXI_OUT.BRESP;
    MUX_S_AXI_BVALID  <= AXI_OUT.BVALID;
    MUX_S_AXI_ARREADY <= AXI_OUT.ARREADY;
    MUX_S_AXI_RDATA   <= AXI_OUT.RDATA;
    MUX_S_AXI_RRESP   <= AXI_OUT.RRESP;
    MUX_S_AXI_RVALID  <= AXI_OUT.RVALID;  


-- OUTBUFF


     
    AXI_IN_OUT_BUFF.ACLK     <= OUTBUFF_S_AXI_ACLK;
    AXI_IN_OUT_BUFF.ARESETN  <= OUTBUFF_S_AXI_ARESETN;
    AXI_IN_OUT_BUFF.AWADDR   <= OUTBUFF_S_AXI_AWADDR;
    AXI_IN_OUT_BUFF.AWPROT   <= OUTBUFF_S_AXI_AWPROT;
    AXI_IN_OUT_BUFF.AWVALID  <= OUTBUFF_S_AXI_AWVALID;
    AXI_IN_OUT_BUFF.WDATA    <= OUTBUFF_S_AXI_WDATA;
    AXI_IN_OUT_BUFF.WSTRB    <= OUTBUFF_S_AXI_WSTRB;
    AXI_IN_OUT_BUFF.WVALID   <= OUTBUFF_S_AXI_WVALID;
    AXI_IN_OUT_BUFF.BREADY   <= OUTBUFF_S_AXI_BREADY;
    AXI_IN_OUT_BUFF.ARADDR   <= OUTBUFF_S_AXI_ARADDR;
    AXI_IN_OUT_BUFF.ARPROT   <= OUTBUFF_S_AXI_ARPROT;
    AXI_IN_OUT_BUFF.ARVALID  <= OUTBUFF_S_AXI_ARVALID;
    AXI_IN_OUT_BUFF.RREADY   <= OUTBUFF_S_AXI_RREADY;

  
    OUTBUFF_S_AXI_AWREADY <= AXI_OUT_OUT_BUFF.AWREADY;
    OUTBUFF_S_AXI_WREADY  <= AXI_OUT_OUT_BUFF.WREADY;
    OUTBUFF_S_AXI_BRESP   <= AXI_OUT_OUT_BUFF.BRESP;
    OUTBUFF_S_AXI_BVALID  <= AXI_OUT_OUT_BUFF.BVALID;
    OUTBUFF_S_AXI_ARREADY <= AXI_OUT_OUT_BUFF.ARREADY;
    OUTBUFF_S_AXI_RDATA   <= AXI_OUT_OUT_BUFF.RDATA;
    OUTBUFF_S_AXI_RRESP   <= AXI_OUT_OUT_BUFF.RRESP;
    OUTBUFF_S_AXI_RVALID  <= AXI_OUT_OUT_BUFF.RVALID;  

-- front end deskew and alignment

front_end_inst: front_end 
port map(
    afe_p           => afe_p_array,
    afe_n           => afe_n_array,
    
    afe_clk_p       => afe_clk_p,
    afe_clk_n       => afe_clk_n,
    clock           => clock,
    clk125          => clk125,
    clk500          => clk500,
    dout            => din_full_array,
    trig            => trig,
    trig_IN         => trig_IN,
	S_AXI_ACLK	    => FRONT_END_S_AXI_ACLK,
	S_AXI_ARESETN	=> FRONT_END_S_AXI_ARESETN,
	S_AXI_AWADDR	=> FE_AXI_AWADDR,
	S_AXI_AWPROT	=> FE_AXI_AWPROT,
	S_AXI_AWVALID	=> FE_AXI_AWVALID,
	S_AXI_AWREADY	=> FE_AXI_AWREADY,
	S_AXI_WDATA	    => FE_AXI_WDATA,
	S_AXI_WSTRB	    => FE_AXI_WSTRB,
	S_AXI_WVALID	=> FE_AXI_WVALID,
	S_AXI_WREADY	=> FE_AXI_WREADY,
	S_AXI_BRESP	    => FE_AXI_BRESP,
	S_AXI_BVALID	=> FE_AXI_BVALID,
	S_AXI_BREADY	=> FE_AXI_BREADY,
	S_AXI_ARADDR	=> FE_AXI_ARADDR,
	S_AXI_ARPROT	=> FE_AXI_ARPROT,
	S_AXI_ARVALID	=> FE_AXI_ARVALID,
	S_AXI_ARREADY	=> FE_AXI_ARREADY,
	S_AXI_RDATA	    => FE_AXI_RDATA,
	S_AXI_RRESP	    => FE_AXI_RRESP,
	S_AXI_RVALID	=> FE_AXI_RVALID,
	S_AXI_RREADY	=> FE_AXI_RREADY
  );

-- Input spy buffers

spybuffers_inst: spybuffers
port map(
    clock           => clock,
    trig            => trig,
    din             => din_full_array,
    timestamp       => timestamp,
	S_AXI_ACLK	    => SPY_BUF_S_S_AXI_ACLK,
	S_AXI_ARESETN	=> SPY_BUF_S_S_AXI_ARESETN,
	S_AXI_AWADDR	=> SB_AXI_AWADDR,
	S_AXI_AWPROT	=> SB_AXI_AWPROT,
	S_AXI_AWVALID	=> SB_AXI_AWVALID,
	S_AXI_AWREADY	=> SB_AXI_AWREADY,
	S_AXI_WDATA	    => SB_AXI_WDATA,
	S_AXI_WSTRB	    => SB_AXI_WSTRB,
	S_AXI_WVALID	=> SB_AXI_WVALID,
	S_AXI_WREADY	=> SB_AXI_WREADY,
	S_AXI_BRESP	    => SB_AXI_BRESP,
	S_AXI_BVALID	=> SB_AXI_BVALID,
	S_AXI_BREADY	=> SB_AXI_BREADY,
	S_AXI_ARADDR	=> SB_AXI_ARADDR,
	S_AXI_ARPROT	=> SB_AXI_ARPROT,
	S_AXI_ARVALID	=> SB_AXI_ARVALID,
	S_AXI_ARREADY	=> SB_AXI_ARREADY,
	S_AXI_RDATA	    => SB_AXI_RDATA,
	S_AXI_RRESP	    => SB_AXI_RRESP,
	S_AXI_RVALID	=> SB_AXI_RVALID,
	S_AXI_RREADY	=> SB_AXI_RREADY
  );

-- Timing Endpoint

endpoint_inst: endpoint
port map(
    sysclk_p        => sysclk_p,
    sysclk_n        => sysclk_n,
    sysclk100     => sysclk100,
    sfp_tmg_los     => sfp_tmg_los,
    rx0_tmg_p       => rx0_tmg_p,
    rx0_tmg_n       => rx0_tmg_n,
    sfp_tmg_tx_dis  => sfp_tmg_tx_dis,
    tx0_tmg_p       => tx0_tmg_p,
    tx0_tmg_n       => tx0_tmg_n,
    clock           => clock,
    clk500          => clk500,
    clk125          => clk125,
    timestamp       => timestamp,
    
   -- mmc0_locked_debug => ep_mmcm0_locked, 
    --mmc1_locked_debug => ep_mmcm1_locked,
    --mclk            => clk_62p5_debug,
    --rx_tmg_debug    => ep_rx_debug,
   -- ep_stat_debug   => ep_stat_debug,
   -- mmcm1_reset_debug => mmcm1_reset_debug,
    --ep_reset_debug => ep_reset_debug,
    S_AXI_ACLK	    => END_P_S_AXI_ACLK,
	S_AXI_ARESETN	=> END_P_S_AXI_ARESETN,
	S_AXI_AWADDR	=> EP_AXI_AWADDR,
	S_AXI_AWPROT	=> EP_AXI_AWPROT,
	S_AXI_AWVALID	=> EP_AXI_AWVALID,
	S_AXI_AWREADY	=> EP_AXI_AWREADY,
	S_AXI_WDATA	    => EP_AXI_WDATA,
	S_AXI_WSTRB	    => EP_AXI_WSTRB,
	S_AXI_WVALID	=> EP_AXI_WVALID,
	S_AXI_WREADY	=> EP_AXI_WREADY,
	S_AXI_BRESP	    => EP_AXI_BRESP,
	S_AXI_BVALID	=> EP_AXI_BVALID,
	S_AXI_BREADY	=> EP_AXI_BREADY,
	S_AXI_ARADDR	=> EP_AXI_ARADDR,
	S_AXI_ARPROT	=> EP_AXI_ARPROT,
	S_AXI_ARVALID	=> EP_AXI_ARVALID,
	S_AXI_ARREADY	=> EP_AXI_ARREADY,
	S_AXI_RDATA	    => EP_AXI_RDATA,
	S_AXI_RRESP	    => EP_AXI_RRESP,
	S_AXI_RVALID	=> EP_AXI_RVALID,
	S_AXI_RREADY	=> EP_AXI_RREADY
);

-- SPI master for AFEs and associated DACs

spim_afe_inst: spim_afe 
port map(
    afe_rst       => afe_rst,
    afe_pdn       => afe_pdn,
    afe0_miso     => afe0_miso,
    afe0_sclk     => afe0_sclk,
    afe0_mosi     => afe0_mosi,
    afe12_miso    => afe12_miso,
    afe12_sclk    => afe12_sclk,
    afe12_mosi    => afe12_mosi,
    afe34_miso    => afe34_miso,
    afe34_sclk    => afe34_sclk,
    afe34_mosi    => afe34_mosi,
    afe_sen       => afe_sen,
    trim_sync_n   => trim_sync_n,
    trim_ldac_n   => trim_ldac_n,
    offset_sync_n => offset_sync_n,
    offset_ldac_n => offset_ldac_n,

    S_AXI_ACLK	     => AFE_SPI_S_AXI_ACLK,
	S_AXI_ARESETN	 => AFE_SPI_S_AXI_ARESETN,
	S_AXI_AWADDR	 => AFE_AXI_AWADDR,
	S_AXI_AWPROT	 => AFE_AXI_AWPROT,
	S_AXI_AWVALID	 => AFE_AXI_AWVALID,
	S_AXI_AWREADY	 => AFE_AXI_AWREADY,
	S_AXI_WDATA	     => AFE_AXI_WDATA,
	S_AXI_WSTRB	     => AFE_AXI_WSTRB,
	S_AXI_WVALID	 => AFE_AXI_WVALID,
	S_AXI_WREADY	 => AFE_AXI_WREADY,
	S_AXI_BRESP	     => AFE_AXI_BRESP,
	S_AXI_BVALID     => AFE_AXI_BVALID,
	S_AXI_BREADY	 => AFE_AXI_BREADY,
	S_AXI_ARADDR     => AFE_AXI_ARADDR,
	S_AXI_ARPROT     => AFE_AXI_ARPROT,
	S_AXI_ARVALID    => AFE_AXI_ARVALID,
	S_AXI_ARREADY    => AFE_AXI_ARREADY,
	S_AXI_RDATA      => AFE_AXI_RDATA,
	S_AXI_RRESP      => AFE_AXI_RRESP,
	S_AXI_RVALID     => AFE_AXI_RVALID,
	S_AXI_RREADY     => AFE_AXI_RREADY
  );

-- I2C master


-- SPI master for 3 DACs

spim_dac_inst: spim_dac 
port map(
    dac_sclk        => dac_sclk,
    dac_din         => dac_din,
    dac_sync_n      => dac_sync_n,
    dac_ldac_n      => dac_ldac_n, 
    S_AXI_ACLK	    => SPI_DAC_S_AXI_ACLK,
	S_AXI_ARESETN	=> SPI_DAC_S_AXI_ARESETN,
	S_AXI_AWADDR	=> DAC_AXI_AWADDR,
	S_AXI_AWPROT	=> DAC_AXI_AWPROT,
	S_AXI_AWVALID	=> DAC_AXI_AWVALID,
	S_AXI_AWREADY	=> DAC_AXI_AWREADY,
	S_AXI_WDATA	    => DAC_AXI_WDATA,
	S_AXI_WSTRB	    => DAC_AXI_WSTRB,
	S_AXI_WVALID	=> DAC_AXI_WVALID,
	S_AXI_WREADY	=> DAC_AXI_WREADY,
	S_AXI_BRESP	    => DAC_AXI_BRESP,
	S_AXI_BVALID	=> DAC_AXI_BVALID,
	S_AXI_BREADY	=> DAC_AXI_BREADY,
	S_AXI_ARADDR	=> DAC_AXI_ARADDR,
	S_AXI_ARPROT	=> DAC_AXI_ARPROT,
	S_AXI_ARVALID	=> DAC_AXI_ARVALID,
	S_AXI_ARREADY	=> DAC_AXI_ARREADY,
	S_AXI_RDATA	    => DAC_AXI_RDATA,
	S_AXI_RRESP	    => DAC_AXI_RRESP,
	S_AXI_RVALID	=> DAC_AXI_RVALID,
	S_AXI_RREADY	=> DAC_AXI_RREADY
  );

-- SPI master for current monitor


-- Misc. Stuff

stuff_inst: stuff
port map(
    fan_tach        => fan_tach,
    fan_ctrl        => fan_ctrl,
    hvbias_en       => hvbias_en,
    mux_en          => mux_en,
    mux_a           => mux_a,
    stat_led        => stat_led,
    version         => version,
    build_id        => build_id,
    core_chan_enable => core_chan_enable,
    S_AXI_ACLK	    => STUFF_S_AXI_ACLK,
	S_AXI_ARESETN	=> STUFF_S_AXI_ARESETN,
	S_AXI_AWADDR	=> STUFF_AXI_AWADDR,
	S_AXI_AWPROT	=> STUFF_AXI_AWPROT,
	S_AXI_AWVALID	=> STUFF_AXI_AWVALID,
	S_AXI_AWREADY	=> STUFF_AXI_AWREADY,
	S_AXI_WDATA	    => STUFF_AXI_WDATA,
	S_AXI_WSTRB	    => STUFF_AXI_WSTRB,
	S_AXI_WVALID	=> STUFF_AXI_WVALID,
	S_AXI_WREADY	=> STUFF_AXI_WREADY,
	S_AXI_BRESP	    => STUFF_AXI_BRESP,
	S_AXI_BVALID	=> STUFF_AXI_BVALID,
	S_AXI_BREADY	=> STUFF_AXI_BREADY,
	S_AXI_ARADDR	=> STUFF_AXI_ARADDR,
	S_AXI_ARPROT	=> STUFF_AXI_ARPROT,
	S_AXI_ARVALID	=> STUFF_AXI_ARVALID,
	S_AXI_ARREADY	=> STUFF_AXI_ARREADY,
	S_AXI_RDATA	    => STUFF_AXI_RDATA,
	S_AXI_RRESP	    => STUFF_AXI_RRESP,
	S_AXI_RVALID	=> STUFF_AXI_RVALID,
	S_AXI_RREADY	=> STUFF_AXI_RREADY
  );

-- reduce din_array, since we don't need the full 45 channels * 16 bits for the core

gena_din: for a in 4 downto 0 generate
genc_din: for c in 7 downto 0 generate

    din_array(a)(c)(13 downto 0) <= din_full_array(a)(c)(13 downto 0);
   -- input_mux_data <= din_array(a)(c);

end generate genc_din;
end generate gena_din;


--input_mux_data <= din_full_array;
-- input mux


input_mux_inst: entity work.stream_input_mux
    port map (
    clock =>  clock,
    din  =>  din_full_array,
    dout =>  input_mux,
    muxctrl =>  channel_id,
    stream_enable => stream_mux_enable,
    AXI_IN =>  AXI_IN,
    AXI_OUT => AXI_OUT 
    
    
    );


core_inst: entity work.stream_core

port map (

    clock 	=>  clock,-- 62.5MHz master clock
    -- Hold every stream4 packer, FIFO, and FSM in reset while the input mux is
    -- disabled. stream_mux_enable rises only with the atomic selector commit,
    -- so synchronous reset release sees stable channel IDs and the first
    -- visible word of each sender is a new timestamp/header sequence.
    reset	=>   not stream_mux_enable,
    ts 	=>  timestamp,-- timestamp
    
    version => version,

    din => input_mux ,
    channel_id => channel_id,  
    dout =>  stream_core_dout,
    valid =>  stream_core_valid,
    last =>  stream_core_last


);





hermes_module_inst: entity work.daphne_streaming_top
port map
    (
    S_AXI_ACLK	    => TRIRG_S_AXI_ACLK,
	S_AXI_ARESETN	=> TRIRG_S_AXI_ARESETN,
	S_AXI_AWADDR	=> CORE_AXI_AWADDR,
	S_AXI_AWPROT	=> CORE_AXI_AWPROT,
	S_AXI_AWVALID	=> CORE_AXI_AWVALID,
	S_AXI_AWREADY	=> CORE_AXI_AWREADY,
	S_AXI_WDATA	    => CORE_AXI_WDATA,
	S_AXI_WSTRB	    => CORE_AXI_WSTRB,
	S_AXI_WVALID	=> CORE_AXI_WVALID,
	S_AXI_WREADY	=> CORE_AXI_WREADY,
	S_AXI_BRESP	    => CORE_AXI_BRESP,
	S_AXI_BVALID	=> CORE_AXI_BVALID,
	S_AXI_BREADY	=> CORE_AXI_BREADY,
	S_AXI_ARADDR	=> CORE_AXI_ARADDR,
	S_AXI_ARPROT	=> CORE_AXI_ARPROT,
	S_AXI_ARVALID	=> CORE_AXI_ARVALID,
	S_AXI_ARREADY	=> CORE_AXI_ARREADY,
	S_AXI_RDATA	    => CORE_AXI_RDATA,
	S_AXI_RRESP	    => CORE_AXI_RRESP,
	S_AXI_RVALID	=> CORE_AXI_RVALID,
	S_AXI_RREADY	=> CORE_AXI_RREADY,
        
        eth_rx_p =>  eth_rx_p, -- Ethernet rx from SFP
        eth_rx_n => eth_rx_n ,
        eth_tx_p =>  eth_tx_p, -- Ethernet tx to SFP
        eth_tx_n => eth_tx_n ,
        eth_tx_dis =>  eth_tx_dis, -- SFP tx_disable
    
        eth_clk_p => eth_clk_p,   -- Transceiver refclk
        eth_clk_n =>  eth_clk_n,
        
        dune_base_clk  => clock, -- DUNE base clock
        dune_base_rst  =>  '0',   -- DUNE base clock sync reset

        data_clk =>  clock,
        data_clk_rst => '0', 
        
        d0         => stream_core_dout(0),
        d0_valid   =>  stream_core_valid(0),
        d0_last    =>  stream_core_last(0),

        d1         => stream_core_dout(1),
        d1_valid   =>  stream_core_valid(1),
        d1_last    =>  stream_core_last(1),

        d2         => stream_core_dout(2),
        d2_valid   =>  stream_core_valid(2),
        d2_last    =>  stream_core_last(2),

        d3         => stream_core_dout(3),
        d3_valid   =>  stream_core_valid(3),
        d3_last    =>  stream_core_last(3),

        d4         => stream_core_dout(4),
        d4_valid   =>  stream_core_valid(4),
        d4_last    =>  stream_core_last(4),

        d5         => stream_core_dout(5),
        d5_valid   =>  stream_core_valid(5),
        d5_last    =>  stream_core_last(5),

        d6         => stream_core_dout(6),
        d6_valid   =>  stream_core_valid(6),
        d6_last    =>  stream_core_last(6),

        d7         => stream_core_dout(7),
        d7_valid   =>  stream_core_valid(7),
        d7_last    =>  stream_core_last(7),

        ts  => timestamp,
        
        ext_mac_addr_0   =>  ext_mac_addr_0,
        ext_ip_addr_0    =>   ext_ip_addr_0,
        ext_port_addr_0 =>  ext_port_addr_0,
         
        ext_mac_addr_1   => ext_mac_addr_1,
        ext_ip_addr_1    =>  ext_ip_addr_1,
        ext_port_addr_1  =>  ext_port_addr_1,
        
        ext_mac_addr_2   =>  ext_mac_addr_2,
        ext_ip_addr_2    =>  ext_ip_addr_2,
        ext_port_addr_2  =>  ext_port_addr_2,
        
        ext_mac_addr_3   =>  ext_mac_addr_3,
        ext_ip_addr_3   =>  ext_ip_addr_3,
        ext_port_addr_3  =>  ext_port_addr_3
    
    
    
    
    
    );


out_buff_data_reg <=  stream_core_dout;
valid_debug_reg <= stream_core_valid;
last_debug_reg <= stream_core_last;
 
outbuff_inst: entity work.outspybuff

port map(

	    clock =>  clock,
	    
	    din =>  out_buff_data_reg, 
	    Valid =>  valid_debug_reg,
	    last =>  last_debug_reg,
	    AXI_IN =>  AXI_IN_OUT_BUFF,
	    AXI_OUT =>  AXI_OUT_OUT_BUFF


);

    
     --debugging signals
    out_buff_trig <= trig_IN;
    out_buff_clk  <= clock;
    out_buff_data <= out_buff_data_reg(0);
    
   -- DIN_DEBUG <= input_mux_data(0)(0));
     VALID_DEBUG <= valid_debug_reg(0);
     LAST_DEBUG <= last_debug_reg(0);
         
    
-- TO DO: add Xilinx IP block: ZYNQ_PS
-- this IP block requires parameters that must be set by the TCL build script

-- TO DO: add Xilinx IP block: AXI SmartConnecct
-- this IP block requires parameters that must be set by the TCL build script

-- Jonathan recommends we make a top level graphical block with the ZYNQ_PS and 
-- AXI SmartConnect blocks wired up. Bring the 9 AXI-Lite buses to "IO pins" on this 
-- block diagram, THEN export the block as VHDL. Instantiate that HERE. This way we 
-- can keep the project top level as VHDL and keep it GIT friendly.

end DAPHNE3_arch;
