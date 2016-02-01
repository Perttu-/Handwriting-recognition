function [xmins,ymins,xmaxs,ymaxs] = extractBoxCorners(boundingBox)
    %extracts the real coordinates from bounding box
    xmins = boundingBox(:,1);
    ymins = boundingBox(:,2);
    xmaxs = xmins + boundingBox(:,3) - 1;
    ymaxs = ymins + boundingBox(:,4) - 1;
end