function finalBoxes = louloudis(binarizedImage)
%implementation based on paper  
%"Line And Word Segmentation of Handwritten Documents (2009)" 
%by Louloudis et.al.
    [imgWidth,imgHeight]=size(binarizedImage);
    
    boxes = regionprops(binarizedImage, 'BoundingBox','Image');
    labels = bwlabel(binarizedImage,8);
%     imagesc(labels),visualizeMoreBoxes(bboxes,'r',2);

    boxList = reshape([boxes.BoundingBox],4,[])';
    %assuming average height equals average width
    %here the notation is similar to the paper
    AH = mean(boxList(:,4));
    AW = AH;
    subset1=struct('BoundingBox',[],'Image',[]);
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
        if (0.5 * AH <= H < 3*AH) && (0.5 * AW <= W)
            subset1(indx1).BoundingBox = box;
            subset1(indx1).Image = image;
            indx1 = indx1+1;
        end
        if (H > 3 * AH)
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

    centroidImg = zeros(imgWidth,imgHeight);
    splitStruct = struct('Index',[],...
                         'PiecesAmount',[]);
    for ii = 1:length(subset1)
        box = subset1(ii).BoundingBox;
        image = subset1(ii).Image;
        boxWidth = box(3);
        %xSplit = box(1);
        xSplit = 0;
        piecesAmount = ceil(boxWidth/AW);
        splitStruct(ii).PiecesAmount = piecesAmount;
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
            %adjust centroid to be in relation to the whole image
            realCentroid = [centroid(1)+newBox(1)+box(1)-0.5,centroid(2)+newBox(2)+box(2)-0.5];
%             hold on;
%             plot(realCentroid(:,1),realCentroid(:,2), 'g*');
%             hold off;
            
            roundedCentroid = round(realCentroid);
            [~,~,id] = find(cropped,1);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=id;
        end
        splitStruct(ii).Index = id;
    end
    
    %theta should be right?
    [accumulatorArray,thetas,rhos,voterCell] = houghTransform(centroidImg,-5:5,0.2*AH);
    tmpAcc = accumulatorArray;
    
    n1 = 5;
    n2 = 9;
    contribution = 0;
    textLineStruct = struct('Theta',[],...
                            'Rho',[],...
                            'Indices',[]);
    
    while 1
        [maxValue, maxIndex]=max(tmpAcc(:));
        [maxIRow, maxICol] = ind2sub(size(tmpAcc),maxIndex);
        [height,width]=size(tmpAcc);
        voterPoints = cell2mat(voterCell(maxIRow-5:maxIRow+5, maxICol));
        voterAmount = length(voterPoints);
        voterIndices = zeros(voterAmount,1);
        for ii = 1:voterAmount
            voterIndices(ii) = centroidImg(voterPoints(ii,1),voterPoints(ii,2));
        end
        
        if contribution < n1
            break
        end
    end

    figure();
    imshow(imadjust(mat2gray(accumulatorArray)),'XData',thetas,'YData',rhos,...
       'InitialMagnification','fit');
    title('Hough Transform');
    xlabel('\theta'), ylabel('\rho');
    axis on, axis normal;
    colormap(hot);
    
    finalBoxes = [];
end