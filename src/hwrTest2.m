function hwrTest2(folderPath)
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
    

     testName = 'n1_votermargin_Test';
     n1TestValues = 1:20;
     vmTestValues = 0:20;


    %% Testing process
    testTic = tic;

    disp(['----- Running test: ',testName,' -----']);
    
    numberOfN1TestValues = length(n1TestValues);
    numberOfVmTestValues = length(vmTestValues);
    initialAccuracyArray = zeros(numberOfN1TestValues,numberOfVmTestValues,100);
    initialLineDetTimeArray = initialAccuracyArray;
    
    for i = 1:numberOfN1TestValues
        for j = 1:numberOfVmTestValues         
            disp(['Testing values ', num2str(i) ,'&',num2str(j)]);
            
            testedN1Value = n1TestValues(i);
            testedVmValue = vmTestValues(j);

            for k = 1:numberOfImageFiles 
                disp(['Processing Image: ', num2str(k) ,'/',num2str(numberOfImageFiles)]);
                imageName = imageFiles(k).name;
                [foundLines,preProcTime,rowDetTime] = HWR([folderPath,imageName],testedN1Value,testedVmValue,0);

                xmlName = xmlFiles(k).name;
                xmlStruct = parseXML(xmlName);
                realLines = getLineAmounts(xmlStruct);

                accuracy = 1-abs(foundLines-realLines)/realLines;
                initialAccuracyArray(i,j,k)=accuracy;
                initialLineDetTimeArray(i,j,k)=rowDetTime;

            end
            
        end

    end

    disp(['Test took ', num2str(toc(testTic)) ,' seconds']);
    
    
    %% Calculations
    avgAccuracyArray = zeros(numberOfN1TestValues,numberOfVmTestValues);
    avgLineDetTimeArray = avgAccuracyArray;
    for i = 1:size(initialAccuracyArray,1)
        for j = 1:size(initialAccuracyArray,2)
            meanLineDetTime = mean(initialAccuracyArray(i,j,:));
            meanAccuracy = mean(initialLineDetTimeArray(i,j,:));
            avgLineDetTimeArray(i,j,:) = meanLineDetTime;
            avgAccuracyArray(i,j,:) = meanAccuracy;
        end
    end
    
    
    %% Save into file
    mkdir(folderPath,'results');
    save([folderPath,'/results/', testName,'_results.mat'],'avgAccuracyArray','avgLineDetTimeArray');
    
end