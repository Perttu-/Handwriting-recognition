function hwrTest(folderPath)
    close all;
    files = dir([folderPath,'/','*.png']);
    numberOfFiles = length(files);
    for ii = 1:numberOfFiles
        disp(['[ Processing file ',int2str(ii),'/',int2str(numberOfFiles),' ]'])
        file = files(11);
        preprocess2(file.name);
    end
end