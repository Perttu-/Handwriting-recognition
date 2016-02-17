function preprocess2(filename)
%% Initialization
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
    p.skewCorrection = 0;
    aoiXExpansionAmount = 70;
    aoiYExpansionAmount = 57;
    areaRatioThreshold = 0.004;
    spaceRatioThreshold = 0.022;
    wordXExpansionAmount = 11;
    wordYExpansionAmount = 19;
    spaceThreshold = 16;
    rlsaThreshold = 30;
    
    
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
    wideBBoxes=expandBBoxes(p.finalImage,...
                            boundingBoxes,...
                            aoiXExpansionAmount,...
                            aoiYExpansionAmount);
                        
    %visualizeBBoxes(p.finalImage,p.boundingBoxes);
    %combine boxes which overlap more than given threshold
    [combinedBBoxes, ~] = combineOverlappingBoxes(wideBBoxes, 0);
    
    %combine elements which might not have been combined on last time
    [combinedBBoxes, ~] = combineOverlappingBoxes(combinedBBoxes, 0);
    
    %remove boxes which are more tall than wide
    %rowBBoxes((rowBBoxes(:,3)<rowBBoxes(:,4)),:)=[];
    
    %visualizeBBoxes(p.strokeImage,combinedBBoxes);
    
    %remove boxes which take only a fraction of the total area.
    areas = combinedBBoxes(:,3).*combinedBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    combinedBBoxes((areaRatio<areaRatioThreshold),:)=[];
   
    %row image extraction and generating projection histograms
    newImage = p.strokeImage;
    aoi = size(combinedBBoxes,1);
    imageStruct = struct('Image',[],...
                         'ObjectCount', [],...
                         'VerticalHistogram',[],...
                         'HorizontalHistogram',[],...
                         'Space',[],...
                         'BoundingBox',[],...
                         'RlsaImage',[],...
                         'RlsaHorizontalHistogram',[],...
                         'RlsaBBoxes',[]);
    
                 
    
    for ii=1:aoi
        bbox = combinedBBoxes(ii,:);
        subImage = imcrop(newImage, bbox);
        vHist = sum(subImage,1);
        %the area of interest images are trimmed so no space is in
        %beginning nor in the end of the image
        startPoint = find(vHist~=0, 1, 'first')-0.5;
        endPoint = find(vHist~=0, 1, 'last')-0.5;
        cropBox = [startPoint,0.5,endPoint-startPoint,bbox(4)];
        aoiImage = imcrop(subImage, cropBox);
        
        %extracting properties from the area of interest
        [L, numberOfObjects] = bwlabel(aoiImage);
        imageStruct(ii).Image = aoiImage;
        imageStruct(ii).ObjectCount = numberOfObjects;
        imageStruct(ii).VerticalHistogram = sum(aoiImage,1);
        imageStruct(ii).HorizontalHistogram = sum(subImage,2);
    end

    %% line detection experiments

    %run length smoothing algorithm
    for ii=1:length(imageStruct)
        x=imageStruct(ii).Image;
        [m, ~] = size(x);
        xx = [ones(m,1) x ones(m,1)];
        xx = reshape(xx',1,[]);
        d = diff(xx);
        start = find(d==-1);
        stop = find(d==1);
        lgt = stop-start;
        b = lgt <= rlsaThreshold;
        d(start(b)) = 0;
        d(stop(b)) = 0;
        yy = cumsum([1 d]);
        yy = reshape(yy, [], m)';
        rlsaImage = yy(:,2:end-1);
        imageStruct(ii).RlsaImage = rlsaImage;
        rlsaHorizontalHistogram = sum(rlsaImage,2);
        imageStruct(ii).RlsaHorizontalHistogram = rlsaHorizontalHistogram;
%         wordBoxes = regionprops(rlsaImage,'BoundingBox');
%         imageStruct(ii).RlsaBBoxes = [wordBoxes.BoundingBox];
    end
    
    
    %maybe the bounding box expansion method could work
%     for ii=1:aoi
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

%     
%     %searching for spaces
%     %doesn't work for one word rows with separated characters
%     for ii=1:length(imageStruct)
%         spaces = imageStruct(ii).Space;
%         if ~isempty(spaces)
%              spaceLengths = spaces(:,2) - spaces(:,1);
% %             totalSpaceLength = sum(spaceLengths);
% %             spaceRatio = spaceLengths/totalSpaceLength;
% %             spaces((spaceRatio<spaceRatioThreshold),:)=[];
%             spaces(spaceLengths<spaceThreshold,:)=[];
%             imageStruct(ii).Space = spaces;
%         end
%     end
  
    %toc
    
    %% visualization
    %visualizeBBoxes(p.finalImage, [imageStruct.RlsaBBoxes]);
%   figure(),imshow(imageStruct(1).Image),hold on, visboundaries(bwboundaries(imageStruct(1).RlsaImage,8,'noholes'));
    %visualizeImgStruct(imageStruct,[],0);
    


    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    disp(['Number of the areas of interest: ', int2str(aoi)]);
