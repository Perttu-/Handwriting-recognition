function finalBoxes = louloudis(binarizedImage)
%implementation based on paper  
%"Line And Word Segmentation of Handwritten Documents (2009)" 
%by Louloudis et.al.
%% pre-procesing
    [imgWidth,imgHeight]=size(binarizedImage);
    labels = bwlabel(binarizedImage,8);
    boxes = regionprops(logical(labels), 'BoundingBox','Image');
    %imagesc(labels),visualizeMoreBoxes(bboxes,'r',2);

    boxList = reshape([boxes.BoundingBox],4,[])';
    %categorizing the connected components into three subsets 
    %here the notation is mostly similar to the paper
    AH = mean(boxList(:,4));
    AW = AH;
    subset1=struct('BoundingBox',[],'Image',[],...
                   'Index',[],'PiecesAmount',[]);
    subset2=struct('BoundingBox',[],'Image',[]);
    subset3=struct('BoundingBox',[],'Image',[]);
    indx1=1;
    indx2=1;
    indx3=1;
    
    for ii=1:length(boxes)
        box = boxes(ii).BoundingBox;
        H = box(:,4);
        W = box(:,3);
        
        image = boxes(ii).Image;
        image = image+0;
        image(image==1)=ii;
        if (0.5 * AH <= H) && (H < 3*AH) && (0.5 * AW <= W)
            subset1(indx1).BoundingBox = box;
            subset1(indx1).Image = image;
            indx1 = indx1+1;
        end
        if (H >= 3 * AH)
            subset2(indx2).BoundingBox = box;
            subset2(indx2).Image = image;
            indx2 = indx2+1;
        end
        if (((H < 3 * AH) && (0.5 * AW > W) || ((H < 0.5 * AH) && (0.5 * AW < W))))
            subset3(indx3).BoundingBox = box;
            subset3(indx3).Image = image;
            indx3 = indx3+1;
        end
    end

    %partition subset1 to equally sized boxes, extracting centroid pixels
    %and categorizing them
%     imagesc(labels);
    centroidImg = zeros(imgWidth,imgHeight);

    for ii = 1:length(subset1)
        box = subset1(ii).BoundingBox;
        image = subset1(ii).Image;
        boxWidth = box(3);
        xSplit = 0;
        piecesAmount = ceil(boxWidth/AW);
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
            cropped = imcrop(image, newBox);
            
            binCropped = logical(cropped);
            centroidStruct = regionprops(uint8(binCropped), 'Centroid');
            centroid = centroidStruct.Centroid;
            %adjust centroid and boxes to be in relation to the whole image
            %for the sake of hough transform for centroids and
            %visualization
            relationalBox = [newBox(1)+box(1),newBox(2)+box(2),newBox(3),newBox(4)];
            relationalCentroid = [centroid(1)+newBox(1)+box(1)-0.5,centroid(2)+newBox(2)+box(2)-0.5];
%             hold on;
%             rectangle('Position',relationalBox,...
%             'EdgeColor','y',...
%             'LineWidth',2);
%             plot(relationalCentroid(:,1),relationalCentroid(:,2), 'g*');
%             hold off;
            roundedCentroid = round(relationalCentroid);
            [~,~,id] = find(cropped,1);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=id;
        end
        subset1(ii).Index = id;
    end
    %% Hough transform mapping
    [accArray,thetas,rhos,voterNumberCell] = houghTransform(centroidImg,-5:5,0.2*AH);
    
%     figure();
%     imshow(imadjust(mat2gray(accArray)),'XData',thetas,'YData',rhos,...
%        'InitialMagnification','fit');
%     title('Hough Transform');
%     xlabel('\theta'), ylabel('\rho');
%     axis on, axis normal;
%     colormap(hot);
    
%% line detection
    n1 = 5;
    n2 = 9;

    lineStruct = struct('Line',{},...
                        'Contribution',{},...
                        'SkewAngle',{});
    
    rowIndex = 1;
    lineLabels = zeros(imgWidth,imgHeight);
    tmpImg = lineLabels;
    tic
    
    while 1
        sizes = cellfun('size', voterNumberCell, 1);
        [maxValue, maxIndex] = max(sizes(:));
        
        if maxValue < n1
            break
        end
        
        [maxIRow, maxICol] = ind2sub(size(voterNumberCell),maxIndex);
        nearVoters = voterNumberCell(maxIRow-5:maxIRow+5,maxICol);
        voterNumbers = cell2mat(nearVoters(~cellfun('isempty',nearVoters)));
        
        uniqueVoters = unique(voterNumbers)';
        pieceAmounts = [subset1.PiecesAmount];
        pieceAmounts(~ismember([subset1.Index],uniqueVoters))=[];
        occurences = histcounts(voterNumbers,'BinMethod','Integers');
        occurences(occurences==0)=[];
        
        objsInLine = uniqueVoters(occurences >= 0.5*pieceAmounts);
        lineLabels(ismember(labels,objsInLine))=rowIndex;
        orientation = regionprops((lineLabels==rowIndex),'Orientation');

        lineStruct(rowIndex).Line = objsInLine;
        lineStruct(rowIndex).Contribution = maxValue;
        lineStruct(rowIndex).SkewAngle = orientation.Orientation;
        rowIndex = rowIndex+1;
        
        voterNumberCell = cellfun(@(x) x(~ismember(x,objsInLine)),...
                                  voterNumberCell,...
                                  'UniformOutput',false);
    end
    toc
    
    boxProps = regionprops(lineLabels,'BoundingBox');
    domSkewAngle = mean([lineStruct.SkewAngle]);
    lineStruct([lineStruct.Contribution]<n2 & abs([lineStruct.SkewAngle]-domSkewAngle)>2)=[];
    %needs testing if works right
    lineLabels(~ismember(labels, [lineStruct.Line]))=0;
    imagesc(lineLabels);
    figure(),
    visualizeBBoxes(lineLabels,boxProps,'g',2);
    %% post-processing

    finalBoxes = [];
end