###### DC Synthesis Script #######

## Give the path to the verilog files and define the WORK directory

lappend search_path ../OpenSPARC_src/trunk/T1-FPU/ 
define_design_lib WORK -path "work"

## Define the library location
#set link_library [ list /mnt/class_data/ecec574-w2019/PDKs/SAED32nm/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v125c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v25c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95vn40c.db]

set link_library [ list /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v125c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v25c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95vn40c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/sram/db_ccs/saed32sram_ss0p95vn40c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/sram/db_ccs/saed32sram_ss0p95v25c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/sram/db_ccs/saed32sram_ss0p95v125c.db ]

set target_library [ list /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/db_ccs/saed32rvt_ss0p95v25c.db /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/sram/db_ccs/saed32sram_ss0p95v25c.db ]

## read the verilog files
#analyze -library WORK -format verilog [list fpu.v dff.v]

analyze -library WORK -format verilog [list fpu.v bw_r_rf16x160.v bw_clk_cl_fpu_cmp.v fpu_cnt_lead0_lvl3.v fpu_in2_gt_in1_2b.v fpu_mul_frac_dp.v fpu_add_ctl.v fpu_cnt_lead0_lvl4.v fpu_in2_gt_in1_3b.v fpu_mul.v fpu_add_exp_dp.v fpu_denorm_3b.v fpu_in2_gt_in1_3to1.v fpu_out_ctl.v fpu_add_frac_dp.v fpu_denorm_3to1.v fpu_in2_gt_in1_frac.v fpu_out_dp.v fpu_add.v fpu_denorm_frac.v fpu_in_ctl.v fpu_out.v fpu_cnt_lead0_53b.v fpu_div_ctl.v fpu_in_dp.v fpu_rptr_groups.v fpu_cnt_lead0_64b.v fpu_div_exp_dp.v fpu_in.v fpu_rptr_macros.v fpu_cnt_lead0_lvl1.v fpu_div_frac_dp.v fpu_mul_ctl.v fpu_rptr_min_global.v fpu_cnt_lead0_lvl2.v fpu_div.v fpu_mul_exp_dp.v mul64.v test_stub_scan.v cluster_header.v swrvr_clib.v swrvr_dlib.v u1.V synchronizer_asr.v] 


elaborate fpu -architecture verilog -library WORK

current_design fpu

link
## Check if design is consistent
check_design  > reports/synth_check_design.rpt

## Create Constraints 
create_clock gclk -name ideal_clock1 -period 3
set_input_delay 0.1 [ remove_from_collection [all_inputs] gclk ] -clock ideal_clock1
set_output_delay 0.1 [all_outputs ] -clock ideal_clock1
set_clock_uncertainty 0.1 [get_clocks ideal_clock1]
set_clock_latency 0.1 [get_clocks ideal_clock1]
set_clock_transition 0.1 [get_clocks ideal_clock1]
set_max_area 0
set_load 0.3 [ all_outputs ]

# Set wire load model
set auto_wire_load_selection false
set_wire_load_model -name 280000

## Compilation 
set compile_top_all_paths true
compile -map_effort high -auto_ungroup delay
compile -top

## Below commands report area , cell, qor, resources, and timing information needed to analyze the design. 

  report_area > reports/synth_area.rpt
  report_cell > reports/synth_cells.rpt
  report_qor  > reports/synth_qor.rpt
  report_resources > reports/synth_resources.rpt
  report_timing -max_paths 10 > reports/synth_timing.rpt

## Dump out the constraints in an SDC file

  write_sdc  const/fpu.sdc

## Dump out the synthesized database and gate-level-netlist
  write -f ddc -hierarchy -output output/fpu.ddc

  write -hierarchy -format verilog -output  output/fpu.v

  exit