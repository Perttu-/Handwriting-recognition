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
    
    testStruct = struct('TestName',[],...
                        'TestValues',[]);
                    
    testValues = 1;
    testTic = tic;
    for i = 1:size(testStruct,2)
        for j = 1:length(testValues)
            for k = 1:numberOfImageFiles
                disp(['Processing file ', num2str(k) ,'/',num2str(numberOfImageFiles)]);
                imageName = imageFiles(k).name;
                xmlName = xmlFiles(k).name;
                xmlStruct = parseXML(xmlName);
                totalLines = getLineAmounts(xmlStruct);
                [foundLines,preProcTime,rowDetTime] = HWR([folderPath,imageName],0);
            end
        end
    end
    disp(['Tests took ', num2str(toc(testTic)) ,' seconds']);
end