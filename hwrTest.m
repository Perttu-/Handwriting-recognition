function testStruct = hwrTest(folderPath)
    %test function to see wheter the number of found rows match those
    %defined in the xml file. 
    %Note: images must be cropped to handwriting part only.
    %this function scans the selected folder and looks for all .png files
    %and correspondingly named .xml files
    %e.g. a01-000u.png & a01-000u.xml
    testValues = [0,2,4,6,8,10,12,14,16,18,20];
    close all;
    files = dir([folderPath,'/','*.png']);
    numberOfFiles = length(files);
    testStruct = struct('TestedValue',testValues,...
                        'RowDiffPercMean',[],...
                        'WordDiffPercMean',[],...
                        'MeanPreprocessingTime',[],...
                        'MeanLayoutAnalysisTime',[],...
                        'ResultStruct',[]);
    for ii = 1:length(testValues)
        disp(['------Test number: ', int2str(ii),' ------']);
        testedValue = testValues(ii);
        resultStruct = struct('ImageName',[],...
                              'RealRows',[],...
                              'FoundRows',[],...
                              'RealWords',[],...
                              'FoundWords',[]);
        preprocessingTimes = zeros(numberOfFiles,1);
        layoutAnalysisTimes = preprocessingTimes;
        for jj = 1:numberOfFiles
            file = files(jj);
            [~,fName,~] = fileparts(file.name);       
            [hwRows, hwWords] = getLayoutInfo(parseXML([fName,'.xml']));
            disp(['[ Processing file ',int2str(jj),'/',int2str(numberOfFiles),' ]'])

            layoutStruct = preprocess([fName,'.png'],testedValue);
            foundRows = layoutStruct.NumberOfRows;
            foundWords = layoutStruct.NumberOfWords;
            disp(['Rows:',int2str(foundRows),'/',int2str(hwRows)]);
            disp(['Words:',int2str(foundWords),'/',int2str(hwWords)]);

            resultStruct(jj).ImageName = fName;
            resultStruct(jj).RealRows = hwRows;
            resultStruct(jj).RealWords = hwWords;
            resultStruct(jj).FoundRows = foundRows;
            resultStruct(jj).FoundWords = foundWords;
            preprocessingTimes(jj) = layoutStruct.PreprocessingTime; 
            layoutAnalysisTimes(jj) = layoutStruct.LayoutAnalysisTime; 
        end
%         figure();
        rowDiff = abs([resultStruct.RealRows]-[resultStruct.FoundRows]);
        wordDiff = abs([resultStruct.RealWords]-[resultStruct.FoundWords]);
        rowDiffPercentage = rowDiff./[resultStruct.RealRows];
        wordDiffPercentage = wordDiff./[resultStruct.RealWords];
        rowDiffPercMean = mean(rowDiffPercentage);
        wordDiffPercMean = mean(wordDiffPercentage);
% 
%         bar([rowDiffPercentage',wordDiffPercentage'])
%         set(gca,'XTick',1:1:25);
%         xlim([0,26]);
% 
%         hold on;
% 
%         plot([1,25],[rowDiffPercMean,rowDiffPercMean],'color','b');
%         plot([1,25],[wordDiffPercMean,wordDiffPercMean],'color','y');
%         legend('Row difference','Word difference','Row difference mean','Word difference mean');
        
        testStruct(ii).RowDiffPercMean = rowDiffPercMean;
        testStruct(ii).WordDiffPercMean = wordDiffPercMean;
        testStruct(ii).ResultStruct = resultStruct;
        testStruct(ii).MeanPreprocessingTime = mean(preprocessingTimes);
        testStruct(ii).MeanLayoutAnalysisTime = mean(layoutAnalysisTimes);
    end
    figure(),plot([testStruct.RowDiffPercMean]);
    hold on, plot([testStruct.WordDiffPercMean]);
    legend('Mean row difference','Mean word difference');
    
    figure(),plot([testStruct.MeanPreprocessingTime]);
    hold on, plot([testStruct.MeanLayoutAnalysisTime]);
    legend('Mean preprocessing time','Mean layout analysis time');
    
    
end