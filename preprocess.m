function [boundaries, boundingBoxes] = preprocess(path, inputArray)
    %close all;
    
    [img,map] = imread(path);
    
    %Change color mode to rgb if it already isn't
    if ~isempty(map)
        img = ind2rgb(origImg,map);
    end
    
     %Change rgb image to grayscale if it already isn't
    [rows, columns, numberOfColorChannels] = size(img);
    if numberOfColorChannels > 1
        grayImg = rgb2gray(img);
    else
        grayImg = img; 
    end
   
    
    %Noise removal.
    noiselessImg = wiener2(grayImg, [3, 3]); %Filter size?
    
    %Histogram equalization
    %noiselessImg = histeq(noiselessImg);

    %Binarization
    binImg=sauvola(noiselessImg,[10, 10],0.06);
    complementedImg = imcomplement(binImg);

    %Remove blobs which areas are outside the two thresholds
    %Following arguments depend on the text size
    low = 400;
    high = 9000;
    openedImg = xor(bwareaopen(complementedImg, low), bwareaopen(complementedImg,high)); 
    
    %closing to remove gaps
    closedImg = imdilate(openedImg,strel('disk',4));
    %closedImg = openedImg;
    
    eccentricities = regionprops(openedImg,'eccentricity');
    boundingBoxes = regionprops(closedImg,'boundingbox');
    boundaries = bwboundaries(closedImg,8,'holes'); 

%     figure();
%     subplot(2,2,1), imshow(noiselessImg), title('Original image');
%     subplot(2,2,2), imshow(complementedImg), title('Binarized image');
%     subplot(2,2,3), imshow(closedImg), title('Morphologically opened image');
%     subplot(2,2,4), imshow(img), title('Found objects');
%     figure();
%     imshow(closedImg), title('Morphologically opened image');
%     figure();
%     imshow(img), title('Found objects');
%     length(boundingBoxes)
%     length(boundaries)
%     hold on;
% 
%     for i =1:length(boundaries)
%         b = boundaries{i};
%         plot(b(:,2),b(:,1),'g','LineWidth',1);
%     end
% 
%     for i = 1:length(boundingBoxes)
%         box = boundingBoxes(i).BoundingBox;
%         rectangle('Position', [box(1),box(2),box(3),box(4)], 'EdgeColor','r','LineWidth',1);
%     end
% hold off;





    
