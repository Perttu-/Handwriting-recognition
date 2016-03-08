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
    %ei toimi pelk?st??n viimeinen boxi j?? listaan pls fix
    for ii = 0:length(subset1)-1
        box = subset1(ii+1,:);
        boxWidth = box(:,3);
        
        for jj=1:ceil(boxWidth/AW)
            newXCoord = ii*AW+box(1);
            if newXCoord <= boxWidth+box(1);
               xCut = newXCoord;
               xWidth = AW;
            else
               lastXWidth = mod(boxWidth,AW);
               xCut = boxWidth-lastXWidth;
               xWidth = lastXWidth;
            end
            (ii+1)*jj
            newBoxes((ii+1)*jj,:) = [xCut+box(1),box(2),xWidth,box(4)];
        end
    end
    figure(),visualizeBBoxes(binarizedImage, subset1,'y',2);
    visualizeMoreBoxes(newBoxes,'g',1);
    
end