classdef preprocessor<handle
    
    properties
        %Images
        originalImage;
        map;
        grayImage;
        noiselessImage;
        binarizedImage;
        openedImage;
        closedImage;
        finalImage;
        skeletonImage;
        
        %Arguments
        wienerFilterSize;
        sauvolaNeighbourhoodSize;
        sauvolaThreshold;
        morphClosingDiscSize;
        strokeWidthThreshold;
        
        %Found object visualization
        boundaries;
        boundingBoxes;
        objectCount;
        
        %Found object properties
        eccentricities;
        eulerNumbers;
        extents;
        solidities;
        areas;
        minorAxisLengths;
        majorAxisLengths;
        centroids;
        perimeters;
        
        %Found object extraction
        subImages;
        
        %"Filters"
        minAspectRatioFilter;
        maxAspectRatioFilter;
        minEulerNumberFilter;
        maxMajorAxisLengthFilter;
        minAreaFilter;
        maxAreaFilter;
        
        %stroke properties
        strokeMetrics;
        strokeWidthFilter;
        
        
    end
    
    
    methods
        %SETTERS
        function obj = set.originalImage(obj,path)
            [i,~] = imread(path);
            obj.originalImage = i;

        end
        
        function obj = set.map(obj,path)
            [~,m] = imread(path);
            obj.map = m;
        end
        
        function obj = set.wienerFilterSize(obj, newWienerFilterSize)
            obj.wienerFilterSize = newWienerFilterSize;
        end
        
        function obj = set.sauvolaNeighbourhoodSize(obj, newSauvolaNeighbourhoodSize)
            obj.sauvolaNeighbourhoodSize = newSauvolaNeighbourhoodSize;
        end
        
        function obj = set.sauvolaThreshold(obj, newSauvolaThreshold)
            obj.sauvolaThreshold = newSauvolaThreshold;
        end
        
        
        function obj = set.morphClosingDiscSize(obj, newMorphClosingDiscSize)
            obj.morphClosingDiscSize = newMorphClosingDiscSize;
        end
        
        function obj = set.strokeWidthThreshold(obj, t)
            obj.strokeWidthThreshold = t;
        end
        
        
        %GETTERS 
        %Images
        function originalImage = get.originalImage(obj)
            originalImage = obj.originalImage;
        end
        
        function noiselessImage = get.noiselessImage(obj)
            noiselessImage = obj.noiselessImage;
        end
        
        function binarizedImage = get.binarizedImage(obj)
            binarizedImage = obj.binarizedImage;
        end
        
        function openedImage = get.openedImage(obj)
            openedImage = obj.openedImage;
        end
        
        function closedImage = get.closedImage(obj)
            closedImage = obj.closedImage;
        end

        %Change this to whichever image is last
        function finalImage = get.finalImage(obj)
            finalImage = obj.closedImage;
        end

        function skeletonImage = get.skeletonImage(obj)
            skeletonImage = obj.skeletonImage;
        end

        %Properties
        function subImages = get.subImages(obj)
            subImages = obj.subImages;
        end
    
    
        %The preprocessing itself
        %Optional phases can be disabled with input -1
        function [boundaries, boundingBoxes] = preprocess(obj)
            
            %Convert to rgb color mode if it already isn't
            if ~isempty(obj.map)
                img = ind2rgb(obj.originalImage,obj.map);
            else
                img = obj.originalImage;
            end
            
            %Convert to grayscale if it already isn't     
            [~, ~, numberOfColorChannels] = size(img);
            if numberOfColorChannels > 1
                obj.grayImage = rgb2gray(img);
            else
                obj.grayImage = img; 
            end
            
            %Remove noise with adaptive wiener filter
            w = obj.wienerFilterSize;
            if w ~= -1
                obj.noiselessImage = wiener2(obj.grayImage,...
                                            [w,w]);
            else
                obj.noiselessImage = obj.grayImage;
            end
            
            %binarize image with adaptive Sauvola algorithm 
            neighbourhood = obj.sauvolaNeighbourhoodSize;
            bin=sauvola(obj.noiselessImage,...
                       [neighbourhood,...
                       neighbourhood],...
                       obj.sauvolaThreshold);
                   
            
            %Inverse colors for further processing
            obj.binarizedImage = ~bin;
            
            %Morphological closing to remove unnecessary holes
            if obj.morphClosingDiscSize ~=-1
                obj.closedImage = imdilate(obj.binarizedImage,...
                                  strel('disk',obj.morphClosingDiscSize));
            else
                obj.closedImage = obj.binarizedImage;
            end
            
            %stroke width analysis
            subImageList = regionprops(obj.finalImage, 'Image');
            subImageAmount = length(subImageList);
            strokeWidthFilterIdx = false(1, subImageAmount);
            metrics = zeros(1, subImageAmount);
            
            for i = 1:subImageAmount
                binaryImage = subImageList(i).Image;
                %bwdist gets the Euclidean distance to nearest nonzero pixel
                %the image colors need to be inversed
                distanceImage = bwdist(~binaryImage);
                subimageSkeleton = bwmorph(binaryImage, 'thin', inf);
                %strokeWidthImage = distanceImage;
                %removing all but the pixels that are in skeleton to get better
                %wiev of stroke width
                %strokeWidthImage(~subimageSkeleton) = 0;
                %one dimensional array containing all strokes
                strokeWidthValues = distanceImage(subimageSkeleton);
                %calculating the metric to analyze stroke width variation
                strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
                %above metric can result in NaN values when mean is 0 (?)
                %happens with one pixel width areas so they can be filtered
                if isnan(strokeWidthMetric)     
                    strokeWidthFilterIdx(i) = 1;
                else
                    strokeWidthFilterIdx(i) = strokeWidthMetric > obj.strokeWidthThreshold;
                end
                metrics(i) = strokeWidthMetric;
            end
            obj.strokeWidthFilter = strokeWidthFilterIdx;
            obj.strokeMetrics = metrics;
            
            
            %Calculate boundaries and bounding boxes for visualization and
            %to extract the needed blobs
            obj.boundingBoxes = regionprops(obj.closedImage,'boundingbox');
            obj.boundaries = bwboundaries(obj.closedImage,8,'holes'); 
            boundingBoxes = obj.boundingBoxes;
            boundaries = obj.boundaries;
            obj.objectCount = length(boundingBoxes);
            
            %Extract properties which may be of use
            fImage = obj.finalImage;
            obj.eccentricities = regionprops(fImage,'Eccentricity');
            obj.eulerNumbers = regionprops(fImage,'EulerNumber');
            obj.extents = regionprops(fImage,'Extent');
            obj.solidities = regionprops(fImage,'Solidity');
            obj.minorAxisLengths = regionprops(fImage,'MinorAxisLength');
            obj.majorAxisLengths = regionprops(fImage,'MajorAxisLength');
            obj.areas = regionprops(fImage,'Area');
            obj.perimeters = regionprops(fImage,'Perimeter');
            
            obj.centroids = regionprops(fImage, 'Centroid');
            
            %2spooky4me
            obj.skeletonImage =  bwmorph(obj.finalImage,'skel',Inf);
            
        end
    end
end


