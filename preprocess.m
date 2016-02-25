function layoutStruct = preprocess(path,testedValue)
%% Initialization
    close all;
    p = preprocessor;
    [image, map]=imread(path);
    p.originalImage = image;
    p.map = map;
    
    
    %IAM database
    p.wienerFilterSize = 15;
    p.sauvolaNeighbourhoodSize = 180;
    p.sauvolaThreshold = 0.3;
    p.morphClosingDiscSize = 3;
    p.strokeWidthThreshold = 0.6;
    p.skewCorrection = 0;
    aoiXExpansionAmount = 40;
    aoiYExpansionAmount = 60;
    areaRatioThreshold = 0.004;
    rlsaRowThreshold = 300;
    rlsaWordHorizontalThreshold = 30;
    rlsaWordVerticalThreshold = 30;
    
%     p.wienerFilterSize = 2;
%     p.sauvolaNeighbourhoodSize = 100;
%     p.sauvolaThreshold = 0.6;
%     p.morphClosingDiscSize = -1;
%     p.strokeWidthThreshold = 0.1;
%     p.skewCorrection = 0;
%     aoiXExpansionAmount = 130;
%     aoiYExpansionAmount = 10;
%     areaRatioThreshold = 0.004;
%     rlsaRowThreshold = 600;
%     rlsaWordHorizontalThreshold = 15;
%     rlsaWordVerticalThreshold = 30;
    
    
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
    
    tic;
    disp('Preprocessing...');
    p.preprocess;
    preprocessingTime = toc;
    
    tic

    disp('Layout analysis...');
    %% Experimental layout analysis
    preprocessedImage = p.finalImage;
    layoutStruct = struct('Image',preprocessedImage,...
                          'NumberOfRows',[],...
                          'NumberOfWords',[],...
                          'AoiBoxes',[],...
                          'AoiStruct',[],...
                          'PreprocessingTime',preprocessingTime,...
                          'LayoutAnalysisTime',[]);
    
    boundingBoxes = regionprops(preprocessedImage,'BoundingBox');
    if isempty(boundingBoxes)
        layoutStruct.LayoutAnalysisTime = -1;
        layoutStruct.NumberOfRows = 0;
        layoutStruct.NumberOfWords = 0;
        return 
    end
    %Largening
    largeBBoxes=expandBBoxes(preprocessedImage,...
                            boundingBoxes,...
                            aoiXExpansionAmount,...
                            aoiYExpansionAmount);
                        
    %visualizeBBoxes(p.finalImage,largeBBoxes,'r');
    %combine boxes which overlap more than given threshold
    [combinedBBoxes, ~] = combineOverlappingBoxes(largeBBoxes, 0);
    
    %combine elements which might not have been combined on last time
    [combinedBBoxes, ~] = combineOverlappingBoxes(combinedBBoxes, 0);
    
    %remove boxes which take only a fraction of the total area.
    areas = combinedBBoxes(:,3).*combinedBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    combinedBBoxes((areaRatio<areaRatioThreshold),:)=[];
    
    layoutStruct.AoiBoxes = combinedBBoxes;
    
    %area of interest image extraction
    aois = size(combinedBBoxes,1);
    aoiStruct = struct('Image',[],...
                       'ObjectCount', [],...
                       'RlsaImage',[],...
                       'RowBoxes',[],...
                       'RowStruct',[]);
    
    wordAmount = 0;
    for ii=1:aois
        bbox = combinedBBoxes(ii,:);
        subImage = imcrop(preprocessedImage, bbox);
        aoiImage = subImage;
        
        %extracting properties from the area of interest
        %average area might be useful in line/word detection thresholds?
        [~, numberOfObjects] = bwlabel(aoiImage);
        aoiStruct(ii).Image = aoiImage;
        aoiStruct(ii).ObjectCount = numberOfObjects;
        
        %line detection with rlsa method 
        rowRlsaImage = rlsa(subImage,rlsaRowThreshold,1);
%         figure();
%         imshow(subImage);
%         figure();
%         imshow(rowRlsaImage);
        
        aoiStruct(ii).RlsaImage = rowRlsaImage;
        rowBoxStruct = regionprops(rowRlsaImage,'BoundingBox');
        rowBoxes = transpose(reshape([rowBoxStruct.BoundingBox],4,[]));
%         figure();
%         visualizeBBoxes(rowRlsaImage,rowBoxes,'c',3);
%         figure();
%         visualizeBBoxes(subImage,rowBoxes,'c',3);
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
%             figure();
%             imshow(wordRlsaImage);
           
            rowStruct(jj).RlsaImage = wordRlsaImage;
            wordBoxes = regionprops(wordRlsaImage,'BoundingBox');
            wordBoxList = transpose(reshape([wordBoxes.BoundingBox],4,[]));
%             figure();
%             visualizeBBoxes(rowImage,wordBoxes,'g',3);
            [combinedWordBoxes,~] = combineOverlappingBoxes(wordBoxList,0);
            [combinedWordBoxes,~] = combineOverlappingBoxes(combinedWordBoxes,0);
            wordAmount = wordAmount + size(combinedWordBoxes,1);
            rowStruct(jj).WordBoxes = combinedWordBoxes;
        end
        aoiStruct(ii).RowStruct = rowStruct;
    end
    %TODO remove aois which doesn't have any rows

    layoutAnalysisTime = toc;
    layoutStruct.AoiStruct = aoiStruct;
    layoutStruct.NumberOfRows = rowBoxesLength;
    layoutStruct.NumberOfWords = wordAmount;
    layoutStruct.LayoutAnalysisTime = layoutAnalysisTime;

%      visualizeLayout(p.originalImage, layoutStruct, 3);
%     disp(['Number of the areas of interest: ', int2str(aois)]);
%     disp(['Number of rows: ', int2str(rowBoxesLength)]);
%     disp(['Number of wordss: ', int2str(wordAmount)]);
