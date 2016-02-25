function testStruct = hwrTest(folderPath)
    %test function to see wheter the number of found rows match those
    %defined in the xml file. 
    %Note: images must be cropped to handwriting part only.
    %this function scans the selected folder and looks for all .png files
    %and correspondingly named .xml files
    %e.g. a01-000u.png & a01-000u.xml
    %vertical expansion?
    %testValues = [5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80];
    %wiener
    %testValues = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
    %sauvola window
    %testValues = [160,170,180,190,200,210,220,230,240,250,260,270,280,290,300];
    %sauvola threshold
    %testValues = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2];
    %morph closing disk size
    %testValues = [-1,0,1,2,3,4,5,6,7,8,9,10];
    %stroke width threshold
    %testValues = [0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2];
    %skew correction
    %testValues = [1,0];
    %aoi x/y expansion
    %testValues = [10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200];
    %area ratio threshold
    %testValues = [0.001,0.002,0.003,0.004,0.005,0.006,0.007,0.008,0.009,0.01];
    %rlsaRowThreshold
    %testValues = [50,100,150,200,250,300,350,400,450,500,550,600,650,700,750,800];
    %rlsaword horizontal/vertical
    %testValues = [5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80];
    testValues = 1;
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
            if isempty(layoutStruct)
                disp('No layout found!');
            end
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