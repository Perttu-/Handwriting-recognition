function  accumulatorArray = houghTransform(image,thetas,rhoResolution)
    image = flipud(image);

    [imgWidth,imgHeight] = size(image);
    
    [xIndices,yIndices] = find(image);
    rhoLimit = sqrt(imgHeight^2+imgWidth^2);
    rhos = -rhoLimit:rhoResolution:rhoLimit;
    
    numThetas = numel(thetas);
    numRhos = numel(rhos);
    accumulatorArray = zeros(numRhos,numThetas);
    voterCell = cell(numRhos,numThetas);
    for ii = 1:length(xIndices)
        for jj = 1:numThetas
            t = thetas(jj);
            t = deg2rad(t);
            r = xIndices(ii)*cos(t)+yIndices(ii)*sin(t);
            %discretizing
            tBin = round((thetas(jj)-min(thetas))/((max(thetas)-min(thetas))/(numThetas-1)))+1;
            rBin = round((r-min(rhos))/((max(rhos)-min(rhos))/(numRhos-1)))+1;
            values = voterCell{rBin,tBin};
            voterCell{rBin,tBin} = [values ;[xIndices(ii), yIndices(ii)]];
            accumulatorArray(rBin,tBin) = accumulatorArray(rBin,tBin)+1;
        end
    end


    figure
    imshow(imadjust(mat2gray(accumulatorArray)),'XData',thetas,'YData',rhos,...
       'InitialMagnification','fit');
    title('Hough Transform own implementation');
    xlabel('\theta'), ylabel('\rho');
    axis on, axis normal;
    colormap(hot)

    %fplot(@(t) xIndices(ii)*cosd(t)+yIndices(ii)*sind(t), [85,95]);
    %fplot(@(t) 1*cosd(t)+1*sind(t),thetas)


end