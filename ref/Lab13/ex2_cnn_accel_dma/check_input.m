clc 
clear all
close all

%% Output from the H/W simulation (by CPU)
im_hw_cpu = imread('out/input_image_by_cpu.bmp');
im_hw_cpu = im_hw_cpu(:,:,1);    % Gray image

%% Output from the H/W simulation (by DMA)
im_hw_dma = imread('out/input_image_by_dma.bmp');
im_hw_dma = im_hw_dma(:,:,1);    % Gray image

%% Calculate the difference between S/W and H/W outputs
img_diff = abs(single(im_hw_cpu) - single(im_hw_dma));
max_diff = max(img_diff(:));

%% Evaluation
if(max_diff == 0)
    fprintf('Two images are SAME!\n');   
else
    fprintf('Two images are different!\n');   
    disp(max_diff);
    figure(1)
    imshow(uint8(img_diff));
end


