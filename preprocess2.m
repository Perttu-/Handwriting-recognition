function preprocess2(filename)

    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %IAM database
    p.wienerFilterSize = 6;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.6;
    p.morphClosingDiscSize = -1;
    p.strokeWidthThreshold = 0.65;
    rowXExpansionAmount = 70;
    rowYExpansionAmount = 1;
    areaRatioThreshold = 0.004;
    spaceRatioThreshold = 0.022;
    wordXExpansionAmount = 11;
    wordYExpansionAmount = 19;
    
    
    %handwriting_new_2.jpg
%     p.wienerFilterSize = 10;
%     p.sauvolaNeighbourhoodSize = 100;
%     p.sauvolaThreshold = 0.1;
%     p.morphClosingDiscSize = -1;
%     p.strokeWidthThreshold = 0.45;
%     xExpansionAmount = 135;
%     yExpansionAmount = 1;
%     areaRatioThreshold = 0.1;
%     spaceRatioThreshold = 0.2;
    
    tic
    p.preprocess;
    toc
    
    tic
    %% Experimental layout analysis
    boundingBoxes = p.boundingBoxes;


    
    %Largening
    wideBBoxes=expandBBoxes(p.originalImage,...
                            boundingBoxes,...
                            rowXExpansionAmount,...
                            rowYExpansionAmount);

    %combine boxes which overlap more than given threshold
    [rowBBoxes, ~] = combineOverlappingBoxes(wideBBoxes, 0);
    
    %combine elements which might not have been combined on last time
    [rowBBoxes, ~] = combineOverlappingBoxes(rowBBoxes, 0);
    
    %remove boxes which are more tall than wide
    rowBBoxes((rowBBoxes(:,3)<rowBBoxes(:,4)),:)=[];
    
    %remove boxes which take only a fraction of the total area.
    areas = rowBBoxes(:,3).*rowBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    rowBBoxes((areaRatio<areaRatioThreshold),:)=[];
   
    %row image extraction and generating projection histograms
    newImage = p.strokeImage;
    rows = size(rowBBoxes,1);
    imageStruct = struct('Image',[],...
                         'ObjectCount', [],...
                         'VerticalHistogram',[],...
                         'HorizontalHistogram',[],...
                         'Space',[],...
                         'BoundingBox',[]);
                    
    %the images are trimmed so no space is in beginning nor in the end of 
    %the image
    for ii=1:rows
        bbox = rowBBoxes(ii,:);
        subImage = imcrop(newImage, bbox);
        vHist = sum(subImage,1);
       
        startPoint = find(vHist~=0, 1, 'first')-0.5;
        endPoint = find(vHist~=0, 1, 'last')-0.5;
        cropBox = [startPoint,0.5,endPoint-startPoint,bbox(4)];
        rowImage = imcrop(subImage, cropBox);

        [~, numberOfObjects] = bwlabel(rowImage);
        imageStruct(ii).Image = rowImage;
        imageStruct(ii).ObjectCount = numberOfObjects;
        imageStruct(ii).VerticalHistogram = sum(rowImage,1);
        imageStruct(ii).HorizontalHistogram = sum(subImage,2);
    end
    
    %maybe the bounding box expansion method could work
%     for ii=1:rows
%         img = imageStruct(ii).Image;
%         bboxes = regionprops(img,'BoundingBox');
%         expandedBBoxes = expandBBoxes(img,...
%                                       bboxes,...
%                                       wordXExpansionAmount,...
%                                       wordYExpansionAmount);
%         [wordBBoxes, ~] = combineOverlappingBoxes(expandedBBoxes, 0);
%         imageStruct(ii).BoundingBox = wordBBoxes;
%         
%     end
    
    
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
    
    %searching for spaces
    %doesn't work for one word rows with separated characters
%     for ii=1:length(imageStruct)
%         spaces = imageStruct(ii).Space;
%         if ~isempty(spaces)
%             spaceLengths = spaces(:,2) - spaces(:,1);
%             totalSpaceLength = sum(spaceLengths);
%             spaceRatio = spaceLengths/totalSpaceLength;
%             spaces((spaceRatio<spaceRatioThreshold),:)=[];
%             imageStruct(ii).Space = spaces;
%         end
%     end
    
    toc
    
    %% visualization
    
    visualizeRows(imageStruct,[]);
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

    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    disp(['Number of rows: ', int2str(size(rowBBoxes,1))]);
