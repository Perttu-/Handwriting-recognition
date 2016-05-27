function lineLabels = louloudis(binarizedImage)
%Implementation based on papers  
%"Line And Word Segmentation of Handwritten Documents (2009)" and
%"A Block-Based Hough Transform Mapping for Text Line Detection in 
%Handwritten Documents" (2006)
%by Louloudis et.al.

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
n1 = 5; 
%n1 = 1;
%Excessive skew constraint is applied if (Hough)contribution is less than n2 
n2 = 9;
%Margin determines how close the undetected lines must be to the detected
%lines to be assigned correctly.
%margin = 0.25;
margin = 0.40;
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
            %Adjusting centroid and boxes to be in relation to the whole 
            %image for the sake of hough transform for centroids as well as
            %visualization.
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
    [rhos,accArr,voterCell]=houghTransform(centroidImg,thetas,0.2*AH);
    disp(['Hough Transform done in ', num2str(toc), ' seconds']);
%     figure(),
%     imshow(imadjust(mat2gray(accArr)),'XData',thetas,'YData',rhos,...
%        'InitialMagnification','fit');
%     title('Hough Transform');
%     xlabel('\theta'), ylabel('\rho');
%     axis on, axis normal;
%     colormap(hot);
%     drawnow

%% line detection
    


    lineStruct = struct('Line',{},...
                        'Contribution',{},...
                        'SkewAngle',{},...
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

        lineStruct(rowIndex).Line = objsInLine;
        lineStruct(rowIndex).Contribution = maxValue;
        lineStruct(rowIndex).SkewAngle = prop.Orientation;
        lineStruct(rowIndex).Centroid = prop.Centroid;
        lineStruct(rowIndex).Theta = thetas(maxICol);
        lineStruct(rowIndex).Rho = rhos(maxIRow);
        
        rowIndex = rowIndex+1;
        
        %this operation takes most of the time. Running time depends on 
        %centroid pixel amount and Hough accumulator array size.
        
        voterCell = cellfun(@(x) x(~ismember(x,objsInLine)),...
                            voterCell,...
                            'UniformOutput',false);
        
    end
    
    %Additional constraint is applied to remove lines with excessive skew.
    domSkewAngle = abs(mean([lineStruct.SkewAngle]));
    lineStruct([lineStruct.Contribution]<n2 & (abs([lineStruct.SkewAngle])-domSkewAngle)>2)=[];
    lineLabels(~ismember(labels, [lineStruct.Line]))=0;
    disp(['Line detection done in ', num2str(toc), ' seconds']);
    
    
    %% post-processing
    %% Merge crossing lines into one line if they are close
    tic
    %find line end points
    numOfLines = length(lineStruct);
    linePoints  = zeros(numOfLines,2);
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
        linePoints(ii,1) = xs(1);
        linePoints(ii,2) = ys(1);
        linePoints(ii,3) = xs(2);
        linePoints(ii,4) = ys(2);
    end
    
    %intersecting lines
    intersection = lineSegmentIntersect(linePoints,linePoints);
    [cLine1,cLine2]=find(tril(intersection.intAdjacencyMatrix));
    
    %draw vertical line to the middle of image
    midX = imgWidth/2;
    centerLineX = [midX,midX];
    centerLineY = [0,imgHeight];
    
    %Check if crossing lines have smaller than average distance at the
    %center of image and merge them if so. 
    %Note: The array lineLabels is the final container of the lines as 
    %lineStruct is not valid after the merging.

    centerLine = [centerLineX(1),centerLineY(1),centerLineX(2),centerLineY(2)];
    middleIntersection = lineSegmentIntersect(linePoints,centerLine);
    yIntersects = middleIntersection.intMatrixY;
    avgDistance = mean(abs(diff(sort(yIntersects))));
    
    for ii=1:length(cLine1)
        crossLine1Y = yIntersects(cLine1(ii));
        crossLine2Y = yIntersects(cLine2(ii));
        distance = abs(crossLine1Y-crossLine2Y);
        %Note: Row above other might be merged with the lower if it is too 
        %close. (skewLine2.png)
        if distance<avgDistance
            lineLabels(ismember(lineLabels,cLine1(ii)))=cLine2(ii);
        end
    end
    clearvars lineStruct;
    
    disp(['Line merging done in ', num2str(toc), ' seconds'])
    
    %% Generate new lines from CCs that werent assigned to any line
    %This is quite a edge-case. For most images (IAM database) we never get here
    %Also this assumes that the undetected lines or objects must be close 
    %to other text lines.
    
    %"If [distance] ranges around the average distance of adjacent lines 
    %then the corresponding block is considered as a candidate to 
    %belong to a new text line." -Louloudis et.al. 
    %'Ranges around' means what exactly?
    %Using variable 'margin' to adjust the distance that defines 
    %'ranges around' 
    
    tic
    ccsInLines = unique(labels(lineLabels~=0));
    subset1CCs = [subset1.Index];
    ccsNotInLine = subset1CCs(~ismember(subset1CCs,ccsInLines));
    foundLineCentYs= mean([linePoints(:,2),linePoints(:,4)],2);
    
    if ccsNotInLine
        [cRow,cCol]=find(ismember(centroidImg,ccsNotInLine));
        cPoints = [cRow,cCol];
       
        %find distance between each of these centroid pixels and nearest
        %detected line. 
        candidateLineStruct = struct('YLoc',{},...
                                     'Indices',{});
        newIndex = 1;
        %make sure we are proceeding from top downwards
        sortedCPoints = sortrows(cPoints,2); 
        
        for ii = 1:size(sortedCPoints,1) 
            p = sortedCPoints(ii,:);
            newComponentId = centroidImg(p(1),p(2));
            %find nearest line
            pY = p(1);
            [~,minIdx] = min(abs(foundLineCentYs-pY));
            closestLineY = foundLineCentYs(minIdx);
            distance = pY-closestLineY;
            absDist = abs(distance);

            %Using previously found line if within the margin distance from
            %it. Otherwise assigning a new position to line which is 
            %average distance apart from closest line.
            if absDist < margin*avgDistance+avgDistance
                
                if absDist < margin*avgDistance
                    newLineY = closestLineY;
                else
                    newLineY = sign(distance)*avgDistance+foundLineCentYs(minIdx);
                end
                
                oldIndex = find([candidateLineStruct.YLoc]==newLineY);

                if oldIndex
                    candidateLineStruct(oldIndex).YLoc = newLineY;
                    oldComponents = [candidateLineStruct(oldIndex).Indices];
                    candidateLineStruct(oldIndex).Indices = [oldComponents,newComponentId];
                else
                    candidateLineStruct(newIndex).YLoc = newLineY;
                    candidateLineStruct(newIndex).Indices = newComponentId;
                    foundLineCentYs(end+1) = newLineY;
                    linePoints(end+1,:) = [0,newLineY,imgWidth,newLineY];
                    newIndex = newIndex+1;
                end
            end
        end

        %categorize newly found lines into the label image
        subset1Indx = [subset1.Index];
        subset1Pieces = [subset1.PiecesAmount];
        highestLabel = max(lineLabels(:));
        for ii = 1:length(candidateLineStruct)
            
            indicesInArea=[candidateLineStruct(ii).Indices];
            piecesInArea = histcounts(indicesInArea,'BinMethod','Integers');
            piecesInArea(piecesInArea==0)=[];
            %Remove value if at least half of corresponding block-centroids 
            %are not in area.
            indicesInArea(piecesInArea<(0.5*subset1Pieces(ismember(subset1Indx,indicesInArea))))=[];
            highestLabel = highestLabel+1;
            lineLabels(ismember(labels,indicesInArea))=highestLabel;
        end
        
        disp(['Detecting previously undetected lines done in ', num2str(toc), ' seconds']);
    end
    
    %finalLineAmount = size(linePoints,1);
    disp(['Final amount of text lines: ', num2str(highestLabel)]);
 
    %% Categorize subset 3 values to the closest line
    %Not if they are too far away (average distance)
    for ii = 1:length(subset3)
        sub3BBox = subset3(ii).BoundingBox;
        yloc = sub3BBox(2)+(sub3BBox(4)/2);
        minDistance = min(abs(foundLineCentYs-yloc));
        if minDistance < avgDistance
            [~,closestRowIndex] = min(abs(foundLineCentYs-yloc));
            lineLabels(labels==subset3(ii).Index)=closestRowIndex;
        end
    end

    %% Subset2 Processing
    if ~isempty(subset2)
        tic
%         figure(),imshow(labels);
%         hold on;
%         visualizeMoreBoxes(subset2,'c',1);
%         sub2BBoxes = reshape([subset2.BoundingBox],4,[])';


        for ii = 1:size(subset2,2)
            %find which lines intersect this box and the average height for the
            %intersections.
            [ul,ur,ll,lr] = extractBoxCornerCoords([subset2(ii).BoundingBox]);

            boxSidesArray = [ul(1),ul(2),ur(1),ur(2);...
                             ll(1),ll(2),lr(1),lr(2);...
                             ul(1),ul(2),ll(1),ll(2);...
                             ur(1),ur(2),lr(1),lr(2)];

            intersection = lineSegmentIntersect(boxSidesArray,linePoints);
            intersectYs = [intersection.intMatrixY];
            intersectYs(isnan(intersectYs))=0;
            [~,interC,interVal] = find(intersectYs);
            intersectingLines = unique(interC);
            interLinesAmount = length(intersectingLines);
            avgYIntersect = zeros(interLinesAmount,1);

            for jj = 1:interLinesAmount
                avgYIntersect(jj)=mean(interVal(interC==intersectingLines(jj)));
            end

            if interLinesAmount>1
                relAvgYIntersect = sort(avgYIntersect-ul(2));
                %Checking if only a fraction of the CC is under the specified
                %line. The line is higher from lowest line by a tenth of the 
                %distance between lowest and second-lowest line.
                yLowest = relAvgYIntersect(end);
                y2ndLowest = relAvgYIntersect(end-1);
                image = subset2(ii).Image;
                skeletonImg = bwmorph(image,'skel',Inf);

                below2ndLowLineSum = sum(sum(image(round(y2ndLowest):end,:)));
                tenthHigherY = yLowest-((yLowest-y2ndLowest)/10);
                belowTenthHigherLineSum = sum(sum(image(round(tenthHigherY):end,:)));

                if belowTenthHigherLineSum/below2ndLowLineSum <= 0.08;
                    relAvgYIntersect(relAvgYIntersect==yLowest)=[];
                end
                
%                 figure(),imagesc(skeletonImg);
%                 hold on;
                skelWidth = size(skeletonImg,2);
                skeletonImgStruct = struct('Image',[]);
                for jj = 1:size(relAvgYIntersect)-1
                    yi = relAvgYIntersect(jj);
                    yip1 = relAvgYIntersect(jj+1);
                    zoneHiLim = yi+(yip1-yi)/2;
                    branchPoints = bwmorph(skeletonImg,'branchpoints');

                    if sum(sum(branchPoints))>0
                        %selecting only area in the zone
                        branchPoints(1:round(zoneHiLim),:)=0;
                        branchPoints(round(yip1):end,:)=0;
                        %remove also 3x3 neighbour of these junction pixels
                        branchPoints = imdilate(branchPoints,[1,1,1;1,1,1;1,1,1]);      
                        skeletonImg = skeletonImg~=(skeletonImg&branchPoints);
                    else
                        %If no junction points exist in zone, remove skeleton 
                        %points in the center of the zone.
                        centerRowY = round((zoneHiLim+yip1)/2);
                        skeletonImg(centerRowY,:)=0;
                    end
                    
                    skeletonLabels = bwlabel(skeletonImg,8);
                    yiInter = skeletonLabels(round(yi),:);
                    interCCs = unique(yiInter(yiInter~=0));
                    flag1Img = ismember(skeletonLabels,interCCs);
                    flag2Img = ~ismember(skeletonLabels,interCCs)&skeletonLabels~=0;
                    skeletonImg = double(skeletonImg);
                    skeletonImg(skeletonImg&flag1Img)=1;
                    skeletonImg(skeletonImg&flag2Img)=2;
                    skeletonImgStruct(jj).Image = skeletonImg;
                    %figure this out
                end
                
                
            end
        end
        disp(['Processing subset2 done in ', num2str(toc), ' seconds']);
    end

    %% visualization stuffs
    
%     figure(), imshow(labels);
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
    
	%row boxes
%     boxProps = regionprops(lineLabels,'BoundingBox');
%     visualizeMoreBoxes(boxProps,'g',2);

	%subset boxes 
    figure(),imshow(binarizedImage);
    title('Subgroups Visualized');
    for ii = 1:length(subset1)
        pboxes = cell2mat(subset1(ii).PieceBoxCell);
        visualizeMoreBoxes(pboxes,'y',1);
    end
    visualizeMoreBoxes(subset2,'c',1);
    visualizeMoreBoxes(subset3,'m',1);

    figure(),imagesc(lineLabels);
    boxProps = regionprops(lineLabels,'BoundingBox');
    visualizeMoreBoxes(boxProps,'g',2);

end