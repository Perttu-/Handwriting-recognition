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
    rlsaRowThreshold = 300;
    rlsaWordHorizontalThreshold = 15;
    rlsaWordVerticalThreshold = 30;
    
    
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
    
    
    
    %visualizeBBoxes(p.strokeImage,combinedBBoxes);
    
    %remove boxes which take only a fraction of the total area.
    areas = combinedBBoxes(:,3).*combinedBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    combinedBBoxes((areaRatio<areaRatioThreshold),:)=[];
    
    mainImage = p.strokeImage;
    layoutStruct = struct('Image',mainImage,...
                          'AoiBoxes',combinedBBoxes,...
                          'AoiStruct',[]);
    
    %area of interest image extraction
    aois = size(combinedBBoxes,1);
    aoiStruct = struct('Image',[],...
                       'ObjectCount', [],...
                       'RlsaImage',[],...
                       'RowBoxes',[],...
                       'RowStruct',[]);

    for ii=1:aois
        bbox = combinedBBoxes(ii,:);
        subImage = imcrop(mainImage, bbox);
        vHist = sum(subImage,1);
        %the area of interest images are trimmed so no space is in
        %beginning nor in the end of the image
%         startPoint = find(vHist~=0, 1, 'first')-0.5;
%         endPoint = find(vHist~=0, 1, 'last')-0.5;
%         cropBox = [startPoint,0.5,endPoint-startPoint,bbox(4)];
%         aoiImage = imcrop(subImage, cropBox);
        aoiImage = subImage;
        
        %extracting properties from the area of interest
        [~, numberOfObjects] = bwlabel(aoiImage);
        aoiStruct(ii).Image = aoiImage;
        aoiStruct(ii).ObjectCount = numberOfObjects;
        
        %line detection with rlsa method 
        rowRlsaImage = rlsa(subImage,rlsaRowThreshold,1);
        aoiStruct(ii).RlsaImage = rowRlsaImage;
        rowBoxStruct = regionprops(rowRlsaImage,'BoundingBox');
        rowBoxes = transpose(reshape([rowBoxStruct.BoundingBox],4,[]));
        %remove boxes which are more tall than wide
        rowBoxes((rowBoxes(:,3)<rowBoxes(:,4)),:)=[];
        aoiStruct(ii).RowBoxes = rowBoxes;
        rowBoxesLength = size(rowBoxes,1);
        rowStruct = struct('RowImage',[],...
                           'RlsaImage',[],...
                           'WordBoxes',[]);
        for jj=1:rowBoxesLength
            rowImage = imcrop(aoiImage,rowBoxes(jj,:));
            rowStruct(jj).RowImage = rowImage;
            wordRlsaImage = rlsa(rowImage,rlsaWordHorizontalThreshold,1);
            wordRlsaImage = rlsa(wordRlsaImage,rlsaWordVerticalThreshold,0);
            rowStruct(jj).RlsaImage = wordRlsaImage;
            wordBoxStruct = regionprops(wordRlsaImage,'BoundingBox');
            rowStruct(jj).WordBoxes = transpose(reshape([wordBoxStruct.BoundingBox],4,[]));
        end
        aoiStruct(ii).RowStruct = rowStruct;
    end
    layoutStruct.AoiStruct = aoiStruct;

    
    %bounding box method
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
    
    %% word detection
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
        
    
%     figure();
%     visualizeBBoxes(aoiStruct(1).Image, aoiStruct(1).RlsaBBoxes);
      visualizeLayout(p.originalImage,layoutStruct);
%       figure();
%       visualizeBBoxes(aoiStruct(2).RowStruct(1).RowImage, aoiStruct(2).RowStruct(1).WordBoxes, 'g');
%     figure();
%     visualizeBBoxes(p.finalImage, combinedBBoxes);
    %figure(),imshow(imageStruct(1).Image),hold on, visboundaries(bwboundaries(imageStruct(1).RlsaImage,8,'noholes'));
    %visualizeImgStruct(imageStruct,[],0);
    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    disp(['Number of the areas of interest: ', int2str(aois)]);
