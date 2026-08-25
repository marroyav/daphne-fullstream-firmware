-- stream_top_wrapper.vhd
--
-- Legacy reference wrapper. The active IP packaging flow excludes this file
-- in xilinx/daphne_fullstream_ip_gen.tcl. It is retained for provenance and is
-- not a supported top-level implementation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ipbus;
use work.ipbus.all;
use work.daphne3_package.all;
library deimos;
use work.tx_mux_decl.all;
use work.freq_pkg.all;
entity stream_top_wrapper is
generic (
    N_SRC: positive  := 2;   -- each mux has 2 inputs
    N_MGT: positive  := 4    -- four transceivers
);
port(
    clock: in std_logic; -- 62.5MHz master clock
    reset: in std_logic;
    ts: in std_logic_vector(63 downto 0); -- timestamp

    din00: std_logic_vector(13 downto 0); -- AFE data after alignment
    din01: std_logic_vector(13 downto 0);
    din02: std_logic_vector(13 downto 0);
    din03: std_logic_vector(13 downto 0);
    din04: std_logic_vector(13 downto 0);
    din05: std_logic_vector(13 downto 0);
    din06: std_logic_vector(13 downto 0);
    din07: std_logic_vector(13 downto 0);
    din08: std_logic_vector(13 downto 0);
    din09: std_logic_vector(13 downto 0);
    din10: std_logic_vector(13 downto 0);
    din11: std_logic_vector(13 downto 0);
    din12: std_logic_vector(13 downto 0);
    din13: std_logic_vector(13 downto 0);
    din14: std_logic_vector(13 downto 0);
    din15: std_logic_vector(13 downto 0);
    din16: std_logic_vector(13 downto 0);
    din17: std_logic_vector(13 downto 0);
    din18: std_logic_vector(13 downto 0);
    din19: std_logic_vector(13 downto 0);
    din20: std_logic_vector(13 downto 0);
    din21: std_logic_vector(13 downto 0);
    din22: std_logic_vector(13 downto 0);
    din23: std_logic_vector(13 downto 0);
    din24: std_logic_vector(13 downto 0);
    din25: std_logic_vector(13 downto 0);
    din26: std_logic_vector(13 downto 0);
    din27: std_logic_vector(13 downto 0);
    din28: std_logic_vector(13 downto 0);
    din29: std_logic_vector(13 downto 0);
    din30: std_logic_vector(13 downto 0);
    din31: std_logic_vector(13 downto 0);

	S_AXI_ACLK	    : in std_logic;  -- axi lite interface is used for IPBUS stuff...
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
	S_AXI_RREADY	: in std_logic;

    eth_clk_p: in std_logic; -- I/O for mgt refclk 156.25MHz
    eth_clk_n: in std_logic;

    eth_rx_p: in std_logic_vector(N_MGT-1 downto 0); -- I/O for SFPs
    eth_rx_n: in std_logic_vector(N_MGT-1 downto 0);
    eth_tx_p: out std_logic_vector(N_MGT-1 downto 0);
    eth_tx_n: out std_logic_vector(N_MGT-1 downto 0);
    eth_tx_dis: out std_logic_vector(N_MGT-1 downto 0)

  );
end stream_top_wrapper;

architecture stream_top_wrapper_arch of stream_top_wrapper is

component stream4
    generic( BLOCKS_PER_RECORD: integer := 64 ); 
    port(
        clock: in std_logic;
        areset: in std_logic;
        ts: in std_logic_vector(63 downto 0);
        din: array_4x14_type;
        dout:  out std_logic_vector(63 downto 0);
        valid: out std_logic;
        last: out std_logic
    );
end component;

component daphne_streaming_top
   -- generic(
       -- N_SRC: positive;
      --  N_MGT: positive;
      --  IN_BUF_DEPTH: natural;
      --  REF_FREQ: t_freq := f156_25
    --);
    port(
        S_AXI_ACLK: in std_logic;
        S_AXI_ARESETN: in std_logic;
        S_AXI_AWADDR: in std_logic_vector(15 downto 0);
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
        S_AXI_ARADDR: in std_logic_vector(15 downto 0);
        S_AXI_ARPROT: in std_logic_vector(2 downto 0);
        S_AXI_ARVALID: in std_logic;
        S_AXI_ARREADY: out std_logic;
        S_AXI_RDATA: out std_logic_vector(31 downto 0);
        S_AXI_RRESP: out std_logic_vector(1 downto 0);
        S_AXI_RVALID: out std_logic;
        S_AXI_RREADY: in std_logic;
        
        eth_rx_p: in  std_logic_vector(3 downto 0); -- Ethernet rx from SFP
        eth_rx_n: in  std_logic_vector(3 downto 0);
        eth_tx_p: out std_logic_vector(3 downto 0); -- Ethernet tx to SFP
        eth_tx_n: out std_logic_vector(3 downto 0);
        eth_tx_dis: out std_logic_vector(3 downto 0); -- SFP tx_disable
    
        eth_clk_p: in std_logic; -- Transceiver refclk
        eth_clk_n: in std_logic;
        
        dune_base_clk: in std_logic; -- DUNE base clock
        dune_base_rst: in std_logic; -- DUNE base clock sync reset

        data_clk: in std_logic; 
        data_clk_rst: in std_logic;
        
        d0: in std_logic_vector(63 downto 0);
        d0_valid: in std_logic;
        d0_last: in std_logic;

        d1: in std_logic_vector(63 downto 0);
        d1_valid: in std_logic;
        d1_last: in std_logic;

        d2: in std_logic_vector(63 downto 0);
        d2_valid: in std_logic;
        d2_last: in std_logic;

        d3: in std_logic_vector(63 downto 0);
        d3_valid: in std_logic;
        d3_last: in std_logic;

        d4: in std_logic_vector(63 downto 0);
        d4_valid: in std_logic;
        d4_last: in std_logic;

        d5: in std_logic_vector(63 downto 0);
        d5_valid: in std_logic;
        d5_last: in std_logic;

        d6: in std_logic_vector(63 downto 0);
        d6_valid: in std_logic;
        d6_last: in std_logic;

        d7: in std_logic_vector(63 downto 0);
        d7_valid: in std_logic;
        d7_last: in std_logic;

        ts : in std_logic_vector(63 downto 0);
        
        ext_mac_addr_0  : in std_logic_vector(47 downto 0);
        ext_ip_addr_0   : in std_logic_vector(31 downto 0);
        ext_port_addr_0 : in std_logic_vector(15 downto 0);
        
        ext_mac_addr_1  : in std_logic_vector(47 downto 0);
        ext_ip_addr_1   : in std_logic_vector(31 downto 0);
        ext_port_addr_1 : in std_logic_vector(15 downto 0);
        
        ext_mac_addr_2  : in std_logic_vector(47 downto 0);
        ext_ip_addr_2   : in std_logic_vector(31 downto 0);
        ext_port_addr_2 : in std_logic_vector(15 downto 0);
        
        ext_mac_addr_3  : in std_logic_vector(47 downto 0);
        ext_ip_addr_3   : in std_logic_vector(31 downto 0);
        ext_port_addr_3 : in std_logic_vector(15 downto 0) 
    );
end component;


 

 

type stream_din_mgt_type is array(N_MGT-1 downto 0) of array_4x14_type;
type stream_din_mgt_mux_type is array(N_SRC-1 downto 0) of stream_din_mgt_type;

signal stream_din: stream_din_mgt_mux_type;
signal d: array_of_src_d_arrays(N_MGT-1 downto 0)(N_SRC-1 downto 0); -- type declared in tx_mux_decl


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

signal        d0:  std_logic_vector(63 downto 0);
signal        d0_valid:  std_logic;
signal        d0_last:  std_logic;

signal        d1:  std_logic_vector(63 downto 0);
signal        d1_valid:  std_logic;
signal        d1_last:  std_logic;

signal        d2:  std_logic_vector(63 downto 0);
signal        d2_valid:  std_logic;
signal        d2_last:  std_logic;

signal        d3:  std_logic_vector(63 downto 0);
signal        d3_valid:  std_logic;
signal        d3_last:  std_logic;

 signal       d4:  std_logic_vector(63 downto 0);
signal        d4_valid:  std_logic;
signal        d4_last:  std_logic;

 signal       d5:  std_logic_vector(63 downto 0);
 signal       d5_valid:  std_logic;
 signal       d5_last:  std_logic;

 signal       d6:  std_logic_vector(63 downto 0);
signal        d6_valid:  std_logic;
 signal       d6_last:  std_logic;

 signal       d7:  std_logic_vector(63 downto 0);
 signal       d7_valid:  std_logic;
 signal       d7_last:  std_logic;

begin




-- simple input mapping into stream_din(mgt)(mux)(input)

stream_din(0)(0)(0) <= din00;
stream_din(0)(0)(1) <= din01;
stream_din(0)(0)(2) <= din02;
stream_din(0)(0)(3) <= din03;

stream_din(0)(1)(0) <= din04;
stream_din(0)(1)(1) <= din05; 
stream_din(0)(1)(2) <= din06;
stream_din(0)(1)(3) <= din07;

stream_din(1)(0)(0) <= din08;
stream_din(1)(0)(1) <= din09;
stream_din(1)(0)(2) <= din10;
stream_din(1)(0)(3) <= din11;

stream_din(1)(1)(0) <= din12;
stream_din(1)(1)(1) <= din13;
stream_din(1)(1)(2) <= din14;
stream_din(1)(1)(3) <= din15;

stream_din(2)(0)(0) <= din00;
stream_din(2)(0)(1) <= din01;
stream_din(2)(0)(2) <= din02;
stream_din(2)(0)(3) <= din03;

stream_din(2)(1)(0) <= din04;
stream_din(2)(1)(1) <= din05;
stream_din(2)(1)(2) <= din06;
stream_din(2)(1)(3) <= din07;

stream_din(3)(0)(0) <= din08;
stream_din(3)(0)(1) <= din09;
stream_din(3)(0)(2) <= din10;
stream_din(3)(0)(3) <= din11;

stream_din(3)(1)(0) <= din12;
stream_din(3)(1)(1) <= din13;
stream_din(3)(1)(2) <= din14;
stream_din(3)(1)(3) <= din15;

-- One streaming sender per MGT/source pair.

genMGT: for mgt in N_MGT-1 downto 0 generate
genMUX: for mux in N_SRC-1 downto 0 generate

    stream4_inst: stream4
        generic map( BLOCKS_PER_RECORD => 64 )
        port map(
            clock  => clock,
            areset => reset,
            ts     => ts,
            din    => stream_din(mgt)(mux),
            -- Legacy wrapper: payload output is intentionally unassociated.
            -- Verify the mapping before reactivating this path.
            valid  => d(mgt)(mux).valid, 
            last   => d(mgt)(mux).last
        );

end generate genMUX;
end generate genMGT;

-- 10G Ethernet sender

wib_eth_readout_inst: component daphne_streaming_top
   -- generic map(
       -- N_SRC => N_SRC,
       -- N_MGT => N_MGT
   -- );
    port map(

        --ipb_clk => ipb_clk, -- IPBUS 
        --ipb_rst => ipb_rst,
        --ipb_in => ipb_in,
       -- ipb_out => ipb_out,

        eth_rx_p => eth_rx_p, 
        eth_rx_n => eth_rx_n,
        eth_tx_p => eth_tx_p,
        eth_tx_n => eth_tx_n,
        eth_tx_dis => eth_tx_dis,

        eth_clk_p => eth_clk_p, 
        eth_clk_n => eth_clk_n,

        --clk => clock,
       -- rst => reset,
        dune_base_clk => clock, -- DUNE base clock
        dune_base_rst=> reset, -- DUNE base clock sync reset

        data_clk => clock, 
        data_clk_rst=> reset,
        d0=> d0 ,
        d0_valid=> d0_valid,
        d0_last=> d0_last,

        d1=>  d1 ,
        d1_valid=> d1_valid,
        d1_last=> d1_last,
        
        d2=>  d2 ,
        d2_valid=> d2_valid,
        d2_last=> d2_last,

        d3=>  d3 ,
        d3_valid=> d3_valid,
        d3_last=> d3_last,

        d4=>  d4 ,
        d4_valid=> d4_valid,
        d4_last=> d4_last,

        d5=>  d5 ,
        d5_valid=> d5_valid,
        d5_last=> d5_last,

        d6=>  d6 ,
        d6_valid=> d6_valid,
        d6_last=> d6_last,

        d7=>  d7 ,
        d7_valid=> d7_valid,
        d7_last=> d7_last,
        
        
        ts => ts,

        --nuke => open,
        --soft_rst => open,

        ext_mac_addr_0 =>   ext_mac_addr_0, -- legacy signal; no driver in this architecture
        ext_ip_addr_0  =>     ext_ip_addr_0,
        ext_port_addr_0 =>  ext_port_addr_0   ,
        

        
        ext_mac_addr_1   =>    ext_mac_addr_1,
        ext_ip_addr_1    =>    ext_ip_addr_1,
        ext_port_addr_1  =>    ext_port_addr_1,
        
        ext_mac_addr_2  =>    ext_mac_addr_2,
        ext_ip_addr_2    =>    ext_ip_addr_2,
        ext_port_addr_2  =>    ext_port_addr_2,
        
        ext_mac_addr_3   =>    ext_mac_addr_3,
        ext_ip_addr_3    =>    ext_ip_addr_3,
        ext_port_addr_3  =>    ext_port_addr_3     ,  
        --axi-light signals for ipbus  
        
        
        S_AXI_ACLK  =>   S_AXI_ACLK,
        S_AXI_ARESETN  =>  S_AXI_ARESETN,
        S_AXI_AWADDR  =>  S_AXI_AWADDR,
        S_AXI_AWPROT  => S_AXI_AWPROT,
        S_AXI_AWVALID  =>  S_AXI_AWVALID,
        S_AXI_AWREADY  =>  S_AXI_AWREADY,
        S_AXI_WDATA  =>  S_AXI_WDATA,
        S_AXI_WSTRB  =>  S_AXI_WSTRB,
        S_AXI_WVALID  =>   S_AXI_WVALID,
        S_AXI_WREADY  =>  S_AXI_WREADY,
        S_AXI_BRESP  =>  S_AXI_BRESP,
        S_AXI_BVALID  =>  S_AXI_BVALID,
        S_AXI_BREADY  =>  S_AXI_BREADY,
        S_AXI_ARADDR  => S_AXI_ARADDR ,
        S_AXI_ARPROT  =>  S_AXI_ARPROT,
        S_AXI_ARVALID  =>  S_AXI_ARVALID,
        S_AXI_ARREADY  =>  S_AXI_ARREADY,
        S_AXI_RDATA  =>  S_AXI_RDATA,
        S_AXI_RRESP  =>  S_AXI_RRESP,
        S_AXI_RVALID  =>  S_AXI_RVALID ,
        S_AXI_RREADY  =>  S_AXI_RREADY
    );

-- another module needed here!
-- something to translate AXI_LITE to IPBUS
-- this should exist already for the wib....




end stream_top_wrapper_arch;
