function visualizeImgStruct(imageStruct, index, sPlot)

    
    if ~isempty(index)
        rowAmount = length(index);
    else
        rowAmount = size(imageStruct,2);
    end
    
    if sPlot == 1
        figure();
    end
    
    for ii=1:rowAmount
        if ~isempty(index)
            ix = index(ii);
        else
            ix = ii;
        end
        
        if sPlot == 1
            subplot(rowAmount,1,ii);
        else
            figure(ii);
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
                     'LineWidth',2);
            end
            hold off;
        end
    end
end