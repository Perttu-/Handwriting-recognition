function [eccentricities, eulerNumbers, extents, solidities]=preprocess(filename)
        close all;
        p = preprocessor;
        
        p.originalImage = filename;
        p.map = filename;
        
        p.wienerFilterSize = 16;
        p.sauvolaNeighbourhoodSize = 13;
        p.sauvolaThreshold = 0.04;
        p.morphOpeningLowThreshold = 19;
        p.morphOpeningHighThreshold = -1;
        p.morphClosingDiscSize = -1;
        
        p.preprocess;
        
        eccentricities = p.eccentricities;
        eulerNumbers = p.eulerNumbers;
        extents = p.extents;
        solidities = p.solidities;
        
%         propertyCellArray = struct2cell(p.eulerNumbers);
%         for i = 1:length(propertyCellArray)
%             finalImage = insertText(finalImage,p.boundingBoxes(i).BoundingBox(1:2),num2str(propertyCellArray{i}),'BoxOpacity',0,'FontSize',25,'TextColor','yellow');
%         end
%         min = struct2cell(p.minorAxisLengths);
%         maj = struct2cell(p.majorAxisLengths);
%         for i = 1:length(min)
%             aspectRatio = num2str(min.MinorAxisLength{i}/maj.MajorAxisLength{i});
%             finalImage = insertText(finalImage,p.boundingBoxes(i).BoundingBox(1:2),aspectRatio,'BoxOpacity',0,'FontSize',25,'TextColor','yellow');
%         end

        
%         figure();
%         subplot(2,2,1), imshow(p.binarizedImage);
%         subplot(2,2,2), imshow(p.openedImage);
%         subplot(2,2,3), imshow(p.closedImage);
%         subplot(2,2,4), imshow(finalImage);
        imshow(p.finalImage);
        hold on;
        
        %different loops because the holes are counted as boundaries
        %whereas bounding boxes include the child holes
        boundaries = p.boundaries;
        boundingBoxes = p.boundingBoxes;
        for i =1:length(boundaries)
            boundary = boundaries{i};
            handles.boundaries(i) = plot(boundary(:,2),boundary(:,1),'g','LineWidth',1);
        end

        for i = 1:length(boundingBoxes)
            box = boundingBoxes(i).BoundingBox;
            handles.boundingBoxes(i) = rectangle('Position', [box(1),box(2),box(3),box(4)], 'EdgeColor','r','LineWidth',1);
        end

%         figure();
%         imshow(p.subImages(2).Image);
end