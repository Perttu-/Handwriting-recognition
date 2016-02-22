function resultStruct = hwrTest(folderPath)
    close all;
    files = dir([folderPath,'/','*.png']);
    
    %TODO add some kind of loop(s) that loops throught different constants
    %thresholds etc.
    numberOfFiles = length(files);
    resultStruct = struct('ImageName',[],...
                          'RealRows',[],...
                          'FoundRows',[],...
                          'RealWords',[],...
                          'FoundWords',[]);
    for ii = 1:numberOfFiles
        file = files(ii);
        [~,fName,~] = fileparts(file.name);       
        [hwRows, hwWords] = getLayoutInfo(parseXML([fName,'.xml']));
        disp(['[ Processing file ',int2str(ii),'/',int2str(numberOfFiles),' ]'])
        [image, map] = imread([fName,'.png']);
        layoutStruct = preprocess2(image, map);
        foundRows = layoutStruct.NumberOfRows;
        foundWords = layoutStruct.NumberOfWords;
        disp(['Rows:',int2str(foundRows),'/',int2str(hwRows)]);
        disp(['Words:',int2str(foundWords),'/',int2str(hwWords)]);
        
        resultStruct(ii).ImageName = fName;
        resultStruct(ii).RealRows = hwRows;
        resultStruct(ii).RealWords = hwWords;
        resultStruct(ii).FoundRows = foundRows;
        resultStruct(ii).FoundWords = foundWords;
    end
    figure();
    diff = abs([resultStruct.RealRows]-[resultStruct.FoundRows]);
    bar(diff);
    set(gca,'XTick',1:1:25);
    xlim([0,26]);
    hold on;
    mn = mean(diff);
    plot([1,25],[mn,mn],'LineWidth',3);
    
    
end