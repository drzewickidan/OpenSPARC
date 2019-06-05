 set search_path "$search_path /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/db_ccs
../src/ "
set target_library "saed32rvt_ss0p95v25c.db"
set link_library "* $target_library"

sh rm -rf fpu.mw

set techfile "/mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/tech/milkyway/saed32nm_1p9m_mw.tf"
set ref_lib "/mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/lib/stdcell_rvt/milkyway/saed32nm_rvt_1p9m"
set lib_name "fpu"

set design_data ../dc_synth/output/fpu.ddc
set cell_name "fpu"
import_designs $design_data -format ddc -top $cell_name

set mw_logic0_net VSS
set mw_logic1_net VDDA

set libdir "/mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/tech/star_rcxt"
set tlupmax "$libdir/saed32nm_1p9m_Cmax.tluplus"
set tlunom "$libdir/saed32nm_1p9m_nominal.tluplus"
set tlupmin "$libdir/saed32nm_1p9m_Cmin.tluplus"
set tech2itf "$libdir/saed32nm_tf_itf_tluplus.map"
set_tlu_plus_files -max_tluplus $tlunom -tech2itf_map $tech2itf

create_mw_lib $lib_name.mw \
		 -technology $techfile \
		 -mw_reference_library $ref_lib 
		 
open_mw_lib $lib_name.mw

read_verilog ../dc_synth/output/fpu.v

uniquify_fp_mw_cel

link

read_sdc ../dc_synth/const/fpu.sdc

save_mw_cel -as fpu_initial

###########################################################################
### Floorplanning
###########################################################################

create_floorplan -core_utilization 0.8 -left_io2core 60 -bottom_io2core 60 -right_io2core 60 -top_io2core 60
derive_pg_connection -power_net VDDA -ground_net VSS
derive_pg_connection -power_net VDDA -ground_net VSS -tie

##Create VSS ring

create_rectangular_rings  -nets  {VSS}  -left_offset 0.5  -left_segment_layer M6 -left_segment_width 1.0 -extend_ll -extend_lh -right_offset 0.5 -right_segment_layer M6 -right_segment_width 1.0 -extend_rl -extend_rh -bottom_offset 0.5  -bottom_segment_layer  M7 -bottom_segment_width 1.0 -extend_bl -extend_bh -top_offset 0.5 -top_segment_layer M7 -top_segment_width 1.0 -extend_tl -extend_th
 
## Create VDDA Ring

create_rectangular_rings  -nets  {VDDA}  -left_offset 1.8  -left_segment_layer M6 -left_segment_width 1.0 -extend_ll -extend_lh -right_offset 1.8 -right_segment_layer M6 -right_segment_width 1.0 -extend_rl -extend_rh -bottom_offset 1.8  -bottom_segment_layer M7 -bottom_segment_width 1.0 -extend_bl -extend_bh -top_offset 1.8 -top_segment_layer M7 -top_segment_width 1.0 -extend_tl -extend_th

## Creates Power Strap 

create_power_strap -nets { VDDA } -layer M6 -direction vertical -width 3  
create_power_strap -nets { VSS } -layer M6 -direction vertical  -width 3


## Save the design
save_mw_cel -as fpu_fp

###########################################################################
### Placement
###########################################################################

set_buffer_opt_strategy -effort high

set_tlu_plus_files -max_tluplus /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -min_tluplus /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -tech2itf_map /mnt/class_data/ecec574-w2019/PDKs/SAED32nm_new/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map

##Goto Layout Window , Placement ' Core Placement and Optimization .  A new window opens up as shown below . There are various options, you can click on what ever option you want and say ok. The tool will do the placement. Alternatively you can also run at the command at icc_shell . Below is example with congestion option.

place_opt -area_recovery -effort high

# Incremental Logic Opt
psynopt -area_recovery

## Save the design
save_mw_cel -as fpu_place

### Reports 

report_placement_utilization > output/fpu_place_util.rpt
report_qor_snapshot > output/fpu_place_qor_snapshot.rpt
report_qor > output/fpu_place_qor.rpt

### Timing Report

report_timing -delay max -max_paths 20 > output/fpu_place.setup.rpt
report_timing -delay min -max_paths 20 > output/fpu_place.hold.rpt
report_clock_tree -summary > reports/fpu_place.clock.rpt
report_power > reports/fpu_place.power.rpt

###########################################################################
### Clock Tree Synthesis
###########################################################################

##In the Layout window, click on "Clock ", you will see various options, you can set any of the options to run CTS. If you click on Clock ' Core CTS and Optimization

##Save the Cell and report timing

clock_opt -only_cts -no_clock_route
route_zrt_group -all_clock_nets -reuse_existing_global_route true

optimize_clock_tree -routed_clock_stage global

save_mw_cel -as fpu_cts
report_placement_utilization > reports/fpu_cts_util.rpt
report_qor_snapshot > reports/fpu_cts_qor_snapshot.rpt
report_qor > reports/fpu_cts_qor.rpt

###########################################################################
### Routing
###########################################################################

# Add filler cells
insert_stdcell_filler -cell_with_metal "SHFILL1 SHFILL2 SHFILL3" -connect_to_power "VDDA" -connect_to_ground "#VSS"

route_zrt_global -effort high
route_zrt_track
route_zrt_detail

derive_pg_connection -power_net VDDA -ground_net VSS
derive_pg_connection -power_net VDDA -ground_net VSS -tie

##Save the cel and report timing

save_mw_cel -as fpu_route
report_placement_utilization > reports/fpu_route_util.rpt
report_qor_snapshot > reports/fpu_route_qor_snapshot.rpt
report_qor > reports/fpu_route_qor.rpt

##POST ROUTE OPTIMIZATION STEPS

##Goto Layout Window, Route -> Verify Route
#verify_route
verify_zrt_route

###########################################################################
### Extraction
###########################################################################

##Go to Layout Window, Route -> Extract RC, it opens up a new window as shown below, click ok. Alternatively, you can run this script on the ICC shell:

extract_rc  -coupling_cap  -routed_nets_only  -incremental

##write parasitic to a file for delay calculations tools (e.g PrimeTime).
write_parasitics -output ./output/fpu_extracted.spef -format SPEF

##Write Standard Delay Format (SDF) back-annotation file
write_sdf ./output/fpu_extracted.sdf

##Write out a script in Synopsys Design Constraints format
write_sdc ./output/fpu_extracted.sdc

##Write out a hierarchical Verilog file for the current design, extracted from layout
write_verilog ./output/fpu_extracted.v

##Save the cel and report timing
report_clock_tree -summary > reports/fpu_extracted.clock.rpt
report_power > reports/fpu_extracted.power.rpt
report_area > reports/fpu_extracted.area.rpt
report_cell > reports/fpu_extracted.cell.rpt

save_mw_cel -as fpu_extracted
