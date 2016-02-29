function largeBBoxes=expandBBoxes(image,boundingBoxes,xExpansionAmount,yExpansionAmount)    
    xmins = zeros(length(boundingBoxes),1);
    xmaxs = xmins;
    ymins = xmins;
    ymaxs = xmins;
    
    for ii=1:length(boundingBoxes)
        %getting corner points
        [xmin,ymin,xmax,ymax] = extractBoxCorners(boundingBoxes(ii).BoundingBox);

        %widening and...
        xmin = xmin-xExpansionAmount;
        xmax = xmax+xExpansionAmount; 
        
        %...heightening the boxes
        ymin = ymin-yExpansionAmount;
        ymax = ymax+yExpansionAmount;
        
        %cropping the boxes to fit image.
        xmin = max(xmin, 0.5);
        ymin = max(ymin, 0.5);
        xmax = min(xmax, size(image,2)-0.5);
        ymax = min(ymax, size(image,1)-0.5);
       
        xmins(ii) = xmin;
        ymins(ii) = ymin;
        xmaxs(ii) = xmax;
        ymaxs(ii) = ymax;
        
        largeBBoxes = [xmins ymins xmaxs-xmins+1 ymaxs-ymins+1];
        
    end