function [eccentricities, eulerNumbers, extents, solidities]=preprocess(filename)
        close all;
        p = preprocessor;
        
        p.originalImage = filename;
        p.map = filename;
        
        p.wienerFilterSize = 16;
        p.sauvolaNeighbourhoodSize = 13;
        p.sauvolaThreshold = 0.04;
        p.morphOpeningLowThreshold = 100;
        p.morphOpeningHighThreshold = 9000;
        p.morphClosingDiscSize = 4;
        
        p.preprocess;
        
        finalImage = p.originalImage;
        
        eccentricities = p.eccentricities;
        eulerNumbers = p.eulerNumbers;
        extents = p.extents;
        solidities = p.solidities;
        
        ecc = struct2cell(p.solidities);
        for i = 1:length(ecc)
            finalImage = insertText(finalImage,p.boundingBoxes(i).BoundingBox(1:2),num2str(ecc{i}),'BoxOpacity',0,'FontSize',25,'TextColor','yellow');
        end
        
%         figure();
%         subplot(2,2,1), imshow(p.binarizedImage);
%         subplot(2,2,2), imshow(p.openedImage);
%         subplot(2,2,3), imshow(p.closedImage);
%         subplot(2,2,4), imshow(finalImage);
        imshow(finalImage);
        hold on;
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
end