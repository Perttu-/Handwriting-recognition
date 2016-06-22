function [newLineLabels, finalLineAmount] = detectLines(binarizedImage,...
                                                        n1,...
                                                        n2,...
                                                        voterMargin,...
                                                        skewDevLim,...
                                                        aroundAvgDistMargin,...
                                                        sameLineMargin,...
                                                        verbose,...
                                                        visualization)
%Implementation based on papers  
%"Line And Word Segmentation of Handwritten Documents (2009)" and
%"A Block-Based Hough Transform Mapping for Text Line Detection in 
%Handwritten Documents" (2006)
%by Louloudis et.al.

%% Functionality
% Input: Binarized image containing preferably only textual components
% with as little noise as possible.
% Output: Image which has different labels for each text line. The unique
% label used is each rows centroid Y location.


%% Constraints:
%--Input image must be single column text
%--Input image must have horizontal text lines.
%--Margin values must be defined when generating new lines from objects that 
%  weren't assigned to any line with hough transform method.
%--If two lines are too close to each other and their lines cross they
%  might be falsefully merged as one.

%% Proposed values for constant variables and explanations
%Required Hough block contribution to detect line.
%n1 = 5; 
%n1 = 1;

%Excessive skew constraint is applied if (Hough)contribution is less than n2 
%n2 = 9;
%n2 = 5;

%Margin determines how close the undetected lines must be to the detected
%lines to be assigned correctly.
%margin = 0.25;
%margin = 0.40;

%Voter margin is used to find nearby elements from Hough accumulator array.
%voterMargin = 4;

%A text line is valid only if the corresponding skew angle of the line 
%deviates from the dominant skew angle less
%than skewAngleDevLim (louloudis et al used 2 degrees)
%skewDevLim = 5;

%For object that is not assigned to any line with Hough transform mapping.
%This parameter determines how close the distance of has to be to the 
%average distance so it can be candidate to a new line.
%aroundAvgDistMargin = 0.9;
%aroundAvgDistMargin = 0.7;

%This parameter determines if the unassigned object can be assigned to a
%already existing line.
%sameLineMargin = 0.5;


%% pre-procesing
    totalTimeStart = tic;
    [imgHeight,imgWidth]=size(binarizedImage);
    labels = bwlabel(binarizedImage,8);
    boxes = regionprops(logical(labels), 'BoundingBox','Image');
    numberOfAllObjects = size(boxes,1);
    boxList = reshape([boxes.BoundingBox],4,[])';
    
    %Categorizing the connected components into three subsets. 
    %Here the notation is mostly similar to the paper.
    AH = mean(boxList(:,4));
    AW = AH;
    subset1=struct('BoundingBox',{},...
                   'Image',{},...
                   'Index',{},...
                   'PieceBoxCell',{},...
                   'PiecesAmount',{});
               
    subset2=struct('BoundingBox',{},...
                   'Image',{},...
                   'Index',{},...
                   'IntersectingLines',{},...
                   'AvgYIntersect',{});
               
    subset3=struct('BoundingBox',{},...
                   'Image',{},...
                   'Index',{});
    indx1=1;
    indx2=1;
    indx3=1;
    
    for ii=1:numberOfAllObjects
        box = boxes(ii).BoundingBox;
        H = box(:,4);
        W = box(:,3);
        componentImage = boxes(ii).Image;
        componentImage = componentImage+0;
        componentImage(componentImage==1)=ii;
        [~,~,ccIndex] = find(componentImage,1);
        
        if (0.5 * AH <= H) && (H < 3*AH) && (0.5 * AW <= W)
            subset1(indx1).BoundingBox = box;
            subset1(indx1).Image = componentImage;
            subset1(indx1).Index = ccIndex;
            indx1 = indx1+1;
        end
        
        if (H >= 3 * AH)
            subset2(indx2).BoundingBox = box;
            subset2(indx2).Image = componentImage;
            subset2(indx2).Index = ccIndex;
            indx2 = indx2+1;
        end
        
        if (((H < 3 * AH) && (0.5 * AW > W) || ((H < 0.5 * AH) && (0.5 * AW < W))))
            subset3(indx3).BoundingBox = box;
            subset3(indx3).Image = componentImage;
            subset3(indx3).Index = ccIndex;
            indx3 = indx3+1;
        end
    end

    %Partition subset1 to equally sized boxes and extracting centroid pixels
    centroidImg = zeros(imgHeight,imgWidth);

    for ii = 1:length(subset1)
        box = subset1(ii).BoundingBox;
        componentImage = subset1(ii).Image;
        boxWidth = box(3);
        xSplit = 0;
        piecesAmount = ceil(boxWidth/AW);
        relBoxes=cell(piecesAmount,1);
        subset1(ii).PiecesAmount = piecesAmount;
        
        for jj = 1:piecesAmount 
            if xSplit+AW <= boxWidth
                newBox = [xSplit,0,AW,box(4)];
                xSplit=xSplit+AW;
            else
                lastXWidth = mod(boxWidth,AW);
                xSplit = boxWidth-lastXWidth;
                newBox = [xSplit,0,lastXWidth,box(4)];
            end
            
            cropped = imcrop(componentImage, newBox);
            binCropped = logical(cropped);
            centroidSt = regionprops(uint8(binCropped), 'Centroid');
            centroid = centroidSt.Centroid;

            relationalBox = [newBox(1)+box(1),...
                             newBox(2)+box(2),...
                             newBox(3),...
                             newBox(4)];
            relBoxes{jj,:}=relationalBox;
            relationalCentroid = [centroid(1)+newBox(1)+box(1)-0.5,...
                                  centroid(2)+newBox(2)+box(2)-0.5];
            roundedCentroid = round(relationalCentroid);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=subset1(ii).Index;
        end
        subset1(ii).PieceBoxCell = relBoxes;
    end
    
%% Hough transform mapping
    tic
    thetas = 85:95;
    [rhos,accumulatorArray,voterArray] = houghTransform(centroidImg,thetas,0.2*AH);
    if verbose
        disp(['Hough Transform done in ', num2str(toc), ' seconds']);
    end
    
%% Finding lines with Hough transform
    tic
    lineStruct = struct('Contribution',{},...
                        'SkewAngle',{},...
                        'CentroidY',{},...
                        'CentroidX',{},...
                        'Theta',{},...
                        'Rho',{});
    
    lineIndex = 1;
    lineLabels = zeros(imgHeight,imgWidth);
    
    %This loop detects peaks from Hough accumulator array, assigns lines
    %and removes values assigned to line until no peaks high enough remain.
    %Additionally skew is monitored.
    objsAssignedToLine = zeros(1,max(max(accumulatorArray)));
    cellTic = tic;
    
    while 1
        maxValue = max(max(accumulatorArray));
        if maxValue < n1
            break
        end
        
        [maxIRow, maxICol] = find(accumulatorArray==maxValue,1);

        voterNumbers = [];
        %maxValue
        for ii = 1:size(voterArray,3)
            currentPage = voterArray(:,:,ii);
            currentPageNearVoters = currentPage(maxIRow-voterMargin:maxIRow+voterMargin,maxICol);
            voterNumbers = [voterNumbers; currentPageNearVoters(currentPageNearVoters~=0)];
        end
        
        uniqueVoters = unique(voterNumbers)';
        pieceAmounts = [subset1.PiecesAmount];
        pieceAmounts(~ismember([subset1.Index],uniqueVoters))=[];
        occurences = histcounts(voterNumbers,'BinMethod','Integers');
        occurences(occurences==0)=[];
        objsInLine = uniqueVoters(occurences >= 0.5*pieceAmounts);
        if isempty(objsInLine)
            break
        end
        
        tempImg = ismember(labels,objsInLine);
        prop = regionprops(double(tempImg),'Centroid','Orientation');
        centroid = prop.Centroid;
        lineLabels(ismember(labels,objsInLine))=centroid(2);
        %Here orientation i.e. skew angle is not same as the theta.
        %The orientation takes whole objects into account whereas Hough
        %line uses the centroids of splitted components. It's a small
        %difference.

        objsAssignedToLine = [objsAssignedToLine,objsInLine];
        lineStruct(lineIndex).Contribution = maxValue;
        lineStruct(lineIndex).SkewAngle = prop.Orientation;
        lineStruct(lineIndex).CentroidY = prop.Centroid(2);
        lineStruct(lineIndex).CentroidX = prop.Centroid(1);
        lineStruct(lineIndex).Theta = thetas(maxICol);
        lineStruct(lineIndex).Rho = rhos(maxIRow);

        lineIndex = lineIndex+1;

        for obj = objsInLine
            toRemoval  = voterArray==obj;
            voterArray = voterArray.*double(~toRemoval);
            accumulatorArray = accumulatorArray-sum(toRemoval,3);
        end
        

    end
    
    if verbose
        disp(['hough cell processing time ',num2str(toc(cellTic))]);
    end
    
    if isempty(lineStruct)
        disp('No lines found!');
        newLineLabels = -1;
        finalLineAmount = 0;
        return
    end
    %Additional constraint is applied to remove lines with excessive skew.
    domSkewAngle = abs(mean([lineStruct.SkewAngle]));
    lineStruct([lineStruct.Contribution]<n2 &...
               (abs([lineStruct.SkewAngle])-domSkewAngle)>skewDevLim)=[];
    lineLabels(~ismember(labels, objsAssignedToLine))=0;
    
    if verbose
        disp(['Initial line detection done in ', num2str(toc), ' seconds']);
    end
    
    lineStruct = rmfield(lineStruct, 'Contribution');
    
    %% Post-processing
    %% Merge crossing lines into one line if they are close
    tic
    numOfLines = length(lineStruct);
    lineEndPoints  = zeros(numOfLines,2);
    xLimits = [0,imgWidth];
    yLimits = [0,imgHeight];
    
    for ii = 1:numOfLines
        theta = lineStruct(ii).Theta;
        rho = lineStruct(ii).Rho;
        ys = (rho-xLimits.*cosd(theta))/sind(theta);
        outIndxY = 0>ys | ys>imgHeight;
        ys(outIndxY)=yLimits(outIndxY);
        xs = (rho-yLimits.*sind(theta))/cosd(theta);
        outIndxX = 0>xs | xs>imgHeight;
        xs(outIndxX)=xLimits(outIndxX);
        lineEndPoints(ii,1) = xs(1);
        lineEndPoints(ii,2) = ys(1);
        lineEndPoints(ii,3) = xs(2);
        lineEndPoints(ii,4) = ys(2);
    end
    
    lineStruct = rmfield(lineStruct,{'Theta', 'Rho'});
    
    %Intersecting lines
    intersection = lineSegmentIntersect(lineEndPoints,lineEndPoints);
    [cLine1Id,cLine2Id]=find(tril(intersection.intAdjacencyMatrix));
    cLine1CentY = [lineStruct(cLine1Id).CentroidY];
    cLine2CentY = [lineStruct(cLine2Id).CentroidY];
    %Draw vertical line to the middle of image
    midX = imgWidth/2;
    centerLineX = [midX,midX];
    centerLineY = [0,imgHeight];
    
    %Check if crossing lines have smaller than average distance at the
    %center of image and merge them if so. 
    centerLine = [centerLineX(1),centerLineY(1),centerLineX(2),centerLineY(2)];
    middleIntersection = lineSegmentIntersect(lineEndPoints,centerLine);
    yIntersects = middleIntersection.intMatrixY;
    avgDistance = mean(abs(diff(sort(yIntersects))));
    newIndex = 1;
    for ii=1:length(cLine1CentY)
        lineStructCentYs = [lineStruct.CentroidY];
        firstLineId = find(lineStructCentYs==cLine1CentY(ii));
        secondLineId = find(lineStructCentYs==cLine2CentY(ii));
        %firstLine = cLine1Id(ii);
        %here is something wrong ii==2 second image in test
        %firstLineCentY = lineStruct(firstLine).CentroidY;
        %secondLine = cLine2Id(ii);
        %secondLineCentY = lineStruct(secondLine).CentroidY;
        firstLineCentY = cLine1CentY(ii); 
        secondLineCentY = cLine2CentY(ii);
        crossLine1Y = yIntersects(firstLineId);
        crossLine2Y = yIntersects(secondLineId);
        distance = abs(crossLine1Y-crossLine2Y);
        
        if distance<avgDistance
            %Merging removes the lines from lineStruct and adds new line
            %with new centroid location.
            newRowImg = ismember(lineLabels,[firstLineCentY,secondLineCentY]);
            prop = regionprops(double(newRowImg),'Orientation','Centroid');
            newCentroid = [prop.Centroid];
            lineLabels(newRowImg)=newCentroid(2);
            lineStruct([firstLineId,secondLineId])=[];
            lineStruct(newIndex).SkewAngle = prop.Orientation;
            lineStruct(newIndex).CentroidY = newCentroid(2);
            lineStruct(newIndex).CentroidX = newCentroid(1);
        end
    end
    
    if verbose
        disp(['Line merging done in ', num2str(toc), ' seconds'])
    end
    
    %% Generate new lines from CCs that werent assigned to any line
    %Constant variable 'sameLineMargin' adjusts how near the previously 
    %undetected objects must be to already existing line to be categorized 
    %into that.
    %Constant variable 'aroundAvgDistMargin' is used to determine how far 
    %away the object must be from other lines to be categorized as a new 
    %line.

    tic
    ccsInLines = unique(labels(lineLabels~=0));
    subset1CCs = [subset1.Index];
    ccsNotInLine = subset1CCs(~ismember(subset1CCs,ccsInLines));
    foundLineCentYs = [lineStruct.CentroidY];
    
    if ccsNotInLine
        [pYs,~,val]=find(centroidImg.*ismember(centroidImg,ccsNotInLine));

        candLineStruct = struct('YLoc',{},...
                                'Indices',{},...
                                'OldLine',{});

        newIndex = 1;
        for ii = 1:size(pYs,1)
            pY = pYs(ii);
            newComponentId = val(ii);
            [~,minIdx]=min(abs(foundLineCentYs-pY));
            closestLineY = foundLineCentYs(minIdx);
            distance = abs(pY-closestLineY);
            oldYLocs = [candLineStruct.YLoc];
            [oldMinDist,oldMinIdx]=min(abs(oldYLocs-pY));
            
            if distance > aroundAvgDistMargin*avgDistance
                oldLine = 0;
            else
                oldLine = 1;
            end
            
            if oldMinDist < sameLineMargin*avgDistance+avgDistance
                    index = oldMinIdx;
                    oldIndices = [candLineStruct(oldMinIdx).Indices];
                    addedIndices  = [oldIndices,newComponentId];
            else
                    index = newIndex;
                    newIndex = newIndex+1;
                    addedIndices = newComponentId;
            end
            
            candLineStruct(index).Indices = addedIndices;
            candLineStruct(index).YLoc = pY;
            candLineStruct(index).OldLine = oldLine;
        end
        
        %Categorizing newly found lines into the label image
        lineStructIndex = size(lineStruct,2)+1;
        for ii = 1:size(candLineStruct,2)
            yLoc = candLineStruct(ii).YLoc;
            indices = [candLineStruct(ii).Indices];
            if candLineStruct(ii).OldLine == 1
                centroidYs = [lineStruct.CentroidY];
                [~,minIdx]=min(abs(centroidYs-yLoc));
                newLabel = centroidYs(minIdx);
            else
                piecesInArea = histcounts(indices,'BinMethod','Integers');
                piecesInArea(piecesInArea==0)=[];
                subset1Indx = [subset1.Index];
                subset1Pieces = [subset1.PiecesAmount];
                indices(piecesInArea<(0.5*subset1Pieces(ismember(subset1Indx,indices))))=[];
                if ~isempty(indices)
                    tmpImg = ismember(labels,indices);
                    props = regionprops(double(tmpImg),'Centroid','Orientation');
                    newLabel = props.Centroid(2);
                    lineStruct(lineStructIndex).CentroidY = props.Centroid(2);
                    lineStruct(lineStructIndex).CentroidX = props.Centroid(1);
                    lineStruct(lineStructIndex).SkewAngle = props.Orientation;
                end
            end
            lineLabels(ismember(labels,indices))=newLabel;
        end
        if verbose
            disp(['Detecting previously undetected lines done in ', num2str(toc), ' seconds']);
        end
    end
    
    finalLineAmount  = length(lineStruct);
    if verbose
        disp(['Final amount of text lines: ', num2str(finalLineAmount)]);
    end
    %% Categorize subset 3 values to the closest line
    %The subset3 objects are removed if they are further than average
    %distance from nearest line.
    tic
    centroidYs = [lineStruct.CentroidY];
    for ii = 1:length(subset3)
        sub3BBox = subset3(ii).BoundingBox;
        yloc = sub3BBox(2)+(sub3BBox(4)/2);
        [minDistance,closestLineIndex] = min(abs(centroidYs-yloc));
        if minDistance < avgDistance
            lineLabels(labels==subset3(ii).Index)=centroidYs(closestLineIndex);
        else
            lineLabels(labels==subset3(ii).Index)=0;
        end
    end
    
    if verbose
        disp(['Processing subset3 done in ', num2str(toc), ' seconds']);
    end
    
    %% Subset2 Processing
    if ~isempty(subset2)
        tic
        flagImageStruct = struct('Image',[],...
                                 'BoundingBox',[]);
        for ii = 1:size(subset2,2)
            %find which lines intersect this box and the average height for the
            %intersections.
            bbox = [subset2(ii).BoundingBox];
            flagImageStruct(ii).BoundingBox = bbox;
            [ul,ur,ll,lr] = extractBoxCornerCoords(bbox);

            boxSidesArray = [ul(1),ul(2),ur(1),ur(2);...
                             ll(1),ll(2),lr(1),lr(2);...
                             ul(1),ul(2),ll(1),ll(2);...
                             ur(1),ur(2),lr(1),lr(2)];

            intersection = lineSegmentIntersect(boxSidesArray,lineEndPoints);
            intersectYs = [intersection.intMatrixY];
            intersectYs(isnan(intersectYs))=0;
            [~,interC,interVal] = find(intersectYs);
            intersectingLines = unique(interC);
            interLinesAmount = length(intersectingLines);
            avgYIntersect = zeros(interLinesAmount,1);

            for jj = 1:interLinesAmount
                avgYIntersect(jj)=mean(interVal(interC==intersectingLines(jj)));
            end
            
            intersectionArray = [intersectingLines,avgYIntersect];
            
            if interLinesAmount>1
                sortedIntersectArr = sortrows(intersectionArray,2);
                relAvgYIntersect = sortedIntersectArr(:,2)-ul(2);
                %Checking if only a fraction of the CC is under the
                %specified line. The line is higher from lowest line by a
                %tenth of the distance between lowest and second-lowest
                %line.
                yLowest = relAvgYIntersect(end);
                y2ndLowest = relAvgYIntersect(end-1);
                roundedY2ndLowest = round(y2ndLowest);
                if roundedY2ndLowest==0;
                   roundedY2ndLowest = 1;
                end
                processedImage = logical(subset2(ii).Image);

                below2ndLowLineSum = sum(sum(processedImage(roundedY2ndLowest:end,:)));
                tenthHigherY = yLowest-((yLowest-y2ndLowest)/10);
                belowTenthHigherLineSum = sum(sum(processedImage(round(tenthHigherY):end,:)));

                if belowTenthHigherLineSum/below2ndLowLineSum <= 0.08;
                    relAvgYIntersect(relAvgYIntersect==yLowest)=[];
                end
                
                finalFlagImage = double(processedImage);
                
                for jj = 1:size(relAvgYIntersect,1)-1
                    yi = relAvgYIntersect(jj);
                    yip1 = relAvgYIntersect(jj+1);
                    zoneHiLim = yi+(yip1-yi)/2;
                    binSkeletonImg = bwmorph(processedImage,'skel',Inf);
                    flagSkeletonImg = double(binSkeletonImg);
                    branchPoints = bwmorph(binSkeletonImg,'branchpoints');
                    
                    if sum(sum(branchPoints))>0
                        %selecting only area in the zone
                        zoneBranchPoints = branchPoints;
                        zoneBranchPoints(1:round(zoneHiLim),:)=0;
                        zoneBranchPoints(round(yip1):end,:)=0;
                        %remove also 3x3 neighbour of these junction pixels
                        zoneBranchPoints = imdilate(zoneBranchPoints,[1,1,1;1,1,1;1,1,1]);
                        flagSkeletonImg = binSkeletonImg~=(binSkeletonImg&zoneBranchPoints);
                    else
                        %If no junction points exist in zone, remove skeleton 
                        %points in the center of the zone.
                        centerRowY = round((zoneHiLim+yip1)/2);
                        flagSkeletonImg(centerRowY,:)=0;
                    end
                    roundedYi = round(yi);
                    if roundedYi==0;
                        roundedYi = 1;
                    end
                    skeletonLabels = bwlabel(flagSkeletonImg,8);
                    yiInter = skeletonLabels(roundedYi,:);
                    interCCs = unique(yiInter(yiInter~=0));
                    flag1Img = ismember(skeletonLabels,interCCs);
                    flag2Img = ~ismember(skeletonLabels,interCCs)&skeletonLabels~=0;
                    flagSkeletonImg = double(flagSkeletonImg);
                    flagSkeletonImg(logical(flagSkeletonImg)&flag1Img)=1;
                    flagSkeletonImg(logical(flagSkeletonImg)&flag2Img)=2;
                    %Assign the value of nearest skeleton pixel to each
                    %pixel in subset2 image
                    tmpSub2Image = logical(processedImage);
                    tmpSub2Image(tmpSub2Image==1)=0;
                    tmpSub2Image= tmpSub2Image+flagSkeletonImg;
                    [~,nearest] = bwdist(tmpSub2Image);
                    finalNearest = double(nearest).*(logical(nearest)&logical(processedImage));
                    nearestIdx=find(finalNearest);
                    flaggedImage = double(processedImage);
                    
                    for k = 1:length(nearestIdx)
                        nearestSkelLoc = nearestIdx(k);
                        newSkelFlag = flagSkeletonImg(nearestSkelLoc);
                        flaggedImage(finalNearest==nearestSkelLoc)=newSkelFlag;
                    end
                    
                    %Excluding previously found part from further processing.
                    processedImage = flaggedImage>1;
                    finalFlagImage = (finalFlagImage+(flaggedImage==2));
                    
                end
                flagImageStruct(ii).Image = finalFlagImage;
            else
                %If only one line intersects the object we don't need to
                %split it.
                flagImageStruct(ii).Image = double(subset2(ii).Image>0);
            end
        end
        %Assign these new components to correct lines.
        for ii = 1:length(flagImageStruct)
            flagImage = flagImageStruct(ii).Image;
            bbox = round(flagImageStruct(ii).BoundingBox);
            upperYLoc = bbox(2);
            prop = regionprops(flagImage,'Centroid');
            for jj = 1:length(prop)
                centroidY = prop(jj).Centroid(2);
                componentImage = flagImage==jj;
                componentYLoc = centroidY+upperYLoc;
                [~,closestLineIndex] = min(abs(foundLineCentYs-componentYLoc));
                newIndex = centroidYs(closestLineIndex);
                newComp = componentImage*newIndex;
                lineLabels(bbox(2):bbox(2)+bbox(4)-1,bbox(1):bbox(1)+bbox(3)-1)=...
                lineLabels(bbox(2):bbox(2)+bbox(4)-1,bbox(1):bbox(1)+bbox(3)-1)+newComp;
            end
        end
        
        if verbose
            disp(['Processing subset2 done in ', num2str(toc), ' seconds']);
        end
        
    end
    
    %Applying more intuitive labels to text lines
    centroidYs = [lineStruct.CentroidY];    
    [~,topDownOrder] = sort(centroidYs,'ascend');
    newLineLabels = zeros(imgHeight,imgWidth);
    
    for ii = 1:length(topDownOrder)
        oldLabel = centroidYs(topDownOrder(ii));
        newLineLabels(lineLabels==oldLabel)=ii;
    end
    
    if verbose
        disp('----------------------------------------');
        disp(['Total line detection time ', num2str(toc(totalTimeStart)), ' seconds']);
        disp('----------------------------------------');
    end

    %% Visualization
    
    % Line intersections with subset2 boxes
%     figure(), imshow(binarizedImage);
%     hold on;
%     for ii = 1:length(subset2)
%         line([ul(ii,1),ur(ii,1)],[ul(ii,2),ur(ii,2)]);
%         line([ll(ii,1),lr(ii,1)],[ll(ii,2),lr(ii,2)]);
%         line([ul(ii,1),ll(ii,1)],[ul(ii,2),ll(ii,2)]);
%         line([ur(ii,1),lr(ii,1)],[ur(ii,2),lr(ii,2)]);
%     end
%     scatter(intersection.intMatrixX(:),intersection.intMatrixY(:),[],'xr');

    %Subset1 splitted components centroids
%     [r,c] = find(centroidImg);
%     plot(c,r,'mo');

    if visualization
        %Subset boxes 
        figure(),imshow(binarizedImage);
        title('Subsets Visualized');
        for ii = 1:length(subset1)
            pboxes = cell2mat(subset1(ii).PieceBoxCell);
            visualizeMoreBoxes(pboxes,'y',1);
        end
        visualizeMoreBoxes(subset2,'c',1);
        visualizeMoreBoxes(subset3,'m',1);
        hold off;
        drawnow;
        
        %Hough accumulator array
%         figure(),
%         imshow(imadjust(mat2gray(accArr)),'XData',thetas,'YData',rhos,...
%            'InitialMagnification','fit');
%         title('Hough Transform Accumulator Array');
%         xlabel('\theta'), ylabel('\rho');
%         axis on, axis normal;
%         colormap(hot);
%         drawnow;
        
        %Components assigned to line
        %figure(), imshow(ismember(labels,ccsNotInLine).*labels);
        %figure(), imshow(~ismember(labels,ccsNotInLine).*labels);
        
        %Final text lines
        figure(),imagesc(newLineLabels);
        title('Final Text Lines');
        editedCm = prism;
        editedCm(1,:)=[0,0,0];
        colormap(editedCm);
        axis equal;
        axis tight;
        
        hold on;
        for ii = 1:length(lineStruct)
            orientation = lineStruct(ii).SkewAngle;
            centroid = [lineStruct(ii).CentroidX,lineStruct(ii).CentroidY];
            ysrt=centroid(2)+centroid(1)*tand(orientation);
            fplot(@(x) tand(-orientation)*x+ysrt,...
                 'LineWidth',1,...
                 'LineStyle',':',...
                 'Color','w');
        end
    end
end