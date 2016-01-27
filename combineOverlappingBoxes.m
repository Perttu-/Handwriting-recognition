function [newBoxes, overlapRatios] = combineOverlappingBoxes(oldBoxes, overlapThreshold)
    %combining all overlapping "bounding"boxes
    %box input in bounding box format 
    %[ul_corner, ll_corner, width, height]
    
    [xmins,ymins,xmaxs,ymaxs] = extractBoxCorners(oldBoxes);

    overlapRatios = bboxOverlapRatio(oldBoxes,oldBoxes,'Min');
    width = size(overlapRatios,1);
    overlapRatios(1:width+1:width^2) = 0;
    
    overlapRatios = overlapRatios>overlapThreshold;
    
    g = graph(overlapRatios); 
    componentIndices = conncomp(g);

    xmins = accumarray(componentIndices', xmins, [], @min);
    ymins = accumarray(componentIndices', ymins, [], @min);
    xmaxs = accumarray(componentIndices', xmaxs, [], @max);
    ymaxs = accumarray(componentIndices', ymaxs, [], @max);

    newBoxes = [xmins ymins xmaxs-xmins+1 ymaxs-ymins+1];
    
end