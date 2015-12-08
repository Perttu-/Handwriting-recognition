classdef preprocessor<handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        %images
        originalImage;
        map;
        noiselessImage;
        binarizedImage;
        openedImage;
        closedImage;
        
        %arguments
        wienerFilterSize;
        sauvolaNeighbourhoodSize;
        sauvolaThreshold;
        morphOpeningLowThreshold;
        morphOpeningHighThreshold;
        morphClosingDiscSize;
        
        %found object properties
        boundaries;
        boundingBoxes;
        eccentricities;
    end
    
    
    methods
        %setters
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
        
        %getters
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
    
    
        %the preprocessing itself
        function [boundaries, boundingBoxes] = preprocess(obj)

            if ~isempty(obj.map)
                img = ind2rgb(obj.originalImage,obj.map);
            else
                img = obj.originalImage;
            end

            [~, ~, numberOfColorChannels] = size(img);
            if numberOfColorChannels > 1
                grayImage = rgb2gray(img);
            else
                grayImage = img; 
            end

            obj.noiselessImage = wiener2(grayImage, [obj.wienerFilterSize, obj.wienerFilterSize]);

            bin=sauvola(obj.noiselessImage, [obj.sauvolaNeighbourhoodSize, obj.sauvolaNeighbourhoodSize], obj.sauvolaThreshold);
            obj.binarizedImage = imcomplement(bin);

            obj.openedImage = xor(bwareaopen(obj.binarizedImage, obj.morphOpeningLowThreshold),...
                                               bwareaopen(obj.binarizedImage, obj.morphOpeningHighThreshold)); 

            obj.closedImage = imdilate(obj.openedImage,strel('disk',obj.morphClosingDiscSize));

            obj.eccentricities = regionprops(obj.closedImage,'eccentricity');
            obj.boundingBoxes = regionprops(obj.closedImage,'boundingbox');
            obj.boundaries = bwboundaries(obj.closedImage,8,'holes'); 
            boundingBoxes = obj.boundingBoxes;
            boundaries = obj.boundaries;
        end
            
    end
end


