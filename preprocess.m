function boundaries = preprocess(path)
    [img,map] = imread(path);
    
    if ~isempty(map)
        img = ind2rgb(img,map);
    end
    img = rgb2gray(img);
    %{
    %http://dsp.stackexchange.com/a/1934 
    se = strel('disk',20); %what is the best option for this structural element?
    closedImg = imclose(img,se);
    normImg = img./closedImg;
    
    level = graythresh(normImg);
    bwImg = im2bw(normImg, map, level);
    %}
    

    %bwImg1=adaptivethreshold(img,11,0.07,0); 
    bwImg2=sauvola(img,[11 11],0.07);

    %closed = imclose(imcomplement(bwImg2),strel('disk',3));
    
    
    boundaries = bwboundaries(bwImg2);

    %{
    for i =1:length(boundaries)
        b = boundaries{i};
        plot(b(:,2),b(:,1),'g','LineWidth',3);
    end
    %}
    
    figure();
    subplot(2,2,1), imshow(img);
    subplot(2,2,2), imshow(bwImg2);
    %subplot(2,2,3), imshow(imcomplement(closed));
    
    %subplot(2,2,4), imshow(bwImg3);
    


    
