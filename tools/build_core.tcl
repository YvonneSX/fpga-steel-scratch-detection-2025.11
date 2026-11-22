# Run from the PDS Tcl console after opening steel_scratch_core.pds.
# This only compiles and synthesizes the reusable pixel-processing core. It
# does not assign board pins or generate a hardware programming file.

set repo_root [file normalize [file join [file dirname [info script]] ".."]]

add_design [file join $repo_root "rtl/top/dual_camera_scratch_core.v"]
add_design [file join $repo_root "rtl/top/scratch_stream_core.v"]
add_design [file join $repo_root "rtl/camera/dvp_rgb565_to_gray.v"]
add_design [file join $repo_root "rtl/scratch/scratch_detector.v"]
add_constraint [file join $repo_root "constraints/core_only.fdc"]

set_arch -family Logos -device PGL50H -speedgrade -6 -package FBG484
compile -top_module dual_camera_scratch_core
synthesize -ads -selected_syn_tool_opt 2
