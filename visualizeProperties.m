function visualizeProperties(img,bboxes,properties)
    %binary image to grayscale
    newImage = 255 * uint8(img);    
    for ii = 1:length(bboxes)
        %property = ii;
        property = properties(ii);
        box = rowBBoxes(ii,:);
        newImage = insertText(newImage,...
                              [box(1),box(2)],...
                              property,...
                              'BoxOpacity',1,...
                              'FontSize',10,...
                              'TextColor','red');
    end