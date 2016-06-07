function lineLabels = detectLines(binarizedImage,n1,n2,margin)
%Implementation based on papers  
%"Line And Word Segmentation of Handwritten Documents (2009)" and
%"A Block-Based Hough Transform Mapping for Text Line Detection in 
%Handwritten Documents" (2006)
%by Louloudis et.al.

%% Functionality
% Input: Binarized image containing preferably only textual components
% with as little noise as possible.
% Output: Image which has different labels for each text line.


%% Constraints:
%--Input image must be single column text
%--Input image must have horizontal text lines.
%--Margin value must be defined when generating new lines from objects that 
%  weren't assigned to any line with hough transform method.
%--If two lines are too close to each other and their lines cross they are
%  falsefully merged as one.
%--If some subset1 components remain to be classfied to any lines they must
%  be near to the other text lines to be classified correctly otherwise
%  they are left out.

%Required Hough block contribution to detect line.
%n1 = 5; 
%n1 = 1;

%Excessive skew constraint is applied if (Hough)contribution is less than n2 
%n2 = 9;

%Margin determines how close the undetected lines must be to the detected
%lines to be assigned correctly.
%margin = 0.25;
%margin = 0.40;

%% pre-procesing
    [imgHeight,imgWidth]=size(binarizedImage);
    labels = bwlabel(binarizedImage,8);
    boxes = regionprops(logical(labels), 'BoundingBox','Image');
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
    
    for ii=1:length(boxes)
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

            relationalBox = [newBox(1)+box(1),newBox(2)+box(2),newBox(3),newBox(4)];
            relBoxes{jj,:}=relationalBox;
            relationalCentroid = [centroid(1)+newBox(1)+box(1)-0.5,centroid(2)+newBox(2)+box(2)-0.5];
            roundedCentroid = round(relationalCentroid);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=subset1(ii).Index;
        end
        subset1(ii).PieceBoxCell = relBoxes;
    end
    
%% Hough transform mapping
    tic
    thetas = 85:95;
    [rhos,~,voterCell]=houghTransform(centroidImg,thetas,0.2*AH);
    disp(['Hough Transform done in ', num2str(toc), ' seconds']);

%% line detection
    lineStruct = struct('Components',{},...
                        'Contribution',{},...
                        'SkewAngle',{},...
                        'Centroid',{},...
                        'Theta',{},...
                        'Rho',{});
    
    rowIndex = 1;
    lineLabels = zeros(imgHeight,imgWidth);

    tic
    
    %This loop detects peaks from Hough accumulator array, assigns lines
    %and removes values assigned to line until no peaks high enough remain.
    %Additionally skew is monitored.
    while 1
        sizes = cellfun('size', voterCell, 1);
        [maxValue, maxIndex] = max(sizes(:));
        if maxValue < n1
            break
        end
        
        [maxIRow, maxICol] = ind2sub(size(voterCell),maxIndex);

        nearVoters = voterCell(maxIRow-5:maxIRow+5,maxICol);
        voterNumbers = cell2mat(nearVoters(~cellfun('isempty',nearVoters)));
        
        uniqueVoters = unique(voterNumbers)';
        pieceAmounts = [subset1.PiecesAmount];
        pieceAmounts(~ismember([subset1.Index],uniqueVoters))=[];
        occurences = histcounts(voterNumbers,'BinMethod','Integers');
        occurences(occurences==0)=[];
        
        objsInLine = uniqueVoters(occurences >= 0.5*pieceAmounts);

        lineLabels(ismember(labels,objsInLine))=rowIndex;
        %Here orientation i.e. skew angle is not same as the theta.
        %The orientation takes whole objects into account whereas Hough
        %line uses the centroids of splitted components.
        prop = regionprops(double(lineLabels==rowIndex),'Orientation','Centroid');

        lineStruct(rowIndex).Components = objsInLine;
        lineStruct(rowIndex).Contribution = maxValue;
        lineStruct(rowIndex).SkewAngle = prop.Orientation;
        lineStruct(rowIndex).Centroid = prop.Centroid;
        lineStruct(rowIndex).Theta = thetas(maxICol);
        lineStruct(rowIndex).Rho = rhos(maxIRow);
        
        rowIndex = rowIndex+1;
        
        %This operation takes most of the time. Running time depends on 
        %centroid pixel amount and Hough accumulator array size.
        voterCell = cellfun(@(x) x(~ismember(x,objsInLine)),...
                            voterCell,...
                            'UniformOutput',false);
        
    end
    
    %Additional constraint is applied to remove lines with excessive skew.
    domSkewAngle = abs(mean([lineStruct.SkewAngle]));
    lineStruct([lineStruct.Contribution]<n2 & (abs([lineStruct.SkewAngle])-domSkewAngle)>2)=[];
    lineLabels(~ismember(labels, [lineStruct.Components]))=0;
    disp(['Line detection done in ', num2str(toc), ' seconds']);
    
    lineStruct = rmfield(lineStruct,'Contribution');
    
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
    lineStruct = rmfield(lineStruct,{'Theta','Rho'});
    
    %intersecting lines
    intersection = lineSegmentIntersect(lineEndPoints,lineEndPoints);
    [cLine1Id,cLine2Id]=find(tril(intersection.intAdjacencyMatrix));
    
    %draw vertical line to the middle of image
    midX = imgWidth/2;
    centerLineX = [midX,midX];
    centerLineY = [0,imgHeight];
    
    %Check if crossing lines have smaller than average distance at the
    %center of image and merge them if so. 

    centerLine = [centerLineX(1),centerLineY(1),centerLineX(2),centerLineY(2)];
    middleIntersection = lineSegmentIntersect(lineEndPoints,centerLine);
    yIntersects = middleIntersection.intMatrixY;
    avgDistance = mean(abs(diff(sort(yIntersects))));
    for ii=1:length(cLine1Id)
        firstLine = cLine1Id(ii);
        secondLine = cLine2Id(ii);
        crossLine1Y = yIntersects(firstLine);
        crossLine2Y = yIntersects(secondLine);
        distance = abs(crossLine1Y-crossLine2Y);
        %Note: Row above other might be merged with the lower if it is too 
        %close. (skewLine2.png)
        
        if distance<avgDistance
            %Merging removes first line and uses second line as new line.
            lineLabels(ismember(lineLabels,firstLine))=secondLine;
            tmpNewLineImg = (lineLabels>=1).*ismember(lineLabels,secondLine);
            prop = regionprops(tmpNewLineImg,'Orientation','Centroid');
            lineStruct(secondLine).SkewAngle = prop.Orientation;
            lineStruct(secondLine).Centroid = prop.Centroid;
            lineStruct(secondLine).Components = [lineStruct(firstLine).Components,...
                                                 lineStruct(secondLine).Components];
            lineStruct(firstLine)=[];
        end
    end

    
    disp(['Line merging done in ', num2str(toc), ' seconds'])
    
    %% Generate new lines from CCs that werent assigned to any line
    %This assumes that the undetected lines or objects must be close 
    %to other text lines.

    %Using variable 'margin' to adjust how far the unclassified object must
    %be to a line to be categorized to that line.
    
    %actually ranges around dist > 0.9*avgDist
    %pls fix
    
    %almost works. see a01-026.png
    
    tic
    ccsInLines = unique(labels(lineLabels~=0));
    subset1CCs = [subset1.Index];
    ccsNotInLine = subset1CCs(~ismember(subset1CCs,ccsInLines));
    foundLineCentYs= mean([lineEndPoints(:,2),lineEndPoints(:,4)],2);
    
    if ccsNotInLine
        [cRow,cCol]=find(ismember(centroidImg,ccsNotInLine));
        figure(),imshow(labels.*double(ismember(labels,ccsNotInLine)));
        hold on;
        for ii = 1:length(lineStruct)
            orientation = lineStruct(ii).SkewAngle;
            centroid = lineStruct(ii).Centroid;
            ysrt=centroid(2)+centroid(1)*tand(orientation);
            fplot(@(x) tand(-orientation)*x+ysrt,...
                  'LineWidth',1,...
                  'LineStyle',':');
        end
        cPoints = [cRow,cCol];
        candLineStruct = struct('YLoc',{},...
                                'Indices',{},...
                                'OldLine',{});

        newIndex = 1;
        %make sure we are proceeding from top downwards
        %sortedCPoints = sortrows(cPoints,1); 
        sortedCPoints = cPoints;
        
        for ii = 1:size(sortedCPoints,1) 
            p = sortedCPoints(ii,:);
            newComponentId = centroidImg(p(1),p(2));
            pY = p(1);
            [~,minIdx] = min(abs(foundLineCentYs-pY));
            closestLineY = foundLineCentYs(minIdx);
            distance = pY-closestLineY;
            absDist = abs(distance);

            %Using previously found line if within the margin distance from
            %it. Otherwise assigning a new position to line which is 
            %average distance apart from closest line.
            
            if absDist < margin*avgDistance
                %Close enought to be categorized into existing line.
                %maybe combine these to ifs into one with and
                locInStruct = find([candLineStruct(:).YLoc]==closestLineY);
                if locInStruct
                    %If the existing line is one of the previously detected
                    %new lines, we use that.
                    candLineStruct(locInStruct).Indices = [candLineStruct(locInStruct).Indices,...
                                                           newComponentId];
                else
                    candLineStruct(newIndex).YLoc = pY;
                    candLineStruct(newIndex).Indices = newComponentId;
                    candLineStruct(newIndex).OldLine = minIdx;
                    foundLineCentYs(end+1) = pY;
                    lineEndPoints(end+1,:) = [0,pY,imgWidth,pY];
                    newIndex = newIndex+1;
                end
            else
            
                if absDist < margin*avgDistance+avgDistance
                    %Close enough to other lines to be a new line.
                    candLineStruct(newIndex).YLoc = pY;
                    candLineStruct(newIndex).Indices = newComponentId;
                    candLineStruct(newIndex).OldLine = 0;
                    foundLineCentYs(end+1) = pY;
                    lineEndPoints(end+1,:) = [0,pY,imgWidth,pY];
                    newIndex = newIndex+1;
                    
                else
                     %idk

                end
            end
        end
        %categorize newly found lines into the label image
        
        % TODO categorize also to line struct
        subset1Indx = [subset1.Index];
        subset1Pieces = [subset1.PiecesAmount];
        highestLabel = max(lineLabels(:));
        for ii = 1:length(candLineStruct)
            indicesInArea=[candLineStruct(ii).Indices];
            piecesInArea = histcounts(indicesInArea,'BinMethod','Integers');
            piecesInArea(piecesInArea==0)=[];
            %Remove value if at least half of corresponding block-centroids 
            %are not in area.
            indicesInArea(piecesInArea<(0.5*subset1Pieces(ismember(subset1Indx,indicesInArea))))=[];
            
            if candLineStruct(ii).OldLine~=0
                newLabel = candLineStruct(ii).OldLine;
            else
                highestLabel = highestLabel+1;
                newLabel = highestLabel;
            end
            highestLabel = highestLabel+1;
            lineLabels(ismember(labels,indicesInArea))=newLabel;
        end
        
        disp(['Detecting previously undetected lines done in ', num2str(toc), ' seconds']);
    end
    
    finalLineAmount  = max(lineLabels(:));
    disp(['Final amount of text lines: ', num2str(finalLineAmount)]);
 
    %% Categorize subset 3 values to the closest line
    %Not if they are too far away (more than average distance)
    %figure(),imagesc(labels),hold on
    for ii = 1:length(subset3)
        sub3BBox = subset3(ii).BoundingBox;
        %visualizeMoreBoxes(sub3BBox,'y',1);
        yloc = sub3BBox(2)+(sub3BBox(4)/2);
        [minDistance,closestRowIndex] = min(abs(foundLineCentYs-yloc));
        if minDistance < 0.2*avgDistance
            %doesn't quite work with e.g. a01-026.png ii==27
            %probably because of detecting the undetected lines
            lineLabels(labels==subset3(ii).Index)=closestRowIndex;
        else
            lineLabels(labels==subset3(ii).Index)=0;
        end
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
                %Checking if only a fraction of the CC is under the specified
                %line. The line is higher from lowest line by a tenth of the 
                %distance between lowest and second-lowest line.
                yLowest = relAvgYIntersect(end);
                y2ndLowest = relAvgYIntersect(end-1);
                processedImage = logical(subset2(ii).Image);

                below2ndLowLineSum = sum(sum(processedImage(round(y2ndLowest):end,:)));
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
                    
                    skeletonLabels = bwlabel(flagSkeletonImg,8);
                    yiInter = skeletonLabels(round(yi),:);
                    interCCs = unique(yiInter(yiInter~=0));
                    flag1Img = ismember(skeletonLabels,interCCs);
                    flag2Img = ~ismember(skeletonLabels,interCCs)&skeletonLabels~=0;
                    flagSkeletonImg = double(flagSkeletonImg);
                    flagSkeletonImg(logical(flagSkeletonImg)&flag1Img)=1;
                    flagSkeletonImg(logical(flagSkeletonImg)&flag2Img)=2;
                    %assign the value of nearest skeleton pixel to each
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
                [~,closestRowIndex] = min(abs(foundLineCentYs-componentYLoc));
                newComp = componentImage*closestRowIndex;
                lineLabels(bbox(2):bbox(2)+bbox(4)-1,bbox(1):bbox(1)+bbox(3)-1)=...
                lineLabels(bbox(2):bbox(2)+bbox(4)-1,bbox(1):bbox(1)+bbox(3)-1)+newComp;
            end
        end
        
        disp(['Processing subset2 done in ', num2str(toc), ' seconds']);
    end

    %% visualization stuffs
    
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

    %centroids
%     [r,c] = find(centroidImg);
%     plot(c,r,'mo');
      
    %orientation
%     for ii = 1:length(lineStruct)
%         orientation = lineStruct(ii).SkewAngle;
%         centroid = lineStruct(ii).Centroid;
%         ysrt=centroid(2)+centroid(1)*tand(orientation);
%         fplot(@(x) tand(-orientation)*x+ysrt,...
%               'LineWidth',1,...
%               'LineStyle',':');
%     end
    
    %subset boxes 
%     title('Subgroups Visualized');
%     for ii = 1:length(subset1)
%         pboxes = cell2mat(subset1(ii).PieceBoxCell);
%         visualizeMoreBoxes(pboxes,'y',1);
%     end
%     visualizeMoreBoxes(subset2,'c',1);
%     visualizeMoreBoxes(subset3,'m',1);
% 

	%Lines
    figure(),imagesc(lineLabels);
    axis equal;
    axis tight;
    title('Final Text Lines');
    %visualizeMoreBoxes(subset2,'c',1);
    %visualizeMoreBoxes(subset1,'r',1);
%      figure(),imagesc(lineLabels);
     boxProps = regionprops(lineLabels,'BoundingBox');
     visualizeMoreBoxes(boxProps,'g',2);

end