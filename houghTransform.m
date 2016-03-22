function  houghTransform(image,thetas,rhoResolution)
    image = flipud(image);
    [imgWidth,imgHeight] = size(image);
    
    [xIndices,yIndices] = find(image);
    rhoLimit = sqrt(imgHeight^2+imgWidth^2);
    rhos = -rhoLimit:rhoResolution:rhoLimit;
    accumulatorArray = zeros(numel(rhos),numel(thetas));
    
    for ii=rhos
        
    end
    
    rh = xIndices*cos(thetas)+yIndices*sin(thetas);

end