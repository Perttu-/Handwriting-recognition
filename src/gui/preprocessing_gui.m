function preprocessing_gui
    close all;
    f = figure();
    global filename;
    filename = '';
    handles = guihandles(f);

    openButton   = uicontrol(f,'Style','pushbutton',...
                                        'String','Open image',...
                                        'Callback',@openButton_callback);

    preprocessButton   = uicontrol(f,'Style','pushbutton',...
                                                 'String','Preprocess',...
                                                 'Callback', {@preprocessButton_callback, handles});

    filenameTextBox = uicontrol(f,'Style','text',...
                                                'String','-',...
                                                'Position',[200,400,130,20]);

   imageAxes =axes('Parent', f, ...
                              'Units', 'normalized', ...
                              'HandleVisibility','callback', ...
                              'Position',[0.11 0.13 0.80 0.67]);
                                            
    %align([preprocessButton, openButton,filenameTextBox],'Center','None');
    
end

function openButton_callback(source, eventdata)
    global filename;
    [filename, pathname] = uigetfile({'*.jpg';'*.png';'*.gif';'*.tiff';'*.*'},'File Selector');
    
end

function preprocessButton_callback(source, eventdata)
global filename;
    if ~isempty(filename)
        disp('Preprocessing starts...');
        [boundaries,boundingBoxes] = preprocess(filename);
        disp('Preprocessing done!');
    else
        disp('Select file first.');
    end
end

