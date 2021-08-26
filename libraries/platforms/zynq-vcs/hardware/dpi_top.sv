`default_nettype none
module replicant_tb_top
  import bsg_manycore_pkg::*;
  import bsg_bladerunner_pkg::*;
  #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 9
    )
  (
   );


   // Uncomment this to enable VCD Dumping
   /*
    initial begin
    $display("[%0t] Tracing to vlt_dump.vcd...\n", $time);
    $dumpfile("dump.vcd");
    $dumpvars();
   end
    */
   initial begin
      #0;
      
      $display("==================== BSG MACHINE SETTINGS: ====================");

      $display("[INFO][TESTBENCH] bsg_machine_pods_x_gp                 = %d", bsg_machine_pods_x_gp);
      $display("[INFO][TESTBENCH] bsg_machine_pods_y_gp                 = %d", bsg_machine_pods_y_gp);

      $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_x_gp            = %d", bsg_machine_pod_tiles_x_gp);
      $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_y_gp            = %d", bsg_machine_pod_tiles_y_gp);
      $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_subarray_x_gp   = %d", bsg_machine_pod_tiles_subarray_x_gp);
      $display("[INFO][TESTBENCH] bsg_machine_pod_tiles_subarray_y_gp   = %d", bsg_machine_pod_tiles_subarray_y_gp);
      $display("[INFO][TESTBENCH] bsg_machine_pod_llcache_rows_gp       = %d", bsg_machine_pod_llcache_rows_gp);

      $display("[INFO][TESTBENCH] bsg_machine_noc_cfg_gp                = %s", bsg_machine_noc_cfg_gp.name());
      $display("[INFO][TESTBENCH] bsg_machine_noc_ruche_factor_X_gp     = %d", bsg_machine_noc_ruche_factor_X_gp);

      $display("[INFO][TESTBENCH] bsg_machine_noc_epa_width_gp          = %d", bsg_machine_noc_epa_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_noc_data_width_gp         = %d", bsg_machine_noc_data_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_noc_coord_x_width_gp      = %d", bsg_machine_noc_coord_x_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_noc_coord_y_width_gp      = %d", bsg_machine_noc_coord_y_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_noc_pod_coord_x_width_gp  = %d", bsg_machine_noc_pod_coord_x_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_noc_pod_coord_y_width_gp  = %d", bsg_machine_noc_pod_coord_y_width_gp);

      $display("[INFO][TESTBENCH] bsg_machine_llcache_sets_gp           = %d", bsg_machine_llcache_sets_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_ways_gp           = %d", bsg_machine_llcache_ways_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_line_words_gp     = %d", bsg_machine_llcache_line_words_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_words_gp          = %d", bsg_machine_llcache_words_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_miss_fifo_els_gp  = %d", bsg_machine_llcache_miss_fifo_els_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_channel_width_gp  = %d", bsg_machine_llcache_channel_width_gp);
      $display("[INFO][TESTBENCH] bsg_machine_llcache_dram_channel_ratio_gp = %d", bsg_machine_llcache_dram_channel_ratio_gp);

      $display("[INFO][TESTBENCH] bsg_machine_dram_bank_words_gp        = %d", bsg_machine_dram_bank_words_gp);
      $display("[INFO][TESTBENCH] bsg_machine_dram_channels_gp          = %d", bsg_machine_dram_channels_gp);
      $display("[INFO][TESTBENCH] bsg_machine_dram_words_gp             = %d", bsg_machine_dram_words_gp);
      $display("[INFO][TESTBENCH] bsg_machine_dram_cfg_gp               = %s", bsg_machine_dram_cfg_gp.name());

      $display("[INFO][TESTBENCH] bsg_machine_io_coord_x_gp             = %d", bsg_machine_io_coord_x_gp);
      $display("[INFO][TESTBENCH] bsg_machine_io_coord_y_gp             = %d", bsg_machine_io_coord_y_gp);

      $display("[INFO][TESTBENCH] bsg_machine_enable_vcore_profiling_lp = %d", bsg_machine_enable_vcore_profiling_lp);
      $display("[INFO][TESTBENCH] bsg_machine_enable_router_profiling_lp= %d", bsg_machine_enable_router_profiling_lp);
      $display("[INFO][TESTBENCH] bsg_machine_enable_cache_profiling_lp = %d", bsg_machine_enable_cache_profiling_lp);

      $display("[INFO][TESTBENCH] bsg_machine_name_gp                   = %s", bsg_machine_name_gp);
   end

   localparam bsg_machine_llcache_data_width_lp = bsg_machine_noc_data_width_gp;
   localparam bsg_machine_llcache_addr_width_lp=(bsg_machine_noc_epa_width_gp-1+`BSG_SAFE_CLOG2(bsg_machine_noc_data_width_gp>>3));

   localparam bsg_machine_wh_flit_width_lp = bsg_machine_llcache_channel_width_gp;
   localparam bsg_machine_wh_ruche_factor_lp = 2;
   localparam bsg_machine_wh_cid_width_lp = `BSG_SAFE_CLOG2(bsg_machine_wh_ruche_factor_lp*2);
   localparam bsg_machine_wh_len_width_lp = `BSG_SAFE_CLOG2(1 + ((bsg_machine_llcache_line_words_gp * bsg_machine_llcache_data_width_lp) / bsg_machine_llcache_channel_width_gp));
   localparam bsg_machine_wh_coord_width_lp = bsg_machine_noc_coord_x_width_gp;

// These are macros... for reasons. 
`ifndef BSG_MACHINE_DISABLE_VCORE_PROFILING
   localparam bsg_machine_enable_vcore_profiling_lp = 1;
`else
   localparam bsg_machine_enable_vcore_profiling_lp = 0;
`endif

`ifndef BSG_MACHINE_DISABLE_ROUTER_PROFILING
   localparam bsg_machine_enable_router_profiling_lp = 1;
`else
   localparam bsg_machine_enable_router_profiling_lp = 0;
`endif

`ifndef BSG_MACHINE_DISABLE_CACHE_PROFILING
   localparam bsg_machine_enable_cache_profiling_lp = 1;
`else
   localparam bsg_machine_enable_cache_profiling_lp = 0;
`endif

   // Clock generator period
   localparam lc_cycle_time_ps_lp = 1000;

   // Reset generator depth
   localparam reset_depth_lp = 3;

   // Global Counter for Profilers, Tracing, Debugging
   localparam global_counter_width_lp = 64;
   logic [global_counter_width_lp-1:0] global_ctr;

   logic host_clk;
   logic host_reset;

   logic core_clk;
   logic core_reset;

   // reset_done is deasserted when tag programming is done.
   logic core_reset_done_lo, core_reset_done_r;

   logic mem_clk;
   logic mem_reset;

   logic cache_clk;
   logic cache_reset;

   // Snoop wires for Print Stat
   logic                                       print_stat_v;
   logic [bsg_machine_noc_data_width_gp-1:0]   print_stat_tag;

   logic [bsg_machine_noc_coord_x_width_gp-1:0] host_x_coord_li = (bsg_machine_noc_coord_x_width_gp)'(bsg_machine_io_coord_x_gp);
   logic [bsg_machine_noc_coord_y_width_gp-1:0] host_y_coord_li = (bsg_machine_noc_coord_y_width_gp)'(bsg_machine_io_coord_y_gp);

   `declare_bsg_manycore_link_sif_s(bsg_machine_noc_epa_width_gp, bsg_machine_noc_data_width_gp, bsg_machine_noc_coord_x_width_gp, bsg_machine_noc_coord_y_width_gp);

   bsg_manycore_link_sif_s host_link_sif_li;
   bsg_manycore_link_sif_s host_link_sif_lo;

   // Trace Enable wire for runtime argument to enable tracing (+trace)
   logic                                        trace_en;
   logic                                        log_en;
   logic                                        dpi_trace_en;
   logic                                        dpi_log_en;
   logic                                        tag_done_lo;
   assign trace_en = dpi_trace_en;
   assign log_en = dpi_log_en;

  //assign core_reset = bit_reset;

   bsg_nonsynth_manycore_testbench
     #(
       .num_pods_x_p(bsg_machine_pods_x_gp)
       ,.num_pods_y_p(bsg_machine_pods_y_gp)
       ,.pod_x_cord_width_p(bsg_machine_noc_pod_coord_x_width_gp)
       ,.pod_y_cord_width_p(bsg_machine_noc_pod_coord_y_width_gp)

       ,.num_tiles_x_p(bsg_machine_pod_tiles_x_gp)
       ,.num_tiles_y_p(bsg_machine_pod_tiles_y_gp)
       ,.num_subarray_x_p(bsg_machine_pod_tiles_subarray_x_gp)
       ,.num_subarray_y_p(bsg_machine_pod_tiles_subarray_y_gp)

       ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
       ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)

       ,.addr_width_p(bsg_machine_noc_epa_width_gp)
       ,.data_width_p(bsg_machine_noc_data_width_gp)
       ,.dmem_size_p(bsg_machine_core_dmem_words_gp)
       ,.icache_entries_p(bsg_machine_core_icache_entries_gp)
       ,.icache_tag_width_p(bsg_machine_core_icache_tag_width_gp)

       ,.ruche_factor_X_p(bsg_machine_noc_ruche_factor_X_gp)

       ,.num_vcache_rows_p(bsg_machine_pod_llcache_rows_gp)
       ,.num_vcaches_per_channel_p(bsg_machine_llcache_dram_channel_ratio_gp)
       ,.vcache_data_width_p(bsg_machine_llcache_data_width_lp)
       ,.vcache_addr_width_p(bsg_machine_llcache_addr_width_lp)
       ,.vcache_size_p(bsg_machine_llcache_words_gp)
       ,.vcache_sets_p(bsg_machine_llcache_sets_gp)
       ,.vcache_ways_p(bsg_machine_llcache_ways_gp)
       ,.vcache_block_size_in_words_p(bsg_machine_llcache_line_words_gp)
       ,.vcache_dma_data_width_p(bsg_machine_llcache_channel_width_gp)

       ,.wh_flit_width_p(bsg_machine_wh_flit_width_lp)
       ,.wh_ruche_factor_p(bsg_machine_wh_ruche_factor_lp)
       ,.wh_cid_width_p(bsg_machine_wh_cid_width_lp)
       ,.wh_len_width_p(bsg_machine_wh_len_width_lp)
       ,.wh_cord_width_p(bsg_machine_wh_coord_width_lp)

       ,.bsg_manycore_mem_cfg_p(bsg_machine_dram_cfg_gp)
       ,.bsg_dram_size_p(bsg_machine_dram_words_gp)

       ,.enable_vcore_profiling_p(bsg_machine_enable_vcore_profiling_lp)
       ,.enable_router_profiling_p(bsg_machine_enable_router_profiling_lp)
       ,.enable_cache_profiling_p(bsg_machine_enable_cache_profiling_lp)
       ,.hetero_type_vec_p(bsg_machine_hetero_type_vec_gp)

       ,.reset_depth_p(reset_depth_lp)
       )
   testbench
     (
      .clk_i(core_clk)
      ,.reset_i(core_reset)

      ,.io_link_sif_i(host_link_sif_li)
      ,.io_link_sif_o(host_link_sif_lo)

      ,.tag_done_o(core_reset_done_lo)
      );

   bsg_nonsynth_dpi_gpio
     #(
       .width_p(2)
       ,.init_o_p('0)
       ,.use_output_p('1)
       ,.debug_p('1)
       )
   trace_control
     (.gpio_o({dpi_log_en, dpi_trace_en})
      ,.gpio_i('0)
      );

    // Ports of Axi Slave Bus Interface S00_AXI

    logic s00_axi_aclk, s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid, s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic s00_axi_wvalid, s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid, s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid, s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid, s00_axi_rready;
    bsg_nonsynth_dpi_to_axil
     #(.addr_width_p(C_S00_AXI_ADDR_WIDTH), .data_width_p(C_S00_AXI_DATA_WIDTH))
     axil0
      (.aclk_o(s00_axi_aclk)
       ,.aresetn_o(s00_axi_aresetn)

       ,.awaddr_o(s00_axi_awaddr)
       ,.awprot_o(s00_axi_awprot)
       ,.awvalid_o(s00_axi_awvalid)
       ,.awready_i(s00_axi_awready)
       ,.wdata_o(s00_axi_wdata)
       ,.wstrb_o(s00_axi_wstrb)
       ,.wvalid_o(s00_axi_wvalid)
       ,.wready_i(s00_axi_wready)
       ,.bresp_i(s00_axi_bresp)
       ,.bvalid_i(s00_axi_bvalid)
       ,.bready_o(s00_axi_bready)

       ,.araddr_o(s00_axi_araddr)
       ,.arprot_o(s00_axi_arprot)
       ,.arvalid_o(s00_axi_arvalid)
       ,.arready_i(s00_axi_arready)
       ,.rdata_i(s00_axi_rdata)
       ,.rresp_i(s00_axi_rresp)
       ,.rvalid_i(s00_axi_rvalid)
       ,.rready_o(s00_axi_rready)
       );

  assign core_clk = s00_axi_aclk;
  assign core_reset = ~s00_axi_aresetn;
  
   // --------------------------------------------------------------------------
   // IO Complex
   // --------------------------------------------------------------------------
   localparam dpi_fifo_width_lp = (1 << $clog2(`bsg_manycore_packet_width(bsg_machine_noc_epa_width_gp,bsg_machine_noc_data_width_gp,bsg_machine_noc_coord_x_width_gp,bsg_machine_noc_coord_y_width_gp)));
   localparam ep_fifo_els_lp = 4;
   assign host_clk = core_clk;
   assign host_reset = core_reset;

   bsg_axi_manycore
     #(.C_S00_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH)
       ,.C_S00_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
       )
     aximc
     (
       .s00_axi_aclk_i    (s00_axi_aclk)
      ,.s00_axi_aresetn_i (s00_axi_aresetn)
      ,.s00_axi_awaddr_i  (s00_axi_awaddr)
      ,.s00_axi_awprot_i  (s00_axi_awprot)
      ,.s00_axi_awvalid_i (s00_axi_awvalid)
      ,.s00_axi_awready_o (s00_axi_awready)
      ,.s00_axi_wdata_i   (s00_axi_wdata)
      ,.s00_axi_wstrb_i   (s00_axi_wstrb)
      ,.s00_axi_wvalid_i  (s00_axi_wvalid)
      ,.s00_axi_wready_o  (s00_axi_wready)
      ,.s00_axi_bresp_o   (s00_axi_bresp)
      ,.s00_axi_bvalid_o  (s00_axi_bvalid)
      ,.s00_axi_bready_i  (s00_axi_bready)
      ,.s00_axi_araddr_i  (s00_axi_araddr)
      ,.s00_axi_arprot_i  (s00_axi_arprot)
      ,.s00_axi_arvalid_i (s00_axi_arvalid)
      ,.s00_axi_arready_o (s00_axi_arready)
      ,.s00_axi_rdata_o   (s00_axi_rdata)
      ,.s00_axi_rresp_o   (s00_axi_rresp)
      ,.s00_axi_rvalid_o  (s00_axi_rvalid)
      ,.s00_axi_rready_i  (s00_axi_rready)

      ,.clk_i   (host_clk)
      ,.reset_i (host_reset)
      ,.reset_done_i(core_reset_done_lo)

      ,.io_link_sif_i(host_link_sif_lo)
      ,.io_link_sif_o(host_link_sif_li)

      ,.global_x_i(host_x_coord_li)
      ,.global_y_i(host_y_coord_li)
      );
  
   bsg_dff_chain
     #(
       .width_p(1)
       ,.num_stages_p(reset_depth_lp)
       )
   reset_dff
     (
      .clk_i(core_clk)
      ,.data_i(core_reset_done_lo)
      ,.data_o(core_reset_done_r)
      );

   // bsg_nonsynth_dpi_cycle_counter
   //   #(.width_p(global_counter_width_lp))
   // ctr
   //   (
   //    .clk_i(core_clk)
   //    ,.reset_i(core_reset)
   //    ,.ctr_r_o(global_ctr)
   //    );

   // bsg_print_stat_snoop
   //   #(
   //     .data_width_p(bsg_machine_noc_data_width_gp)
   //     ,.addr_width_p(bsg_machine_noc_epa_width_gp)
   //     ,.x_cord_width_p(bsg_machine_noc_coord_x_width_gp)
   //     ,.y_cord_width_p(bsg_machine_noc_coord_y_width_gp)
   //     )
   // print_stat_snoop
   //   (
   //    .loader_link_sif_in_i(host_link_sif_lo) // output from manycore
   //    ,.loader_link_sif_out_i(host_link_sif_li) // output from host

   //    ,.print_stat_v_o(print_stat_v)
   //    ,.print_stat_tag_o(print_stat_tag)
   //    );

   // In VCS, the C/C++ testbench is controlled by the
   // simulator. Therefore, we need to "call into" the C/C++ program
   // using the cosim_main function, during the initial block.
   //
   // DPI Calls in cosim_main will cause simulator time to progress.
   //
   // This mirrors the DPI functions in aws simulation
`ifndef VERILATOR
   import "DPI-C" context task cosim_main(output int unsigned exit_code, input string args, input string path);
   initial begin
      int exit_code;
      string args;
      string path;
      longint t;
      $value$plusargs("c_path=%s", path);
      $value$plusargs("c_args=%s", args);
      #1000
      replicant_tb_top.cosim_main(exit_code, args, path);
      if(exit_code < 0) begin
        $display("BSG COSIM FAIL: Test failed with exit code: %d", exit_code);
        $fatal;
      end else begin
        $display("BSG COSIM PASS: Test passed!");
        $finish;
      end
   end // initial begin

  // Evaluate the simulation, until the next clk_i positive edge.
   //
   // Call bsg_dpi_next in simulators where the C testbench does not
   // control the progression of time (i.e. NOT Verilator).
   //
   // The #1 statement guarantees that the positive edge has been
   // evaluated, which is necessary for ordering in all of the DPI
   // functions.
   export "DPI-C" task bsg_dpi_next;
   task bsg_dpi_next();
      @(posedge core_clk);
      #1;
   endtask // bsg_dpi_next
`endif

`ifdef BSG_MACHINE_ENABLE_SAIF
   wor saif_en = 0;

   bind vanilla_core vanilla_core_saif_dumper
     #(
       )
   saif_dumper
   (
    .*
    ,.saif_en_i($root.`HOST_MODULE_PATH.saif_en)
    ,.saif_en_o($root.`HOST_MODULE_PATH.saif_en)
   );
`endif
endmodule