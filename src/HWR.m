function [lineLabels,lineAmount,preprocessingTime,rowDetectionTime] = HWR(path,testedValue,verbose)
%% Initialization
    close all;
    [image, map]=imread(path);
    
    rowVerbose = verbose;
    visualization = verbose;
    
%% Constraints
    %replace with testedValue
    %IAM database
    
    %pre-processing
    wienerFilterSize = 5;
    sauvolaNeighbourhoodSize = 180;
    sauvolaThreshold = 0.6;
    morphClosingDiscSize = -1;
    strokeWidthThreshold = 0.8;
    skewCorrection = 0;
    
    %Row detection
    n1 = 6;
    n2 = testedValue;
    voterMargin = 6;
    skewDevLim = 5;
    aroundAvgDistMargin = 0.7;
    sameLineMargin = 0.5;

%     wiener filter can cause some disortion
%     wienerFilterSize = -1;
%     sauvolaThreshold = 0.3;   
%     strokeWidthThreshold = 0.6; 
%     aoiXExpansionAmount = 40;
%     aoiYExpansionAmount = 60;
%     areaRatioThreshold = 0.004;
%     rlsaRowThreshold = 300;
%     rlsaWordThreshold = 30;

    
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
    
%% Preprocessing
    preprocessingStartTime = tic;
    p = preprocessor(image,...
                     map,...
                     wienerFilterSize,...
                     sauvolaNeighbourhoodSize,...
                     sauvolaThreshold,...
                     skewCorrection,...
                     morphClosingDiscSize,...
                     strokeWidthThreshold);
    
    preprocessedImage = p.preprocess;
    preprocessingTime = toc(preprocessingStartTime);
    if verbose
        disp(['Pre processing done in ', num2str(preprocessingTime), ' seconds']);
    end
    
%% Layout Analysis
    rowDetectionStartTime = tic;

    [lineLabels,lineAmount] = detectLines(preprocessedImage,...
                                          n1,...
                                          n2,...
                                          voterMargin,...
                                          skewDevLim,...
                                          aroundAvgDistMargin,...
                                          sameLineMargin,...
                                          rowVerbose,...
                                          visualization);
                                      
    rowDetectionTime = toc(rowDetectionStartTime);
    if verbose
        disp(['Found ',num2str(lineAmount),' lines in ', num2str(rowDetectionTime), ' seconds']);
    end
