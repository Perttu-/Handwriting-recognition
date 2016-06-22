function hwrTest(folderPath)
    %Input: Full path to directory containing image files with
    %corresponding XML documents.
    
    imageFiles = dir([folderPath,'/*.png']);
    xmlFiles = dir([folderPath,'/*.xml']);
    numberOfImageFiles = length(imageFiles);
    numberOfXmlFiles = length(xmlFiles);
    if numberOfImageFiles~=numberOfXmlFiles
        disp('Number of images and xml-files does not match.');
        return
    end 
    
    %% Define these for each test
    %remember to change testedValue to HWR.m
%     testName = 'n1Test';
%     testValues = 1:20;
    
%     testName = 'n2Test';
%     testValues = 0:20;

    testName = 'voterMarginTest';
    testValues = 0:20;

%     testName = 'skewDevLimTest';
%     testValues = 0:20;

%     testName = 'aroundAvgDistMarginTest';
%     testValues = 0:0.1:1;

%     testName = 'sameLineMarginTest';
%     testValues = 0:0.1:1;
    
    %% Testing process
    testTic = tic;

    disp(['----- Running test: ',testName,' -----']);

    numberOfTestValues = length(testValues);
    resultStruct = struct('TestedValue',[],...
                          'InnerResultStruct',[],...
                          'AvgPreProcessingTime',[],...
                          'AvgLineDetectionTime',[],...
                          'AvgAccuracy',[]);

    for j = 1:numberOfTestValues         
        disp(['Testing value ', num2str(j) ,'/',num2str(numberOfTestValues)]);

        testedValue = testValues(j);
        resultStruct(j).TestedValue = testedValue;
        innerResultStruct = struct('FileName',[],...
                                   'FoundLines',[],...
                                   'RealAmountOfLines',[],...
                                   'Accuracy',[],...
                                   'PreProcessingTime',[],...
                                   'LineDetectionTime',[]);
                               
        for k = 1:numberOfImageFiles 
            disp(['Processing Image: ', num2str(k) ,'/',num2str(numberOfImageFiles)]);
            imageName = imageFiles(k).name;
            [lineLabels,foundLines,preProcTime,rowDetTime] = HWR([folderPath,imageName],testedValue,0);
            
            xmlName = xmlFiles(k).name;
            xmlStruct = parseXML(xmlName);
            realLines = getLineAmounts(xmlStruct);
            
            accuracy = 1-abs(foundLines-realLines)/realLines;
            
            innerResultStruct(k).FileName = imageName;
            innerResultStruct(k).FoundLines = foundLines;
            innerResultStruct(k).RealAmountOfLines = realLines;
            innerResultStruct(k).Accuracy = accuracy;
            innerResultStruct(k).PreProcessingTime = preProcTime;
            innerResultStruct(k).LineDetectionTime = rowDetTime;
            %innerResultStruct(k).LabelImage = lineLabels;
        end
        resultStruct(j).InnerResultStruct = innerResultStruct;
    end

    disp(['Test took ', num2str(toc(testTic)) ,' seconds']);
    
    
    %% Calculations
    for i = 1:size(resultStruct,2)
        meanPreProcTime = mean([resultStruct(i).InnerResultStruct.PreProcessingTime]);
        meanLineDetTime = mean([resultStruct(i).InnerResultStruct.LineDetectionTime]);
        meanAccuracy = mean([resultStruct(i).InnerResultStruct.Accuracy]);
        resultStruct(i).AvgPreProcessingTime = meanPreProcTime;
        resultStruct(i).AvgLineDetectionTime = meanLineDetTime;
        resultStruct(i).AvgAccuracy = meanAccuracy;
    end
    
    %% Save into file
    mkdir(folderPath,'results');
    save([folderPath,'/results/', testName,'_results.mat'],'resultStruct');
    
end