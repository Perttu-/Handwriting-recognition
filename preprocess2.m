function preprocess2(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values for testimage2.jpg
    p.wienerFilterSize = 6;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphClosingDiscSize = -1;
    %another argument to tweak
    %0.45 good for IAM database?
    p.strokeWidthThreshold = 0.372;
    
    tic
    p.preprocess;
    toc
    boundingBoxes = p.boundingBoxes;
    pairs = nchoosek(1:length(boundingBoxes),2);
    overlapRatios = zeros(length(pairs),1);
    length(pairs)
    for i=1:length(pairs)
        bboxA = boundingBoxes(pairs(i,1));
        bboxB = boundingBoxes(pairs(i,2));
        overlapRatios(i) = bboxOverlapRatio(bboxA.BoundingBox,bboxB.BoundingBox);
    end
    sum(overlapRatios)
    figure();
    newImage = p.strokeImage;
    newImage = 255 * uint8(newImage);
    
    properties = p.strokeMetrics;
    for i = 1:length(properties)
        if isnan(properties(i))
            property = 'NaN';
        else
            property = num2str(properties(i));
        end
        newImage = insertText(newImage,...
                              boundingBoxes(i).BoundingBox(1:2),...
                              property,...
                              'BoxOpacity',0,...
                              'FontSize',25,...
                              'TextColor','green');
    end

    imshow(newImage);
    hold on;
    for i = 1:length(boundingBoxes)
        box = boundingBoxes(i).BoundingBox;
        handles.boundingBoxes(i) = rectangle('Position',...
                                   [box(1),box(2),box(3),box(4)],...
                                   'EdgeColor','r',...
                                   'LineWidth',1);
    end
    


    
%     imagesc(strokeWidthImage);
%     colormap('jet');
%     colorbar;

    disp(['Number of objects: ', int2str(p.objectCount)]);

    
    

