library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.daphne3_package.all;

entity stream_input_mux_axi_smoke_tb is
end entity stream_input_mux_axi_smoke_tb;

architecture tb of stream_input_mux_axi_smoke_tb is
    constant AXI_CLK_PERIOD_C    : time := 10 ns;
    constant STREAM_CLK_PERIOD_C : time := 16 ns;
    constant MUX_BASE_C          : std_logic_vector(31 downto 0) := x"A0020000";

    signal axi_clk       : std_logic := '0';
    signal stream_clk    : std_logic := '0';
    signal aresetn       : std_logic := '0';
    signal awaddr        : std_logic_vector(31 downto 0) := (others => '0');
    signal awprot        : std_logic_vector(2 downto 0) := (others => '0');
    signal awvalid       : std_logic := '0';
    signal wdata         : std_logic_vector(31 downto 0) := (others => '0');
    signal wstrb         : std_logic_vector(3 downto 0) := (others => '0');
    signal wvalid        : std_logic := '0';
    signal bready        : std_logic := '1';
    signal araddr        : std_logic_vector(31 downto 0) := (others => '0');
    signal arprot        : std_logic_vector(2 downto 0) := (others => '0');
    signal arvalid       : std_logic := '0';
    signal rready        : std_logic := '1';
    signal axi_in        : AXILITE_INREC;
    signal axi_out       : AXILITE_OUTREC;

    signal din           : array_5x9x16_type :=
        (others => (others => (others => '0')));
    signal dout          : array_8x4x14_type;
    signal muxctrl       : array_8x4x8_type;
    signal stream_enable : std_logic;

    function axi_address(constant offset : natural)
        return std_logic_vector is
    begin
        return std_logic_vector(unsigned(MUX_BASE_C) + to_unsigned(offset, 32));
    end function axi_address;

    function programmed_selector(
        constant flat_index : natural;
        constant afe2_selector : std_logic_vector(7 downto 0)
    ) return std_logic_vector is
    begin
        case flat_index is
            when 0  => return x"00"; -- board AFE 0 -> PL din(0)
            when 4  => return x"10"; -- board AFE 1 -> PL din(4)
            when 8  => return afe2_selector; -- board AFE 2 -> PL din(3)
            when 12 => return x"30"; -- board AFE 3 -> PL din(2)
            when 16 => return x"40"; -- board AFE 4 -> PL din(1)
            when 31 => return x"50"; -- all-ones diagnostic
            when others => return x"FF";
        end case;
    end function programmed_selector;

    procedure axi_write(
        constant addr        : in std_logic_vector(31 downto 0);
        constant data        : in std_logic_vector(31 downto 0);
        constant byte_strobe : in std_logic_vector(3 downto 0);
        signal awaddr_s      : out std_logic_vector(31 downto 0);
        signal awvalid_s     : out std_logic;
        signal wdata_s       : out std_logic_vector(31 downto 0);
        signal wstrb_s       : out std_logic_vector(3 downto 0);
        signal wvalid_s      : out std_logic;
        signal awready_s     : in std_logic;
        signal wready_s      : in std_logic;
        signal bvalid_s      : in std_logic;
        signal bresp_s       : in std_logic_vector(1 downto 0);
        signal clk_s         : in std_logic
    ) is
    begin
        awaddr_s <= addr;
        awvalid_s <= '1';
        wdata_s <= data;
        wstrb_s <= byte_strobe;
        wvalid_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        assert awready_s = '1' and wready_s = '1'
            report "AXI slave did not accept write address/data"
            severity failure;
        wait until rising_edge(clk_s);
        wait for 1 ns;
        awvalid_s <= '0';
        wvalid_s <= '0';
        assert bvalid_s = '1'
            report "AXI slave did not return a write response"
            severity failure;
        assert bresp_s = "00"
            report "AXI slave returned a non-OKAY write response"
            severity failure;
        wait until rising_edge(clk_s);
    end procedure axi_write;

    procedure axi_read(
        constant addr       : in std_logic_vector(31 downto 0);
        signal araddr_s     : out std_logic_vector(31 downto 0);
        signal arvalid_s    : out std_logic;
        signal arready_s    : in std_logic;
        signal rdata_s      : in std_logic_vector(31 downto 0);
        signal rvalid_s     : in std_logic;
        signal rresp_s      : in std_logic_vector(1 downto 0);
        signal clk_s        : in std_logic;
        variable read_data  : out std_logic_vector(31 downto 0)
    ) is
    begin
        araddr_s <= addr;
        arvalid_s <= '1';
        wait until rising_edge(clk_s);
        wait for 1 ns;
        assert arready_s = '1'
            report "AXI slave did not accept read address"
            severity failure;
        wait until rising_edge(clk_s);
        wait for 1 ns;
        arvalid_s <= '0';
        assert rvalid_s = '1'
            report "AXI slave did not return read data"
            severity failure;
        assert rresp_s = "00"
            report "AXI slave returned a non-OKAY read response"
            severity failure;
        read_data := rdata_s;
        wait until rising_edge(clk_s);
    end procedure axi_read;

    procedure expect_read(
        constant addr       : in std_logic_vector(31 downto 0);
        constant expected   : in std_logic_vector(31 downto 0);
        constant message    : in string;
        signal araddr_s     : out std_logic_vector(31 downto 0);
        signal arvalid_s    : out std_logic;
        signal arready_s    : in std_logic;
        signal rdata_s      : in std_logic_vector(31 downto 0);
        signal rvalid_s     : in std_logic;
        signal rresp_s      : in std_logic_vector(1 downto 0);
        signal clk_s        : in std_logic
    ) is
        variable actual : std_logic_vector(31 downto 0);
    begin
        axi_read(
            addr, araddr_s, arvalid_s, arready_s, rdata_s, rvalid_s,
            rresp_s, clk_s, actual
        );
        assert actual = expected report message severity failure;
    end procedure expect_read;

    procedure assert_all_disabled(
        signal muxctrl_s : in array_8x4x8_type;
        signal dout_s    : in array_8x4x14_type
    ) is
    begin
        for output_index in 0 to 7 loop
            for lane_index in 0 to 3 loop
                assert muxctrl_s(output_index)(lane_index) = x"FF"
                    report "Disabled selector mismatch at output " &
                           integer'image(output_index) & ", lane " &
                           integer'image(lane_index)
                    severity failure;
                assert dout_s(output_index)(lane_index) = "00000000000000"
                    report "Disabled mux output was not zero at output " &
                           integer'image(output_index) & ", lane " &
                           integer'image(lane_index)
                    severity failure;
            end loop;
        end loop;
    end procedure assert_all_disabled;

    procedure assert_atomic_boundary(
        signal muxctrl_s : in array_8x4x8_type;
        constant afe2_selector : in std_logic_vector(7 downto 0);
        constant message : in string
    ) is
        variable disabled_state : boolean := true;
        variable active_state   : boolean := true;
        variable flat_index     : natural;
    begin
        for output_index in 0 to 7 loop
            for lane_index in 0 to 3 loop
                flat_index := output_index * 4 + lane_index;
                disabled_state := disabled_state and
                    (muxctrl_s(output_index)(lane_index) = x"FF");
                active_state := active_state and
                    (muxctrl_s(output_index)(lane_index) =
                        programmed_selector(flat_index, afe2_selector));
            end loop;
        end loop;
        assert disabled_state or active_state report message severity failure;
    end procedure assert_atomic_boundary;
begin
    axi_clk <= not axi_clk after AXI_CLK_PERIOD_C / 2;
    stream_clk <= not stream_clk after STREAM_CLK_PERIOD_C / 2;

    axi_in <= (
        ACLK => axi_clk,
        ARESETN => aresetn,
        AWADDR => awaddr,
        AWPROT => awprot,
        AWVALID => awvalid,
        WDATA => wdata,
        WSTRB => wstrb,
        WVALID => wvalid,
        BREADY => bready,
        ARADDR => araddr,
        ARPROT => arprot,
        ARVALID => arvalid,
        RREADY => rready
    );

    dut : entity work.stream_input_mux
        port map (
            clock => stream_clk,
            din => din,
            dout => dout,
            muxctrl => muxctrl,
            stream_enable => stream_enable,
            AXI_IN => axi_in,
            AXI_OUT => axi_out
        );

    stimulus : process
        variable expected : std_logic_vector(31 downto 0);
        variable status   : std_logic_vector(31 downto 0);
    begin
        assert AXI_CLK_PERIOD_C /= STREAM_CLK_PERIOD_C
            report "Test requires independent AXI and stream clocks"
            severity failure;

        wait for 3 * AXI_CLK_PERIOD_C;
        aresetn <= '1';
        wait until rising_edge(axi_clk);
        wait for 1 ns;

        assert stream_enable = '0'
            report "Stream enable was asserted after reset"
            severity failure;
        assert_all_disabled(muxctrl, dout);
        for output_index in 0 to 7 loop
            for lane_index in 0 to 3 loop
                expected := (others => '0');
                expected(7 downto 0) := x"FF";
                expect_read(
                    axi_address(((output_index * 4) + lane_index) * 4),
                    expected,
                    "Mux shadow reset readback mismatch at output " &
                        integer'image(output_index) & ", lane " &
                        integer'image(lane_index),
                    araddr, arvalid, axi_out.ARREADY, axi_out.RDATA,
                    axi_out.RVALID, axi_out.RRESP, axi_clk
                );
            end loop;
        end loop;
        expect_read(
            axi_address(16#80#), x"00000000",
            "Activation request/acknowledgement did not reset disabled",
            araddr, arvalid, axi_out.ARREADY, axi_out.RDATA,
            axi_out.RVALID, axi_out.RRESP, axi_clk
        );

        -- Full-word strobes are required for both selector and control words.
        axi_write(
            axi_address(16#00#), x"00000000", "0001",
            awaddr, awvalid, wdata, wstrb, wvalid,
            axi_out.AWREADY, axi_out.WREADY, axi_out.BVALID,
            axi_out.BRESP, axi_clk
        );
        expect_read(
            axi_address(16#00#), x"000000FF",
            "Partial write changed a mux shadow",
            araddr, arvalid, axi_out.ARREADY, axi_out.RDATA,
            axi_out.RVALID, axi_out.RRESP, axi_clk
        );
        axi_write(
            axi_address(16#80#), x"00000001", "0001",
            awaddr, awvalid, wdata, wstrb, wvalid,
            axi_out.AWREADY, axi_out.WREADY, axi_out.BVALID,
            axi_out.BRESP, axi_clk
        );
        expect_read(
            axi_address(16#80#), x"00000000",
            "Partial write changed the activation request",
            araddr, arvalid, axi_out.ARREADY, axi_out.RDATA,
            axi_out.RVALID, axi_out.RRESP, axi_clk
        );

        -- Give each physical PL AFE input a distinct value. Board/logical AFE
        -- selectors 0,1,2,3,4 must source PL din indices 0,4,3,2,1 while the
        -- exported channel IDs remain the board-coded bytes 00,10,20,30,40.
        din(0)(0) <= x"1004";
        din(4)(0) <= x"2008";
        din(3)(0) <= x"300C";
        din(2)(0) <= x"4010";
        din(1)(0) <= x"5014";
        din(3)(1) <= x"6018";

        axi_write(axi_address(16#00#), x"00000000", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        axi_write(axi_address(16#10#), x"00000010", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        axi_write(axi_address(16#20#), x"00000020", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        axi_write(axi_address(16#30#), x"00000030", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        axi_write(axi_address(16#40#), x"00000040", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        axi_write(axi_address(16#7C#), x"00000050", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);

        for cycle in 1 to 4 loop
            wait until rising_edge(stream_clk);
        end loop;
        wait for 1 ns;
        assert stream_enable = '0'
            report "Shadow writes enabled the stream before commit"
            severity failure;
        assert_all_disabled(muxctrl, dout);

        -- The synchronized rising request captures every stable shadow on one
        -- stream-clock edge and returns an independently synchronized ack.
        axi_write(axi_address(16#80#), x"00000001", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        status := (others => '0');
        for attempt in 0 to 15 loop
            axi_read(axi_address(16#80#), araddr, arvalid, axi_out.ARREADY,
                axi_out.RDATA, axi_out.RVALID, axi_out.RRESP, axi_clk, status);
            assert status(0) = '1'
                report "Activation request bit did not read back as one"
                severity failure;
            assert_atomic_boundary(muxctrl, x"20",
                "Selector bank was observed partially committed");
            exit when status(1) = '1';
        end loop;
        assert status(1) = '1' and stream_enable = '1'
            report "Activation acknowledgement did not return"
            severity failure;
        assert_atomic_boundary(muxctrl, x"20",
            "Selector bank did not reach the programmed state");
        assert muxctrl(0)(0) = x"00" and dout(0)(0) = din(0)(0)(15 downto 2)
            report "Board AFE 0 selector/source mapping failed" severity failure;
        assert muxctrl(1)(0) = x"10" and dout(1)(0) = din(4)(0)(15 downto 2)
            report "Board AFE 1 selector/source mapping failed" severity failure;
        assert muxctrl(2)(0) = x"20" and dout(2)(0) = din(3)(0)(15 downto 2)
            report "Board AFE 2 selector/source mapping failed" severity failure;
        assert muxctrl(3)(0) = x"30" and dout(3)(0) = din(2)(0)(15 downto 2)
            report "Board AFE 3 selector/source mapping failed" severity failure;
        assert muxctrl(4)(0) = x"40" and dout(4)(0) = din(1)(0)(15 downto 2)
            report "Board AFE 4 selector/source mapping failed" severity failure;
        assert muxctrl(7)(3) = x"50" and dout(7)(3) = "11111111111111"
            report "Committed diagnostic selector failed" severity failure;

        -- Readback is always the AXI shadow. Changing it while active must not
        -- alter the selected data or exported channel ID until a new commit.
        axi_write(axi_address(16#20#), x"00000021", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        expect_read(axi_address(16#20#), x"00000021",
            "Active shadow update did not read back", araddr, arvalid,
            axi_out.ARREADY, axi_out.RDATA, axi_out.RVALID, axi_out.RRESP,
            axi_clk);
        for cycle in 1 to 4 loop
            wait until rising_edge(stream_clk);
        end loop;
        wait for 1 ns;
        assert muxctrl(2)(0) = x"20" and
               dout(2)(0) = din(3)(0)(15 downto 2)
            report "Shadow write leaked into the active stream bank"
            severity failure;

        -- Disable remains active until the stream domain accepts it. Once bit
        -- 1 returns zero, every exported ID is FF and every payload is zero.
        axi_write(axi_address(16#80#), x"00000000", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        status := (others => '1');
        for attempt in 0 to 15 loop
            axi_read(axi_address(16#80#), araddr, arvalid, axi_out.ARREADY,
                axi_out.RDATA, axi_out.RVALID, axi_out.RRESP, axi_clk, status);
            assert status(0) = '0'
                report "Disable request bit did not read back as zero"
                severity failure;
            assert_atomic_boundary(muxctrl, x"20",
                "Selector bank was observed partially disabled");
            exit when status(1) = '0';
        end loop;
        assert status(1) = '0' and stream_enable = '0'
            report "Disabled acknowledgement did not return"
            severity failure;
        assert_all_disabled(muxctrl, dout);
        expect_read(axi_address(16#20#), x"00000021",
            "Disable unexpectedly changed the selector shadow", araddr,
            arvalid, axi_out.ARREADY, axi_out.RDATA, axi_out.RVALID,
            axi_out.RRESP, axi_clk);

        -- A 0->1 request is required to commit the updated AFE 2 shadow.
        axi_write(axi_address(16#80#), x"00000001", "1111", awaddr,
            awvalid, wdata, wstrb, wvalid, axi_out.AWREADY, axi_out.WREADY,
            axi_out.BVALID, axi_out.BRESP, axi_clk);
        status := (others => '0');
        for attempt in 0 to 15 loop
            axi_read(axi_address(16#80#), araddr, arvalid, axi_out.ARREADY,
                axi_out.RDATA, axi_out.RVALID, axi_out.RRESP, axi_clk, status);
            assert_atomic_boundary(muxctrl, x"21",
                "Recommit exposed a partially updated selector bank");
            exit when status(1) = '1';
        end loop;
        assert status(1 downto 0) = "11" and stream_enable = '1'
            report "Reactivation request/acknowledgement did not complete"
            severity failure;
        assert muxctrl(2)(0) = x"21" and
               dout(2)(0) = din(3)(1)(15 downto 2)
            report "Reactivation did not capture the updated board AFE 2 shadow"
            severity failure;

        -- Reset assertion while active immediately returns the stream domain
        -- to fail-closed, then clears shadows/request on the AXI clock edge.
        wait for 3 ns;
        aresetn <= '0';
        wait for 1 ns;
        assert stream_enable = '0'
            report "Reset did not asynchronously clear stream enable"
            severity failure;
        assert_all_disabled(muxctrl, dout);
        wait until rising_edge(axi_clk);
        wait for 1 ns;
        aresetn <= '1';
        wait until rising_edge(axi_clk);
        wait for 1 ns;
        expect_read(axi_address(16#20#), x"000000FF",
            "Reset did not clear the selector shadow", araddr, arvalid,
            axi_out.ARREADY, axi_out.RDATA, axi_out.RVALID, axi_out.RRESP,
            axi_clk);
        expect_read(axi_address(16#80#), x"00000000",
            "Reset did not restore disabled request/acknowledgement", araddr,
            arvalid, axi_out.ARREADY, axi_out.RDATA, axi_out.RVALID,
            axi_out.RRESP, axi_clk);
        assert_all_disabled(muxctrl, dout);

        expect_read(axi_address(16#84#), x"00000000",
            "Unknown mux address did not read zero", araddr, arvalid,
            axi_out.ARREADY, axi_out.RDATA, axi_out.RVALID, axi_out.RRESP,
            axi_clk);

        report "stream-input-mux atomic activation CDC smoke test passed"
            severity note;
        wait;
    end process stimulus;
end architecture tb;
