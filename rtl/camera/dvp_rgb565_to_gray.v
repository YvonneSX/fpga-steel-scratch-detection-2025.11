// Convert the assumed OV5640 RGB565, high-byte-first DVP stream to grayscale.
// Clock this module directly from the selected sensor's PCLK.
module dvp_rgb565_to_gray (
    input            pclk,
    input            rst_n,
    input            vsync,
    input            href,
    input      [7:0] data,
    output reg       frame_start,
    output reg       line_start,
    output reg       pixel_valid,
    output reg [7:0] gray_pixel
);
    reg vsync_d;
    reg href_d;
    reg frame_pending;
    reg line_pending;
    reg byte_phase;
    reg [7:0] rgb565_high;
    wire [4:0] red5 = rgb565_high[7:3];
    wire [5:0] green6 = {rgb565_high[2:0], data[7:5]};
    wire [4:0] blue5 = data[4:0];
    wire [7:0] red8 = {red5, red5[4:2]};
    wire [7:0] green8 = {green6, green6[5:4]};
    wire [7:0] blue8 = {blue5, blue5[4:2]};
    wire [10:0] gray_sum = {2'b00, red8, 1'b0}
                         + {1'b0, green8, 2'b00}
                         + {2'b00, green8}
                         + {2'b00, blue8};

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_d <= 0;
            href_d <= 0;
            frame_pending <= 0;
            line_pending <= 0;
            byte_phase <= 0;
            rgb565_high <= 0;
            frame_start <= 0;
            line_start <= 0;
            pixel_valid <= 0;
            gray_pixel <= 0;
        end else begin
            vsync_d <= vsync;
            href_d <= href;
            frame_start <= 0;
            line_start <= 0;
            pixel_valid <= 0;

            if (vsync && !vsync_d)
                frame_pending <= 1;
            if (href && !href_d)
                line_pending <= 1;

            if (!href) begin
                byte_phase <= 0;
            end else if (!byte_phase) begin
                rgb565_high <= data;
                byte_phase <= 1;
            end else begin
                byte_phase <= 0;
                gray_pixel <= gray_sum[10:3];
                pixel_valid <= 1;
                if (line_pending) begin
                    line_start <= 1;
                    line_pending <= 0;
                end
                if (frame_pending) begin
                    frame_start <= 1;
                    frame_pending <= 0;
                end
            end
        end
    end
endmodule
