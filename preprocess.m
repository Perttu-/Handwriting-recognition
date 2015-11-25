function preprocess(path)
    close all;
    
    [img,map] = imread(path);
    
    %Change color mode to rgb if it already isnt
    if ~isempty(map)
        img = ind2rgb(img,map);
    end
    
    %Change rgb image to grayscale
    img = rgb2gray(img);
    
    %Noise removal.
    img = wiener2(img, [10, 10]); %Filter size?
    
    %Histogram equalization
    img = histeq(img);

    %Binarization
    bwImg=sauvola(img,[11 11],0.07);
    complementedImg = imcomplement(bwImg);
    figure();
    imshow(bwImg);
    %imshow(xor(bwImg,bwImg2));
    
    %Remove blobs which areas are between the two thresholds
    %Following parameters depend on the text size
    low = 60;
    high = 90000;
     aOpened = xor(bwareaopen(complementedImg, low), bwareaopen(complementedImg,high)); 
     boundaries = bwboundaries(aOpened);


%     figure();
%     subplot(2,2,1), imshow(img);
%     subplot(2,2,2), imshow(bwImg2);
%     subplot(2,2,3), imshow(imcomplement(aOpened)); 

    figure();
    imshow(img);
    hold on;
    for i =1:length(boundaries)
        b = boundaries{i};
        plot(b(:,2),b(:,1),'g','LineWidth',1);
    end





    
