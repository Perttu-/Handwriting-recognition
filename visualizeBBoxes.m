function visualizeBBoxes(image,boundingBoxes)
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
                  'EdgeColor','r',...
                  'LineWidth',1);
    end
    hold off;
end