// Streaming local-contrast scratch-candidate detector.
//
// Three synchronous-read line banks rotate through the current row and the
// two preceding rows. Keeping each bank as a simple synchronous RAM allows
// Pango synthesis to map the image line storage into on-chip DRM blocks.
// The output is delayed by the RAM read latency and marks the pixel centered
// at (input_x - 1, input_y - 1).
//
// This produces candidate pixels, not a calibrated industrial defect decision.
module scratch_detector #(
    parameter MAX_WIDTH = 1280,
    parameter CONTRAST_THRESHOLD = 20,
    parameter X_BITS = 11,
    parameter Y_BITS = 11
) (
    input                    clk,
    input                    rst_n,
    input                    frame_start,
    input                    line_start,
    input                    pixel_valid,
    input       [7:0]        gray_pixel,
    output wire              candidate_valid,
    output wire              candidate_pixel,
    output wire [X_BITS-1:0] candidate_x,
    output wire [Y_BITS-1:0] candidate_y,
    output reg  [31:0]       frame_candidate_count
);

    reg [7:0] row_bank_0 [0:MAX_WIDTH-1];
    reg [7:0] row_bank_1 [0:MAX_WIDTH-1];
    reg [7:0] row_bank_2 [0:MAX_WIDTH-1];
    reg [7:0] row_bank_0_q;
    reg [7:0] row_bank_1_q;
    reg [7:0] row_bank_2_q;

    reg [1:0] write_bank;
    reg [1:0] read1_bank_q;
    reg [1:0] read2_bank_q;
    reg [X_BITS-1:0] x_count;
    reg [Y_BITS-1:0] y_count;
    reg [X_BITS-1:0] sample_x_q;
    reg [Y_BITS-1:0] sample_y_q;
    reg sample_valid_q;
    reg [31:0] running_candidate_count;

    reg [7:0] row1_d1, row1_d2;
    reg [7:0] row2_d1;
    reg [7:0] current_row_d1, current_row_d2;

    function [1:0] next_bank;
        input [1:0] bank;
        begin
            if (bank == 2)
                next_bank = 0;
            else
                next_bank = bank + 1'b1;
        end
    endfunction

    wire [1:0] active_write_bank = frame_start ? 2'd0
                                 : line_start ? next_bank(write_bank)
                                 : write_bank;
    wire [1:0] active_read1_bank = (active_write_bank == 0) ? 2'd2
                                 : (active_write_bank == 1) ? 2'd0 : 2'd1;
    wire [1:0] active_read2_bank = (active_write_bank == 0) ? 2'd1
                                 : (active_write_bank == 1) ? 2'd2 : 2'd0;
    wire [X_BITS-1:0] access_x = line_start ? {X_BITS{1'b0}} : x_count;
    wire [Y_BITS-1:0] access_y = frame_start ? {Y_BITS{1'b0}}
                                 : line_start ? y_count + 1'b1 : y_count;

    // Each bank performs either one synchronous read or one write per pixel.
    // The bank being written is never selected as either preceding row.
    always @(posedge clk) begin
        if (pixel_valid && (access_x < MAX_WIDTH)) begin
            if (active_write_bank == 0)
                row_bank_0[access_x] <= gray_pixel;
            else
                row_bank_0_q <= row_bank_0[access_x];

            if (active_write_bank == 1)
                row_bank_1[access_x] <= gray_pixel;
            else
                row_bank_1_q <= row_bank_1[access_x];

            if (active_write_bank == 2)
                row_bank_2[access_x] <= gray_pixel;
            else
                row_bank_2_q <= row_bank_2[access_x];
        end
    end

    reg [7:0] read1_data;
    reg [7:0] read2_data;
    always @* begin
        case (read1_bank_q)
            0: read1_data = row_bank_0_q;
            1: read1_data = row_bank_1_q;
            default: read1_data = row_bank_2_q;
        endcase
        case (read2_bank_q)
            0: read2_data = row_bank_0_q;
            1: read2_data = row_bank_1_q;
            default: read2_data = row_bank_2_q;
        endcase
    end

    wire [9:0] center_x4 = {row1_d1, 2'b00};
    wire [9:0] cross_sum = {2'b00, row1_d2} + {2'b00, read1_data}
                         + {2'b00, row2_d1} + {2'b00, current_row_d2};
    wire [9:0] cross_delta = (center_x4 >= cross_sum)
                           ? center_x4 - cross_sum
                           : cross_sum - center_x4;
    wire [7:0] local_contrast = cross_delta[9:2];
    wire candidate_hit = candidate_valid && candidate_pixel;

    assign candidate_valid = sample_valid_q
                           && (sample_x_q >= 2)
                           && (sample_x_q < MAX_WIDTH)
                           && (sample_y_q >= 2);
    assign candidate_pixel = candidate_valid
                           && (local_contrast >= CONTRAST_THRESHOLD);
    assign candidate_x = candidate_valid ? sample_x_q - 1'b1 : {X_BITS{1'b0}};
    assign candidate_y = candidate_valid ? sample_y_q - 1'b1 : {Y_BITS{1'b0}};

    // Control, synchronous-read pipeline, and frame activity counter.
    // RAM contents and RAM output registers are intentionally not reset so
    // synthesis can infer memory primitives; valid coordinates gate warm-up.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_bank <= 2;
            read1_bank_q <= 0;
            read2_bank_q <= 1;
            x_count <= 0;
            y_count <= 0;
            sample_x_q <= 0;
            sample_y_q <= 0;
            sample_valid_q <= 0;
            row1_d1 <= 0;
            row1_d2 <= 0;
            row2_d1 <= 0;
            current_row_d1 <= 0;
            current_row_d2 <= 0;
            running_candidate_count <= 0;
            frame_candidate_count <= 0;
        end else begin
            sample_valid_q <= pixel_valid;

            if (pixel_valid) begin
                write_bank <= active_write_bank;
                read1_bank_q <= active_read1_bank;
                read2_bank_q <= active_read2_bank;
                sample_x_q <= access_x;
                sample_y_q <= access_y;

                if (line_start) begin
                    x_count <= 1;
                    row1_d1 <= 0;
                    row1_d2 <= 0;
                    row2_d1 <= 0;
                    current_row_d1 <= gray_pixel;
                    current_row_d2 <= 0;
                end else begin
                    x_count <= x_count + 1'b1;
                    row1_d1 <= read1_data;
                    row1_d2 <= row1_d1;
                    row2_d1 <= read2_data;
                    current_row_d1 <= gray_pixel;
                    current_row_d2 <= current_row_d1;
                end

                if (frame_start)
                    y_count <= 0;
                else if (line_start)
                    y_count <= y_count + 1'b1;
            end

            if (frame_start) begin
                frame_candidate_count <= running_candidate_count
                                       + (candidate_hit ? 1'b1 : 1'b0);
                running_candidate_count <= 0;
            end else if (candidate_hit) begin
                running_candidate_count <= running_candidate_count + 1'b1;
            end
        end
    end

endmodule
