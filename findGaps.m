function imageStruct = findGaps(imageStruct)
    %getting information of the consecutive zero pixels
    %saving them as their start and end point pairs into the image struct
    for ii=1:length(imageStruct)
        vHist = imageStruct(ii).VerticalHistogram;
        bHist = vHist~=0;
        ebHist = [1,bHist,1];
        stloc = strfind(ebHist,[1 0]);
        endloc = strfind(ebHist,[0 1]);
        gaps = [];
        for jj =1:length(stloc)
            gaps(jj,:) = [stloc(jj),endloc(jj)];
        end
        imageStruct(ii).Gap = gaps;
    end
end