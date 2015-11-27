function preprocess(path)
    close all;
    
    [img,map] = imread(path);
    
    %Change color mode to rgb if it already isnt
    if ~isempty(map)
        img = ind2rgb(origImg,map);
    end
    
    %Change rgb image to grayscale
    grayImg = rgb2gray(img);
    
    %Noise removal.
    noiselessImg = wiener2(grayImg, [3, 3]); %Filter size?
    
    %Histogram equalization
    %noiselessImg = histeq(noiselessImg);

    %Binarization
    binImg=sauvola(noiselessImg,[10, 10],0.06);
    complementedImg = imcomplement(binImg);

    %Remove blobs which areas are outside the two thresholds
    %Following arguments depend on the text size
    low = 100;
    high = 9000;
    openedImg= xor(bwareaopen(complementedImg, low), bwareaopen(complementedImg,high)); 
    eccentricities = regionprops(openedImg,'eccentricity');
    boundaries = bwboundaries(openedImg,8,'holes'); 

    figure();
    subplot(2,2,1), imshow(noiselessImg), title('Original image');
    subplot(2,2,2), imshow(complementedImg), title('Binarized image');
    subplot(2,2,3), imshow(openedImg), title('Morphologically opened image');
    subplot(2,2,4), imshow(img), title('Found objects');
    hold on;

    for i =1:length(boundaries)
        b = boundaries{i};
        plot(b(:,2),b(:,1),'g','LineWidth',1);
    end
    






    
