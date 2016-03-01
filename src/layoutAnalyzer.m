classdef layoutAnalyzer
    properties
        %images
        inputImage;

        rowRlsaImages;
        wordRlsaImages;
        
        %arguments
        aoiXExpansionAmount;
        aoiYExpansionAmount;
        areaRatioThreshold;
        rlsaRowThreshold;
        rlsaWordThreshold;
        
        layout;
        
        
    end
    
    methods
               
        function l = layoutAnalyzer(img,...
                                    xExp,...
                                    yExp,...
                                    areaT,...
                                    rlsaR ,...
                                    rlsaW)
           l.inputImage = img;
           l.aoiXExpansionAmount = xExp;
           l.aoiYExpansionAmount = yExp;
           l.areaRatioThreshold = areaT;
           l.rlsaRowThreshold = rlsaR;
           l.rlsaWordThreshold = rlsaW;

        end
        
        function layout = analyze(obj)
            preprocessedImage = obj.inputImage;
            layoutStruct = struct('Image',preprocessedImage,...
                                  'NumberOfRows',[],...
                                  'NumberOfWords',[],...
                                  'AoiBoxes',[],...
                                  'AoiStruct',[]);

            boundingBoxes = regionprops(preprocessedImage,'BoundingBox');
            if isempty(boundingBoxes)
                layoutStruct.LayoutAnalysisTime = -1;
                layoutStruct.NumberOfRows = 0;
                layoutStruct.NumberOfWords = 0;
                layout = layoutStruct;
                return 
            end
            
            %Expanding the bounding boxes
            largeBBoxes=expandBBoxes(preprocessedImage,...
                                    boundingBoxes,...
                                    obj.aoiXExpansionAmount,...
                                    obj.aoiYExpansionAmount);

            %combine boxes which overlap more than given threshold
            [combinedBBoxes, ~] = combineOverlappingBoxes(largeBBoxes, 0);

            %combine elements which might not have been combined on last time
            [combinedBBoxes, ~] = combineOverlappingBoxes(combinedBBoxes, 0);

            %remove boxes which take only a fraction of the total area.
            areas = combinedBBoxes(:,3).*combinedBBoxes(:,4);
            totalArea = sum(areas);
            areaRatio = areas/totalArea;
            combinedBBoxes((areaRatio<obj.areaRatioThreshold),:)=[];

            layoutStruct.AoiBoxes = combinedBBoxes;

            %area of interest image extraction
            aois = size(combinedBBoxes,1);
            aoiStruct = struct('Image',[],...
                               'ObjectCount', [],...
                               'RlsaImage',[],...
                               'RowBoxes',[],...
                               'RowStruct',[]);

            wordAmount = 0;
            for ii=1:aois
                bbox = combinedBBoxes(ii,:);
                subImage = imcrop(preprocessedImage, bbox);
                aoiImage = subImage;

                %extracting properties from the area of interest
                %average area might be useful in line/word detection thresholds?
                [~, numberOfObjects] = bwlabel(aoiImage);
                aoiStruct(ii).Image = aoiImage;
                aoiStruct(ii).ObjectCount = numberOfObjects;

                %line detection with rlsa method 
                rowRlsaImage = rlsa(subImage,obj.rlsaRowThreshold,1);

                aoiStruct(ii).RlsaImage = rowRlsaImage;
                rowBoxStruct = regionprops(rowRlsaImage,'BoundingBox');
                rowBoxes = transpose(reshape([rowBoxStruct.BoundingBox],4,[]));
                
                %remove boxes which are more tall than wide
                rowBoxes((rowBoxes(:,3)<rowBoxes(:,4)),:)=[];

                aoiStruct(ii).RowBoxes = rowBoxes;
                rowBoxesLength = size(rowBoxes,1);
                rowStruct = struct('RowImage',[],...
                                   'RlsaImage',[],...
                                   'WordBoxes',[]);
                for jj=1:rowBoxesLength
                    rowImage = imcrop(aoiImage,rowBoxes(jj,:));
                    rowStruct(jj).RowImage = rowImage;
                    wordRlsaImage = rlsa(rowImage,obj.rlsaWordThreshold,1);
                    wordRlsaImage = rlsa(wordRlsaImage,obj.rlsaWordThreshold,0);

                    rowStruct(jj).RlsaImage = wordRlsaImage;
                    wordBoxes = regionprops(wordRlsaImage,'BoundingBox');
                    wordBoxList = transpose(reshape([wordBoxes.BoundingBox],4,[]));
                    [combinedWordBoxes,~] = combineOverlappingBoxes(wordBoxList,0);
                    [combinedWordBoxes,~] = combineOverlappingBoxes(combinedWordBoxes,0);
                    wordAmount = wordAmount + size(combinedWordBoxes,1);
                    rowStruct(jj).WordBoxes = combinedWordBoxes;
                end
                aoiStruct(ii).RowStruct = rowStruct;
            end
            
            %TODO remove aois which doesn't have any rows
            
            layoutStruct.AoiStruct = aoiStruct;
            layoutStruct.NumberOfRows = rowBoxesLength;
            layoutStruct.NumberOfWords = wordAmount;
            layout = layoutStruct;
        end 
    end
end