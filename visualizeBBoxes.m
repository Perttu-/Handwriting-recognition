function visualizeBBoxes(image,boundingBoxes, color)
    if isstruct(boundingBoxes)
        bboxes = transpose(reshape([boundingBoxes.BoundingBox],4,[]));
    else
        bboxes = boundingBoxes;
    end
    
    imshow(image);
    hold on;
    for ii = 1:size(boundingBoxes,1)
        box = bboxes(ii,:);
        rectangle('Position',box,...
                  'EdgeColor',color,...
                  'LineWidth',1);
    end
    hold off;
end