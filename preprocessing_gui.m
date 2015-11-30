function preprocessing_gui

f = figure();

openButton   = uicontrol('Style','pushbutton','String','Open image','Position',[10,10,70,25],...
                        'Callback',@openButton_callback);

preprocessButton   = uicontrol('Style','pushbutton','String','Preprocess','Position',[315,220,70,25],...
                        'Callback', {@preprocessButton_callback, filename});



align([preprocessButton, openButton],'Center','None');
end

function openButton_callback(source, eventdata)
    [filename, pathname] = uigetfile({'*.jpg';'*.png';'*.gif';'*.tiff';'*.*'},'File Selector');
    filename
end

function preprocessButton_callback(source, eventdata,filename)

    preprocess(filename);

end

