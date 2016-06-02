function hwrTest(folderPath)
    %Input: Full path to image folder with corresponding XML documents.
    imageFiles = dir([folderPath,'/*.png']);
    xmlFiles = dir([folderPath,'/*.xml']);
    numberOfImageFiles = length(imageFiles);
    numberOfXmlFiles = length(xmlFiles);
    if numberOfImageFiles~=numberOfXmlFiles
        disp('Number of images and xml-files does not match.');
        return
    end
    
    tests = 1;
    testValues = 1;
    for i = 1:length(tests)
        for j = 1:length(testValues)
            for k = 1:numberOfFiles
                xmlStruct = parseXML([fName,'.xml']);
                
                %HWR(files(k));
            end
        end
    end
end