function preprocess2(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values
    p.wienerFilterSize = 6;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphClosingDiscSize = -1;
    
    tic
    p.preprocess;
    toc
    imgs = p.subImages;
    
    strokeWidthThreshold = 0.4;

    for i = 1:length(imgs)
        binaryImage = imgs(i).Image;
        %bwdist gets the Euclidean distance to nearest nonzero pixel
        %the image colors need to be inversed
        distanceImage = bwdist(~binaryImage);
        skeletonImage = bwmorph(binaryImage, 'thin', inf);
        strokeWidthImage = distanceImage;
        %removing all but the pixels that are in skeleton to get better
        %wiev of stroke width
        strokeWidthImage(~skeletonImage) = 0;
        strokeWidthValues = distanceImage(skeletonImage);
        strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);

        strokeWidthFilterIdx(i) = strokeWidthMetric > strokeWidthThreshold;
        ar{i} = strokeWidthMetric;
    end
    boundingBoxes = p.boundingBoxes;
    boundingBoxes(strokeWidthFilterIdx) = [];
    figure();
    imshow(p.binarizedImage);
    hold on;
    for i = 1:length(boundingBoxes)
    box = boundingBoxes(i).BoundingBox;
    handles.boundingBoxes(i) = rectangle('Position',...
                               [box(1),box(2),box(3),box(4)],...
                               'EdgeColor','r',...
                               'LineWidth',1);
    end
    
%     properties = ar;
% 
%     for i = 1:length(properties)
%         newImage = insertText(p.binarizedImage,...
%                                 boundingBoxes(i).BoundingBox(1:2),...
%                                 num2str(properties(i)),...
%                                 'BoxOpacity',0,...
%                                 'FontSize',25,...
%                                 'TextColor','green');
%     end
%     imshow(newImage);
%     imagesc(strokeWidthImage);
%     colormap('jet');
%     colorbar;
    
    %"one dimensional" array containing all stroke widths 
    

    
% 
%     strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
%     strokeWidthThreshold = 7;
%     strokeWidthFilterIdx = strokeWidthMetric > strokeWidthThreshold;
%     binaryImage(strokeWidthFilterIdx)=0;
%     figure(), imshow(binaryImage);
    disp(['Number of objects: ', int2str(p.objectCount)]);

    
    

