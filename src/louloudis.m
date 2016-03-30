function finalBoxes = louloudis(binarizedImage)
%implementation based on paper 
%"Line And Word Segmentation of Handwritten Documents (2009)" 
%by Louloudis et.al.
    [imgWidth,imgHeight]=size(binarizedImage);
    bboxes = regionprops(binarizedImage, 'BoundingBox');
    boxList = reshape([bboxes.BoundingBox],4,[])';
    %assuming average height equals average width
    AH = mean(boxList(:,4));
    AW = AH;
    H = boxList(:,4);
    W = boxList(:,3);
    subset1 = boxList((0.5 * AH <= H < 3*AH) & (0.5 * AW <= W),:);
    %figure(),visualizeBBoxes(binarizedImage, subset1,'y',2);
    subset2 = boxList(H > 3 * AH,:);
    %visualizeMoreBoxes(subset2,'c',2);
    subset3 = boxList(((H < 3 * AH) & (0.5 * AW > W) |...
                      ((H < 0.5 * AH) & (0.5 * AW < W))),:);
    %visualizeMoreBoxes(subset3,'m',2);
    
    %partition subset1 to equally sized boxes, extracting centroid pixels
    %and categorizing them

    centroidImg = zeros(imgWidth,imgHeight);
    
    for ii = 1:length(subset1)
        box = subset1(ii,:);
        boxWidth = subset1(ii,3);
        xSplit = box(1);
        for jj = 1:ceil(boxWidth/AW) 
            if xSplit+AW <= boxWidth+box(1)
                newBox = [xSplit,box(2),AW,box(4)];
                xSplit=xSplit+AW;
            else
                lastXWidth = mod(boxWidth,AW);
                xSplit = boxWidth+box(1)-lastXWidth;
                newBox = [xSplit,box(2),lastXWidth,box(4)];
            end
            cropped = imcrop(binarizedImage, newBox);
            centroidStruct = regionprops(uint8(cropped), 'Centroid');
            centroid = centroidStruct.Centroid;
            %centroid in relation to whole image
            realCentroid = [centroid(1)+newBox(1)-0.5,centroid(2)+newBox(2)-0.5];
            roundedCentroid = round(realCentroid);
            centroidImg(roundedCentroid(2),roundedCentroid(1))=ii;
        end
    end
    
    %theta should be right?
    [accumulatorArray,thetas,rhos,voterCell] = houghTransform(centroidImg,-5:5,0.2*AH);
    tmpAcc = accumulatorArray;
    
    n1 = 5;
    n2 = 9;
%     while 1
%         [maxValue, maxIndex]=max(accumulatorArray(:));
%         [maxIRow, maxICol] = ind2sub(size(accumulatorArray),maxIndex);
%         if contribution < n1
%             break
%         end
%     end

    
    
    
    
    figure();
    imshow(imadjust(mat2gray(accumulatorArray)),'XData',thetas,'YData',rhos,...
       'InitialMagnification','fit');
    title('Hough Transform');
    xlabel('\theta'), ylabel('\rho');
    axis on, axis normal;
    colormap(hot);
    
    

    
    finalBoxes = [];
end