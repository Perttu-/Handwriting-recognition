function visualizeRows(imageStruct, index)

    rowAmount = size(imageStruct,2);
    if ~isempty(index)
        rowAmount = 1;
    end
    figure();
    for ii=1:rowAmount
        if ~isempty(index)
            ix = index;
            subplot(1,1,1);
            
        else
            ix = ii;
            subplot(rowAmount,1,ix);
        end
        
        imshow(imageStruct(ix).Image,'border', 'tight');
        if ~isempty(imageStruct(ix).BoundingBox)
            hold on;
            boundingBoxes = imageStruct(ix).BoundingBox;
            for jj = 1:size(boundingBoxes,1)
                box = boundingBoxes(jj,:);
                rectangle('Position',box,...
                          'EdgeColor','r',...
                          'LineWidth',1);
            end
            hold off;
        end
        
        if ~isempty(imageStruct(ix).Space)
            hold on;
            spaces = imageStruct(ix).Space;
            yMiddle = round(size(imageStruct(ix).Image,1)/2);
            for jj = 1:size(spaces,1)
                
                line(spaces(jj,:),[yMiddle,yMiddle],...
                     'Color','g',...
                     'LineWidth',4);
            end
            hold off;
        end
    end
end