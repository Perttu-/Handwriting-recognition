function visualizeLayout(backgroundImage, layoutStruct, width)
    imshow(backgroundImage);
    hold on;
    for ii = 1:size(layoutStruct.AoiBoxes,1)
        aoiBox = layoutStruct.AoiBoxes(ii,:);
        rectangle('Position',aoiBox,...
                  'EdgeColor','r',...
                  'LineWidth',width);
              
        for jj = 1:size(layoutStruct.AoiStruct(ii).RowBoxes,1)
            rowBox = layoutStruct.AoiStruct(ii).RowBoxes(jj,:);
            finalRowBox = [rowBox(1)+aoiBox(1),rowBox(2)+aoiBox(2),rowBox(3),rowBox(4)];
            rectangle('Position',finalRowBox,...
                      'EdgeColor','c',...
                      'LineWidth',width);
                  
            for kk = 1:size(layoutStruct.AoiStruct(ii).RowStruct(jj).WordBoxes,1)
                wordBox = layoutStruct.AoiStruct(ii).RowStruct(jj).WordBoxes(kk,:);
                finalWordBox = [wordBox(1)+finalRowBox(1),wordBox(2)+finalRowBox(2),wordBox(3),wordBox(4)];
                rectangle('Position',finalWordBox,...
                          'EdgeColor','g',...
                          'LineWidth',width);
            end
        end
    end
end