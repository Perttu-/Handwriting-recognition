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
    p.strokeWidthThreshold = 100;
    
    tic
    p.preprocess;
    toc
    
    tic
    boundingBoxes = p.boundingBoxes;
    bbList = zeros(length(boundingBoxes),4);
    for i=1:length(boundingBoxes)
        bbList(i,:)=boundingBoxes(i).BoundingBox;
    end
    
    overlapRatio = bboxOverlapRatio(bbList,bbList);
    width = size(overlapRatio,1);
    %looping through the array diagonally and setting the overlap ratios of
    %bounding boxes with itself to zero
    overlapRatio(1:width+1:width^2) = 0;
    toc
    figure(1);
    g = graph(overlapRatio); %cool
    plot(g);
    
    %Exessive amount of combinations with large number of objects
%     pairs = nchoosek(1:length(boundingBoxes),2);
%     overlapRatios = struct('Pair', {},'OverlapRatio', {});
% 
%     for i=1:length(pairs)
%         bboxA = boundingBoxes(pairs(i,1));
%         bboxB = boundingBoxes(pairs(i,2));
%         overlapRatio = bboxOverlapRatio(bboxA.BoundingBox,bboxB.BoundingBox, 'Min');
%         if overlapRatio ~= 0
%             overlapRatios(end+1) = struct('Pair',[pairs(i,1), pairs(i,2)],...
%                                           'OverlapRatio', overlapRatio);
%         end
%     end
    
    
    
    newImage = p.strokeImage;
    newImage = 255 * uint8(newImage);
    
    properties = p.strokeMetrics;
    for i = 1:length(properties)
        if isnan(properties(i))
            property = 'NaN';
        else
            property = num2str(properties(i));
        end
        property = i;
        newImage = insertText(newImage,...
                              boundingBoxes(i).BoundingBox(1:2),...
                              property,...
                              'BoxOpacity',0,...
                              'FontSize',10,...
                              'TextColor','green');
    end
    figure(2);
    imshow(newImage);
    hold on;
    for i = 1:length(boundingBoxes)
        box = boundingBoxes(i).BoundingBox;
        handles.boundingBoxes(i) = rectangle('Position',...
                                   [box(1),box(2),box(3),box(4)],...
                                   'EdgeColor','r',...
                                   'LineWidth',1);
    end
    hold off;
    

%     imagesc(strokeWidthImage);
%     colormap('jet');
%     colorbar;

    disp(['Number of objects: ', int2str(p.objectCount)]);

    
    

