function finalBoxes = louloudis(binarizedImage)
%implementation based on paper 
%"Line And Word Segmentation of Handwritten Documents (2009)" 
%by Louloudis et.al.

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
    
    %partition subset1 to equally sized boxes
    newBoxes = [];
    centroids = [];
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
            c = regionprops(cropped, 'Centroid');
            cc=c.Centroid;
            %what if in area there is more than one object?
            centroids(end+1,:) = [cc(1)+newBox(1),cc(2)+newBox(2)];
        end
    end
    

%     figure(),visualizeBBoxes(binarizedImage, subset1,'y',5);
%     visualizeMoreBoxes(newBoxes,'r',1);
    %imshow(binarizedImage);
    %hold on;
    plot(centroids(:,1),centroids(:,2), 'r*')
    %hold off;
    
end