# System design and assumptions

## Camera and FPGA baseline

The local PGL50H development-kit archive contains an OV5640 dual-camera
experiment and a separate HDMI/DDR3/OV5640 project. This supports using two
OV5640 sensors on DVP as the best-fit hardware baseline. The README and RTL
keep this as an explicit assumption because the module's exact revision and
register configuration have not been inspected on the live board.

The processing core accepts two byte-wide DVP streams. Each stream is
independent and clocked by its sensor's PCLK. `dvp_rgb565_to_gray.v` assumes
RGB565 high-byte-first samples; it converts each two-byte pixel to an
8-bit approximation `(2R + 5G + B) / 8`. VSYNC and HREF rising edges are
carried to the detector with the first emitted pixel. If the camera is
configured for YUV422, a different byte order, or a different sync polarity,
this decoder must be changed to match the sensor setup.

The board-kit initialization example comments specify 1280x720 at 30 fps,
using a 24 MHz sensor input and 84 MHz PCLK. The RTL defaults to a maximum
line width of 1280; changing the camera mode requires changing this parameter
and rechecking the available PGL50H memory and timing margin.

## Candidate detector

For center intensity `C` and four axial neighbors `N`, `S`, `E`, and `W`, the
streaming RTL computes:

```text
contrast = abs(4*C - (N + S + E + W)) / 4
candidate = contrast >= threshold
```

Three synchronous-read line banks rotate through the current row and the two
preceding rows. Each camera uses three PGL50H DRM18K blocks at the default
1280-pixel width. The read latency is included in the window pipeline; the
candidate coordinate refers to the center pixel, one pixel and one row behind
the incoming sample. The detector outputs a candidate mask with its pixel
coordinate and accumulates candidate-pixel count per frame. The count is a
coarse activity metric; it is not a count of separate defects. It is also one
frame delayed because the previous frame's count is latched at the next frame
start.

This local-contrast filter detects thin dark or bright features against a
smooth background but can also mark texture, scratches, glare boundaries, and
sensor noise. A useful next algorithm stage is connected-component/run-length
filtering (minimum length, aspect ratio, and continuity), followed by
threshold calibration on real surface images under fixed illumination.

## Dual-camera behavior

`dual_camera_scratch_core.v` instantiates two independent pipelines and keeps
the camera clocks separate. It does not synchronize the cameras, rectify
their images, calculate disparity, or fuse their decisions. The pair can be
used for independent inspection views initially; stereo processing should be
added only after intrinsic/extrinsic calibration and confirmation that both
sensors see the same inspection region.

## Board-level work still required

- Configure both OV5640 sensors with a verified RGB565 mode and matching
  sync polarity/byte order.
- Connect the DVP pins using the exact MES50HP/PGL50H board revision's FDC
  table. Do not use guessed pin assignments.
- Add reset synchronization per PCLK domain and verify the actual camera PCLK
  frequencies and timing constraints.
- Integrate the candidate mask into the board's chosen output path (HDMI,
  UART summaries, or frame capture). The kit's HDMI example uses DDR3 and
  generated Pango IP; those files are deliberately not duplicated here.
- Run on hardware with real steel samples, lock down illumination and camera
  geometry, then tune thresholds and candidate filtering.
