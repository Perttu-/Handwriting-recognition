function visualizeMoreBoxes(boundingBoxes,color,width)
    if isstruct(boundingBoxes)
        bboxes = transpose(reshape([boundingBoxes.BoundingBox],4,[]));
    else
        bboxes = boundingBoxes;
    end
    
    
    for ii = 1:size(bboxes,1)
        box = bboxes(ii,:);
        rectangle('Position',box,...
                  'EdgeColor',color,...
                  'LineWidth',width);
    end
    
end