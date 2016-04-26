function  [rhos,accArr,voterCell] = houghTransform(image,thetas,rhoRes)
    % Customized implementation of Hough Transform for the purpose of block
    % based Hough Transform mapping. Resulting voter cells contain list of
    % all the contributing connected components.
    [imgWidth,imgHeight] = size(image);
    [xIndices,yIndices] = find(image);
    rhoLimit = sqrt(imgHeight^2+imgWidth^2);
    rhos = -rhoLimit:rhoRes:rhoLimit;
    
    numThetas = numel(thetas);
    numRhos = numel(rhos);
    accArr = zeros(numRhos,numThetas);
    voterCell = cell(numRhos,numThetas);
    voterArray = accArr;
    thetas=thetas-90;
    for ii = 1:length(xIndices)
        r = xIndices(ii).*cosd(thetas)+yIndices(ii).*sind(thetas);
        for jj = 1:numThetas
            tBin = round((thetas(jj)-min(thetas))/((max(thetas)-min(thetas))/(numThetas-1)))+1;
            rBin = round((r(jj)-min(rhos))/((max(rhos)-min(rhos))/(numRhos-1)))+1;
            oldNumbers = voterCell{rBin,tBin};
            voterCell{rBin,tBin} = [oldNumbers ;image(xIndices(ii), yIndices(ii))];
            accArr(rBin,tBin) = accArr(rBin,tBin)+1;
        end
    end
end