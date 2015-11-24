function preprocess(path)
    close all;
    
    [img,map] = imread(path);
    %Change color mode to rgb
    if ~isempty(map)
        img = ind2rgb(img,map);
    end
    %Change rgb image to grayscale
    img = rgb2gray(img);
    
    %Binarization
    bwImg2=sauvola(img,[11 11],0.07);
    complementedImg = imcomplement(bwImg2);
    %Remove blobs which areas are between the two thresholds
    %following parameters depend on the text size
    low = 80;
    high = 8000;
    aOpened = xor(bwareaopen(complementedImg, low), bwareaopen(complementedImg,high)); 
    boundaries = bwboundaries(aOpened);

%     figure();
%     subplot(2,2,1), imshow(img);
%     subplot(2,2,2), imshow(bwImg2);
%     subplot(2,2,3), imshow(imcomplement(aOpened)); 
%     hold on;
    figure();
    imshow(img);
    hold on;
    for i =1:length(boundaries)
        b = boundaries{i};
        plot(b(:,2),b(:,1),'g','LineWidth',3);
    end





    
