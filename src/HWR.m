function HWR(path,testedValue)
%% Initialization
    close all;
    [image, map]=imread(path);
    
%% Constraints
    %IAM database
    wienerFilterSize = 5;
    %wiener filter can cause some disortion
    %wienerFilterSize = -1;
    sauvolaNeighbourhoodSize = 180;
    %sauvolaThreshold = 0.3;
    sauvolaThreshold = 0.6;
    morphClosingDiscSize = -1;
    strokeWidthThreshold = 0.8;
    %strokeWidthThreshold = 0.6;
    skewCorrection = 0;
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
    tic;
    p = preprocessor(image,...
                     map,...
                     wienerFilterSize,...
                     sauvolaNeighbourhoodSize,...
                     sauvolaThreshold,...
                     skewCorrection,...
                     morphClosingDiscSize,...
                     strokeWidthThreshold);
    
    preprocessedImage = p.preprocess;
    disp(['Pre processing done in ', num2str(toc), ' seconds']);
    
%% Layout Analysis
    tic;
    n1 = 5;
    %n2 = 9;
    n2 = 5;
    voterMargin = 4;
    skewDevLim = 5;
    aroundAvgDistMargin = 0.7;
    sameLineMargin = 0.5;
    lineLabels = detectLines(preprocessedImage,...
                             n1,...
                             n2,...
                             voterMargin,...
                             skewDevLim,...
                             aroundAvgDistMargin,...
                             sameLineMargin);
                         
    disp(['Line detection done in ', num2str(toc), ' seconds']);

    %Old stuff
%     disp('Layout analysis...');
%     tic
%     l = layoutAnalyzer(preprocessedImage,...
%                        aoiXExpansionAmount,...
%                        aoiYExpansionAmount,...
%                        areaRatioThreshold,...
%                        rlsaRowThreshold ,...
%                        rlsaWordThreshold);
%     
%     aoiStruct = l.analyze;
%     toc
%     
% 	visualizeLayout(p.originalImage, aoiStruct, 3);

