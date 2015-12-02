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

% Last Modified by GUIDE v2.5 02-Dec-2015 14:03:10

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

% Update handles structure
guidata(hObject, handles);


global filename;
global imageLoaded;

filename='';
imageLoaded = false;
%[wiener,]
global inputArray;
inputArray = [];



% UIWAIT makes gui2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


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
    
    global filename;
    global imageLoaded;
    [filename, pathname] = uigetfile({'*.jpg';'*.png';'*.gif';'*.tiff';'*.*'},'File Selector');
    cla;
    imshow(filename, 'parent',handles.imageAxes);
    imageLoaded = true;
    



% --- Executes on button press in preprocessButton.
function preprocessButton_Callback(hObject, eventdata, handles)
% hObject    handle to preprocessButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure witfloath handles and user data (see GUIDATA)

    global filename;
    global imageLoaded;
    wienerFilterSize = str2double(get(handles.wienerFilterSize, 'string'));
    sauvolaNeighbourhoodSize = str2double(get(handles.sauvolaNeighbourhoodSize,'string'));
	sauvolaThreshold = str2double(get(handles.sauvolaThreshold, 'string'));
    morphOpeningLowThreshold = str2double(get(handles.morphOpeningLowThreshold, 'string'));
    morphOpeningHighThreshold = str2double(get(handles.morphOpeningHighThreshold, 'string'));
    morphClosingDiscSize = str2double(get(handles.morphClosingDiscSize, 'string'));

%     inputArray=[str2double(get(handles.wienerFilterSize, 'string')),...
%     str2double(get(handles.sauvolaNeighbourhoodSize,'string')),...
%     str2double(get(handles.sauvolaThreshold, 'string')),...
%     str2double(get(handles.morphOpeningLowThreshold, 'string')),...
%     str2double(get(handles.morphOpeningHighThreshold, 'string')),...
%     str2double(get(handles.morphClosingDiscSize, 'string'))];

   imshow(filename, 'parent',handles.imageAxes);
   hold on;
    if ~isempty(filename) && imageLoaded==true
        disp('Preprocessing started.');

        %[boundaries,boundingBoxes] = preprocess(filename,inputArray);
        [boundaries,boundingBoxes] = preprocess(filename,...    
                                                                        wienerFilterSize,...
                                                                        sauvolaNeighbourhoodSize,...
                                                                        sauvolaThreshold,...
                                                                        morphOpeningLowThreshold,...
                                                                        morphOpeningHighThreshold,...
                                                                        morphClosingDiscSize);
        disp('Preprocessing done.');
        
        for i =1:length(boundaries)
            boundary = boundaries{i};
            plot(boundary(:,2),boundary(:,1),'g','LineWidth',1);
        end

        for i = 1:length(boundingBoxes)
            box = boundingBoxes(i).BoundingBox;
            rectangle('Position', [box(1),box(2),box(3),box(4)], 'EdgeColor','r','LineWidth',1);
        end

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
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sauvolaThreshold as text
%        str2double(get(hObject,'String')) returns contents of sauvolaThreshold as a double


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
