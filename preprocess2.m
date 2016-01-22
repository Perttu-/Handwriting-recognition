function preprocess2(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values for testimage2.jpg
    p.wienerFilterSize = -1;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphClosingDiscSize = -1;
    %another argument to tweak
    %0.65 good for IAM database?
    p.strokeWidthThreshold = 0.65;
    
    %two more
    xExpansionAmount = 75;
    yExpansionAmount = 4;
    
    tic
    p.preprocess;
    toc
    
    boundingBoxes = p.boundingBoxes;

    xmins = zeros(length(boundingBoxes),1);
    xmaxs = xmins;
    ymins = xmins;
    ymaxs = xmins;
    
    %Largening
    for i=1:length(boundingBoxes)
        %getting corner points
        [xmin,ymin,xmax,ymax] = extractBoxCorners(boundingBoxes(i).BoundingBox);

        %widening and...
        xmin = xmin-xExpansionAmount;
        xmax = xmax+xExpansionAmount; 
        
        %...heightening the boxes
        ymin = ymin-yExpansionAmount;
        ymax = ymax+yExpansionAmount;
        
        %cropping the boxes to fit image.
        xmin = max(xmin, 0.5);
        ymin = max(ymin, 0.5);
        xmax = min(xmax, size(p.originalImage,2)-0.5);
        ymax = min(ymax, size(p.originalImage,1)-0.5);
       
        xmins(i) = xmin;
        ymins(i) = ymin;
        xmaxs(i) = xmax;
        ymaxs(i) = ymax;
        
    end

    wideBBoxes = [xmins ymins xmaxs-xmins+1 ymaxs-ymins+1];
    
    %combine
    [rowBBoxes, overlapRatios] = combineOverlappingBoxes(wideBBoxes);
    
    %remove areas which have only one object inside them.
    g = graph(overlapRatios); 
    componentIndices = conncomp(g);
    histg = histcounts(componentIndices, max(componentIndices));
    rowBBoxes(histg == 1,:)=[];
    
    newImage = p.strokeImage;
    
    for i=1:size(rowBBoxes,1)
        %sub image extraction
        [xmins,ymins,xmaxs,ymaxs] = extractBoxCorners(rowBBoxes);
        
    end
    
    
    
    %binary image to grayscale
%     newImage = 255 * uint8(newImage);    
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
%                               'BoxOpacity',1,...
%                               'FontSize',10,...
%                               'TextColor','red');
%     end
%     imshow(imgWideBoxes);

    figure();
    imshow(newImage);
    hold on;
    boundingBoxes = rowBBoxes;
    for i = 1:length(boundingBoxes)
        box = boundingBoxes(i,:);
        handles.boundingBoxes(i) = rectangle('Position',...
                                   box,...
                                   'EdgeColor','r',...
                                   'LineWidth',1);
    end
    hold off;
    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    disp(['Number of rows: ', int2str(length(rowBBoxes))]);
