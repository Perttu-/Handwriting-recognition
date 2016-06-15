function totalLines = getLineAmounts(xmlStruct)
    firstChildren = [xmlStruct.Children];
    machinePrintedLines = 0;
    for i = 1:size(firstChildren,2)
        if strcmp(firstChildren(i).Name,'machine-printed-part');
            nextChildren = firstChildren(i).Children;
            for j = 1:size(nextChildren,2)
                if strcmp(nextChildren(j).Name,'machine-print-line');
                    machinePrintedLines = machinePrintedLines+1;
                end
            end
        end
    end
    
    secondChildren = [xmlStruct.Children.Children];
    handWrittenLines =  0;
    for ii = 1:size(secondChildren,2)
        if strcmp(secondChildren(ii).Name,'line')
            handWrittenLines = handWrittenLines + 1;
        end
    end
    totalLines = machinePrintedLines+handWrittenLines+2;
end