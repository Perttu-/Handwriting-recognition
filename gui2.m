function varargout = gui2(varargin)
% GUI2 MATLAB code for gui2.fig
%      GUI2, by itself, creates a new GUI2 or raises the existing
%      singleton*.
%
%      H = GUI2 returns the handle to a new GUI2 or the handle to
%      the existing singleton*.
%
%      GUI2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI2.M with the given input arguments.
%
%      GUI2('Property','Value',...) creates a new GUI2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui2

% Last Modified by GUIDE v2.5 08-Dec-2015 14:10:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui2_OpeningFcn, ...
                   'gui_OutputFcn',  @gui2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before gui2 is made visible.
function gui2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui2 (see VARARGIN)

% Choose default command line output for gui2
handles.output = hObject;
handles.boundaries=[];
handles.boundingBoxes=[];
% Update handles structure
guidata(hObject, handles);

global filename;
global imageLoaded;

filename='';
imageLoaded = false;

global p;
p = preprocessor;

% UIWAIT makes gui2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function displayObjects(hObject, handles, display)
global p;
    if display == 1
        for i =1:length(p.boundaries)
            boundary = p.boundaries{i};
            handles.boundaries(i) = plot(boundary(:,2),boundary(:,1),'g','LineWidth',1);
        end

        for i = 1:length(p.boundingBoxes)
            box = p.boundingBoxes(i).BoundingBox;
            handles.boundingBoxes(i) = rectangle('Position', [box(1),box(2),box(3),box(4)], 'EdgeColor','r','LineWidth',1);
        end
        guidata(hObject, handles);
    end
    if display == 0
        %t?s on joku bugi. 
        %ei toimi jos muutetaan asetuksia ja preprosessoidaan sen j?lkeen
        set(handles.boundaries, 'visible', 'off');
        set(handles.boundingBoxes, 'visible', 'off');
    end


% --- Outputs from this function are returned to the command line.
function varargout = gui2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in openImageButton.
function openImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to openImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    global p;
    global imageLoaded;
    handles.boundaries=[];
    handles.boundingBoxes=[];
    guidata(hObject, handles);
    
    [filename, ~] = uigetfile({'*.jpg';'*.png';'*.gif';'*.tiff';'*.*'},'File Selector');
    if filename 
        p.originalImage = filename;
    end
    p.map = filename;
    cla;
    set(handles.fileNameText,'String',filename);
    imshow(filename, 'parent',handles.imageAxes);
    imageLoaded = true;
    hold on;
    
% --- Executes on button press in preprocessButton.
function preprocessButton_Callback(hObject, eventdata, handles)
% hObject    handle to preprocessButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure witfloath handles and user data (see GUIDATA)
global p;
global imageLoaded;
p.wienerFilterSize = str2double(get(handles.wienerFilterSize, 'string'));
p.sauvolaNeighbourhoodSize = str2double(get(handles.sauvolaNeighbourhoodSize,'string'));
p.sauvolaThreshold = str2double(get(handles.sauvolaThreshold, 'string'));
p.morphOpeningLowThreshold = str2double(get(handles.morphOpeningLowThreshold, 'string'));
p.morphOpeningHighThreshold = str2double(get(handles.morphOpeningHighThreshold, 'string'));
p.morphClosingDiscSize = str2double(get(handles.morphClosingDiscSize, 'string'));

if imageLoaded==true
    disp('Preprocessing started.');
    p.preprocess;
    
    disp('Preprocessing done.');
    cla;
    imshow(p.originalImage, 'parent',handles.imageAxes);
    hold on;
    displayObjects(hObject, handles, 1);
    set(handles.displayObjects,'Value',1);
    set(handles.imageMenu,'Value',1);
else
    disp('Select file first.');
end

function wienerFilterSize_Callback(hObject, eventdata, handles)
% hObject    handle to wienerFilterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of wienerFilterSize as text
%        str2double(get(hObject,'String')) returns contents of wienerFilterSize as a double

% --- Executes during object creation, after setting all properties.
function wienerFilterSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wienerFilterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sauvolaNeighbourhoodSize_Callback(hObject, eventdata, handles)
% hObject    handle to sauvolaNeighbourhoodSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of sauvolaNeighbourhoodSize as text
%        str2double(get(hObject,'String')) returns contents of sauvolaNeighbourhoodSize as a double

% --- Executes during object creation, after setting all properties.
function sauvolaNeighbourhoodSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sauvolaNeighbourhoodSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function sauvolaThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to sauvolaThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)% Hints: get(hObject,'String') returns contents of sauvolaThreshold as text
%        str2double(get(hObject,'String')) returns contents of
%        sauvolaThreshold as a doubles

% --- Executes during object creation, after setting all properties.
function sauvolaThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sauvolaThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
function morphOpeningLowThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to morphOpeningLowThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of morphOpeningLowThreshold as text
%        str2double(get(hObject,'String')) returns contents of morphOpeningLowThreshold as a double

% --- Executes during object creation, after setting all properties.
function morphOpeningLowThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to morphOpeningLowThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function morphOpeningHighThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to morphOpeningHighThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of morphOpeningHighThreshold as text
%        str2double(get(hObject,'String')) returns contents of morphOpeningHighThreshold as a double

% --- Executes during object creation, after setting all properties.
function morphOpeningHighThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to morphOpeningHighThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function morphClosingDiscSize_Callback(hObject, eventdata, handles)
% hObject    handle to morphClosingDiscSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of morphClosingDiscSize as text
%        str2double(get(hObject,'String')) returns contents of morphClosingDiscSize as a double
% --- Executes during object creation, after setting all properties.
function morphClosingDiscSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to morphClosingDiscSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in imageMenu.
function imageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to imageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: contents = cellstr(get(hObject,'String')) returns imageMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from imageMenu
contents = cellstr(get(hObject,'String'));
global p;
switch (contents{get(hObject,'Value')})
    
    case 'Original'
        cla;
        set(handles.displayObjects,'Value',0);
        imshow(p.originalImage, 'parent', handles.imageAxes);
        
    case 'Noiseless'
        cla;
        set(handles.displayObjects,'Value',0);
        imshow(p.noiselessImage, 'parent', handles.imageAxes)
        
    case 'Binarized'
        cla;
        set(handles.displayObjects,'Value',0);
        imshow(p.binarizedImage, 'parent', handles.imageAxes);

    case 'Morphologically opened'
        cla;
        set(handles.displayObjects,'Value',0);
        imshow(p.openedImage, 'parent', handles.imageAxes);
        
    case 'Morphologically closed'
        cla;
        set(handles.displayObjects,'Value',0);
        imshow(p.closedImage, 'parent', handles.imageAxes);
end


% --- Executes during object creation, after setting all properties.
function imageMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in displayObjects.
function displayObjects_Callback(hObject, eventdata, handles)
% hObject    handle to displayObjects (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of displayObjects    

displayObjects(hObject, handles, get(hObject,'Value'));
