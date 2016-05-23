function [ul,ur,ll,lr] = extractBoxCornerCoords(box)
    %extracting the end points of given bounding box sides
    ul = [box(:,1),box(:,2)];
    ur = [box(:,1)+box(:,3),box(:,2)];
    ll = [box(:,1),box(:,2)+box(:,4)];
    lr = [box(:,1)+box(:,3),box(:,2)+box(:,4)];
end