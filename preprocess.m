function layoutStruct = preprocess(path,testedValue)
%% Initialization
    close all;
    p = preprocessor;
    [image, map]=imread(path);
    p.originalImage = image;
    p.map = map;
    
    %IAM database
%     p.wienerFilterSize = 6;
%     p.sauvolaNeighbourhoodSize = 100;
%     p.sauvolaThreshold = 0.6;
%     p.morphClosingDiscSize = -1;
%     p.strokeWidthThreshold = 0.65;
%     p.skewCorrection = 0;
%     aoiXExpansionAmount = 70;
%     aoiYExpansionAmount = 57;
%     areaRatioThreshold = 0.004;
%     rlsaRowThreshold = 300;
%     rlsaWordHorizontalThreshold = 15;
%     rlsaWordVerticalThreshold = 30;
    
    p.wienerFilterSize = testedValue;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.6;
    p.morphClosingDiscSize = -1;
    p.strokeWidthThreshold = 0.65;
    p.skewCorrection = 0;
    aoiXExpansionAmount = 70;
    aoiYExpansionAmount = 57;
    areaRatioThreshold = 0.004;
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
    
    tic;
    disp('Preprocessing...');
    p.preprocess;
    preprocessingTime = toc;
    
    tic

    disp('Layout analysis...');
    %% Experimental layout analysis
    preprocecessedImage = p.finalImage;
    boundingBoxes = regionprops(preprocecessedImage);

    %Largening
    wideBBoxes=expandBBoxes(preprocecessedImage,...
                            boundingBoxes,...
                            aoiXExpansionAmount,...
                            aoiYExpansionAmount);
                        
    %visualizeBBoxes(p.finalImage,p.boundingBoxes);
    %combine boxes which overlap more than given threshold
    [combinedBBoxes, ~] = combineOverlappingBoxes(wideBBoxes, 0);
    
    %combine elements which might not have been combined on last time
    [combinedBBoxes, ~] = combineOverlappingBoxes(combinedBBoxes, 0);
    
    %remove boxes which take only a fraction of the total area.
    areas = combinedBBoxes(:,3).*combinedBBoxes(:,4);
    totalArea = sum(areas);
    areaRatio = areas/totalArea;
    combinedBBoxes((areaRatio<areaRatioThreshold),:)=[];
    
    mainImage = p.strokeImage;
    layoutStruct = struct('Image',mainImage,...
                          'NumberOfRows',[],...
                          'NumberOfWords',[],...
                          'AoiBoxes',combinedBBoxes,...
                          'AoiStruct',[],...
                          'PreprocessingTime',preprocessingTime,...
                          'LayoutAnalysisTime',[]);
    
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
        subImage = imcrop(mainImage, bbox);
        aoiImage = subImage;
        
        %extracting properties from the area of interest
        %average area might be useful in line/word detection?
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
            wordAmount = wordAmount + size(wordBoxStruct,1);
            rowStruct(jj).WordBoxes = transpose(reshape([wordBoxStruct.BoundingBox],4,[]));
        end
        aoiStruct(ii).RowStruct = rowStruct;
    end
    layoutAnalysisTime = toc;
    layoutStruct.AoiStruct = aoiStruct;
    layoutStruct.NumberOfRows = rowBoxesLength;
    layoutStruct.NumberOfWords = wordAmount;
    layoutStruct.LayoutAnalysisTime = layoutAnalysisTime;

%     disp(['Number of the areas of interest: ', int2str(aois)]);
%     disp(['Number of rows: ', int2str(rowBoxesLength)]);
%     disp(['Number of wordss: ', int2str(wordAmount)]);
