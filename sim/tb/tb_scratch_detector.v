`timescale 1ns/1ps

module tb_scratch_detector;
    reg clk = 0;
    reg rst_n = 0;
    reg frame_start = 0;
    reg line_start = 0;
    reg pixel_valid = 0;
    reg [7:0] gray_pixel = 0;
    wire candidate_valid;
    wire candidate_pixel;
    wire [3:0] candidate_x;
    wire [3:0] candidate_y;
    wire [31:0] frame_candidate_count;
    integer x;
    integer y;
    integer detected;
    reg [7:0] value;

    always #5 clk = ~clk;

    scratch_detector #(
        .MAX_WIDTH(8),
        .CONTRAST_THRESHOLD(20),
        .X_BITS(4),
        .Y_BITS(4)
    ) dut (
        .clk(clk),
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

    task send_pixel;
        input [7:0] pixel;
        input is_frame_start;
        input is_line_start;
        begin
            @(negedge clk);
            gray_pixel = pixel;
            pixel_valid = 1;
            frame_start = is_frame_start;
            line_start = is_line_start;
            @(posedge clk);
            #1;
            if (candidate_valid && candidate_pixel)
                detected = detected + 1;
            @(negedge clk);
            pixel_valid = 0;
            frame_start = 0;
            line_start = 0;
        end
    endtask

    initial begin
        detected = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        // Flat field plus a narrow vertical dark scratch.
        for (y = 0; y < 8; y = y + 1) begin
            for (x = 0; x < 8; x = x + 1) begin
                value = ((x == 3) && (y >= 2) && (y <= 5)) ? 8'd40 : 8'd200;
                send_pixel(value, ((x == 0) && (y == 0)), (x == 0));
            end
        end

        if (detected < 2) begin
            $display("FAIL: expected vertical scratch candidates, got %0d", detected);
            $finish(1);
        end

        $display("PASS: detected %0d scratch candidate pixels", detected);
        $finish(0);
    end
endmodule
