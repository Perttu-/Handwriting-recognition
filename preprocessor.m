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
        morphOpeningLowThreshold;
        morphOpeningHighThreshold;
        morphClosingDiscSize;
        
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
        
        function obj = set.morphOpeningLowThreshold(obj, newLowThreshold)
            obj.morphOpeningLowThreshold = newLowThreshold;
        end
        
        function obj = set.morphOpeningHighThreshold(obj, newHighThreshold)
            obj.morphOpeningHighThreshold = newHighThreshold;
        end
        
        function obj = set.morphClosingDiscSize(obj, newMorphClosingDiscSize)
            obj.morphClosingDiscSize = newMorphClosingDiscSize;
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

        %Change to whichever image is last
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
            if obj.wienerFilterSize ~= -1
                obj.noiselessImage = wiener2(obj.grayImage, [obj.wienerFilterSize, obj.wienerFilterSize]);
            else
                obj.noiselessImage = obj.grayImage;
            end
            
            %binarize image with adaptive Sauvola algorithm 
            neighbourhood = obj.sauvolaNeighbourhoodSize;
            bin=sauvola(obj.noiselessImage,...
                       [neighbourhood,...
                       neighbourhood],...
                       obj.sauvolaThreshold);
                   
            %optionally nick binarization can be used
            %bin = nick(obj.noiselessImage,[100 100],-0.1);
            
            %Inverse colors for further processing
            obj.binarizedImage = imcomplement(bin);
            
            %Try to remove too small and too big blobs with 
            %morphological opening operations
            
            
            if obj.morphOpeningLowThreshold ~=-1 && obj.morphOpeningHighThreshold ~= -1
            obj.openedImage = xor(bwareaopen(obj.binarizedImage, obj.morphOpeningLowThreshold),...
                                               bwareaopen(obj.binarizedImage, obj.morphOpeningHighThreshold)); 
            
            elseif obj.morphOpeningLowThreshold ~= -1 && obj.morphOpeningHighThreshold ==-1
                 obj.openedImage = bwareaopen(obj.binarizedImage, obj.morphOpeningLowThreshold);
           
                 %might need to be redefined...
            elseif obj.morphOpeningLowThreshold == -1 && obj.morphOpeningHighThreshold ~=-1
                 obj.openedImage = xor(obj.binarizedImage,...
                                                   bwareaopen(obj.binarizedImage, obj.morphOpeningHighThreshold));
            else
                obj.openedImage = obj.binarizedImage;
            end
            
            %Morphological closing to remove unnecessary holes
            if obj.morphClosingDiscSize ~=-1
                obj.closedImage = imdilate(obj.openedImage,strel('disk',obj.morphClosingDiscSize));
            else
                obj.closedImage = obj.openedImage;
            end
            
            
            %Calculate boundaries and bounding boxes for visualization and
            %to extract the needed blobs
            obj.boundingBoxes = regionprops(obj.closedImage,'boundingbox');
            obj.boundaries = bwboundaries(obj.closedImage,8,'holes'); 
            boundingBoxes = obj.boundingBoxes;
            boundaries = obj.boundaries;
            obj.objectCount = length(boundingBoxes);
            
            %Extract properties which may be of use
            obj.eccentricities = regionprops(obj.finalImage,'Eccentricity');
            obj.eulerNumbers = regionprops(obj.finalImage,'EulerNumber');
            obj.extents = regionprops(obj.finalImage,'Extent');
            obj.solidities = regionprops(obj.finalImage,'Solidity');
            obj.minorAxisLengths = regionprops(obj.finalImage,'MinorAxisLength');
            obj.majorAxisLengths = regionprops(obj.finalImage,'MajorAxisLength');
            obj.areas = regionprops(obj.finalImage,'Area');
            obj.perimeters = regionprops(obj.finalImage,'Perimeter');
            
            obj.subImages = regionprops(obj.finalImage, 'Image');
            obj.centroids = regionprops(obj.finalImage, 'Centroid');
            
            %2spooky4me
            obj.skeletonImage =  bwmorph(obj.finalImage,'skel',Inf);
            
        end

    end
end


