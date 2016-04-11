function  [accumulatorArray,thetas,rhos,voterCoordCell,voterNumberCell] =...
    houghTransform(image,thetas,rhoResolution)
    %flippedImage = flipud(image);

    [imgWidth,imgHeight] = size(image);
    [xIndices,yIndices] = find(image);
    %[fxIndices,fyIndices] = find(flippedImage);
    
    rhoLimit = sqrt(imgHeight^2+imgWidth^2);
    rhos = -rhoLimit:rhoResolution:rhoLimit;
    
    numThetas = numel(thetas);
    numRhos = numel(rhos);
    accumulatorArray = zeros(numRhos,numThetas);
    voterCoordCell = cell(numRhos,numThetas);
    voterNumberCell = voterCoordCell;
    for ii = 1:length(xIndices)
        for jj = 1:numThetas
            t = thetas(jj);
            t = deg2rad(t);
            r = xIndices(ii)*cos(t)+yIndices(ii)*sin(t);
            %discretizing
            tBin = round((thetas(jj)-min(thetas))/((max(thetas)-min(thetas))/(numThetas-1)))+1;
            rBin = round((r-min(rhos))/((max(rhos)-min(rhos))/(numRhos-1)))+1;
            
            oldCoords = voterCoordCell{rBin,tBin};
            voterCoordCell{rBin,tBin} = [oldCoords ;[xIndices(ii), yIndices(ii)]];
            
            oldNumbers = voterNumberCell{rBin,tBin};
            voterNumberCell{rBin,tBin} = [oldNumbers ;image(xIndices(ii), yIndices(ii))];
            accumulatorArray(rBin,tBin) = accumulatorArray(rBin,tBin)+1;
        end
    end
end