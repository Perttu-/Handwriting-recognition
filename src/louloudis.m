function finalBoxes = louloudis(binarizedImage)
%Implementation based on paper  
%"Line And Word Segmentation of Handwritten Documents (2009)" 
%by Louloudis et.al.
%% pre-procesing
    [imgHeight,imgWidth]=size(binarizedImage);
    labels = bwlabel(binarizedImage,8);
    boxes = regionprops(logical(labels), 'BoundingBox','Image');
    boxList = reshape([boxes.BoundingBox],4,[])';
    
    %Categorizing the connected components into three subsets. 
    %Here the notation is mostly similar to the paper.
    AH = mean(boxList(:,4));
    AW = AH;
    subset1=struct('BoundingBox',[],...
                   'Image',[],...
                   'Index',[],...
                   'PieceBoxCell',[],...
                   'PiecesAmount',[]);
               
    subset2=struct('BoundingBox',[],...
                   'Image',[]);
               
    subset3=struct('BoundingBox',[],...
                   'Image',[]);
    indx1=1;
    indx2=1;
    indx3=1;
    
    for ii=1:length(boxes)
        box = boxes(ii).BoundingBox;
        H = box(:,4);
        W = box(:,3);
        
        wordImage = boxes(ii).Image;
        wordImage = wordImage+0;
        wordImage(wordImage==1)=ii;
        if (0.5 * AH <= H) && (H < 3*AH) && (0.5 * AW <= W)
            subset1(indx1).BoundingBox = box;
            subset1(indx1).Image = wordImage;
            indx1 = indx1+1;
        end
        if (H >= 3 * AH)
            subset2(indx2).BoundingBox = box;
            subset2(indx2).Image = wordImage;
            indx2 = indx2+1;
        end
        if (((H < 3 * AH) && (0.5 * AW > W) || ((H < 0.5 * AH) && (0.5 * AW < W))))
            subset3(indx3).BoundingBox = box;
            subset3(indx3).Image = wordImage;
            indx3 = indx3+1;
        end
    end

    %Partition subset1 to equally sized boxes and extracting centroid pixels
    centroidImg = zeros(imgHeight,imgWidth);

    for ii = 1:length(subset1)
        box = subset1(ii).BoundingBox;
        wordImage = subset1(ii).Image;
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
            cropped = imcrop(wordImage, newBox);
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
            [~,~,id] = find(cropped,1);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=id;
        end
        subset1(ii).Index = id;
        subset1(ii).PieceBoxCell = relBoxes;
    end
    %% Hough transform mapping
    tic
    thetas = 85:95;
    %thetas = 40:130;
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
    
    n1 = 5;
    n2 = 9;

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
        tic
        voterCell = cellfun(@(x) x(~ismember(x,objsInLine)),...
                            voterCell,...
                            'UniformOutput',false);
        toc

    end
    
    
    %Additional constraint is applied to remove lines with excessive skew.
    %Excessive skew defined by parameter n2.
    domSkewAngle = mean([lineStruct.SkewAngle]);
    lineStruct([lineStruct.Contribution]<n2 & (abs([lineStruct.SkewAngle])-domSkewAngle)>2)=[];
    lineLabels(~ismember(labels, [lineStruct.Line]))=0;
    disp(['Line detection done in ', num2str(toc), ' seconds']);
    
    %% post-processing
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
    
    imshow(lineLabels);
    hold on;
    for ii =1:numOfLines
        plot([linePoints(ii,1),linePoints(ii,3)],...
             [linePoints(ii,2),linePoints(ii,4)],...
             'LineWidth',2);
    end
    
    %intersecting lines
    intersection = lineSegmentIntersect(linePoints,linePoints);
    [cLine1,cLine2]=find(tril(intersection.intAdjacencyMatrix));
    
    %draw vertical line to the middle of image
    midX = imgWidth/2;
    centerLineX = [midX,midX];
    centerLineY = [0,imgHeight];
    plot(centerLineX, centerLineY,...
         'LineWidth',2,...
         'LineStyle',':');
    hold off;
    figure(),imagesc(lineLabels);
    title('Before merging');
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
    
    disp(['Line merging done in ', num2str(toc), ' seconds'])
    figure(),imagesc(lineLabels);
    title('After merging');
    
    %% visualization stuffs

    %centroids
%     [r,c] = find(centroidImg);
%     plot(c,r,'mo');
      
%     %orientation
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
%     for ii = 1:length(subset1)
%         pboxes = cell2mat(subset1(ii).PieceBoxCell);
%         visualizeMoreBoxes(pboxes,'y',1);
%     end
% 
%     visualizeMoreBoxes(subset2,'c',1);
%     visualizeMoreBoxes(subset3,'m',1);


    finalBoxes = [];
end