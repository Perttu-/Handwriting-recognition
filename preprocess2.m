function preprocess2(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;
    
    %optimal values
    p.wienerFilterSize = 6;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphOpeningLowThreshold = -1;
    p.morphOpeningHighThreshold = -1;
    p.morphClosingDiscSize = -1;
    
    tic
    p.preprocess;
    toc
    
    finalImage = p.finalImage;
    skeletonImage = p.skeletonImage;
    
    disp(['Number of objects: ', int2str(p.objectCount)]);
    [D, IDX] = bwdist(~finalImage);
    D;
    imshow(IDX);
    

