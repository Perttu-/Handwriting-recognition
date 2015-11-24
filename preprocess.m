function boundaries = preprocess(path)
    close all;
    [img,map] = imread(path);

    if ~isempty(map)
        img = ind2rgb(img,map);
    end
    img = rgb2gray(img);

    bwImg2=sauvola(img,[11 11],0.07);
    complementedImg = imcomplement(bwImg2);
    aOpened = xor(bwareaopen(complementedImg, 80), bwareaopen(complementedImg,8000)); %parameters depend on the text size
    boundaries = bwboundaries(aOpened);
%     figure();
%     subplot(2,2,1), imshow(img);
%     subplot(2,2,2), imshow(bwImg2);
%     subplot(2,2,3), imshow(imcomplement(aOpened)); 
    %hold on;
    figure();
    imshow(img);
    hold on;
    for i =1:length(boundaries)
        b = boundaries{i};
        plot(b(:,2),b(:,1),'g','LineWidth',3);
    end





    