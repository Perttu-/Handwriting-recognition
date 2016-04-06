function aoiStruct = preprocess(path,testedValue)
%% Initialization
    close all;
    [image, map]=imread(path);
    
    %IAM database
    
    %wienerFilterSize = 15;
    %wiener filter can cause some disortion
    wienerFilterSize = -1;
    sauvolaNeighbourhoodSize = 180;
    sauvolaThreshold = 0.3;
    morphClosingDiscSize = -1;
    strokeWidthThreshold = 0.6;
    skewCorrection = 0;
    aoiXExpansionAmount = 40;
    aoiYExpansionAmount = 60;
    areaRatioThreshold = 0.004;
    rlsaRowThreshold = 300;
    rlsaWordThreshold = 30;

    
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
    
    
    
    disp('Preprocessing...');
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
    toc;
    tic;
    boxes = louloudis(preprocessedImage);
    toc;
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

