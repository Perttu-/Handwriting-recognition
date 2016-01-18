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
    wideBBoxes = bbList;
    expansionAmount = 0.09;
    
    for i=1:length(boundingBoxes)
        bBox = boundingBoxes(i).BoundingBox;
        xmin = bBox(:,1);
        ymin = bBox(:,2);
        xmax = xmin + bBox(:,3) - 1;
        ymax = ymin + bBox(:,4) - 1;
        
        %making the boxes wider in both directions
        xmin = (1-expansionAmount) * xmin;
        xmax = (1+expansionAmount) * xmax;
        
        bbList(i,:)= [xmin,ymin,xmax,ymax];
        wideBBoxes(i,:) = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        
    end
    
    
    
    overlapRatio = bboxOverlapRatio(bbList,bbList);
    width = size(overlapRatio,1);
    %looping through the array diagonally and setting the overlap ratios of
    %bounding boxes with itself to zero (from corner to corner)
    overlapRatio(1:width+1:width^2) = 0;
    toc
    
    figure(1);
    g = graph(overlapRatio); 
    plot(g);
    componentIndices = conncomp(g);
     
    newImage = p.strokeImage;
%     
%     se = strel('line', 130, 0);
%     lineImg = imdilate(newImage,se);
%     lineBBoxes = regionprops(lineImg,'BoundingBox');
%     figure();
%     imshow(lineImg);
    
    newImage = 255 * uint8(newImage);
    imgWideBoxes = insertShape(newImage,'Rectangle',wideBBoxes,'LineWidth',4,'Color','Green');
    figure();
    imshow(imgWideBoxes);
%     properties = p.strokeMetrics;
%     for i = 1:length(properties)
%         if isnan(properties(i))
%             property = 'NaN';
%         else
%             property = num2str(properties(i));
%         end
%         property = i;
%         newImage = insertText(newImage,...
%                               boundingBoxes(i).BoundingBox(1:2),...
%                               property,...
%                               'BoxOpacity',0,...
%                               'FontSize',10,...
%                               'TextColor','green');
%     end
%     figure(2);
%     imshow(newImage);
%     hold on;
%     boundingBoxes = lineBBoxes;
%     for i = 1:length(boundingBoxes)
%         box = boundingBoxes(i).BoundingBox;
%         handles.boundingBoxes(i) = rectangle('Position',...
%                                    [box(1),box(2),box(3),box(4)],...
%                                    'EdgeColor','r',...
%                                    'LineWidth',1);
%     end
%     hold off;
    

%     imagesc(strokeWidthImage);
%     colormap('jet');
%     colorbar;

    disp(['Number of objects: ', int2str(p.objectCount)]);

    
    

