function visualizeBBoxes(image,boundingBoxes)
    figure();
    imshow(image);
    hold on;
    for jj = 1:size(boundingBoxes,1)
        box = boundingBoxes(jj,:);
        rectangle('Position',box,...
                  'EdgeColor','r',...
                  'LineWidth',1);
    end
    hold off;
end