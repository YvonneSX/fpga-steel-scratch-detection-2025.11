// Parallel scratch candidate pipelines for a dual OV5640 DVP module.
// Each sensor remains in its own PCLK domain; no stereo matching is performed.
module dual_camera_scratch_core #(
    parameter MAX_WIDTH = 1280,
    parameter CONTRAST_THRESHOLD = 20,
    parameter X_BITS = 11,
    parameter Y_BITS = 11
) (
    input                   cam1_pclk,
    input                   cam1_vsync,
    input                   cam1_href,
    input       [7:0]       cam1_data,
    input                   cam2_pclk,
    input                   cam2_vsync,
    input                   cam2_href,
    input       [7:0]       cam2_data,
    input                   rst_n,
    output                  cam1_candidate_valid,
    output                  cam1_candidate_pixel,
    output      [X_BITS-1:0] cam1_candidate_x,
    output      [Y_BITS-1:0] cam1_candidate_y,
    output      [31:0]      cam1_frame_candidate_count,
    output                  cam2_candidate_valid,
    output                  cam2_candidate_pixel,
    output      [X_BITS-1:0] cam2_candidate_x,
    output      [Y_BITS-1:0] cam2_candidate_y,
    output      [31:0]      cam2_frame_candidate_count
);
    scratch_stream_core #(
        .MAX_WIDTH(MAX_WIDTH),
        .CONTRAST_THRESHOLD(CONTRAST_THRESHOLD),
        .X_BITS(X_BITS),
        .Y_BITS(Y_BITS)
    ) cam1_pipeline (
        .pclk(cam1_pclk), .rst_n(rst_n),
        .cam_vsync(cam1_vsync), .cam_href(cam1_href), .cam_data(cam1_data),
        .candidate_valid(cam1_candidate_valid),
        .candidate_pixel(cam1_candidate_pixel),
        .candidate_x(cam1_candidate_x), .candidate_y(cam1_candidate_y),
        .frame_candidate_count(cam1_frame_candidate_count)
    );

    scratch_stream_core #(
        .MAX_WIDTH(MAX_WIDTH),
        .CONTRAST_THRESHOLD(CONTRAST_THRESHOLD),
        .X_BITS(X_BITS),
        .Y_BITS(Y_BITS)
    ) cam2_pipeline (
        .pclk(cam2_pclk), .rst_n(rst_n),
        .cam_vsync(cam2_vsync), .cam_href(cam2_href), .cam_data(cam2_data),
        .candidate_valid(cam2_candidate_valid),
        .candidate_pixel(cam2_candidate_pixel),
        .candidate_x(cam2_candidate_x), .candidate_y(cam2_candidate_y),
        .frame_candidate_count(cam2_frame_candidate_count)
    );
endmodule
