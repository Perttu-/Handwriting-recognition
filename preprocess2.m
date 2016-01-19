function preprocess2(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values for testimage2.jpg
    p.wienerFilterSize = -1;%6
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphClosingDiscSize = -1;
    %another argument to tweak
    %0.45 good for IAM database?
    p.strokeWidthThreshold = 0.9;
    
    tic
    p.preprocess;
    toc
    
    tic
    boundingBoxes = p.boundingBoxes;

    
    bbList = zeros(length(boundingBoxes),4);
    wideBBoxes = bbList;
    expansionAmount = 0.25;
    xmins = zeros(length(boundingBoxes),1);
    xmaxs = xmins;
    ymins = xmins;
    ymaxs = xmins;
    
    
    for i=1:length(boundingBoxes)
        bBox = boundingBoxes(i).BoundingBox;
        xmin = bBox(:,1);
        ymin = bBox(:,2);
        xmax = xmin + bBox(:,3) - 1;
        ymax = ymin + bBox(:,4) - 1;
        
        %making the boxes wider in both directions
%         xmin = (1-expansionAmount) * xmin;
%         xmax = (1+expansionAmount) * xmax;
        
        
        xmin = max(xmin, 1);
        ymin = max(ymin, 1);
        xmax = min(xmax, size(p.originalImage,2));
        ymax = min(ymax, size(p.originalImage,1));
        
        bbList(i,:)= [xmin,ymin,xmax,ymax];
        wideBBoxes(i,:) = [xmin ymin xmax-xmin+1 ymax-ymin+1];
        
        xmins(i) = xmin;
        ymins(i) = ymin;
        xmaxs(i) = xmax;
        ymaxs(i) = ymax;
        
    end
    

    
    overlapRatio = bboxOverlapRatio(wideBBoxes,wideBBoxes);
    width = size(overlapRatio,1);
    overlapRatio(1:width+1:width^2) = 0;
    toc
    
    figure(1);
    g = graph(overlapRatio); 
    plot(g);
    componentIndices = conncomp(g);
    
    xmins = accumarray(componentIndices', xmins, [], @min);
    ymins = accumarray(componentIndices', ymins, [], @min);
    xmaxs = accumarray(componentIndices', xmaxs, [], @max);
    ymaxs = accumarray(componentIndices', ymaxs, [], @max);

    textBBoxes = [xmins ymins xmaxs-xmins+1 ymaxs-ymins+1];
    

    %remove areas which have only one object inside them.

     
    newImage = p.strokeImage;
%     
%     se = strel('line', 130, 0);
%     lineImg = imdilate(newImage,se);
%     lineBBoxes = regionprops(lineImg,'BoundingBox');
%     figure();
%     imshow(lineImg);
    
    newImage = 255 * uint8(newImage);
    imgWideBoxes = insertShape(newImage,'Rectangle',textBBoxes,'LineWidth',4,'Color','Green');
    figure();
    
    
%     properties = p.strokeMetrics;
%     for i = 1:length(properties)
%         if isnan(properties(i))
%             property = 'NaN';
%         else
%             property = num2str(properties(i));
%         end
%         property = i;
%         imgWideBoxes = insertText(imgWideBoxes,...
%                               boundingBoxes(i).BoundingBox(1:2),...
%                               property,...
%                               'BoxOpacity',1,...
%                               'FontSize',10,...
%                               'TextColor','red');
%     end
    imshow(imgWideBoxes);
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
    disp(['Number of rows: ', int2str(length(textBBoxes))]);

    
    

