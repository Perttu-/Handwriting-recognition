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
        strokeImage;
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
        imageProperties;
        
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
            finalImage = obj.strokeImage;
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
                distanceImage = bwdist(~binaryImage);
                subimageSkeleton = bwmorph(binaryImage, 'thin', inf);
                %one dimensional array containing all strokes
                strokeWidthValues = distanceImage(subimageSkeleton);
                %calculating the metric to analyze stroke width variation
                strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);
                %strokeWidthImage = distanceImage;
                %strokeWidthImage(~subimageSkeleton) = 0;
                %above metric can result in NaN  or zero values when mean is 0 
                %happens with one pixel width areas so they can be filtered
                %NaN happens if mean value is zero
                if isnan(strokeWidthMetric) || strokeWidthMetric == 0     
                    strokeWidthFilterIdx(i) = 1;
                else
                    strokeWidthFilterIdx(i) = strokeWidthMetric > obj.strokeWidthThreshold;
                end
                metrics(i) = strokeWidthMetric;
            end
            
            pixels = regionprops(obj.closedImage,'PixelIdxList');
            removedPixels = pixels(strokeWidthFilterIdx).PixelIdxList; %??? rikki
            obj.strokeImage = obj.closedImage;
            obj.strokeImage(removedPixels) = 0;
            obj.strokeMetrics = metrics;
            

            
            fImage = obj.finalImage;
            %Calculate boundaries and bounding boxes for visualization and
            %to extract the needed blobs
            obj.boundingBoxes = regionprops(fImage,'boundingbox');
            obj.boundaries = bwboundaries(fImage,8,'holes'); 
            boundingBoxes = obj.boundingBoxes;
            boundaries = obj.boundaries;
            obj.objectCount = length(boundingBoxes);
            
            %Extract properties which may be of use
            
            obj.imageProperties = regionprops(fImage,'Eccentricity',...
                                                     'EulerNumber',...
                                                     'Extent',...
                                                     'Solidity',...
                                                     'MinorAxisLength',...
                                                     'MajorAxisLength',...
                                                     'Area',...
                                                     'Perimeter',...
                                                     'Centroid');
            
            %2spooky4me
            obj.skeletonImage =  bwmorph(obj.finalImage,'skel',Inf);
            
        end
    end
end


