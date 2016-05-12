classdef preprocessor<handle
    %Includes image aquisition, noise removal with adaptive Wiener filter, 
    %binarization with Sauvola algorithm, and stroke analysis to help 
    %determining text regions.
    properties
        %Images
        originalImage;
        map;
        grayImage;
        noiselessImage;
        binarizedImage;
        horizontalImage;
        openedImage;
        closedImage;
        strokeImage;
        finalImage;
        skeletonImage;
        strokeWidthImage;
        
        %Arguments
        wienerFilterSize;
        sauvolaNeighbourhoodSize;
        sauvolaThreshold;
        skewCorrection;
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
        

        
    end
    
    
    methods
        %constructor
        function p = preprocessor(img,...
                                  map,...
                                  wSize,...
                                  sauvolaN,...
                                  sauvolaT,...
                                  skew,...
                                  morphD,...
                                  strokeT)
                              
        p.originalImage = img;
        p.map = map;
        p.wienerFilterSize = wSize;
        p.sauvolaNeighbourhoodSize = sauvolaN;
        p.sauvolaThreshold = sauvolaT;
        p.skewCorrection = skew;
        p.morphClosingDiscSize = morphD;
        p.strokeWidthThreshold = strokeT;
                              
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
        
        function strokeWidthImage = get.strokeWidthImage(obj)
            strokeWidthImage = obj.strokeWidthImage;
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
    
    
        %% Preprocessing
        %Optional phases can be disabled with input -1
        function processedImage = preprocess(obj)
            %% Image aquisition
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

            %% Noise Removal
            %Remove noise with adaptive wiener filter
            w = obj.wienerFilterSize;
            if w ~= -1
                obj.noiselessImage = wiener2(obj.grayImage,...
                                            [w,w]);
            else
                obj.noiselessImage = obj.grayImage;
            end
            
            %% Adapthisteg???

            %% Binarization
            %binarize image with adaptive Sauvola algorithm 
            
            neighbourhood = obj.sauvolaNeighbourhoodSize;
            bin=sauvola(obj.noiselessImage,...
                       [neighbourhood,...
                       neighbourhood],...
                       obj.sauvolaThreshold);
                   
            
            %Inverse colors for further processing
            obj.binarizedImage = ~bin;
            
            %% Skew correction
            if obj.skewCorrection == 1
                obj.horizontalImage = imrotate(obj.binarizedImage,-horizon(obj.binarizedImage));
            else
                obj.horizontalImage = obj.binarizedImage;
            end
            
            %% Hole removal
            %Morphological closing to remove unnecessary holes
            disc = obj.morphClosingDiscSize;
            if disc > 0
                obj.closedImage = imdilate(obj.horizontalImage,...
                                  strel('disk',disc));
            else
                obj.closedImage = obj.horizontalImage;
            end
            
            %% Stroke width analysis
            subImageList = regionprops(obj.closedImage, 'Image');
            subImageAmount = length(subImageList);
            strokeWidthFilterIdx = false(1, subImageAmount);
            metrics = zeros(1, subImageAmount);
            obj.strokeWidthImage = bwdist(~obj.closedImage);
                
            for i = 1:subImageAmount
                binaryImage = subImageList(i).Image;
                %bwdist gets the Euclidean distance to nearest nonzero pixel
                distanceImage = bwdist(~binaryImage);
                subimageSkeleton = bwmorph(binaryImage, 'thin', inf);
                %one dimensional array containing all strokes
                strokeWidthValues = distanceImage(subimageSkeleton);
                %calculating the metric to analyze stroke width variation
                strokeWidthMetric = std(strokeWidthValues)/mean(strokeWidthValues);

                %above metric can result in NaN  or zero values when mean is 0 
                %happens with one pixel areas and round areas
                %can't be filtered out or else writing data is lost
                
                if isnan(strokeWidthMetric) || strokeWidthMetric == 0    
                    strokeWidthFilterIdx(i) = 0;
                else
                    %objects with higher metric than threshold marked for
                    %removal
                    strokeWidthFilterIdx(i) = strokeWidthMetric > obj.strokeWidthThreshold;
                end
                metrics(i) = strokeWidthMetric;
            end
            pixels = regionprops(obj.closedImage,'PixelIdxList');
            removedPixels = vertcat(pixels(strokeWidthFilterIdx).PixelIdxList); 
            strkImg = obj.closedImage;
            strkImg(removedPixels) = 0;
            obj.strokeImage = strkImg;
            processedImage = strkImg;
            
            
        end
    end
end


