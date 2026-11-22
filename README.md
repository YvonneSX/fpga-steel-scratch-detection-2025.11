# FPGA Steel Scratch Detection

A reconstructed FPGA image-processing project for the Pango PGL50H and the
board-kit dual OV5640 DVP camera module. The repository contains a streaming
grayscale conversion path, a 3x3 local-contrast scratch-candidate detector, a
parallel two-camera core, and a pure-Python reference model for image-level
experiments.

The current detector marks pixels whose center differs from the average of
its four axial neighbors. Three synchronous-read line banks rotate through
the current row and two preceding rows so Pango synthesis can use on-chip
DRM18K memory. It is a first-pass candidate extractor, not a validated
production inspection classifier: connected-component filtering, camera
calibration, lighting control, stereo matching, and a complete board
display/download top level remain outside this baseline.

## Hardware baseline

- FPGA: Pango Logos PGL50H, board-kit device target PGL50H-6 / FBG484.
- Camera: dual OV5640 DVP module, inferred from the matching PGL50H kit example
  and camera documentation. The image on the module and its exact revision
  have not been electrically verified.
- Pixel format assumption: RGB565, high byte first, with active-high VSYNC
  and HREF. Confirm these settings against the actual sensor register setup
  before connecting the stream core.
- Camera timing baseline: the matching kit example configures 1280x720 at
  30 fps from a 24 MHz input clock, with an 84 MHz pixel clock.
- Each camera pipeline runs in its own PCLK domain. The two outputs are
  independent; this project does not perform stereo depth estimation.

## Repository layout

```text
constraints/             Board pin/clock constraint notes and templates
docs/                    System assumptions and integration notes
rtl/camera/              DVP byte unpacking and RGB565-to-gray conversion
rtl/preprocess/          Reserved for additional filtering stages
rtl/scratch/             Streaming scratch-candidate detector
rtl/stereo/              Reserved for stereo calibration/matching
rtl/top/                 Single-stream and dual-camera processing cores
sim/tb/                  Verilog testbench for the streaming detector
tools/data_synth/        Synthetic PGM image generator
tools/reference_model/   Pure-Python algorithm reference
tools/tests/             Standard-library reference-model checks
assets/test_images/      Small test-image notes; generated images are ignored
```

## Run the software reference

Requires Python 3.10 or newer; no third-party packages are needed.

```powershell
python tools/data_synth/generate_synthetic.py
python tools/run_reference.py assets/test_images/generated/synthetic_steel.pgm
python -m unittest discover -s tools/tests -v
```

The detector writes a binary PGM candidate mask beside the input image by
default. Override the threshold or output path with `--threshold` and `--mask`.

To run the RTL testbench, install Icarus Verilog and run
`powershell -ExecutionPolicy Bypass -File tools/simulate_rtl.ps1`.

## FPGA integration status

`rtl/top/dual_camera_scratch_core.v` accepts two independent DVP pixel
interfaces and returns per-camera candidate masks, coordinates, and a
per-frame candidate-pixel count. It expects the camera modules to be
configured externally for the stated RGB565 timing. The PGL50H kit includes a
separate OV5640/DDR3/HDMI example that can be used as a board-level reference;
its generated DDR and HDMI IP are not copied into this repository.

Open `steel_scratch_core.pds` in PDS 2022.2-SP1-Lite. `tools/build_core.tcl`
compiles and synthesizes the reusable core; it is not a board-programming flow.
The core-only PDS synthesis completed for PGL50H-6-FBG484. The detector line
buffers mapped to six DRM18K blocks across both camera pipelines. The report
used 588 LUTs (1.37%), 358 registers (0.56%), and six DRM18K blocks (4.48%).

The FDC pin map and project-level clock constraints must be taken from the
exact board revision and verified against the attached camera/display hardware
before generating a board-programming file. The example LED bitstream built
successfully in PDS 2022.2-SP1-Lite; that validates the tool installation, not
this reconstructed camera design.
