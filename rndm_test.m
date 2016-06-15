
%doesnt work
testcell = cell(5,5,3);

for i = 1:numel(testcell)
    testcell{i}=randi([1 10],3,3);
end
        
testarray = cat(3,randi([1 10],5,5),randi([1 10],5,5),randi([1 10],5,5));
searchedObjects = 1:10;
cellTic = tic;
% while ~isempty(testcell)       
%     testcell = cellfun(@(x) x(~ismember(x,searchedObjects)),...
%                                 testcell,...
%                                 'UniformOutput',false);
% end
% disp(num2str(toc(cellTic)));
arrTic = tic;
while ~isempty(testarray)       
    testarray = arrayfun(@(x) x(~ismember(x,searchedObjects)),...
                                testarray,...
                                'UniformOutput',false);
end
disp(num2str(toc(arrTic)));