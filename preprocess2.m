function preprocess2(filename)
    %close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values chosen for IAM database images
    p.wienerFilterSize = 10;
    p.sauvolaNeighbourhoodSize = 300;
    p.sauvolaThreshold = 0.1;
    p.morphClosingDiscSize = -1;
    
    %another argument to tweak
    %0.65 good for IAM database?
    p.strokeWidthThreshold = 0.35;
    
    %two more
    xExpansionAmount = 135;
    yExpansionAmount = 1;
    
    tic
    p.preprocess;
    toc
    
    tic
    boundingBoxes = p.boundingBoxes;

    xmins = zeros(length(boundingBoxes),1);
    xmaxs = xmins;
    ymins = xmins;
    ymaxs = xmins;
    
     %Largening
    for ii=1:length(boundingBoxes)
        %getting corner points
        [xmin,ymin,xmax,ymax] = extractBoxCorners(boundingBoxes(ii).BoundingBox);

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
       
        xmins(ii) = xmin;
        ymins(ii) = ymin;
        xmaxs(ii) = xmax;
        ymaxs(ii) = ymax;
        
    end

    wideBBoxes = [xmins ymins xmaxs-xmins+1 ymaxs-ymins+1];
    
    %combine boxes which overlap more than given threshold
    [rowBBoxes, ~] = combineOverlappingBoxes(wideBBoxes, 0);
    %combine elements which might not have been combined on last time
    [rowBBoxes, ~] = combineOverlappingBoxes(rowBBoxes, 0);
    
    %remove boxes which are more tall than wide
    rowBBoxes((rowBBoxes(:,3)<rowBBoxes(:,4)),:)=[];
    
    %remove boxes which take only a fraction of the total area.
    areaRatioThreshold = 0.1;
    areas = rowBBoxes(:,3).*rowBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    rowBBoxes((areaRatio<areaRatioThreshold),:)=[];
    
    
%     for i=1:length(boundingBoxes)
%         rowBBoxes(i,:) = boundingBoxes(i).BoundingBox;
%     end
    %sub image extraction and generating projection histograms
    newImage = p.strokeImage;
    rows = size(rowBBoxes,1);
    imageStruct = struct('Image',[],...
                         'ObjectCount', [],...
                         'VerticalHistogram',[],...
                         'HorizontalHistogram',[],...
                         'Space',[]);
    for ii=1:rows
        bbox = rowBBoxes(ii,:);
        subImage = imcrop(newImage, bbox);
        vHist = sum(subImage,1);
        %the images are trimmed so no space is in beginning nor end of the
        %image
        startPoint = find(vHist~=0, 1, 'first')-0.5;
        endPoint = find(vHist~=0, 1, 'last')-0.5;
        cropBox = [startPoint,0.5,endPoint-startPoint,bbox(4)];
        rowImage = imcrop(subImage, cropBox);
        [~, numberOfObjects] = bwlabel(rowImage);
        imageStruct(ii).Image = rowImage;
        imageStruct(ii).ObjectCount = numberOfObjects;
        imageStruct(ii).VerticalHistogram = vHist;
        imageStruct(ii).HorizontalHistogram = sum(subImage,2);
    end

    
    %getting information of the consecutive zero pixels
    %saving them as their start and end point pairs into the image struct
    for ii=1:length(imageStruct)
        vHist = imageStruct(ii).VerticalHistogram;
        bHist = vHist~=0;
        ebHist = [1,bHist,1];
        stloc = strfind(ebHist,[1 0]);
        endloc = strfind(ebHist,[0 1]);
        spaces = [];
        for jj =1:length(stloc)
            spaces(jj,:) = [stloc(jj),endloc(jj)];
        end
        imageStruct(ii).Space = spaces;
    end
    
    toc
    %visualization
    
    %binary image to grayscale
%     newImage = 255 * uint8(newImage);    
%     for ii = 1:length(rowBBoxes)
%         property = ii;
%         box = rowBBoxes(ii,:);
%         newImage = insertText(newImage,...
%                               [box(1),box(2)],...
%                               property,...
%                               'BoxOpacity',1,...
%                               'FontSize',10,...
%                               'TextColor','red');
%     end

    figure();
    imshow(newImage);
    hold on;
    boundingBoxes = rowBBoxes;
    for ii = 1:size(boundingBoxes,1)
        box = boundingBoxes(ii,:);
        handles.boundingBoxes(ii) = rectangle('Position',...
                                   box,...
                                   'EdgeColor','r',...
                                   'LineWidth',3);
    end
    hold off;
    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    disp(['Number of rows: ', int2str(size(rowBBoxes,1))]);
