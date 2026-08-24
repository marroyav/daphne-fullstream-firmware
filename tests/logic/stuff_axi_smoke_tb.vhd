library ieee;
use ieee.std_logic_1164.all;

use work.daphne3_package.all;

entity stuff_axi_smoke_tb is
end entity stuff_axi_smoke_tb;

architecture tb of stuff_axi_smoke_tb is
    constant CLK_PERIOD_C : time := 10 ns;

    signal clk      : std_logic := '0';
    signal aresetn  : std_logic := '0';
    signal awaddr   : std_logic_vector(31 downto 0) := (others => '0');
    signal awprot   : std_logic_vector(2 downto 0) := (others => '0');
    signal awvalid  : std_logic := '0';
    signal awready  : std_logic;
    signal wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal wstrb    : std_logic_vector(3 downto 0) := (others => '0');
    signal wvalid   : std_logic := '0';
    signal wready   : std_logic;
    signal bresp    : std_logic_vector(1 downto 0);
    signal bvalid   : std_logic;
    signal bready   : std_logic := '1';
    signal araddr   : std_logic_vector(31 downto 0) := (others => '0');
    signal arprot   : std_logic_vector(2 downto 0) := (others => '0');
    signal arvalid  : std_logic := '0';
    signal arready  : std_logic;
    signal rdata    : std_logic_vector(31 downto 0);
    signal rresp    : std_logic_vector(1 downto 0);
    signal rvalid   : std_logic;
    signal rready   : std_logic := '1';

    signal fan_tach         : std_logic_vector(1 downto 0) := "11";
    signal fan_ctrl         : std_logic;
    signal hvbias_en        : std_logic;
    signal mux_en           : std_logic_vector(1 downto 0);
    signal mux_a            : std_logic_vector(1 downto 0);
    signal stat_led         : std_logic_vector(5 downto 0);
    signal version          : std_logic_vector(3 downto 0) := x"A";
    signal core_chan_enable : std_logic_vector(39 downto 0);

    procedure axi_write(
        constant addr       : in std_logic_vector(31 downto 0);
        constant data       : in std_logic_vector(31 downto 0);
        constant byte_strobe: in std_logic_vector(3 downto 0);
        signal awaddr_s     : out std_logic_vector(31 downto 0);
        signal awvalid_s    : out std_logic;
        signal wdata_s      : out std_logic_vector(31 downto 0);
        signal wstrb_s      : out std_logic_vector(3 downto 0);
        signal wvalid_s     : out std_logic;
        signal bvalid_s     : in std_logic;
        signal clk_s        : in std_logic
    ) is
    begin
        awaddr_s <= addr;
        awvalid_s <= '1';
        wdata_s <= data;
        wstrb_s <= byte_strobe;
        wvalid_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        assert awready = '1' and wready = '1'
            report "AXI slave did not accept write address/data"
            severity failure;
        wait until rising_edge(clk_s);
        wait for 1 ns;
        awvalid_s <= '0';
        wvalid_s <= '0';
        assert bvalid_s = '1'
            report "AXI slave did not return a write response"
            severity failure;
        wait until rising_edge(clk_s);
    end procedure axi_write;

    procedure axi_read(
        constant addr    : in std_logic_vector(31 downto 0);
        signal araddr_s  : out std_logic_vector(31 downto 0);
        signal arvalid_s : out std_logic;
        signal rdata_s   : in std_logic_vector(31 downto 0);
        signal rvalid_s  : in std_logic;
        signal clk_s     : in std_logic;
        variable data    : out std_logic_vector(31 downto 0)
    ) is
    begin
        araddr_s <= addr;
        arvalid_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        assert arready = '1'
            report "AXI slave did not accept read address"
            severity failure;
        wait until rising_edge(clk_s);
        wait for 1 ns;
        arvalid_s <= '0';
        assert rvalid_s = '1'
            report "AXI slave did not return read data"
            severity failure;
        data := rdata_s;
        wait until rising_edge(clk_s);
    end procedure axi_read;

    procedure expect_read(
        constant addr     : in std_logic_vector(31 downto 0);
        constant expected : in std_logic_vector(31 downto 0);
        constant message  : in string;
        signal araddr_s   : out std_logic_vector(31 downto 0);
        signal arvalid_s  : out std_logic;
        signal rdata_s    : in std_logic_vector(31 downto 0);
        signal rvalid_s   : in std_logic;
        signal clk_s      : in std_logic
    ) is
        variable actual : std_logic_vector(31 downto 0);
    begin
        axi_read(addr, araddr_s, arvalid_s, rdata_s, rvalid_s, clk_s, actual);
        assert actual = expected report message severity failure;
    end procedure expect_read;
begin
    clk <= not clk after CLK_PERIOD_C / 2;

    dut : entity work.stuff
        port map (
            fan_tach => fan_tach,
            fan_ctrl => fan_ctrl,
            hvbias_en => hvbias_en,
            mux_en => mux_en,
            mux_a => mux_a,
            stat_led => stat_led,
            version => version,
            core_chan_enable => core_chan_enable,
            S_AXI_ACLK => clk,
            S_AXI_ARESETN => aresetn,
            S_AXI_AWADDR => awaddr,
            S_AXI_AWPROT => awprot,
            S_AXI_AWVALID => awvalid,
            S_AXI_AWREADY => awready,
            S_AXI_WDATA => wdata,
            S_AXI_WSTRB => wstrb,
            S_AXI_WVALID => wvalid,
            S_AXI_WREADY => wready,
            S_AXI_BRESP => bresp,
            S_AXI_BVALID => bvalid,
            S_AXI_BREADY => bready,
            S_AXI_ARADDR => araddr,
            S_AXI_ARPROT => arprot,
            S_AXI_ARVALID => arvalid,
            S_AXI_ARREADY => arready,
            S_AXI_RDATA => rdata,
            S_AXI_RRESP => rresp,
            S_AXI_RVALID => rvalid,
            S_AXI_RREADY => rready
        );

    stimulus : process
    begin
        wait for 3 * CLK_PERIOD_C;
        aresetn <= '1';
        wait until rising_edge(clk);

        assert hvbias_en = '0' report "HV enable reset value is not zero" severity failure;
        assert mux_en = "00" report "MUX enable reset value is not zero" severity failure;
        assert mux_a = "00" report "MUX address reset value is not zero" severity failure;
        assert stat_led = "000000" report "LED reset value is not zero" severity failure;
        assert core_chan_enable = DEFAULT_core_enable
            report "Channel-enable reset value differs from package default"
            severity failure;

        expect_read(x"00000000", x"000000FF", "Fan demand reset readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000004", x"00000000", "Fan 0 RPM reset readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000008", x"00000000", "Fan 1 RPM reset readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"0000001C", x"0000000A", "Version readback failed",
                    araddr, arvalid, rdata, rvalid, clk);

        axi_write(x"00000000", x"00000055", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"0000000C", x"00000001", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"00000010", x"00000002", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"00000014", x"00000003", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"00000018", x"00000015", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"00000020", x"A5A55AA5", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        axi_write(x"00000024", x"0000005A", "1111",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);

        assert hvbias_en = '1' report "HV enable write did not reach output" severity failure;
        assert mux_en = "10" report "MUX enable write did not reach output" severity failure;
        assert mux_a = "11" report "MUX address write did not reach output" severity failure;
        assert stat_led = "010101" report "LED write did not reach output" severity failure;
        assert core_chan_enable = x"5AA5A55AA5"
            report "Channel-enable writes did not reach output"
            severity failure;

        expect_read(x"00000000", x"00000055", "Fan demand write/readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"0000000C", x"00000001", "HV enable write/readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000010", x"00000002", "MUX enable write/readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000014", x"00000003", "MUX address write/readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000018", x"00000015", "LED write/readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000020", x"A5A55AA5", "Low channel mask readback failed",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000024", x"0000005A", "High channel mask readback failed",
                    araddr, arvalid, rdata, rvalid, clk);

        -- Partial writes are intentionally rejected by this legacy interface.
        axi_write(x"00000000", x"00000011", "0001",
                  awaddr, awvalid, wdata, wstrb, wvalid, bvalid, clk);
        expect_read(x"00000000", x"00000055", "Partial write changed fan demand",
                    araddr, arvalid, rdata, rvalid, clk);
        expect_read(x"00000028", x"00000000", "Unknown address did not read zero",
                    araddr, arvalid, rdata, rvalid, clk);

        assert bresp = "00" report "AXI write response was not OKAY" severity failure;
        assert rresp = "00" report "AXI read response was not OKAY" severity failure;
        report "board-control AXI smoke test passed" severity note;
        wait;
    end process stimulus;
end architecture tb;
