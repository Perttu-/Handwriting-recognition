function removeXMLDoctype(path)
    xmlFiles = dir([path,'/*.xml']);
    for i = 1:length(xmlFiles)
        A = regexp( fileread([path,'/',xmlFiles(i).name]), '\n', 'split');
        
        A{3} = sprintf('');
        fid = fopen(['/home/perttu/Programming/IAMFull/xmlremoved2/',xmlFiles(i).name], 'w');
        fprintf(fid, '%s\n', A{:});
        fclose(fid);

    end
end