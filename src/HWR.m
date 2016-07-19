function [lineAmount,preprocessingTime,rowDetectionTime] = HWR(path,testedN1Value,testedVmValue,verbose)
%% Initialization
    close all;
    [image, map]=imread(path);
    
    rowVerbose = verbose;
    visualization = verbose;
    
%% Constraints
    %replace with testedValue
    %IAM database
    
    %pre-processing
    wienerFilterSize = 3;
    sauvolaNeighbourhoodSize = 40;   
    sauvolaThreshold = 0.5;
    morphClosingDiscSize = -1;
    strokeWidthThreshold = 0.4;
    skewCorrection = 0;
    
    %Row detection
    %n1 = 6;
    n1 = testedN1Value;
    n2 = 9;
    %voterMargin = 7;
    voterMargin = testedVmValue;
    skewDevLim = 7;
    aroundAvgDistMargin = 0.7;
    sameLineMargin = 0.5;


    
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
                                      
%     rlsaImage = rlsa(preprocessedImage,testedValue,1);  
%     [~,lineAmount] = bwlabel(rlsaImage);
                                      
    rowDetectionTime = toc(rowDetectionStartTime);
    if verbose
        disp(['Found ',num2str(lineAmount),' lines in ', num2str(rowDetectionTime), ' seconds']);
    end
