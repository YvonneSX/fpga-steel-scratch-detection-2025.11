# Stereo stage

The dual-camera wrapper preserves both sensor streams in their own PCLK
domains, but it does not yet rectify images or estimate disparity. Add stereo
processing only after camera synchronization and lens/rig calibration data
are available.
