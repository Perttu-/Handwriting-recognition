function rlsaImage = rlsa(image,rlsaThreshold,vertical)
    %run length smearing/smoothing algorithm
    [xSize, ySize] = size(image);
    if vertical==1
    temp = [ones(xSize,1), image, ones(xSize,1)];
    temp = reshape(temp',1,[]);
    else
        temp = [ones(1,ySize); image; ones(1,ySize)];
        temp = reshape(temp,1,[]);
    end
    differences = diff(temp);
    startPoints = find(differences==-1);
    endPoints = find(differences==1);
    lengths = endPoints-startPoints;
    marked = lengths <= rlsaThreshold;
    differences(startPoints(marked)) = 0;
    differences(endPoints(marked)) = 0;
    yy = cumsum([1 differences]);
    if vertical == 1
        yy = reshape(yy, [], xSize)';
        rlsaImage = logical(yy(:,2:end-1));
    else
        yy = reshape(yy,[],ySize);
        rlsaImage = logical(yy(2:end-1,:));
    end
    
end