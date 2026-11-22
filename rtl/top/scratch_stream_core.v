// One-clock-domain camera receiver plus grayscale scratch candidate detector.
module scratch_stream_core #(
    parameter MAX_WIDTH = 1280,
    parameter CONTRAST_THRESHOLD = 20,
    parameter X_BITS = 11,
    parameter Y_BITS = 11
) (
    input                   pclk,
    input                   rst_n,
    input                   cam_vsync,
    input                   cam_href,
    input       [7:0]       cam_data,
    output                  candidate_valid,
    output                  candidate_pixel,
    output      [X_BITS-1:0] candidate_x,
    output      [Y_BITS-1:0] candidate_y,
    output      [31:0]      frame_candidate_count
);
    wire frame_start;
    wire line_start;
    wire pixel_valid;
    wire [7:0] gray_pixel;

    dvp_rgb565_to_gray rgb565_to_gray (
        .pclk(pclk),
        .rst_n(rst_n),
        .vsync(cam_vsync),
        .href(cam_href),
        .data(cam_data),
        .frame_start(frame_start),
        .line_start(line_start),
        .pixel_valid(pixel_valid),
        .gray_pixel(gray_pixel)
    );

    scratch_detector #(
        .MAX_WIDTH(MAX_WIDTH),
        .CONTRAST_THRESHOLD(CONTRAST_THRESHOLD),
        .X_BITS(X_BITS),
        .Y_BITS(Y_BITS)
    ) detector (
        .clk(pclk),
        .rst_n(rst_n),
        .frame_start(frame_start),
        .line_start(line_start),
        .pixel_valid(pixel_valid),
        .gray_pixel(gray_pixel),
        .candidate_valid(candidate_valid),
        .candidate_pixel(candidate_pixel),
        .candidate_x(candidate_x),
        .candidate_y(candidate_y),
        .frame_candidate_count(frame_candidate_count)
    );
endmodule
