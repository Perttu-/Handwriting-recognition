function [hwRows,hwWords] = getLayoutInfo(xmlStruct)
    childs = [xmlStruct.Children.Children];
    attr = childs;
    hwRows =  0;
    hwWords = 0;
    for ii = 1:length(attr)
        if strcmp(attr(ii).Name,'line')
            hwRows = hwRows + 1;
        end
    end
    attr2 = [childs.Children];
    for ii = 1:length(attr2)
        if strcmp(attr2(ii).Name,'word')
            hwWords = hwWords + 1;
        end
    end
end