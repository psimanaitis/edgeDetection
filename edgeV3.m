close all; clc;

%Converting uint8 to double for later mathematical use
imported_image = double(imread('test3.jpg'));
Show_image(uint8(imported_image), "Given image");
%When downsampling and using 1-stride
downsampled_image = Downsample(imported_image, 2);
Show_image(uint8(downsampled_image), "Downsampled")
with_1_stride = Calculate_edges(downsampled_image, 1);
Show_image(uint8(with_1_stride), "Downsampled + 1-stride")
%When just using 2-stride
with_2_stride = Calculate_edges(imported_image, 2);
Show_image(uint8(with_2_stride), "2-stride")
%Show_channels(with_2_stride)
Show_grayscale(with_1_stride)

function edges = Calculate_edges(image, stride)
    %Padding is used because we do not want to lose resolution if stride == 1
    image = Pad_image(image);
    horizontal_edge = Convolute_image(image, "horizontal", stride);
    vertical_edge = Convolute_image(image, "vertical", stride);
    edges = Normalize(sqrt(horizontal_edge .^2 + vertical_edge .^2));
end

function downsampled_image = Downsample(image_to_downsample, stride)
    %Using padding, so that dimensions of 2-strided and downsampled images would match
    image_to_downsample = Pad_image(image_to_downsample);
    downsampled_image = Convolute_image(image_to_downsample, "pool", stride);
    downsampled_image = Normalize(downsampled_image);
end

function normalized = Normalize(edges)
    %[1,2] means that we find maximum value in channel. If we would like to find
    %absolute maximum, we would use "all"
    max_val = max(max(max(edges, [], 1), [], 2), [], 3);
    normalized = (edges ./ max_val) * 255;
end

function padded_image = Pad_image(image_to_pad)
    [height, width, channel] = size(image_to_pad);
    padded_image = zeros(height + 2, width + 2, channel);
    %using parameter+1 because we are using image_to_pad parameters, however, padded_image is parameter+2
    padded_image(2:height + 1, 2:width + 1, 1:channel) = image_to_pad;
end

function [] = Show_image(image_to_show, image_title)
    figure;
    imshow(image_to_show);
    title(image_title)
end

function [] = Show_channels(image)
    Show_image(uint8(image(:,:,1)), "Red")
    Show_image(uint8(image(:,:,2)), "Green")
    Show_image(uint8(image(:,:,3)), "Blue")
end

function [] = Show_grayscale(image)
    grayscale_image = (image(:,:,1) + image(:,:,2) + image(:,:,3)) / 3;
    Show_image(uint8(grayscale_image), "Grayscale")
end

function convolution = Convolute_image(image, kernel, stride)
    switch kernel
        case "blur"
            conv = [1 2 1
                    2 4 2
                    1 2 1];
        case "horizontal"
            conv = [1 0 -1
                    2 0 -2
                    1 0 -1];
        case "vertical"
            conv = [1  2  1
                    0  0  0
                   -1 -2 -1];
        %Using 3x3 pool because otherwise dimension may not match with
        %2-strided image
        case "pool"
            conv = [1 1 1
                    1 1 1
                    1 1 1];
    end
    [height, width, ~] = size(image);
    [kernel_size, ~] = size(conv);
    %new dimensions formula is: (length - filter length) / stride + 1
    amount_of_height_convolutions = floor((height - kernel_size) / stride) + 1;
    amount_of_width_convolutions = floor((width - kernel_size) / stride) + 1;
    last_starting_height_element = amount_of_height_convolutions * stride;
    last_starting_width_element = amount_of_width_convolutions * stride;
    convolution = zeros(amount_of_height_convolutions, amount_of_width_convolutions, 3);
    for row = 1:kernel_size
        for col = 1:kernel_size
            %-1 + parameter, because Matlab arrays start for 1
            convolution = convolution + conv(row, col) * image(row:stride:last_starting_height_element - 1 + row, col:stride:last_starting_width_element - 1 + col,:);
        end
    end
    switch kernel
        case "blur"
            convolution = convolution / 16;
        case "pool"
            %avg pool
            convolution = convolution / 9;
    end
end

