function subImages = preprocess(filename)
    close all;
    p = preprocessor;

    p.originalImage = filename;
    p.map = filename;

    p.wienerFilterSize = 6;
    p.sauvolaNeighbourhoodSize = 100;
    p.sauvolaThreshold = 0.4;
    p.morphOpeningLowThreshold = -1;
    p.morphOpeningHighThreshold = -1;
    p.morphClosingDiscSize = -1;

    p.preprocess;

    eccentricities = p.eccentricities;
    eulerNumbers = p.eulerNumbers;
    extents = p.extents;
    solidities = p.solidities;

    originalImage = p.originalImage;

    boundingBoxes = p.boundingBoxes;
    boundaries = p.boundaries;
    eulerNumbers = vertcat(p.eulerNumbers.EulerNumber);
    majorAxisLengths = vertcat(p.majorAxisLengths.MajorAxisLength);
    areas = vertcat(p.areas.Area);

    bboxes=vertcat(boundingBoxes.BoundingBox);
    w = bboxes(:,3);
    h = bboxes(:,4);
    aspectRatios = w./h;
    perimeters = vertcat(p.perimeters.Perimeter);
    compactnesses = (perimeters.^2)/4*pi.*areas;
%      filter = aspectRatios < 0.06;
%      filter = filter | aspectRatios > 7.7;

%      filter = filter | majorAxisLengths > 400;

%       filter = filter | areas < 16;
           filter = areas < 209;
            filter = filter | eulerNumbers < -4;
%          filter = filter | areas > 5000;



    %removing the elements defined by the filters
    %boundaries(filter)=[];

    newImage = p.finalImage;
    
	boundingBoxes(filter)=[];
    lb = logical(p.finalImage);
    st = regionprops(lb, 'Area', 'PixelIdxList');
    newImage(vertcat(st(filter).PixelIdxList)) = 0;

    if ~1
        %properties = struct2cell(regionprops(newImage,'EulerNumber'));

        bboxes = regionprops(newImage,'boundingbox');
        newImage = 255 * uint8(newImage);
        for i = 1:length(properties)
            newImage = insertText(newImage,...
                                    bboxes(i).BoundingBox(1:2),...
                                    num2str(properties(i)),...
                                    'BoxOpacity',0,...
                                    'FontSize',25,...
                                    'TextColor','green');
        end
    end


    imshow(newImage);
%         hold on;
    %different loops because the holes are counted as separate boundaries
    %whereas bounding boxes include the child holes
%         for i =1:length(boundaries)
%             boundary = boundaries{i};
%             handles.boundaries(i) = plot(boundary(:,2),...
%                                          boundary(:,1),...
%                                          'g',...
%                                          'LineWidth',1);
%         end

        length(boundingBoxes)
        for i = 1:length(boundingBoxes)
            box = boundingBoxes(i).BoundingBox;
            handles.boundingBoxes(i) = rectangle('Position',...
                                       [box(1),box(2),box(3),box(4)],...
                                       'EdgeColor','r',...
                                       'LineWidth',1);
        end
%         subImages = p.subImages;

end